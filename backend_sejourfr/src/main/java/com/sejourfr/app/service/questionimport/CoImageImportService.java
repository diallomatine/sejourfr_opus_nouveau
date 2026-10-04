package com.sejourfr.app.service.questionimport;

import com.sejourfr.app.audioquestion.entity.AudioQuestionDraft;
import com.sejourfr.app.audioquestion.service.CloudflareR2Client;
import com.sejourfr.app.audioquestion.service.CloudflareR2Client.R2UploadResult;
import com.sejourfr.app.config.QuestionImportProperties;
import com.sejourfr.app.dto.CoImageImportReport;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AudioQuestionDraftManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.mapper.CoImageImportMapper;
import com.sejourfr.app.service.questionimport.CoImageImportValidator.ManifesteLu;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Import par lot des questions TCF CO image, vers des BROUILLONS
 * ({@code audio_question_draft}, statut {@code TEXT_VALIDATED}) — jamais vers
 * {@code questions} : la synthese audio, la revue et la publication restent
 * celles du pipeline des brouillons ({@code /audio-questions/review}).
 *
 * <p><b>Analyser</b> ne lit que la base (themes, identifiants deja importes) et
 * n'ecrit rien, nulle part. <b>Importer</b> rejoue la meme validation, puis :
 * tout ou rien.
 * <ol>
 *   <li>une seule transaction persiste les N brouillons (id tire par Hibernate,
 *       aucun INSERT avant le flush), envoie les N images sur R2 sous
 *       {@code questions/images/drafts/<draftId>/<uuid>.<ext>} en gardant les
 *       cles, pose les URL, puis flush et commit ;</li>
 *   <li>au moindre echec (R2, contrainte, base) : rollback, et suppression au
 *       mieux des cles deja envoyees.</li>
 * </ol>
 * L'index unique {@code external_id} ferme la course entre deux imports : le
 * second echoue au flush, compense, et rend le rapport qui le dit.
 */
@Slf4j
@Service
public class CoImageImportService {

    private final CoImageImportValidator validator;
    private final CoImageImportMapper mapper;
    private final ThemeManager themeManager;
    private final AudioQuestionDraftManager draftManager;
    private final CloudflareR2Client r2Client;
    private final CharteImagesCo charte;
    private final QuestionImportProperties props;
    private final TransactionTemplate tx;

    public CoImageImportService(
            CoImageImportValidator validator,
            CoImageImportMapper mapper,
            ThemeManager themeManager,
            AudioQuestionDraftManager draftManager,
            CloudflareR2Client r2Client,
            CharteImagesCo charte,
            QuestionImportProperties props,
            PlatformTransactionManager txManager) {
        this.validator = validator;
        this.mapper = mapper;
        this.themeManager = themeManager;
        this.draftManager = draftManager;
        this.r2Client = r2Client;
        this.charte = charte;
        this.props = props;
        this.tx = new TransactionTemplate(txManager);
    }

    /** Rapport du lot, sans aucune ecriture. */
    public CoImageImportReport analyser(String manifeste, List<MultipartFile> images) {
        return rapport(valider(manifeste, lire(images)), Map.of());
    }

    /**
     * Cree les brouillons si le lot est entierement valide ({@code imported =
     * true}) ; sinon rend le rapport et n'ecrit rien.
     */
    public CoImageImportReport importer(String manifeste, List<MultipartFile> images) {
        List<FichierImport> fichiers = lire(images);
        ResultatValidation verdict = valider(manifeste, fichiers);
        if (!verdict.ok()) {
            return rapport(verdict, Map.of());
        }

        List<String> clesEnvoyees = Collections.synchronizedList(new ArrayList<>());
        Map<Integer, AudioQuestionDraft> crees;
        try {
            crees = tx.execute(status -> ecrire(verdict, clesEnvoyees));
        } catch (DataIntegrityViolationException e) {
            compenser(clesEnvoyees);
            log.warn("Import CO image refuse au commit (import concurrent ?) : {}", e.getMostSpecificCause().getMessage());
            ResultatValidation rejoue = valider(manifeste, fichiers);
            if (rejoue.ok()) {
                throw new IllegalStateException("Import CO image refuse par la base : relancez l'analyse.");
            }
            return rapport(rejoue, Map.of());
        } catch (RuntimeException e) {
            compenser(clesEnvoyees);
            throw e;
        }
        log.info("Import CO image : {} brouillon(s) cree(s) ({})", crees.size(),
                verdict.questions().stream().map(QuestionAnalysee::externalId).toList());
        return rapport(verdict, crees);
    }

    private Map<Integer, AudioQuestionDraft> ecrire(ResultatValidation verdict, List<String> clesEnvoyees) {
        List<AudioQuestionDraft> brouillons = verdict.questions().stream().map(mapper::versBrouillon).toList();
        draftManager.persistAll(brouillons);
        Map<Integer, AudioQuestionDraft> parIndex = new LinkedHashMap<>();
        for (int i = 0; i < brouillons.size(); i++) {
            QuestionAnalysee q = verdict.questions().get(i);
            AudioQuestionDraft d = brouillons.get(i);
            String cle = "questions/images/drafts/" + d.getId() + "/" + UUID.randomUUID() + "." + q.format().extension();
            R2UploadResult envoi = r2Client.uploadImage(cle, q.image().octets(), q.format().contentType());
            clesEnvoyees.add(envoi.objectKey());
            d.setImageUrl(envoi.publicUrl());
            parIndex.put(q.index(), d);
        }
        draftManager.flush();
        return parIndex;
    }

    private void compenser(List<String> cles) {
        for (String cle : cles) {
            r2Client.deleteObject(cle);
        }
        if (!cles.isEmpty()) {
            log.warn("Import CO image annule : {} image(s) R2 supprimee(s) au mieux", cles.size());
        }
    }

    private ResultatValidation valider(String manifeste, List<FichierImport> fichiers) {
        ManifesteLu lu = validator.lire(manifeste);
        Map<String, Theme> themes = new HashMap<>();
        Set<String> connus = Set.of();
        if (lu.manifeste() != null) {
            for (String code : validator.codesDeTheme(lu.manifeste())) {
                themeManager.findByCode(code).ifPresent(t -> themes.put(code, t));
            }
            connus = draftManager.findExistingExternalIds(validator.externalIds(lu.manifeste()));
        }
        return validator.valider(lu, fichiers, themes, connus);
    }

    private CoImageImportReport rapport(ResultatValidation verdict, Map<Integer, AudioQuestionDraft> crees) {
        return mapper.rapport(verdict, CoImageImportValidator.FORMAT, charte.version(), props.getMaxQuestions(), crees);
    }

    private static List<FichierImport> lire(List<MultipartFile> images) {
        if (images == null) return List.of();
        List<FichierImport> fichiers = new ArrayList<>(images.size());
        for (MultipartFile f : images) {
            if (f == null) continue;
            try {
                fichiers.add(new FichierImport(nomDeBase(f.getOriginalFilename()), f.getBytes()));
            } catch (IOException e) {
                throw new BusinessException("Lecture du fichier « " + f.getOriginalFilename() + " » impossible");
            }
        }
        return fichiers;
    }

    /** Nom sans repertoire : certains navigateurs envoient un chemin relatif sur un depot de dossier. */
    private static String nomDeBase(String nom) {
        if (nom == null) return null;
        int i = Math.max(nom.lastIndexOf('/'), nom.lastIndexOf('\\'));
        return i >= 0 ? nom.substring(i + 1) : nom;
    }
}

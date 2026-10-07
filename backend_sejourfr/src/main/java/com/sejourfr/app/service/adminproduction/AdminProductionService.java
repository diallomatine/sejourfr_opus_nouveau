package com.sejourfr.app.service.adminproduction;

import com.sejourfr.app.dto.AdminProductionCompteursDto;
import com.sejourfr.app.dto.AdminProductionDetailDto;
import com.sejourfr.app.dto.AdminProductionFlagDto;
import com.sejourfr.app.dto.AdminProductionListItemDto;
import com.sejourfr.app.dto.AdminProductionStatsDto;
import com.sejourfr.app.dto.PageResponse;
import com.sejourfr.app.dto.ProductionSubmissionDto;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.AiEvaluationFlag;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AdminProductionAnnotationFiltre;
import com.sejourfr.app.enums.AdminProductionExaminateurFiltre;
import com.sejourfr.app.enums.AdminProductionNiveauFiltre;
import com.sejourfr.app.enums.AdminProductionSignalementFiltre;
import com.sejourfr.app.enums.AdminProductionStatutIa;
import com.sejourfr.app.enums.AdminProductionTri;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.EtatSignalement;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AdminProductionReadManager;
import com.sejourfr.app.manager.AiEvaluationFlagManager;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.mapper.AdminProductionMapper;
import com.sejourfr.app.mapper.ProductionSubmissionMapper;
import com.sejourfr.app.repository.AdminProductionReadRepository;
import com.sejourfr.app.specification.LikePattern;
import com.sejourfr.app.util.FenetreMesure;
import com.sejourfr.app.util.PeriodeAdmin;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Console admin « Productions IA » : liste et fiche des productions TCF EE/EO
 * complètes (F-2 A), EO temps réel comprise.
 *
 * <p>🛑 <b>Lecture passive</b> : transaction en lecture seule, aucun runner,
 * aucun client LLM, aucun service candidat qui résout le Plan ou un quota —
 * uniquement des managers, des mappers et des fonctions de calcul pures.
 * Consulter une production n'écrit rien et n'appelle aucune IA.
 */
@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
public class AdminProductionService {

    static final int MAX_SIZE = 100;
    private static final Pattern UUID_CANONIQUE = Pattern.compile(
            "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$");

    private final AdminProductionReadManager readManager;
    private final ProductionSubmissionManager submissionManager;
    private final AiEvaluationManager aiEvaluationManager;
    private final TranscriptionManager transcriptionManager;
    private final AiEvaluationFlagManager flagManager;
    private final UserManager userManager;
    private final AdminProductionMapper mapper;
    private final ProductionSubmissionMapper submissionMapper;
    private final AdminProductionCalculService calculService;
    private final Clock clock;

    /** Filtres de la liste, tels que reçus ; {@code null} = pas de filtre. */
    public record Filtres(
            String q,
            EpreuveType epreuve,
            Integer tache,
            AdminProductionNiveauFiltre niveau,
            AdminProductionStatutIa statut,
            AdminProductionSignalementFiltre signalement,
            AdminProductionAnnotationFiltre annotation,
            AdminProductionExaminateurFiltre examinateur,
            String preset,
            String from,
            String to,
            boolean includeInternal
    ) {}

    /**
     * Une page de productions. {@code page} indexée à 0 (négative ⇒ 0),
     * {@code size} bornée à [1 ; {@value #MAX_SIZE}].
     *
     * @throws IllegalArgumentException (→ 400) épreuve hors EE/EO, tâche hors
     *         1-3, {@code preset} inconnu ou avec {@code from}/{@code to}, borne
     *         seule ou illisible
     */
    public PageResponse<AdminProductionListItemDto> list(Filtres f, AdminProductionTri sort, int page, int size) {
        int safeSize = Math.min(Math.max(size, 1), MAX_SIZE);
        int safePage = Math.max(page, 0);
        AdminProductionReadManager.Criteres criteres = criteres(f, aujourdhui());
        AdminProductionTri tri = sort == null ? AdminProductionTri.DATE_DESC : sort;

        List<AdminProductionListItemDto> content = readManager
                .findPage(criteres, tri.name(), safeSize, (long) safePage * safeSize).stream()
                .map(mapper::listItem)
                .toList();
        long total = readManager.count(criteres);
        return PageResponse.from(new PageImpl<>(content, PageRequest.of(safePage, safeSize), total));
    }

    /**
     * Encart de la liste (DI-35) : la période et les comptes internes, rien
     * d'autre — les filtres de la liste n'y entrent pas. Une requête.
     *
     * @throws IllegalArgumentException (→ 400) mêmes refus de période que la liste
     */
    public AdminProductionStatsDto stats(String preset, String from, String to, boolean includeInternal) {
        PeriodeAdmin periode = PeriodeAdmin.resolveOuSansBorne(preset, from, to, aujourdhui());
        FenetreMesure fenetre = periode == null ? null : periode.window();
        AdminProductionReadRepository.Compteurs c = readManager.compter(includeInternal, null,
                fenetre == null ? null : fenetre.startInstant(),
                fenetre == null ? null : fenetre.endInstantExclusive());
        return new AdminProductionStatsDto(
                periode == null ? null : periode.preset(),
                fenetre == null ? null : fenetre.from(),
                fenetre == null ? null : fenetre.to(),
                includeInternal,
                c.getCandidats() == null ? 0 : c.getCandidats().longValue(),
                mapper.compteurs(c));
    }

    /**
     * Productions d'un candidat, depuis toujours, comptes internes compris (D-57) :
     * exactement ce que montre {@code /productions-ia?q=<userId>&internes=1} (sans période = tout).
     * Une requête, quel que soit le nombre de productions.
     */
    public AdminProductionCompteursDto compteursDuCandidat(UUID userId) {
        return mapper.compteurs(readManager.compter(true, userId, null, null));
    }

    /** Fiche d'une production du périmètre ; 404 si inconnue ou hors périmètre (diagnostic…). */
    public AdminProductionDetailDto detail(UUID submissionId) {
        AdminProductionReadRepository.Ligne ligne = readManager.findLigne(submissionId)
                .orElseThrow(() -> new NotFoundException("Production introuvable : " + submissionId));
        ProductionSubmission s = submissionManager.findByIdWithTaskAndUser(submissionId)
                .orElseThrow(() -> new NotFoundException("Production introuvable : " + submissionId));
        ProductionTask task = s.getProductionTask();
        AiEvaluation evaluation = aiEvaluationManager.findLatestBySubmissionId(submissionId).orElse(null);
        boolean oral = task.getEpreuve() == EpreuveType.TCF_EO;

        String transcription = oral ? transcriptionManager.findLatestTexteBySubmissionId(submissionId).orElse(null) : null;
        TranscriptionManager.TranscriptionMeta meta = oral
                ? transcriptionManager.findLatestMetaBySubmissionId(submissionId).orElse(null) : null;

        ProductionSubmissionDto vueCandidat = submissionMapper.toDto(s);
        AdminProductionCalculService.Explication explication = calculService.expliquer(evaluation, task);

        AdminProductionDetailDto.EvaluationIa evaluationIa = evaluation == null ? null
                : mapper.evaluationIa(evaluation, aiEvaluationManager.countBySubmissionId(submissionId),
                        explication.poidsParCode(),
                        vueCandidat.evaluation() != null && vueCandidat.evaluation().niveauObserve() != null);

        List<AdminProductionFlagDto> signalements = signalements(flagManager.findBySubmissionId(submissionId));
        boolean actif = signalements.stream().anyMatch(fl -> fl.etat() != EtatSignalement.RETIRE);

        return new AdminProductionDetailDto(
                mapper.listItem(ligne),
                mapper.sujet(task),
                mapper.reponse(s, transcription, meta),
                evaluationIa,
                explication.calcul(),
                vueCandidat,
                mapper.technique(s, evaluation),
                evaluation == null ? null : evaluation.getFeedbackJson(),
                signalements,
                evaluation != null && !actif);
    }

    /** Signalements mappés avec leurs auteurs, chargés en une requête. */
    public List<AdminProductionFlagDto> signalements(List<AiEvaluationFlag> flags) {
        Set<UUID> ids = new HashSet<>();
        for (AiEvaluationFlag f : flags) {
            ids.add(f.getCreatedBy());
            if (f.getVerifiedBy() != null) ids.add(f.getVerifiedBy());
            if (f.getRemovedBy() != null) ids.add(f.getRemovedBy());
        }
        Map<UUID, User> acteurs = ids.isEmpty() ? Map.of()
                : userManager.findAllById(ids).stream().collect(Collectors.toMap(User::getId, Function.identity()));
        return flags.stream().map(f -> mapper.flag(f, acteurs)).toList();
    }

    private LocalDate aujourdhui() {
        return LocalDate.ofInstant(clock.instant(), FenetreMesure.PARIS);
    }

    private static AdminProductionReadManager.Criteres criteres(Filtres f, LocalDate aujourdhui) {
        if (f.epreuve() != null && f.epreuve() != EpreuveType.TCF_EE && f.epreuve() != EpreuveType.TCF_EO) {
            throw new IllegalArgumentException("Valeur invalide pour « epreuve » : TCF_EE ou TCF_EO.");
        }
        if (f.tache() != null && (f.tache() < 1 || f.tache() > 3)) {
            throw new IllegalArgumentException("Valeur invalide pour « tache » : 1, 2 ou 3.");
        }

        PeriodeAdmin periode = PeriodeAdmin.resolveOuSansBorne(f.preset(), f.from(), f.to(), aujourdhui);
        Instant fromTs = periode == null ? null : periode.window().startInstant();
        Instant toTs = periode == null ? null : periode.window().endInstantExclusive();

        UUID qUuid = null;
        String qPattern = null;
        if (!blank(f.q())) {
            String q = f.q().trim();
            if (UUID_CANONIQUE.matcher(q).matches()) qUuid = UUID.fromString(q);
            else qPattern = LikePattern.contient(q);
        }

        return new AdminProductionReadManager.Criteres(
                f.includeInternal(),
                qUuid,
                qPattern,
                f.epreuve() == null ? null : f.epreuve().name(),
                f.tache(),
                f.examinateur() == null ? null : f.examinateur().source().name(),
                fromTs,
                toTs,
                f.niveau() == null ? null : f.niveau().name(),
                f.statut() == null ? null : f.statut().name(),
                etatSignalement(f.signalement()),
                f.annotation() == null ? null : f.annotation() == AdminProductionAnnotationFiltre.ANNOTEES);
    }

    private static String etatSignalement(AdminProductionSignalementFiltre filtre) {
        if (filtre == null) return null;
        return switch (filtre) {
            case SIGNALEES -> EtatSignalement.SIGNALE.name();
            case VERIFIEES -> EtatSignalement.VERIFIE.name();
            case NON_SIGNALEES -> EtatSignalement.AUCUN.name();
        };
    }

    private static boolean blank(String s) {
        return s == null || s.isBlank();
    }
}

package com.sejourfr.app.service;

import com.sejourfr.app.config.CompetenceProperties;
import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.dto.SkillAttemptDto;
import com.sejourfr.app.dto.SubmitSkillTextRequest;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillSelfEvaluation;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.SkillPromptManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.mapper.SkillAttemptMapper;
import com.sejourfr.app.ratelimit.RateLimitGuard;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.competence.SkillAnalysisAsyncRunner;
import com.sejourfr.app.util.AudioEphemere;
import com.sejourfr.app.util.ProductionPayloadSupport;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

/**
 * Cas d'usage « rendre une production sur un petit sujet » et lecture des
 * tentatives.
 *
 * <p><b>Deux verrous distincts, jamais confondus</b> :
 * <ul>
 *   <li><b>ce sur quoi on peut produire</b> — {@link SkillAccessService}. Depuis
 *       le 2026-08-10 un compte sans acces TCF ne travaille que la premiere
 *       competence de chaque tache (ses 2 premiers sujets) et la competence de
 *       la priorite n&deg;1 de son Plan. Le refus est <b>serveur</b> (403) : le
 *       cadenas des fronts n'est qu'un affichage ;</li>
 *   <li><b>l'analyse IA</b> — {@link SkillAnalysisAccessService}, 3 analyses
 *       offertes a vie, inchangees.</li>
 * </ul>
 * Sur un sujet ouvert, s'auto-evaluer, relire ses productions et consulter les
 * references restent gratuits et illimites.
 *
 * <p>Volontairement decouple des epreuves completes : une tentative n'est
 * rattachee a AUCUN {@code attempt}. Un micro-exercice n'est pas une session
 * d'examen, il n'a ni chrono, ni composition, ni bilan — l'y raccrocher aurait
 * fait entrer tout le freemium des examens blancs dans un exercice cense rester
 * ouvert.
 *
 * <p>Pas de {@code @Transactional} sur la soumission : l'upload R2 et l'analyse
 * ont leurs propres frontieres, et on ne veut pas tenir une transaction ouverte
 * pendant un appel reseau.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SkillAttemptService {

    private static final int MIN_HISTORY_LIMIT = 1;
    private static final int MAX_HISTORY_LIMIT = 20;

    /**
     * Relances manuelles autorisees par tentative. Meme plafond que
     * {@code production_submissions.retry_count}, et double : applique ici pour
     * rendre un message utile au candidat, garanti en base par
     * {@code chk_user_skill_attempts_retry_count}.
     */
    static final short MAX_RETRIES = 3;

    private final SkillPromptManager promptManager;
    private final UserSkillAttemptManager attemptManager;
    private final UserManager userManager;
    private final SkillAccessService accessService;
    private final SkillAnalysisAccessService analysisAccessService;
    private final SkillAnalysisAsyncRunner analysisRunner;
    private final WhisperTranscriptionService whisperService;
    private final SkillAttemptMapper mapper;
    private final RateLimitGuard rateLimitGuard;
    private final CurrentUser currentUser;
    private final CompetenceProperties props;
    private final ProductionEvaluationProperties productionProps;

    /** Production ECRITE (section EE). */
    public SkillAttemptDto submitText(SubmitSkillTextRequest req) {
        UUID userId = currentUser.getId();

        // REJEU D'ABORD. Une production deja rendue sous cette cle ne doit ni
        // etre rate-limitee, ni reconsommer une analyse, ni repayer le LLM.
        SkillAttemptDto rejeu = rejeu(userId, req.clientSubmissionId());
        if (rejeu != null) {
            return rejeu;
        }

        rateLimitGuard.checkSkillAttempt(userId);

        SkillPrompt prompt = loadActivePrompt(req.skillPromptId());
        accessService.assertCanProduce(userId, prompt);
        assertSection(prompt, SkillSection.EE);

        String texte = ProductionPayloadSupport.sanitizeText(req.texte());
        if (texte.isEmpty()) {
            throw new BusinessException("Votre réponse est vide.");
        }
        int mots = ProductionPayloadSupport.countWords(texte);
        // Garde-fou ANTI-ABUS, pas une regle pedagogique : les bornes
        // recommandees du sujet restent indicatives et ne bloquent jamais.
        int maxWords = props.getAnalysis().getMaxTextWords();
        if (mots > maxWords) {
            throw new BusinessException(
                    "Votre réponse dépasse " + maxWords + " mots. Ces petits sujets se traitent "
                            + "en quelques phrases : concentrez-vous sur le critère travaillé.");
        }

        boolean analyse = acceptAnalysis(userId, req.requestAnalysis());

        UserSkillAttempt attempt = newAttempt(userId, prompt, req.selfEvaluation(), analyse);
        attempt.setClientSubmissionId(req.clientSubmissionId());
        attempt.setWrittenProduction(texte);
        attempt.setWordsCount(mots);
        try {
            attempt = attemptManager.save(attempt);
        } catch (DataIntegrityViolationException conflit) {
            return resoudreCourseIdempotence(userId, req.clientSubmissionId(), conflit);
        }

        return finish(attempt, analyse);
    }

    /** Production ORALE (section EO). */
    public SkillAttemptDto submitAudio(UUID skillPromptId,
                                       MultipartFile audio,
                                       int durationSec,
                                       SkillSelfEvaluation selfEvaluation,
                                       boolean requestAnalysis,
                                       UUID clientSubmissionId) {
        UUID userId = currentUser.getId();

        // REJEU D'ABORD, AVANT WHISPER : c'est ici que la cle rapporte le plus.
        SkillAttemptDto rejeu = rejeu(userId, clientSubmissionId);
        if (rejeu != null) {
            return rejeu;
        }

        rateLimitGuard.checkSkillAttempt(userId);

        SkillPrompt prompt = loadActivePrompt(skillPromptId);
        accessService.assertCanProduce(userId, prompt);
        assertSection(prompt, SkillSection.EO);

        if (audio == null || audio.isEmpty()) {
            throw new BusinessException("Aucun enregistrement reçu.");
        }
        ProductionPayloadSupport.validateAudioContentType(audio);
        int maxDuration = props.getAnalysis().getMaxAudioDurationSeconds();
        if (durationSec <= 0) {
            throw new BusinessException("La durée de l'enregistrement est manquante ou invalide.");
        }
        if (durationSec > maxDuration) {
            throw new BusinessException(
                    "Votre enregistrement dépasse " + maxDuration + " secondes. Ces petits sujets "
                            + "se traitent en quelques phrases.");
        }
        byte[] bytes = ProductionPayloadSupport.readBytes(audio);
        // Plafond de taille partage avec les productions completes : c'est la
        // meme contrainte de stockage et le meme transfert vers Whisper, il n'y
        // a pas de raison qu'ils divergent.
        long maxBytes = productionProps.getMaxAudioSizeBytes();
        if (bytes.length > maxBytes) {
            throw new BusinessException(
                    "Enregistrement trop volumineux (max " + (maxBytes / (1024 * 1024)) + " Mo).");
        }

        boolean analyse = acceptAnalysis(userId, requestAnalysis);

        // TRANSCRIPTION SYNCHRONE ET SYSTEMATIQUE, avant l'insert. L'audio n'est
        // plus stocke (decision produit, motif consentement) : les octets
        // n'existent que le temps de cette requete. AudioEphemere efface le
        // tampon dans un finally, y compris si Whisper echoue.
        //
        // ⚠️ La regle « on ne paie pas Whisper pour un audio que personne ne
        // corrigera » est REVOQUEE ici : sans audio conserve, ne pas transcrire
        // ne laisserait plus RIEN de la production. On transcrit donc meme sans
        // analyse demandee — c'est le prix de ne rien garder.
        //
        // Transcrire PUIS inserer : un echec Whisper ne laisse aucune ligne,
        // aucun quota consomme, et le candidat renvoie depuis son appareil.
        WhisperTranscriptionClient.WhisperResult transcrit = AudioEphemere.avecOctets(
                bytes, octets -> whisperService.transcribe(octets, fileNameOf(audio)));

        UserSkillAttempt attempt = newAttempt(userId, prompt, selfEvaluation, analyse);
        attempt.setClientSubmissionId(clientSubmissionId);
        attempt.setTranscript(transcrit.texte());
        // La duree detectee par Whisper fait foi sur celle annoncee par le
        // client : c'est la seule mesure faite sur le fichier reellement recu.
        attempt.setAudioDurationSec(
                transcrit.durationSec() != null ? transcrit.durationSec() : durationSec);
        try {
            attempt = attemptManager.save(attempt);
        } catch (DataIntegrityViolationException conflit) {
            // Course perdue : on rend la ligne gagnante et on jette notre
            // transcription. Meme cout assume que cote productions completes.
            return resoudreCourseIdempotence(userId, clientSubmissionId, conflit);
        }

        return finish(attempt, analyse);
    }

    /**
     * Demande l'analyse IA d'une production deja enregistree SANS analyse
     * (statut {@link SkillAttemptStatut#RECORDED}).
     *
     * <p>Cas reel : un compte gratuit produit sans analyse, puis s'abonne. Sans
     * cette route, sa seule issue etait de refaire le sujet — donc de perdre sa
     * production. Le quota est consomme ici comme a la soumission, a
     * l'acceptation.
     *
     * <p>A l'oral, la production analysee est la <b>transcription</b>, ecrite des
     * la soumission : il n'y a plus rien a transcrire ici, et il n'y aurait plus
     * rien a transcrire AVEC quoi — l'audio n'est pas conserve. Les tentatives
     * orales anterieures a ce changement, enregistrees sans analyse donc sans
     * transcription, ne sont plus analysables : elles sont refusees ci-dessous
     * <b>avant</b> toute consommation de quota.
     */
    public SkillAttemptDto analyse(UUID attemptId) {
        UUID userId = currentUser.getId();
        rateLimitGuard.checkSkillAttempt(userId);

        UserSkillAttempt attempt = loadOwnAttempt(attemptId);
        accessService.assertCanProduce(userId, attempt.getSkillPrompt());
        // RECORDED est le seul etat analysable : c'est l'etat final d'une
        // production rendue sans IA. Tout autre statut signifie qu'une analyse a
        // deja ete acceptee — la relancer par ici contournerait le quota, alors
        // que le retry (reserve a FAILED) est plafonne et gratuit.
        if (attempt.getStatut() != SkillAttemptStatut.RECORDED) {
            throw new BusinessException(
                    "Cette production a déjà fait l'objet d'une analyse (statut actuel : "
                            + attempt.getStatut() + ").");
        }
        // LEGACY : une tentative orale rendue sans analyse AVANT que l'audio
        // cesse d'etre stocke n'a ni transcription ni audio relisible. On le dit
        // franchement, et surtout AVANT assertCanAnalyse : le candidat ne doit
        // pas depenser une de ses 3 analyses offertes sur une production qu'on
        // ne peut plus lire.
        if (attempt.getSkillPrompt().getSection() == SkillSection.EO
                && (attempt.getTranscript() == null || attempt.getTranscript().isBlank())) {
            throw new BusinessException(
                    "Cet enregistrement date d'avant la mise en place de la transcription "
                            + "automatique et n'a pas pu être retranscrit. Refaites le sujet "
                            + "pour obtenir une analyse.");
        }
        analysisAccessService.assertCanAnalyse(userId);

        attempt.setAnalysisRequested(true);
        attempt.setErrorMessage(null);
        attempt.setStatut(SkillAttemptStatut.SUBMITTED);
        UserSkillAttempt saved = attemptManager.save(attempt);

        return finish(saved, true);
    }

    /**
     * Relance l'analyse d'une tentative en echec. <b>Ne reconsomme pas le quota
     * gratuit</b> : l'analyse a deja ete decomptee a son acceptation, et l'echec
     * n'est pas du fait du candidat. C'est precisement ce qui impose un plafond
     * propre — sans lui, une panne fournisseur se traduirait par une boucle
     * d'appels payants offerts.
     */
    public SkillAttemptDto retry(UUID attemptId) {
        UUID userId = currentUser.getId();
        rateLimitGuard.checkSkillAttempt(userId);

        UserSkillAttempt attempt = loadOwnAttempt(attemptId);
        accessService.assertCanProduce(userId, attempt.getSkillPrompt());
        if (attempt.getStatut() != SkillAttemptStatut.FAILED) {
            throw new IllegalStateException(
                    "Seule une analyse en échec peut être relancée (statut actuel : "
                            + attempt.getStatut() + ").");
        }
        if (!attempt.isAnalysisRequested()) {
            throw new IllegalStateException(
                    "Cette production a été enregistrée sans analyse : il n'y a rien à relancer.");
        }
        if (attempt.getRetryCount() >= MAX_RETRIES) {
            throw new BusinessException(
                    "Vous avez déjà relancé cette analyse " + MAX_RETRIES + " fois sans succès. "
                            + "Votre production est conservée : réessayez plus tard ou refaites le sujet.");
        }
        attempt.setRetryCount((short) (attempt.getRetryCount() + 1));
        attempt.setErrorMessage(null);
        attempt.setStatut(SkillAttemptStatut.SUBMITTED);
        UserSkillAttempt saved = attemptManager.save(attempt);

        return finish(saved, true);
    }

    /**
     * Detail d'une tentative. <b>404 et non 403</b> quand elle appartient a
     * quelqu'un d'autre : repondre 403 confirmerait son existence. Meme
     * convention que le detail d'une production.
     */
    @Transactional(readOnly = true)
    public SkillAttemptDto detail(UUID attemptId) {
        return mapper.toDto(loadOwnAttempt(attemptId));
    }

    /** Historique du candidat sur un sujet, plus recente d'abord. */
    @Transactional(readOnly = true)
    public List<SkillAttemptDto> history(UUID promptId, int limit) {
        UUID userId = currentUser.getId();
        SkillPrompt prompt = loadActivePrompt(promptId);
        return attemptManager.findByUserAndPrompt(userId, prompt.getId(), clampLimit(limit)).stream()
                .map(mapper::toDto)
                .toList();
    }

    // ------------------------------------------------------------------------
    // Interne
    // ------------------------------------------------------------------------

    /**
     * Verifie le budget d'analyse quand une analyse est demandee. Le quota est
     * consomme par la persistance de {@code analysisRequested = true}, pas par
     * le succes de l'analyse : sinon un retry gratuit apres echec permettrait
     * d'en obtenir plus que le nombre offert.
     */
    private boolean acceptAnalysis(UUID userId, Boolean requested) {
        if (!Boolean.TRUE.equals(requested)) {
            return false;
        }
        analysisAccessService.assertCanAnalyse(userId);
        return true;
    }

    /**
     * La production deja rendue sous cette cle d'idempotence (V046), ou
     * {@code null} si c'est la premiere fois — cle absente comprise.
     *
     * <p>On rend la ligne telle qu'elle est : une analyse encore en cours rend
     * un {@code SUBMITTED}, exactement ce qu'aurait rendu le premier appel.
     */
    private SkillAttemptDto rejeu(UUID userId, UUID clientSubmissionId) {
        return attemptManager.findByClientKey(userId, clientSubmissionId)
                .map(mapper::toDto)
                .orElse(null);
    }

    /**
     * La production gagnante d'une course sur la cle d'idempotence, ou
     * {@code null} si le conflit n'a rien a voir avec elle — auquel cas on
     * relaie l'exception plutot que de l'avaler.
     */
    private SkillAttemptDto resoudreCourseIdempotence(
            UUID userId, UUID clientSubmissionId, DataIntegrityViolationException conflit) {
        if (clientSubmissionId == null) {
            throw conflit;
        }
        return attemptManager.findByClientKey(userId, clientSubmissionId)
                .map(gagnante -> {
                    log.info("Course sur la cle d'idempotence {} : la production {} l'emporte.",
                            clientSubmissionId, gagnante.getId());
                    return mapper.toDto(gagnante);
                })
                .orElseThrow(() -> conflit);
    }

    private UserSkillAttempt newAttempt(UUID userId,
                                        SkillPrompt prompt,
                                        SkillSelfEvaluation selfEvaluation,
                                        boolean analyse) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new NotFoundException("Utilisateur introuvable : " + userId));
        UserSkillAttempt attempt = new UserSkillAttempt();
        attempt.setUser(user);
        attempt.setSkillPrompt(prompt);
        attempt.setSelfEvaluation(selfEvaluation);
        attempt.setAnalysisRequested(analyse);
        // Sans analyse, RECORDED est un etat FINAL : la production est
        // conservee, rien d'autre n'est attendu.
        attempt.setStatut(analyse ? SkillAttemptStatut.SUBMITTED : SkillAttemptStatut.RECORDED);
        return attempt;
    }

    /**
     * Declenche l'analyse si elle a ete acceptee, puis rend la reponse. Le
     * candidat n'attend jamais le correcteur : il recoit sa tentative en
     * {@code SUBMITTED} et poll ensuite.
     */
    private SkillAttemptDto finish(UserSkillAttempt attempt, boolean analyse) {
        if (analyse) {
            analysisRunner.runAsync(attempt.getId());
        }
        return mapper.toDto(attempt);
    }

    /**
     * Nom transmis a Whisper : il en deduit le format du conteneur. On ne rend
     * jamais le nom d'origine du fichier du candidat.
     */
    private static String fileNameOf(MultipartFile audio) {
        return "competence." + ProductionPayloadSupport.extractExtension(audio);
    }

    private SkillPrompt loadActivePrompt(UUID promptId) {
        return promptManager.findActiveByIdWithSkill(promptId)
                .orElseThrow(() -> new NotFoundException("Sujet introuvable : " + promptId));
    }

    private UserSkillAttempt loadOwnAttempt(UUID attemptId) {
        UUID userId = currentUser.getId();
        UserSkillAttempt attempt = attemptManager.findByIdWithPrompt(attemptId)
                .orElseThrow(() -> new NotFoundException("Tentative introuvable : " + attemptId));
        if (attempt.getUser() == null || !attempt.getUser().getId().equals(userId)) {
            throw new NotFoundException("Tentative introuvable : " + attemptId);
        }
        return attempt;
    }

    /**
     * Coherence section - media. Un sujet ecrit ne se rend pas en audio et
     * inversement : la consigne, le critere et les references sont ecrits pour
     * une modalite precise, les croiser rendrait l'analyse absurde.
     */
    private static void assertSection(SkillPrompt prompt, SkillSection expected) {
        if (prompt.getSection() != expected) {
            throw new BusinessException(expected == SkillSection.EE
                    ? "Ce sujet est un sujet d'expression orale : il attend un enregistrement, pas un texte."
                    : "Ce sujet est un sujet d'expression écrite : il attend un texte, pas un enregistrement.");
        }
    }

    private static int clampLimit(int limit) {
        return Math.max(MIN_HISTORY_LIMIT, Math.min(limit, MAX_HISTORY_LIMIT));
    }
}

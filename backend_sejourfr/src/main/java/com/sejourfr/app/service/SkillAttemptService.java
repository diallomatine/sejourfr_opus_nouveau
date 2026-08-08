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
import com.sejourfr.app.util.ProductionPayloadSupport;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

/**
 * Cas d'usage « rendre une production sur un petit sujet » et lecture des
 * tentatives.
 *
 * <p><b>Ce qui est gratuit</b> : produire, s'auto-evaluer, relire ses
 * productions — sur tous les sujets, sans limite. Aucun sujet n'est verrouille.
 * <b>Ce qui est premium</b> : l'analyse IA, avec 3 analyses offertes a vie
 * (cf. {@link SkillAnalysisAccessService}).
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
    private final SkillAnalysisAccessService analysisAccessService;
    private final SkillAnalysisAsyncRunner analysisRunner;
    private final ProductionAudioStorageService audioStorage;
    private final SkillAttemptMapper mapper;
    private final RateLimitGuard rateLimitGuard;
    private final CurrentUser currentUser;
    private final CompetenceProperties props;
    private final ProductionEvaluationProperties productionProps;

    /** Production ECRITE (section EE). */
    public SkillAttemptDto submitText(SubmitSkillTextRequest req) {
        UUID userId = currentUser.getId();
        rateLimitGuard.checkSkillAttempt(userId);

        SkillPrompt prompt = loadActivePrompt(req.skillPromptId());
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
        attempt.setWrittenProduction(texte);
        attempt.setWordsCount(mots);
        attempt = attemptManager.save(attempt);

        return finish(attempt, analyse, false);
    }

    /** Production ORALE (section EO). */
    public SkillAttemptDto submitAudio(UUID skillPromptId,
                                       MultipartFile audio,
                                       int durationSec,
                                       SkillSelfEvaluation selfEvaluation,
                                       boolean requestAnalysis) {
        UUID userId = currentUser.getId();
        rateLimitGuard.checkSkillAttempt(userId);

        SkillPrompt prompt = loadActivePrompt(skillPromptId);
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

        // Upload AVANT l'insert : la contrainte
        // chk_user_skill_attempts_has_production exige deja une source, donc la
        // ligne ne peut pas exister sans sa cle audio. La cle utilise un UUID
        // independant — pre-assigner l'id de l'entite ferait echouer Hibernate
        // avec @UuidGenerator (« detached entity »).
        UUID storageKeyId = UUID.randomUUID();
        ProductionAudioStorageService.StoredAudio stored = audioStorage.upload(
                storageKeyId, bytes, audio.getContentType(),
                ProductionPayloadSupport.extractExtension(audio));

        UserSkillAttempt attempt = newAttempt(userId, prompt, selfEvaluation, analyse);
        attempt.setAudioObjectKey(stored.objectKey());
        attempt.setAudioDurationSec(durationSec);
        attempt = attemptManager.save(attempt);

        return finish(attempt, analyse, true);
    }

    /**
     * Demande l'analyse IA d'une production deja enregistree SANS analyse
     * (statut {@link SkillAttemptStatut#RECORDED}).
     *
     * <p>Cas reel : un compte gratuit produit sans analyse, puis s'abonne. Sans
     * cette route, sa seule issue etait de refaire le sujet — donc de perdre sa
     * production. Le quota est consomme ici comme a la soumission, a
     * l'acceptation ; en oral, la transcription Whisper n'ayant jamais ete
     * faite, le pipeline la declenche d'abord, exactement comme sur la voie
     * normale.
     */
    public SkillAttemptDto analyse(UUID attemptId) {
        UUID userId = currentUser.getId();
        rateLimitGuard.checkSkillAttempt(userId);

        UserSkillAttempt attempt = loadOwnAttempt(attemptId);
        // RECORDED est le seul etat analysable : c'est l'etat final d'une
        // production rendue sans IA. Tout autre statut signifie qu'une analyse a
        // deja ete acceptee — la relancer par ici contournerait le quota, alors
        // que le retry (reserve a FAILED) est plafonne et gratuit.
        if (attempt.getStatut() != SkillAttemptStatut.RECORDED) {
            throw new BusinessException(
                    "Cette production a déjà fait l'objet d'une analyse (statut actuel : "
                            + attempt.getStatut() + ").");
        }
        analysisAccessService.assertCanAnalyse(userId);

        attempt.setAnalysisRequested(true);
        attempt.setErrorMessage(null);
        attempt.setStatut(SkillAttemptStatut.SUBMITTED);
        UserSkillAttempt saved = attemptManager.save(attempt);

        return finish(saved, true, saved.getAudioObjectKey() != null);
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

        return finish(saved, true, saved.getAudioObjectKey() != null);
    }

    /**
     * Detail d'une tentative. <b>404 et non 403</b> quand elle appartient a
     * quelqu'un d'autre : repondre 403 confirmerait son existence. Meme
     * convention que le detail d'une production.
     */
    @Transactional(readOnly = true)
    public SkillAttemptDto detail(UUID attemptId) {
        return mapWithAudioIfPresent(loadOwnAttempt(attemptId));
    }

    /** Historique du candidat sur un sujet, plus recente d'abord. */
    @Transactional(readOnly = true)
    public List<SkillAttemptDto> history(UUID promptId, int limit) {
        UUID userId = currentUser.getId();
        SkillPrompt prompt = loadActivePrompt(promptId);
        return attemptManager.findByUserAndPrompt(userId, prompt.getId(), clampLimit(limit)).stream()
                .map(this::mapWithAudioIfPresent)
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
    private SkillAttemptDto finish(UserSkillAttempt attempt, boolean analyse, boolean estOral) {
        if (analyse) {
            analysisRunner.runAsync(attempt.getId(), estOral);
        }
        return mapWithAudioIfPresent(attempt);
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

    private SkillAttemptDto mapWithAudioIfPresent(UserSkillAttempt attempt) {
        return attempt.getAudioObjectKey() != null
                ? mapper.toDtoWithSignedAudio(attempt)
                : mapper.toDto(attempt);
    }

    private static int clampLimit(int limit) {
        return Math.max(MIN_HISTORY_LIMIT, Math.min(limit, MAX_HISTORY_LIMIT));
    }
}

package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.Transcription;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.ProductionSubmissionSource;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.util.AudioEphemere;
import com.sejourfr.app.util.ProductionPayloadSupport;
import com.sejourfr.app.util.ProductionTextBounds;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.time.Instant;
import java.util.UUID;

/**
 * Orchestration end-to-end d'une submission EO ou EE :
 * <ol>
 *   <li>valide l'entree (taille audio / nombre de mots) ;</li>
 *   <li><b>transcrit l'audio (EO) PENDANT la requete</b>, puis efface les
 *       octets ;</li>
 *   <li>cree la submission en {@code SUBMITTED} + sa transcription ;</li>
 *   <li>appelle le correcteur en arriere-plan ;</li>
 *   <li>passe la submission a {@code EVALUATED} ou {@code FAILED} avec un
 *       {@code erreur_message} parlant.</li>
 * </ol>
 *
 * <p><b>L'audio d'un candidat n'est jamais stocke</b> (decision produit, motif
 * consentement) : ni R2, ni base, ni disque. Il sert a produire la
 * transcription, puis il disparait. C'est ce qui impose l'etape 2 en synchrone :
 * un runner asynchrone ne pourrait plus relire les octets. La production
 * conservee, c'est le texte — et lui seul est rendu aux ecrans.
 *
 * <p>Le mecanisme de retry est dans les clients HTTP (Spring Retry). Cette classe
 * expose en plus {@link #retry(UUID, UUID)} pour relancer une submission
 * marquee {@code FAILED} : il repart <b>de la transcription</b>, jamais de
 * l'audio, qui n'existe plus.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ProductionEvaluationService {

    private final ProductionTaskManager taskManager;
    private final ProductionSubmissionManager submissionManager;
    private final TranscriptionManager transcriptionManager;
    private final AttemptManager attemptManager;
    private final UserManager userManager;
    private final WhisperTranscriptionService whisperService;
    private final ProductionPipelineAsyncRunner pipelineRunner;
    private final ProductionAccessService accessService;
    private final ProductionEvaluationProperties props;

    /**
     * Soumet une production EO (audio) ou EE (texte). Exactement un des deux
     * parametres {@code audio} / {@code texte} doit etre non-null.
     * <p>
     * Pas de {@code @Transactional} : chaque etape (creation submission, upload R2,
     * Whisper, Claude) a son propre tx. Une coupure reseau au milieu laisse la
     * submission avec un statut intermediaire que l'utilisateur peut relancer via
     * {@link #retry(UUID, UUID)}.
     */
    public ProductionSubmission submitAndEvaluate(
            UUID userId, UUID taskId, UUID attemptId,
            MultipartFile audio, String texte) {
        return submitAndEvaluate(userId, taskId, attemptId, audio, texte, null);
    }

    /**
     * Meme chose, avec la cle d'idempotence du client (V046). Une cle
     * {@code null} signifie « ce client ne sait pas encore se repeter sans
     * dommage » : comportement d'avant, a l'identique.
     *
     * <p>Le rejeu NORMAL est intercepte bien plus haut, dans
     * {@code ProductionSubmissionService}, avant Whisper. Ce qui reste ici,
     * c'est la <b>course</b> : deux requetes parties ensemble, aucune des deux
     * ne voyant la ligne de l'autre. L'index unique tranche, la perdante relit
     * la ligne gagnante et la rend. Un seul rapport, un seul quota consomme.
     */
    public ProductionSubmission submitAndEvaluate(
            UUID userId, UUID taskId, UUID attemptId,
            MultipartFile audio, String texte, UUID clientSubmissionId) {

        User user = userManager.findById(userId)
            .orElseThrow(() -> new NotFoundException("User introuvable : " + userId));
        ProductionTask task = taskManager.findById(taskId)
            .orElseThrow(() -> new NotFoundException("ProductionTask introuvable : " + taskId));
        Attempt attempt = attemptManager.findById(attemptId)
            .orElseThrow(() -> new NotFoundException("Attempt introuvable : " + attemptId));

        // Gardes de session partagées avec la voie temps réel : appartenance
        // (IDOR), épreuve terminée, chrono, correspondance épreuve tâche ⇄
        // attempt, plafond d'une soumission par tâche en examen.
        accessService.assertCanSubmit(userId, attempt, task);

        if (!task.isActive()) {
            throw new BusinessException("La tache " + taskId + " n'est pas active.");
        }

        boolean estOral = task.getEpreuve() == EpreuveType.TCF_EO;
        validatePayload(estOral, audio, texte);

        ProductionSubmission submission = new ProductionSubmission();
        submission.setUser(user);
        submission.setAttempt(attempt);
        submission.setProductionTask(task);
        submission.setStatut(SubmissionStatut.SUBMITTED);
        submission.setDiagnostic(task.isDiagnostic());
        submission.setClientSubmissionId(clientSubmissionId);

        if (estOral) {
            byte[] bytes = ProductionPayloadSupport.readBytes(audio);
            validateAudio(bytes);
            // TRANSCRIPTION SYNCHRONE, avant toute écriture. L'audio n'est plus
            // stocké nulle part (décision produit, motif consentement) : les
            // octets n'existent que le temps de cette requête, c'est donc le
            // SEUL moment où l'on peut transcrire. AudioEphemere efface le
            // tampon dans un finally, y compris si Whisper échoue.
            //
            // Ordre volontaire — transcrire PUIS insérer :
            //   * un échec Whisper ne laisse alors AUCUNE ligne, aucun quota
            //     consommé, et le candidat, qui a encore son enregistrement sur
            //     son appareil, renvoie simplement. C'est la seule reprise
            //     possible depuis que l'audio ne survit pas ;
            //   * l'ordre inverse (insérer puis transcrire) fabriquerait des
            //     productions FAILED définitivement irrécupérables.
            // Coût assumé : sur un double-clic diagnostic, le perdant paie une
            // transcription jetée — rare, borné, et préférable à une production
            // morte.
            WhisperTranscriptionClient.WhisperResult transcrit = AudioEphemere.avecOctets(
                bytes, octets -> whisperService.transcribe(octets, fileNameOf(audio)));

            submission.setMediaUrl(null);
            submission.setMediaDurationSec(transcrit.durationSec());
            try {
                submission = submissionManager.save(submission);
            } catch (DataIntegrityViolationException conflit) {
                // Course perdue sur la cle d'idempotence : l'autre requete a
                // insere la meme soumission entre notre lecture et notre
                // insert. On rend SA ligne, et on jette notre transcription —
                // c'est le meme cout assume qu'un double-clic diagnostic.
                ProductionSubmission gagnante = resoudreCourseIdempotence(userId, clientSubmissionId, conflit);
                if (gagnante != null) {
                    return gagnante;
                }
                // L'index partiel uq_prod_submission_diagnostic_attempt rend le
                // double-clic atomique.
                if (task.isDiagnostic()) {
                    throw new BusinessException("Cette étape du diagnostic a déjà été rendue.");
                }
                throw conflit;
            }
            // La production, désormais : le texte. Persistée AVANT le pipeline,
            // qui saute alors Whisper (branche « transcription déjà présente »,
            // celle qu'emprunte déjà la voie temps réel).
            whisperService.persist(submission, transcrit);
        } else {
            String clean = ProductionPayloadSupport.sanitizeText(texte);
            int mots = ProductionPayloadSupport.countWords(clean);
            validateTextWordCount(mots, task);
            submission.setTexteSoumis(clean);
            submission.setMotsCount(mots);
            try {
                submission = submissionManager.save(submission);
            } catch (DataIntegrityViolationException conflit) {
                ProductionSubmission gagnante = resoudreCourseIdempotence(userId, clientSubmissionId, conflit);
                if (gagnante != null) {
                    return gagnante;
                }
                if (task.isDiagnostic()) {
                    throw new BusinessException("Cette étape du diagnostic a déjà été rendue.");
                }
                throw conflit;
            }
        }

        // Sous-attempt EE/EO d'un examen blanc complet TCF : dès que les 3
        // tâches de l'épreuve sont rendues, on auto-finalise pour que le hub de
        // progression côté mobile détecte l'étape comme terminée. Aucune
        // route /finish n'est appelée par le mobile pour les productions.
        finishSubAttemptIfFullExam(attempt.getId());

        // Pipeline IA déclenché en arrière-plan : le caller HTTP reçoit la
        // submission en SUBMITTED immédiatement et n'attend pas Whisper +
        // Claude (~15 s). Le mobile poll ensuite l'état via /api/full-tcf-exams
        // ou /api/production-submissions/{id}. Si l'eval échoue, le runner
        // pose la submission en FAILED, l'utilisateur peut relancer via
        // /retry. Cf. ProductionPipelineAsyncRunner.
        pipelineRunner.runPipelineAsync(submission.getId(), estOral);
        return submission;
    }

    /**
     * La soumission gagnante d'une course sur la cle d'idempotence, ou
     * {@code null} si le conflit n'a rien a voir avec elle.
     *
     * <p>On ne devine JAMAIS a partir du message d'erreur : on relit. Si la cle
     * retrouve une ligne, la course est bien la cause et cette ligne est la
     * bonne reponse. Sinon, l'appelant reprend son traitement d'erreur normal —
     * un conflit qu'on ne comprend pas ne doit pas etre avale.
     */
    private ProductionSubmission resoudreCourseIdempotence(
            UUID userId, UUID clientSubmissionId, DataIntegrityViolationException conflit) {
        if (clientSubmissionId == null) {
            return null;
        }
        return submissionManager.findByClientKey(userId, clientSubmissionId)
                .map(gagnante -> {
                    log.info("Course sur la cle d'idempotence {} : la soumission {} l'emporte.",
                            clientSubmissionId, gagnante.getId());
                    return gagnante;
                })
                .orElse(null);
    }

    /**
     * Notation d'une session d'expression orale TEMPS RÉEL (examinateur IA). La
     * production n'est pas un fichier audio mais le TRANSCRIPT DIALOGUÉ (tours
     * examinateur + candidat) déjà capturé côté serveur pendant la session. On
     * crée une submission {@code REALTIME} (sans média) + une {@link Transcription}
     * pré-remplie, puis on lance le MÊME pipeline d'évaluation : comme une
     * transcription existe déjà, le runner SAUTE Whisper et note directement.
     * La consigne « interaction » des rubriques fait noter le candidat à partir
     * de l'échange complet (le pipeline n'est pas réécrit).
     *
     * <p>Pas de {@code @Transactional} (idem {@link #submitAndEvaluate}) : la
     * submission + la transcription sont commitées avant que le pipeline async
     * ne les lise.
     *
     * @param dialogueTranscript le dialogue complet (« Examinateur : … » /
     *                           « Candidat : … »).
     * @param durationSec        durée approximative de l'échange (warnings), ou null.
     */
    public ProductionSubmission evaluateRealtimeTranscript(
            UUID userId, UUID taskId, UUID attemptId, String dialogueTranscript, Integer durationSec) {

        User user = userManager.findById(userId)
            .orElseThrow(() -> new NotFoundException("User introuvable : " + userId));
        ProductionTask task = taskManager.findById(taskId)
            .orElseThrow(() -> new NotFoundException("ProductionTask introuvable : " + taskId));
        Attempt attempt = attemptManager.findById(attemptId)
            .orElseThrow(() -> new NotFoundException("Attempt introuvable : " + attemptId));

        if (task.getEpreuve() != EpreuveType.TCF_EO) {
            throw new BusinessException("La notation temps réel ne concerne que l'expression orale (TCF_EO).");
        }
        if (task.isDiagnostic()) {
            throw new BusinessException("Le diagnostic oral utilise un enregistrement, pas le temps réel.");
        }
        // MÊMES gardes que la voie asynchrone : la notation temps réel crée une
        // submission et déclenche le même pipeline payant, elle ne peut pas être
        // un chemin de contournement (épreuve terminée, chrono, quota freemium).
        accessService.assertCanSubmit(userId, attempt, task);
        accessService.enforceQuota(userId, task.getEpreuve(), attemptId);
        if (dialogueTranscript == null || dialogueTranscript.isBlank()) {
            throw new BusinessException("Transcript vide — rien à noter.");
        }

        ProductionSubmission submission = new ProductionSubmission();
        submission.setUser(user);
        submission.setAttempt(attempt);
        submission.setProductionTask(task);
        submission.setSource(ProductionSubmissionSource.REALTIME);
        submission.setMediaDurationSec(durationSec);
        submission.setStatut(SubmissionStatut.SUBMITTED);
        submission = submissionManager.save(submission);

        // La production : le dialogue complet. Pré-rempli -> Whisper sauté.
        Transcription t = new Transcription();
        t.setSubmission(submission);
        t.setTexte(dialogueTranscript.strip());
        t.setLangueDetectee("fr");
        t.setModeleUtilise("realtime");
        t.setAudioDurationSec(durationSec);
        // Le temps reel n'expose AUCUN indicateur de confiance (Gemini
        // natif-audio), alors que c'est la source la plus abimee. L'indicateur
        // maison, lui, se calcule sur le texte final : il vaut pour les deux
        // sources, et c'est ce qui rend la table comparable.
        TranscriptionQualityAudit.renseigner(t, t.getTexte());
        transcriptionManager.save(t);

        // Examen complet : auto-finalise le sous-attempt EO à 3 productions.
        finishSubAttemptIfFullExam(attempt.getId());

        pipelineRunner.runPipelineAsync(submission.getId(), true);
        return submission;
    }

    /**
     * Re-fetch l'attempt avec parent eager-loaded (impossible d'accéder à
     * {@code attempt.parentAttempt} ici sinon LazyInitializationException :
     * {@code submitAndEvaluate} n'est pas {@code @Transactional} et la session
     * Hibernate est déjà fermée quand on arrive ici).
     */
    private void finishSubAttemptIfFullExam(UUID attemptId) {
        Attempt attempt = attemptManager.findByIdWithParent(attemptId).orElse(null);
        if (attempt == null || attempt.getFinishedAt() != null) return;
        Attempt parent = attempt.getParentAttempt();
        if (parent == null || parent.getEpreuve() != EpreuveType.TCF_COMPLET) return;
        // Tâches DISTINCTES de l'épreuve de ce sous-attempt : compter les lignes
        // brutes finalisait l'épreuve sur 3 soumissions quelconques (même tâche
        // rejouée, ou tâches d'une autre épreuve mal aiguillées).
        long count = submissionManager.countDistinctTachesByAttemptAndEpreuve(
                attempt.getId(), attempt.getEpreuve());
        if (count >= ProductionBilanService.EXPECTED_TASKS_PER_EPREUVE) {
            attempt.setFinishedAt(Instant.now());
            attempt.setStatus(com.sejourfr.app.enums.AttemptStatus.TERMINE);
            attemptManager.save(attempt);
            log.info("Sub-attempt {} auto-finished (3 submissions reached, parent TCF_COMPLET={})",
                    attempt.getId(), parent.getId());
        }
    }

    /**
     * Relance le pipeline pour une submission {@code FAILED}. Verifie
     * l'appartenance utilisateur et le plafond de retries.
     */
    public ProductionSubmission retry(UUID submissionId, UUID userId) {
        ProductionSubmission sub = submissionManager.findByIdWithTaskAndUser(submissionId)
            .orElseThrow(() -> new NotFoundException("Submission introuvable : " + submissionId));
        if (sub.getUser() == null || !sub.getUser().getId().equals(userId)) {
            throw new BusinessException("Cette submission ne vous appartient pas.");
        }
        if (sub.isDiagnostic() || sub.getProductionTask().isDiagnostic()) {
            throw new BusinessException("Utilisez la relance du diagnostic pour cette production.");
        }
        if (sub.getStatut() != SubmissionStatut.FAILED) {
            throw new BusinessException(
                "Seules les submissions FAILED peuvent etre relancees (statut actuel : " + sub.getStatut() + ")."
            );
        }
        int max = props.getMaxRetriesPerSubmission();
        if (sub.getRetryCount() >= max) {
            throw new BusinessException("Plafond de " + max + " retries atteint pour cette submission.");
        }

        sub.setRetryCount((short) (sub.getRetryCount() + 1));
        sub.setErreurMessage(null);
        sub.setStatut(SubmissionStatut.SUBMITTED);
        submissionManager.save(sub);

        boolean estOral = sub.getProductionTask().getEpreuve() == EpreuveType.TCF_EO;
        // Pipeline en arrière-plan, idem submitAndEvaluate — le mobile reçoit
        // immédiatement la submission en SUBMITTED et poll pour l'état EVALUATED.
        pipelineRunner.runPipelineAsync(sub.getId(), estOral);
        return sub;
    }

    /** Relance réservée au DiagnosticService ; ne peut jamais bifurquer vers la note /20. */
    public ProductionSubmission retryDiagnostic(UUID submissionId, UUID userId, int maxRetries) {
        ProductionSubmission sub = submissionManager.findByIdWithTaskAndUser(submissionId)
                .orElseThrow(() -> new NotFoundException("Submission introuvable : " + submissionId));
        if (sub.getUser() == null || !sub.getUser().getId().equals(userId)
                || !sub.isDiagnostic() || !sub.getProductionTask().isDiagnostic()) {
            throw new BusinessException("Submission diagnostic introuvable.");
        }
        if (sub.getStatut() != SubmissionStatut.FAILED) {
            throw new BusinessException("Seule une étape diagnostic en échec peut être relancée.");
        }
        if (sub.getRetryCount() >= maxRetries) {
            throw new BusinessException("Plafond de " + maxRetries + " relances atteint.");
        }
        sub.setRetryCount((short) (sub.getRetryCount() + 1));
        sub.setErreurMessage(null);
        sub.setStatut(SubmissionStatut.SUBMITTED);
        submissionManager.save(sub);
        pipelineRunner.runPipelineAsync(
                sub.getId(), sub.getProductionTask().getEpreuve() == EpreuveType.TCF_EO);
        return sub;
    }

    private void validatePayload(boolean estOral, MultipartFile audio, String texte) {
        if (estOral && (audio == null || audio.isEmpty())) {
            throw new BusinessException("Tache TCF_EO : fichier audio requis.");
        }
        if (!estOral && (texte == null || texte.isBlank())) {
            throw new BusinessException("Tache TCF_EE : texte requis.");
        }
        if (estOral && texte != null && !texte.isBlank()) {
            throw new BusinessException("Tache TCF_EO : ne pas envoyer un texte en plus de l'audio.");
        }
        if (!estOral && audio != null && !audio.isEmpty()) {
            throw new BusinessException("Tache TCF_EE : ne pas envoyer un audio en plus du texte.");
        }
        if (estOral && audio != null && !audio.isEmpty()) {
            ProductionPayloadSupport.validateAudioContentType(audio);
        }
    }

    /**
     * Nom transmis à Whisper : il en déduit le format du conteneur. On ne rend
     * jamais le nom d'origine du fichier du candidat — seulement son extension
     * sûre, résolue comme elle l'était pour la clé de stockage.
     */
    private static String fileNameOf(MultipartFile audio) {
        return "production." + ProductionPayloadSupport.extractExtension(audio);
    }

    private void validateAudio(byte[] bytes) {
        if (bytes.length > props.getMaxAudioSizeBytes()) {
            throw new BusinessException(
                "Audio trop volumineux (max " + (props.getMaxAudioSizeBytes() / (1024 * 1024)) + " Mo)."
            );
        }
    }

    /**
     * Validation des mots EE selon les bornes officielles de la tache :
     * <ul>
     *   <li>mots &lt; {@code mots_min} → bloque (trop court) ;</li>
     *   <li>{@code mots_min} ≤ mots ≤ {@code mots_max} → OK ;</li>
     *   <li>mots &gt; {@code mots_max} → bloque (trop long).</li>
     * </ul>
     * Contrairement a l'EO (jamais bloquante), l'EE bloque hors-bornes : le
     * front desactive deja le bouton, c'est un garde-fou serveur.
     *
     * <p>Les bornes sont resolues par {@link ProductionTextBounds}, partage avec
     * le second appel « version au niveau vise » : le texte MODELE rendu au
     * candidat est ainsi soumis exactement au meme plafond que sa propre copie.
     */
    private void validateTextWordCount(int mots, ProductionTask task) {
        int plancher = ProductionTextBounds.of(task.getMotsMin(), task.getMotsMax(),
            props.getMinTextWords(), props.getMaxTextWords()).min();
        if (mots < plancher) {
            // 🛑 Le diagnostic ne parle pas de « tache » et ne reprimande pas :
            // c'est une porte d'entree, et le candidat n'a encore rien appris de
            // nous (10_ §3.3, formulation imposee). Aucun appel LLM n'a ete emis
            // a ce stade -- la garde est AVANT le pipeline.
            throw new BusinessException(task.isDiagnostic()
                ? "Nous n'avons pas assez d'éléments pour estimer votre niveau. "
                  + "Complétez votre texte : il faut au moins " + plancher + " mots."
                : "Votre texte est trop court : " + mots + " mots, il en faut au moins "
                  + plancher + " pour cette tache.");
        }
        if (task.getMotsMax() != null) {
            if (mots > task.getMotsMax()) {
                throw new BusinessException(
                    "Votre texte est trop long : " + mots + " mots pour un maximum de "
                    + task.getMotsMax() + ". Reduisez-le avant de soumettre.");
            }
        }
        // Garde-fou absolu anti-payload geant, independant de la tache.
        if (mots > props.getMaxTextWords()) {
            throw new BusinessException(
                "Votre texte est trop long : " + mots + " mots (maximum " + props.getMaxTextWords() + ").");
        }
    }

}

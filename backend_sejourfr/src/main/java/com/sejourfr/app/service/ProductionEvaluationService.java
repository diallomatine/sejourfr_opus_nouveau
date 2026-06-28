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
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.text.Normalizer;
import java.time.Instant;
import java.util.UUID;

/**
 * Orchestration end-to-end d'une submission EO ou EE :
 * <ol>
 *   <li>valide l'entree (taille audio / nombre de mots) ;</li>
 *   <li>uploade l'audio sur R2 (EO) ;</li>
 *   <li>cree la submission en {@code SUBMITTED} ;</li>
 *   <li>appelle Whisper (si EO) puis Claude ;</li>
 *   <li>passe la submission a {@code EVALUATED} ou {@code FAILED} avec un
 *       {@code erreur_message} parlant.</li>
 * </ol>
 * Le mecanisme de retry est dans les clients HTTP (Spring Retry). Cette classe
 * expose en plus {@link #retry(UUID, UUID)} pour relancer une submission
 * marquee {@code FAILED}.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ProductionEvaluationService {

    /** Grâce après expiration du chrono d'épreuve (latence de l'auto-soumission front). */
    private static final int SUBMIT_GRACE_SECONDS = 60;

    private final ProductionTaskManager taskManager;
    private final ProductionSubmissionManager submissionManager;
    private final TranscriptionManager transcriptionManager;
    private final AttemptManager attemptManager;
    private final UserManager userManager;
    private final ProductionAudioStorageService audioStorage;
    private final ProductionPipelineAsyncRunner pipelineRunner;
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

        User user = userManager.findById(userId)
            .orElseThrow(() -> new NotFoundException("User introuvable : " + userId));
        ProductionTask task = taskManager.findById(taskId)
            .orElseThrow(() -> new NotFoundException("ProductionTask introuvable : " + taskId));
        Attempt attempt = attemptManager.findById(attemptId)
            .orElseThrow(() -> new NotFoundException("Attempt introuvable : " + attemptId));

        // Vérif d'appartenance (IDOR — audit Vuln 5) : sans ce check, un
        // attaquant peut deviner un UUID d'attempt actif d'une victime et
        // y poster ses propres submissions, polluant son examen blanc
        // TCF_COMPLET (sub-attempt finalisé prématurément, plancher CECRL
        // calculé sur les productions de l'attaquant).
        if (attempt.getUser() == null || !attempt.getUser().getId().equals(userId)) {
            throw new AccessDeniedException("Cette session ne vous appartient pas");
        }

        // Épreuve déjà finalisée (fin de session, expiration du chrono, ou
        // sous-attempt auto-fini d'un examen complet) : plus aucune soumission.
        if (attempt.getFinishedAt() != null) {
            throw new BusinessException("Cette épreuve est terminée — soumission refusée.");
        }
        // Chrono d'épreuve (EE en examen : 30 min). Grâce de 60 s pour couvrir
        // la latence réseau de l'auto-soumission front à 0:00.
        if (attempt.getTimeLimitSeconds() != null && attempt.getStartedAt() != null
                && Instant.now().isAfter(attempt.getStartedAt()
                        .plusSeconds(attempt.getTimeLimitSeconds() + SUBMIT_GRACE_SECONDS))) {
            throw new BusinessException("Le temps de l'épreuve est écoulé — soumission refusée.");
        }

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

        if (estOral) {
            byte[] bytes = readBytes(audio);
            validateAudio(bytes);
            // On uploade R2 AVANT de creer la row pour respecter le CHECK
            // `chk_prod_sub_audio_or_text` (media_url DOIT etre non-null pour
            // une submission EO). La cle R2 utilise un UUID independant : on
            // ne pre-assigne pas l'id de la submission (Hibernate refuse
            // "Detached entity" avec @UuidGenerator + id pre-set).
            UUID storageKeyId = UUID.randomUUID();
            String extension = extractExtension(audio);
            ProductionAudioStorageService.StoredAudio stored = audioStorage.upload(
                storageKeyId, bytes, audio.getContentType(), extension
            );
            submission.setMediaUrl(stored.objectKey());
            submission.setMediaDurationSec(null); // sera mis a jour apres Whisper
            submission = submissionManager.save(submission);
        } else {
            String clean = sanitize(texte);
            int mots = compteMots(clean);
            validateTextWordCount(mots, task);
            submission.setTexteSoumis(clean);
            submission.setMotsCount(mots);
            submission = submissionManager.save(submission);
        }

        // Sous-attempt EE/EO d'un examen blanc complet TCF : dès qu'on
        // atteint 3 submissions, on auto-finalise pour que le hub de
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

        if (attempt.getUser() == null || !attempt.getUser().getId().equals(userId)) {
            throw new AccessDeniedException("Cette session ne vous appartient pas");
        }
        if (task.getEpreuve() != EpreuveType.TCF_EO) {
            throw new BusinessException("La notation temps réel ne concerne que l'expression orale (TCF_EO).");
        }
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
        int count = submissionManager.findByAttemptId(attempt.getId()).size();
        if (count >= 3) {
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
        ProductionSubmission sub = submissionManager.findById(submissionId)
            .orElseThrow(() -> new NotFoundException("Submission introuvable : " + submissionId));
        if (sub.getUser() == null || !sub.getUser().getId().equals(userId)) {
            throw new BusinessException("Cette submission ne vous appartient pas.");
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
    }

    private byte[] readBytes(MultipartFile audio) {
        try {
            return audio.getBytes();
        } catch (IOException e) {
            throw new BusinessException("Lecture du fichier audio impossible : " + e.getMessage());
        }
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
     *   <li>{@code mots_max} &lt; mots ≤ {@code mots_max} × 1.2 → toleré (un
     *       avertissement de depassement modere est ajoute a la correction par
     *       {@link AiEvaluationService}) ;</li>
     *   <li>mots &gt; {@code mots_max} × 1.2 → bloque (trop long).</li>
     * </ul>
     * Contrairement a l'EO (jamais bloquante), l'EE bloque hors-bornes : le
     * front desactive deja le bouton, c'est un garde-fou serveur.
     */
    private void validateTextWordCount(int mots, ProductionTask task) {
        int plancher = Math.max(props.getMinTextWords(),
            task.getMotsMin() != null ? task.getMotsMin() : 0);
        if (mots < plancher) {
            throw new BusinessException(
                "Votre texte est trop court : " + mots + " mots, il en faut au moins "
                + plancher + " pour cette tache.");
        }
        if (task.getMotsMax() != null) {
            int plafondTolere = (int) Math.floor(task.getMotsMax() * 1.2);
            if (mots > plafondTolere) {
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

    /**
     * Extrait une extension de fichier sûre à utiliser comme suffixe de clé
     * R2/S3. La valeur user-controlled (filename, content-type) est
     * whitelistée par une regex stricte — sinon on retombe sur "bin".
     *
     * <p>Sans cette garde, un {@code originalFilename = "foo.x/../audio/<id>.mp3"}
     * produit une key R2 contenant des slashes et {@code ..} (R2 stocke les
     * clés en strings opaques, mais des proxies/CDN peuvent canoniser). Cf
     * audit Vuln 7.
     */
    private static final java.util.regex.Pattern SAFE_EXTENSION =
            java.util.regex.Pattern.compile("^[a-z0-9]{1,8}$");

    private static String extractExtension(MultipartFile file) {
        String name = file.getOriginalFilename();
        if (name != null) {
            int dot = name.lastIndexOf('.');
            if (dot >= 0 && dot < name.length() - 1) {
                String candidate = name.substring(dot + 1).toLowerCase();
                if (SAFE_EXTENSION.matcher(candidate).matches()) {
                    return candidate;
                }
            }
        }
        String ct = file.getContentType();
        if (ct != null) {
            return switch (ct) {
                case "audio/webm" -> "webm";
                case "audio/mpeg", "audio/mp3" -> "mp3";
                case "audio/mp4", "audio/m4a", "audio/x-m4a" -> "m4a";
                case "audio/ogg" -> "ogg";
                case "audio/wav", "audio/x-wav" -> "wav";
                default -> "bin";
            };
        }
        return "bin";
    }

    private static String sanitize(String texte) {
        String nfc = Normalizer.normalize(texte, Normalizer.Form.NFC);
        return nfc.strip();
    }

    private static int compteMots(String texte) {
        if (texte == null || texte.isBlank()) return 0;
        return texte.trim().split("\\s+").length;
    }
}

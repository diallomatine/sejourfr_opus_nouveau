package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.exception.ProductionEvaluationException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.manager.UserManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.text.Normalizer;
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

    private final ProductionTaskManager taskManager;
    private final ProductionSubmissionManager submissionManager;
    private final TranscriptionManager transcriptionManager;
    private final AttemptManager attemptManager;
    private final UserManager userManager;
    private final ProductionAudioStorageService audioStorage;
    private final WhisperTranscriptionService whisperService;
    private final AiEvaluationService aiEvaluationService;
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

        try {
            runPipeline(submission, estOral);
        } catch (ProductionEvaluationException e) {
            markFailed(submission, e);
        }
        return submission;
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
        try {
            runPipeline(sub, estOral);
        } catch (ProductionEvaluationException e) {
            markFailed(sub, e);
        }
        return sub;
    }

    /**
     * Reprend le pipeline depuis le bon point :
     * <ul>
     *   <li>EO sans transcription -> Whisper puis Claude.</li>
     *   <li>EO avec transcription -> Claude direct (economie de cout au retry).</li>
     *   <li>EE -> Claude direct.</li>
     * </ul>
     */
    private void runPipeline(ProductionSubmission submission, boolean estOral) {
        if (estOral) {
            boolean hasTranscription = transcriptionManager
                .findLatestBySubmissionId(submission.getId()).isPresent();
            if (!hasTranscription) {
                whisperService.transcribe(submission.getId());
            } else {
                submission.setStatut(SubmissionStatut.EVALUATING);
                submissionManager.save(submission);
            }
        } else {
            submission.setStatut(SubmissionStatut.EVALUATING);
            submissionManager.save(submission);
        }
        AiEvaluation eval = aiEvaluationService.evaluate(submission.getId());
        if (eval == null) {
            throw new AiEvaluationException("Evaluation Claude n'a pas produit de resultat.");
        }
    }

    private void markFailed(ProductionSubmission submission, Exception e) {
        log.warn("Submission {} en FAILED : {}", submission.getId(), e.getMessage());
        submission.setStatut(SubmissionStatut.FAILED);
        submission.setErreurMessage(truncate(e.getMessage(), 1000));
        submissionManager.save(submission);
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

    private void validateTextWordCount(int mots, ProductionTask task) {
        int plancher = Math.max(props.getMinTextWords(),
            task.getMotsMin() != null ? task.getMotsMin() : 0);
        int plafond = Math.min(props.getMaxTextWords(),
            task.getMotsMax() != null ? task.getMotsMax() : Integer.MAX_VALUE);
        if (mots < plancher) {
            throw new BusinessException("Texte trop court : " + mots + " mots (minimum " + plancher + ").");
        }
        if (mots > plafond) {
            throw new BusinessException("Texte trop long : " + mots + " mots (maximum " + plafond + ").");
        }
    }

    private static String extractExtension(MultipartFile file) {
        String name = file.getOriginalFilename();
        if (name != null) {
            int dot = name.lastIndexOf('.');
            if (dot >= 0 && dot < name.length() - 1) return name.substring(dot + 1);
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

    private static String truncate(String s, int max) {
        if (s == null) return null;
        return s.length() <= max ? s : s.substring(0, max);
    }
}

package com.sejourfr.app.service;

import com.sejourfr.app.config.OpenAiProperties;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.Transcription;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.exception.TranscriptionException;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.TranscriptionManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Orchestration de la transcription Whisper pour une {@link ProductionSubmission}.
 * Pas de retry maison ici : le retry est dans {@link WhisperTranscriptionClient}
 * via Spring Retry.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class WhisperTranscriptionService {

    /** Cout indicatif Whisper : 0.006 USD / minute -> on stocke en centimes de cent, arrondi sup. */
    private static final double COUT_USD_PAR_SECONDE = 0.006 / 60.0;

    private final ProductionSubmissionManager submissionManager;
    private final TranscriptionManager transcriptionManager;
    private final ProductionAudioStorageService audioStorage;
    private final WhisperTranscriptionClient whisperClient;
    private final OpenAiProperties props;

    @Transactional
    public Transcription transcribe(UUID submissionId) {
        ProductionSubmission sub = submissionManager.findById(submissionId)
            .orElseThrow(() -> new NotFoundException("Submission introuvable : " + submissionId));
        if (sub.getMediaUrl() == null || sub.getMediaUrl().isBlank()) {
            throw new TranscriptionException("Submission " + submissionId + " n'a pas de media_url (texte uniquement ?)");
        }

        // Marquer le statut intermediaire (utile pour la migration future en async).
        sub.setStatut(SubmissionStatut.TRANSCRIBING);
        submissionManager.save(sub);

        byte[] bytes = audioStorage.download(sub.getMediaUrl());
        String fileName = sub.getMediaUrl();
        int slash = fileName.lastIndexOf('/');
        if (slash >= 0 && slash < fileName.length() - 1) fileName = fileName.substring(slash + 1);

        WhisperTranscriptionClient.WhisperResult result = whisperClient.transcribe(bytes, fileName);

        Integer detectedDuration = result.durationSec();
        Integer storedDuration = sub.getMediaDurationSec() != null ? sub.getMediaDurationSec() : detectedDuration;

        Transcription t = new Transcription();
        t.setSubmission(sub);
        t.setTexte(result.texte());
        t.setLangueDetectee(result.languageDetected());
        t.setModeleUtilise(props.getWhisper().getModel());
        t.setPromptUtilise(props.getWhisper().getLiteralModePrompt());
        t.setAudioDurationSec(detectedDuration);
        t.setCoutEstimeCentimes(estimerCout(detectedDuration));
        transcriptionManager.save(t);

        sub.setStatut(SubmissionStatut.EVALUATING);
        sub.setMediaDurationSec(storedDuration);
        submissionManager.save(sub);

        log.info("Transcription persistee submission={} chars={} model={}",
            submissionId, result.texte().length(), props.getWhisper().getModel());
        return t;
    }

    private static Integer estimerCout(Integer durationSec) {
        if (durationSec == null || durationSec <= 0) return null;
        double centsUsd = durationSec * COUT_USD_PAR_SECONDE * 100.0;
        return (int) Math.ceil(centsUsd);
    }
}

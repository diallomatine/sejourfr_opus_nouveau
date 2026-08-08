package com.sejourfr.app.service.competence;

import com.sejourfr.app.config.OpenAiProperties;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.exception.TranscriptionException;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.service.ProductionAudioStorageService;
import com.sejourfr.app.service.WhisperTranscriptionClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Transcription Whisper d'une production ORALE de competence.
 *
 * <p><b>Pourquoi un service distinct de {@code WhisperTranscriptionService}.</b>
 * Ce dernier est ecrit pour une {@code ProductionSubmission} : il persiste une
 * ligne {@code transcriptions}, dont la colonne {@code submission_id} est NOT
 * NULL et referencee en cle etrangere. Une tentative de competence n'a pas de
 * submission — il n'y en aura jamais, c'est une voie parallele. On reutilise
 * donc ce qui est reutilisable (le CLIENT HTTP {@link WhisperTranscriptionClient},
 * avec son retry, son prompt de transcription litterale et sa detection de
 * duree) et on ecrit le texte la ou il appartient : la colonne
 * {@code user_skill_attempts.transcript}. Aucune ligne du service existant n'est
 * modifiee.
 *
 * <p><b>Appelee uniquement quand une analyse a ete demandee</b> : on ne paie
 * pas Whisper pour un audio que personne ne corrigera. L'audio, lui, est
 * conserve dans tous les cas — le candidat doit pouvoir se reecouter.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SkillTranscriptionService {

    private final UserSkillAttemptManager attemptManager;
    private final ProductionAudioStorageService audioStorage;
    private final WhisperTranscriptionClient whisperClient;
    private final OpenAiProperties props;

    /**
     * Transcrit l'audio de la tentative, ecrit le texte et fait passer le statut
     * a {@code EVALUATING}.
     *
     * @return le texte transcrit
     */
    @Transactional
    public String transcribe(UUID attemptId) {
        UserSkillAttempt attempt = attemptManager.findById(attemptId)
                .orElseThrow(() -> new NotFoundException("Tentative introuvable : " + attemptId));
        String objectKey = attempt.getAudioObjectKey();
        if (objectKey == null || objectKey.isBlank()) {
            throw new TranscriptionException(
                    "La tentative " + attemptId + " n'a pas d'audio (production écrite ?)");
        }

        attempt.setStatut(SkillAttemptStatut.TRANSCRIBING);
        attemptManager.save(attempt);

        byte[] bytes = audioStorage.download(objectKey);
        WhisperTranscriptionClient.WhisperResult result =
                whisperClient.transcribe(bytes, fileNameOf(objectKey));

        attempt.setTranscript(result.texte());
        // La duree detectee par Whisper fait foi sur celle annoncee par le
        // client : c'est la seule mesure faite sur le fichier reellement recu.
        if (result.durationSec() != null) {
            attempt.setAudioDurationSec(result.durationSec());
        }
        attempt.setStatut(SkillAttemptStatut.EVALUATING);
        attemptManager.save(attempt);

        log.info("Transcription competence persistee attempt={} chars={} model={}",
                attemptId, result.texte().length(), props.getWhisper().getModel());
        return result.texte();
    }

    /** Whisper exige un nom de fichier avec extension pour deviner le format. */
    private static String fileNameOf(String objectKey) {
        int slash = objectKey.lastIndexOf('/');
        return (slash >= 0 && slash < objectKey.length() - 1)
                ? objectKey.substring(slash + 1)
                : objectKey;
    }
}

package com.sejourfr.app.service;

import com.sejourfr.app.config.OpenAiProperties;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.Transcription;
import com.sejourfr.app.exception.TranscriptionException;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.util.CoutTranscription;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Transcription Whisper d'une production ORALE de candidat.
 *
 * <p><b>L'audio n'est jamais stocké</b> (décision produit, motif consentement) :
 * les octets arrivent dans la requête de soumission, servent à produire la
 * transcription, et disparaissent avec elle. Ce service ne connaît donc plus
 * aucun stockage — il reçoit un {@code byte[]} et rend un résultat. Le corollaire
 * assumé : <b>la transcription se fait PENDANT la requête</b>, seul moment où les
 * octets existent, et non plus dans un runner asynchrone qui relisait l'objet R2.
 *
 * <p>Deux étapes volontairement séparées :
 * <ul>
 *   <li>{@link #transcribe} — l'appel réseau, <b>hors transaction</b> : on ne
 *       tient pas une transaction ouverte pendant plusieurs secondes d'attente
 *       fournisseur ;</li>
 *   <li>{@link #persist} — l'écriture de la ligne {@code transcriptions}, une
 *       fois la {@link ProductionSubmission} créée (la clé étrangère
 *       {@code submission_id} est NOT NULL).</li>
 * </ul>
 *
 * <p>Pas de retry maison : il est dans {@link WhisperTranscriptionClient} via
 * Spring Retry. Un échec remonte au candidat, qui a encore son enregistrement
 * sur son appareil et peut renvoyer — c'est la seule reprise possible, et c'est
 * pour ça qu'elle est SYNCHRONE.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class WhisperTranscriptionService {

    private final TranscriptionManager transcriptionManager;
    private final WhisperTranscriptionClient whisperClient;
    private final OpenAiProperties props;

    /**
     * Transcrit des octets audio qui ne seront jamais écrits nulle part.
     *
     * @param bytes    l'enregistrement, tel qu'il a été reçu dans la requête
     * @param fileName nom porteur d'une extension : Whisper devine le format
     *                 avec, un nom vide le ferait échouer sur certains conteneurs
     */
    public WhisperTranscriptionClient.WhisperResult transcribe(byte[] bytes, String fileName) {
        if (bytes == null || bytes.length == 0) {
            throw new TranscriptionException("Aucun octet audio à transcrire.");
        }
        return whisperClient.transcribe(bytes, safeFileName(fileName));
    }

    /**
     * Écrit la transcription d'une soumission déjà persistée. Rend aussi la durée
     * détectée par Whisper — la seule mesure faite sur le fichier réellement reçu.
     */
    @Transactional
    public Transcription persist(ProductionSubmission sub, WhisperTranscriptionClient.WhisperResult result) {
        Transcription t = new Transcription();
        t.setSubmission(sub);
        t.setTexte(result.texte());
        t.setLangueDetectee(result.languageDetected());
        t.setModeleUtilise(props.getWhisper().getModel());
        t.setPromptUtilise(props.getWhisper().getLiteralModePrompt());
        t.setAudioDurationSec(result.durationSec());
        t.setCoutMicroUsd(coutMicroUsd(result.durationSec()));
        t.setAvgLogprob(result.quality().avgLogprob());
        t.setNoSpeechProb(result.quality().noSpeechProb());
        t.setCompressionRatio(result.quality().compressionRatio());
        t.setSegmentsCount(result.quality().segmentsCount() > 0
            ? result.quality().segmentsCount() : null);
        TranscriptionQualityAudit.renseigner(t, result.texte());
        transcriptionManager.save(t);

        log.info("Transcription persistee submission={} chars={} model={}",
            sub.getId(), result.texte().length(), props.getWhisper().getModel());
        return t;
    }

    /** Whisper exige un nom de fichier avec extension pour deviner le format. */
    static String safeFileName(String fileName) {
        return (fileName == null || fileName.isBlank()) ? "audio.webm" : fileName;
    }

    /**
     * Whisper facture a la MINUTE d'audio. Le tarif vient de la configuration
     * (jamais d'une constante Java : il voyage avec le modele), l'unite et
     * l'arrondi sont ceux de tout le depot — cf. {@link CoutTranscription}.
     */
    private Integer coutMicroUsd(Integer durationSec) {
        return new CoutTranscription(props.getWhisper().getCostPerMinuteUsd())
            .microDollars(durationSec);
    }
}

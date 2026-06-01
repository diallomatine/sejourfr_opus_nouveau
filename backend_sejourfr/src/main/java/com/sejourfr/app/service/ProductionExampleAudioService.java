package com.sejourfr.app.service;

import com.sejourfr.app.audioquestion.service.AzureVoices;
import com.sejourfr.app.audioquestion.service.AzureSpeechClient;
import com.sejourfr.app.audioquestion.service.CloudflareR2Client;
import com.sejourfr.app.dto.ExampleAudioBatchResultDto;
import com.sejourfr.app.dto.ExampleAudioDto;
import com.sejourfr.app.entity.ProductionExample;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.ExampleAudioStatus;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.ProductionTaskManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Génération batch des audios des exemples-modèles d'Expression Orale, puis
 * validation par un admin. Réutilise le pipeline existant
 * ({@link AzureSpeechClient} + {@link CloudflareR2Client}) — on ne réimplémente
 * ni Azure ni R2.
 *
 * <p>Cycle : {@code NONE/PENDING/ERROR} → (batch) → {@code GENERATED} → (publish)
 * → {@code PUBLISHED}. Seuls les exemples PUBLISHED exposent leur audio au candidat.
 *
 * <p>Pas de {@code @Transactional} de classe : chaque {@code saveExample} est sa
 * propre transaction, ce qui rend le batch résilient (un échec n'annule pas les
 * items déjà générés et le statut GENERATING est visible pendant l'appel Azure).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ProductionExampleAudioService {

    /** Statuts depuis lesquels une (re)génération est possible. */
    private static final List<ExampleAudioStatus> RELAUNCHABLE =
            List.of(ExampleAudioStatus.NONE, ExampleAudioStatus.PENDING, ExampleAudioStatus.ERROR);

    private static final String VOICE_FEMININE = "fr-FR-DeniseNeural";
    private static final String VOICE_MASCULINE = "fr-FR-HenriNeural";

    /** audio-24khz-48kbitrate-mono-mp3 ≈ 6000 octets/seconde. */
    private static final double BYTES_PER_SECOND = 6000.0;

    private final ProductionTaskManager taskManager;
    private final AzureSpeechClient azureSpeechClient;
    private final CloudflareR2Client r2Client;

    public long countPendingAudio() {
        return taskManager.countEoExamplesNeedingAudio(RELAUNCHABLE);
    }

    public List<ExampleAudioDto> listGeneratedForReview() {
        return taskManager.findEoExamplesByAudioStatus(ExampleAudioStatus.GENERATED).stream()
                .map(this::toDto)
                .toList();
    }

    public ExampleAudioBatchResultDto generateBatchAudio(int batchSize) {
        int size = Math.max(1, Math.min(batchSize, 50));
        List<ProductionExample> examples = taskManager.findEoExamplesNeedingAudio(RELAUNCHABLE, size);
        UUID batchId = UUID.randomUUID();

        int succeeded = 0;
        int failed = 0;
        List<ExampleAudioBatchResultDto.Outcome> outcomes = new ArrayList<>();

        for (ProductionExample ex : examples) {
            try {
                generateFor(ex, batchId, null);
                succeeded++;
                outcomes.add(new ExampleAudioBatchResultDto.Outcome(ex.getId(), true, null));
            } catch (Exception e) {
                failed++;
                markError(ex, e);
                outcomes.add(new ExampleAudioBatchResultDto.Outcome(ex.getId(), false, message(e)));
                log.warn("Audio exemple {} échoué : {}", ex.getId(), e.getMessage());
            }
        }
        log.info("Batch audio exemples EO {} : {} générés, {} en erreur", batchId, succeeded, failed);
        return new ExampleAudioBatchResultDto(batchId, examples.size(), succeeded, failed, outcomes);
    }

    public ExampleAudioDto publishExampleAudio(UUID id) {
        ProductionExample ex = loadEoExample(id);
        if (ex.getAudioStatus() != ExampleAudioStatus.GENERATED) {
            throw new BusinessException(
                    "Seul un audio GENERATED peut être publié (statut actuel : " + ex.getAudioStatus() + ").");
        }
        ex.setAudioStatus(ExampleAudioStatus.PUBLISHED);
        return toDto(taskManager.saveExample(ex));
    }

    public ExampleAudioDto regenerateExampleAudio(UUID id, String voice) {
        ProductionExample ex = loadEoExample(id);
        ex.setAudioUrl(null);
        ex.setAudioStatus(ExampleAudioStatus.PENDING);
        ex.setAudioError(null);
        taskManager.saveExample(ex);
        try {
            generateFor(ex, ex.getAudioBatchId(), voice);
        } catch (Exception e) {
            markError(ex, e);
            log.warn("Régénération audio exemple {} échouée : {}", id, e.getMessage());
        }
        return toDto(taskManager.findExampleById(id).orElseThrow());
    }

    // ------------------------------------------------------------------------

    /** Synthèse Azure + upload R2 d'un exemple. Lève en cas d'échec Azure/R2. */
    private void generateFor(ProductionExample ex, UUID batchId, String requestedVoice) {
        ex.setAudioStatus(ExampleAudioStatus.GENERATING);
        ex.setAudioBatchId(batchId);
        ex.setAudioError(null);
        taskManager.saveExample(ex);

        String voice = resolveVoice(requestedVoice, ex.getDisplayOrder());
        byte[] mp3 = azureSpeechClient.synthesize(resolveSsml(ex, voice));
        CloudflareR2Client.R2UploadResult upload = r2Client.uploadAudio(UUID.randomUUID(), mp3);

        ex.setAudioUrl(upload.publicUrl());
        ex.setAudioVoice(voice);
        ex.setAudioDurationSec(estimateDurationSec(mp3));
        ex.setAudioGeneratedAt(Instant.now());
        ex.setAudioStatus(ExampleAudioStatus.GENERATED);
        ex.setAudioError(null);
        taskManager.saveExample(ex);
    }

    private void markError(ProductionExample ex, Exception e) {
        ex.setAudioStatus(ExampleAudioStatus.ERROR);
        ex.setAudioError(message(e));
        taskManager.saveExample(ex);
    }

    private ProductionExample loadEoExample(UUID id) {
        ProductionExample ex = taskManager.findExampleById(id)
                .orElseThrow(() -> new NotFoundException("Exemple introuvable : " + id));
        // Garde-fou : on ne génère/publie de l'audio que pour les exemples EO.
        boolean isEo = taskManager.findById(ex.getTaskId())
                .map(t -> t.getEpreuve() == EpreuveType.TCF_EO)
                .orElse(false);
        if (!isEo) {
            throw new BusinessException("L'audio n'est généré que pour les exemples d'Expression Orale.");
        }
        return ex;
    }

    /** Voix demandée si valide, sinon alternance Denise/Henri selon l'ordre. */
    private String resolveVoice(String requested, int displayOrder) {
        if (requested != null && AzureVoices.ALLOWED.contains(requested)) {
            return requested;
        }
        return displayOrder % 2 == 0 ? VOICE_FEMININE : VOICE_MASCULINE;
    }

    private int estimateDurationSec(byte[] mp3) {
        return Math.max(1, (int) Math.round(mp3.length / BYTES_PER_SECOND));
    }

    /**
     * SSML multi-voix écrit à la main (dialogues examinateur ↔ candidat) s'il est
     * renseigné, sinon génération automatique mono-voix depuis {@code contenu}.
     */
    private String resolveSsml(ProductionExample ex, String voice) {
        String ssml = ex.getSsmlText();
        return (ssml != null && !ssml.isBlank()) ? ssml : buildSsml(ex.getContenu(), voice);
    }

    /**
     * SSML simple : voix neutre, débit légèrement ralenti, légère pause après
     * chaque ponctuation forte pour un rendu naturel. Le contenu est échappé XML.
     */
    private String buildSsml(String contenu, String voice) {
        String escaped = escapeXml(contenu == null ? "" : contenu.strip());
        String withBreaks = escaped.replaceAll("([.!?])\\s+", "$1<break time=\"300ms\"/> ");
        return "<speak version=\"1.0\" xml:lang=\"fr-FR\">"
                + "<voice name=\"" + voice + "\">"
                + "<prosody rate=\"0.95\">" + withBreaks + "</prosody>"
                + "</voice></speak>";
    }

    private static String escapeXml(String s) {
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&apos;");
    }

    private static String message(Exception e) {
        String m = e.getMessage();
        if (m == null) m = e.getClass().getSimpleName();
        return m.length() > 1000 ? m.substring(0, 1000) : m;
    }

    private ExampleAudioDto toDto(ProductionExample e) {
        return new ExampleAudioDto(
                e.getId(),
                e.getTaskId(),
                e.getTitre(),
                e.getResume(),
                e.getContenu(),
                e.getSsmlText(),
                e.getAudioStatus(),
                e.getAudioUrl(),
                e.getAudioVoice(),
                e.getAudioDurationSec(),
                e.getAudioGeneratedAt(),
                e.getAudioBatchId(),
                e.getAudioError(),
                e.getCreatedAt()
        );
    }
}

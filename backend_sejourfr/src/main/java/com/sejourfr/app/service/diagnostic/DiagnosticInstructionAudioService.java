package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.audioquestion.config.AzureSpeechProperties;
import com.sejourfr.app.audioquestion.config.CloudflareR2Properties;
import com.sejourfr.app.audioquestion.service.AzureSpeechClient;
import com.sejourfr.app.audioquestion.service.CloudflareR2Client;
import com.sejourfr.app.dto.DiagnosticInstructionAudioDto;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.ProductionTaskManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * Opération admin explicite et idempotente pour l'audio fixe du diagnostic.
 * La clé R2 est l'UUID immuable du sujet, donc une version ultérieure obtient
 * automatiquement une autre clé et une relance ne crée jamais de copie.
 */
@Service
@RequiredArgsConstructor
public class DiagnosticInstructionAudioService {

    private static final String VOICE = "fr-FR-DeniseNeural";

    private final ProductionTaskManager taskManager;
    private final AzureSpeechClient azureSpeechClient;
    private final CloudflareR2Client r2Client;
    private final AzureSpeechProperties azureProperties;
    private final CloudflareR2Properties r2Properties;

    /** Lecture seule : permet à l'admin de vérifier configuration, URL et objet R2. */
    public DiagnosticInstructionAudioDto status(String code, int version) {
        ProductionTask task = loadOralTask(code, version);
        boolean present = r2Properties.isConfigured() && r2Client.audioExists(task.getId());
        return toDto(task, present, false);
    }

    /**
     * Génère au plus un objet par sujet/version. Si un upload existe après une
     * interruption avant l'écriture DB, l'URL est simplement réparée sans TTS.
     */
    public DiagnosticInstructionAudioDto generate(String code, int version) {
        ProductionTask task = loadOralTask(code, version);
        if (!r2Properties.isConfigured()) {
            throw new BusinessException("Cloudflare R2 n'est pas configuré pour stocker l'audio diagnostic.");
        }

        boolean present = r2Client.audioExists(task.getId());
        String canonicalUrl = r2Client.audioPublicUrl(task.getId());
        if (present) {
            if (!canonicalUrl.equals(task.getInstructionAudioUrl())) {
                task.setInstructionAudioUrl(canonicalUrl);
                task = taskManager.save(task);
            }
            return toDto(task, true, false);
        }

        if (!azureProperties.isConfigured()) {
            throw new BusinessException("Azure Speech n'est pas configuré pour générer l'audio diagnostic.");
        }

        byte[] mp3 = azureSpeechClient.synthesize(buildSsml(task.getConsigne()));
        CloudflareR2Client.R2UploadResult upload = r2Client.uploadAudio(task.getId(), mp3);
        task.setInstructionAudioUrl(upload.publicUrl());
        task = taskManager.save(task);
        return toDto(task, true, true);
    }

    private ProductionTask loadOralTask(String code, int version) {
        ProductionTask task = taskManager.findActiveDiagnostic(code, version, EpreuveType.TCF_EO)
                .orElseThrow(() -> new NotFoundException(
                        "Sujet oral diagnostic introuvable : " + code + " v" + version));
        if (task.getConsigne() == null || task.getConsigne().isBlank()) {
            throw new BusinessException("La consigne orale diagnostic est vide.");
        }
        return task;
    }

    /** Les balises ne changent aucun mot : le texte parlé est la consigne visible. */
    private static String buildSsml(String instruction) {
        String escaped = escapeXml(instruction);
        return "<speak version=\"1.0\" xml:lang=\"fr-FR\">"
                + "<voice name=\"" + VOICE + "\">"
                + "<prosody rate=\"0.95\">" + escaped + "</prosody>"
                + "</voice></speak>";
    }

    private static String escapeXml(String value) {
        return value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&apos;");
    }

    private DiagnosticInstructionAudioDto toDto(
            ProductionTask task, boolean present, boolean generatedNow) {
        return new DiagnosticInstructionAudioDto(
                task.getId(), task.getDiagnosticCode(), task.getDiagnosticVersion(),
                r2Client.audioObjectKey(task.getId()), task.getInstructionAudioUrl(),
                azureProperties.isConfigured(), r2Properties.isConfigured(), present, generatedNow);
    }
}

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
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Opération admin explicite et idempotente pour l'audio fixe du diagnostic.
 * La clé R2 est l'UUID immuable du sujet, donc une version ultérieure obtient
 * automatiquement une autre clé et une relance ne crée jamais de copie.
 */
@Service
@Slf4j
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

    /** Comportement par défaut : idempotent, aucune synthèse si l'objet existe déjà. */
    public DiagnosticInstructionAudioDto generate(String code, int version) {
        return generate(code, version, false);
    }

    /**
     * Génère au plus un objet par sujet/version. Si un upload existe après une
     * interruption avant l'écriture DB, l'URL est simplement réparée sans TTS.
     *
     * <p>{@code force} est le seul moyen de refaire la synthèse quand l'objet
     * existe déjà : une consigne corrigée (cf. V756) rend l'audio faux, et la
     * relance idempotente ne savait alors que réparer l'URL. Opt-in strict — un
     * client qui rejoue la route sans le paramètre ne paie jamais Azure. La clé
     * R2 reste l'UUID du sujet, donc l'écrasement se fait sous la même clé et
     * l'URL en base ne bouge pas (le front garde son lien).</p>
     */
    public DiagnosticInstructionAudioDto generate(String code, int version, boolean force) {
        ProductionTask task = loadOralTask(code, version);
        if (!r2Properties.isConfigured()) {
            throw new BusinessException("Cloudflare R2 n'est pas configuré pour stocker l'audio diagnostic.");
        }

        boolean present = r2Client.audioExists(task.getId());
        if (present && !force) {
            String canonicalUrl = r2Client.audioPublicUrl(task.getId());
            if (!canonicalUrl.equals(task.getInstructionAudioUrl())) {
                task.setInstructionAudioUrl(canonicalUrl);
                task = taskManager.save(task);
            }
            return toDto(task, true, false);
        }

        if (!azureProperties.isConfigured()) {
            throw new BusinessException("Azure Speech n'est pas configuré pour générer l'audio diagnostic.");
        }

        if (present) {
            log.warn("Régénération forcée de l'audio diagnostic {} v{} : écrasement de {}",
                    code, version, r2Client.audioObjectKey(task.getId()));
        }

        // La synthèse part toujours du texte courant en base, jamais d'une copie.
        byte[] mp3 = azureSpeechClient.synthesize(buildSsml(task.getConsigne()));
        // putObject sur la même clé = remplacement atomique last-write-wins ; un
        // delete préalable ouvrirait une fenêtre où l'URL servie renvoie 404.
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

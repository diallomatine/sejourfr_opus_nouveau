package com.sejourfr.app.service.email.campaign;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.core.io.ClassPathResource;

import java.io.IOException;
import java.io.InputStream;

/**
 * Les vagues des campagnes de service, lues dans
 * {@code email/campaigns-config-v1.json} (versionne, jamais en dur).
 *
 * @param waveSize        taille de vague par defaut ({@code batch} absent)
 * @param maxWaveSize     plafond d'un {@code batch} demande
 * @param pauseSeconds    pause a respecter entre deux vagues (limite SMTP)
 * @param waveWaitSeconds attente maximale de la reponse HTTP ; au-dela la vague
 *                        continue sur l'executor email et la reponse dit IN_PROGRESS
 * @param sampleSize      taille de l'echantillon masque du dry-run
 */
public record EmailCampaignConfig(
        int campaignsConfigVersion,
        int waveSize,
        int maxWaveSize,
        int pauseSeconds,
        int waveWaitSeconds,
        int sampleSize
) {

    static final int VERSION = 1;
    private static final String PATH = "email/campaigns-config-v" + VERSION + ".json";

    private static final ObjectMapper MAPPER = new ObjectMapper()
            .enable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
            .enable(DeserializationFeature.FAIL_ON_NULL_FOR_PRIMITIVES)
            .enable(DeserializationFeature.FAIL_ON_MISSING_CREATOR_PROPERTIES);

    public static EmailCampaignConfig load() {
        try (InputStream in = new ClassPathResource(PATH).getInputStream()) {
            EmailCampaignConfig c = MAPPER.readValue(in, EmailCampaignConfig.class);
            if (c.campaignsConfigVersion != VERSION || c.waveSize < 1 || c.maxWaveSize < c.waveSize
                    || c.pauseSeconds < 0 || c.waveWaitSeconds < 1 || c.sampleSize < 0) {
                throw new IllegalStateException("Configuration des campagnes invalide : " + PATH);
            }
            return c;
        } catch (IOException e) {
            throw new IllegalStateException("Configuration des campagnes illisible : " + PATH, e);
        }
    }
}

package com.sejourfr.app.service.email;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sejourfr.app.enums.EmailType;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;

import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;
import java.util.List;

/**
 * Charge et <b>verifie</b> {@code email-automation-config-vN.json} au demarrage.
 * Meme doctrine que {@code PlanConfigLoader} : une configuration incomplete qui
 * demarrerait quand meme enverrait (ou n'enverrait plus) des mails sans que rien
 * n'echoue.
 *
 * <p>Refus volontaires : cle inconnue, version differente de celle demandee,
 * scenario manquant, fenetre inversee ou negative, plafond nul, delai negatif.
 */
@Slf4j
public final class EmailAutomationConfigLoader {

    private static final ObjectMapper MAPPER = new ObjectMapper()
            .enable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
            .enable(DeserializationFeature.FAIL_ON_NULL_FOR_PRIMITIVES)
            .enable(DeserializationFeature.FAIL_ON_MISSING_CREATOR_PROPERTIES);

    /** Les scenarios automatises : chacun DOIT avoir sa fenetre. */
    public static final List<EmailType> SCENARIOS = Arrays.stream(EmailType.values())
            .filter(t -> t.deferredRetry() == EmailType.DeferredRetry.SCENARIO)
            .toList();

    private EmailAutomationConfigLoader() {
    }

    public static EmailAutomationConfig load(int configVersion) {
        String path = "email/email-automation-config-v" + configVersion + ".json";
        try (InputStream in = new ClassPathResource(path).getInputStream()) {
            return parse(in, configVersion, path);
        } catch (IOException e) {
            throw new IllegalStateException("Configuration des emails illisible : " + path, e);
        }
    }

    static EmailAutomationConfig parse(InputStream in, int configVersion, String path) throws IOException {
        EmailAutomationConfig config = MAPPER.readValue(in, EmailAutomationConfig.class);
        if (config.emailAutomationConfigVersion() != configVersion) {
            throw new IllegalStateException("emailAutomationConfigVersion="
                    + config.emailAutomationConfigVersion() + " dans " + path
                    + " alors que la version demandee est " + configVersion);
        }
        if (config.engagement() == null || config.retry() == null || config.scenarios() == null) {
            throw new IllegalStateException("Sections engagement/retry/scenarios absentes de " + path);
        }
        positif(config.engagement().dailyCap(), "engagement.dailyCap", path);
        positif(config.batchSize(), "batchSize", path);
        positif(config.retentionMonths(), "retentionMonths", path);
        EmailAutomationConfig.Retry retry = config.retry();
        if (retry.immediateDelaysSeconds() == null
                || retry.immediateDelaysSeconds().stream().anyMatch(d -> d == null || d < 0)) {
            throw new IllegalStateException("retry.immediateDelaysSeconds absent ou negatif dans " + path);
        }
        if (retry.maxDeferredAttempts() < 0) {
            throw new IllegalStateException("retry.maxDeferredAttempts negatif dans " + path);
        }
        positif(retry.eventWindowHours(), "retry.eventWindowHours", path);
        positif(retry.stalePendingMinutes(), "retry.stalePendingMinutes", path);
        for (EmailType scenario : SCENARIOS) {
            EmailAutomationConfig.ScenarioWindow w = config.scenarios().get(scenario);
            if (w == null) {
                throw new IllegalStateException("scenarios n'a pas d'entree pour " + scenario + " dans " + path);
            }
            if (w.minDays() < 0 || w.maxDays() < w.minDays() || w.maxDays() == 0 || w.minAccessAgeDays() < 0
                    || w.minAccessDurationDays() < 0) {
                throw new IllegalStateException("Fenetre invalide pour " + scenario + " dans " + path);
            }
        }
        for (EmailType type : config.scenarios().keySet()) {
            if (!SCENARIOS.contains(type)) {
                throw new IllegalStateException(type + " n'est pas un scenario automatise (" + path + ")");
            }
        }
        log.info("Configuration des emails chargee (v{}) : plafond {} / jour, relances {}",
                config.emailAutomationConfigVersion(), config.engagement().dailyCap(),
                retry.immediateDelaysSeconds());
        return config;
    }

    private static void positif(int valeur, String cle, String path) {
        if (valeur <= 0) {
            throw new IllegalStateException(cle + " doit etre > 0 dans " + path);
        }
    }
}

package com.sejourfr.app.service.analytics;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sejourfr.app.enums.SuiviIndicator;
import com.sejourfr.app.util.FenetreMesure;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;

import java.io.IOException;
import java.io.InputStream;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.EnumSet;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * Charge et <b>verifie</b> {@code analytics/analytics-config-vN.json} au
 * demarrage. Meme doctrine que {@code PlanConfigLoader} et
 * {@code EmailAutomationConfigLoader} : une configuration incomplete qui
 * demarrerait quand meme produirait des chiffres faux sans que rien n'echoue.
 *
 * <p>Refus volontaires : cle inconnue ou manquante, version differente de celle
 * demandee, fuseau autre que {@code FenetreMesure.PARIS}, duree nulle ou
 * negative, source rangee dans deux groupes, indicateur sans entree, date
 * illisible.
 */
@Slf4j
public final class AnalyticsConfigLoader {

    private static final ObjectMapper MAPPER = new ObjectMapper()
            .enable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
            .enable(DeserializationFeature.FAIL_ON_NULL_FOR_PRIMITIVES)
            .enable(DeserializationFeature.FAIL_ON_MISSING_CREATOR_PROPERTIES);

    /** Nom de groupe et source declaree : meme charset que {@code ft_source_raw}. */
    private static final Pattern SLUG = Pattern.compile("^[a-z0-9][a-z0-9._-]{0,39}$");

    private AnalyticsConfigLoader() {
    }

    public static AnalyticsConfig load(int configVersion) {
        String path = "analytics/analytics-config-v" + configVersion + ".json";
        try (InputStream in = new ClassPathResource(path).getInputStream()) {
            return parse(in, configVersion, path);
        } catch (IOException e) {
            throw new IllegalStateException("Configuration d'analytics illisible : " + path, e);
        }
    }

    static AnalyticsConfig parse(InputStream in, int configVersion, String path) throws IOException {
        AnalyticsConfig config = MAPPER.readValue(in, AnalyticsConfig.class);
        if (config.analyticsConfigVersion() != configVersion) {
            throw new IllegalStateException("analyticsConfigVersion=" + config.analyticsConfigVersion()
                    + " dans " + path + " alors que la version demandee est " + configVersion);
        }
        if (!FenetreMesure.PARIS.getId().equals(config.timezone())) {
            throw new IllegalStateException("timezone doit valoir " + FenetreMesure.PARIS.getId()
                    + " (FenetreMesure.PARIS fait autorite) dans " + path);
        }
        positif(config.cohortWindowDays(), "cohortWindowDays", path);
        positif(config.claimTokenTtlDays(), "claimTokenTtlDays", path);
        positif(config.runReuseWindowHours(), "runReuseWindowHours", path);
        positif(config.purchaseIntentTtlHours(), "purchaseIntentTtlHours", path);
        positif(config.anonymousIdTtlDays(), "anonymousIdTtlDays", path);
        positif(config.rawEventRetentionDays(), "rawEventRetentionDays", path);
        positif(config.purgeBatchSize(), "purgeBatchSize", path);
        if (!(config.civicSubmittedMinAnsweredRatio() > 0 && config.civicSubmittedMinAnsweredRatio() <= 1)) {
            throw new IllegalStateException("civicSubmittedMinAnsweredRatio doit etre dans ]0, 1] dans " + path);
        }
        verifierIngestion(config.ingestion(), path);
        verifierFenetres(config.diagnosticRunRateLimit(), "diagnosticRunRateLimit", path);
        verifierGroupes(config, path);
        verifierDebutsDeMesure(config.measurementStart(), path);
        log.info("Configuration d'analytics chargee (v{}) : retention {} j, cohorte {} j, lot max {}",
                config.analyticsConfigVersion(), config.rawEventRetentionDays(),
                config.cohortWindowDays(), config.ingestion().maxBatchSize());
        return config;
    }

    private static void verifierIngestion(AnalyticsConfig.Ingestion ingestion, String path) {
        if (ingestion == null || ingestion.rateLimit() == null) {
            throw new IllegalStateException("Section ingestion / ingestion.rateLimit absente de " + path);
        }
        positif(ingestion.maxBatchSize(), "ingestion.maxBatchSize", path);
        positif(ingestion.clockSkewToleranceMinutes(), "ingestion.clockSkewToleranceMinutes", path);
        positif(ingestion.maxEventAgeHours(), "ingestion.maxEventAgeHours", path);
        verifierFenetres(ingestion.rateLimit(), "ingestion.rateLimit", path);
    }

    private static void verifierFenetres(AnalyticsConfig.RateLimit rl, String section, String path) {
        if (rl == null) {
            throw new IllegalStateException("Section " + section + " absente de " + path);
        }
        fenetre(rl.perIpBurst(), section + ".perIpBurst", path);
        fenetre(rl.perIpDaily(), section + ".perIpDaily", path);
        fenetre(rl.perAnonymousIdBurst(), section + ".perAnonymousIdBurst", path);
        fenetre(rl.perAnonymousIdDaily(), section + ".perAnonymousIdDaily", path);
    }

    private static void verifierGroupes(AnalyticsConfig config, String path) {
        Map<String, List<String>> groupes = config.utmSourceGroups();
        if (groupes == null || groupes.isEmpty()) {
            throw new IllegalStateException("utmSourceGroups absent ou vide dans " + path);
        }
        String repli = config.utmSourceFallbackGroup();
        if (repli == null || !SLUG.matcher(repli).matches() || groupes.containsKey(repli)) {
            throw new IllegalStateException("utmSourceFallbackGroup invalide (slug requis, distinct des groupes) dans "
                    + path);
        }
        Set<String> vues = new HashSet<>();
        for (Map.Entry<String, List<String>> groupe : groupes.entrySet()) {
            if (!SLUG.matcher(groupe.getKey()).matches()) {
                throw new IllegalStateException("Nom de groupe invalide « " + groupe.getKey() + " » dans " + path);
            }
            if (groupe.getValue() == null || groupe.getValue().isEmpty()) {
                throw new IllegalStateException("Groupe « " + groupe.getKey() + " » sans source dans " + path);
            }
            for (String source : groupe.getValue()) {
                if (source == null || !SLUG.matcher(source).matches()) {
                    throw new IllegalStateException("Source invalide « " + source + " » (minuscules, slug) dans "
                            + path);
                }
                if (!vues.add(source)) {
                    throw new IllegalStateException("La source « " + source
                            + " » est rangee dans deux groupes dans " + path);
                }
            }
        }
    }

    private static void verifierDebutsDeMesure(Map<SuiviIndicator, String> debuts, String path) {
        if (debuts == null) {
            throw new IllegalStateException("measurementStart absent de " + path);
        }
        Set<SuiviIndicator> manquants = EnumSet.allOf(SuiviIndicator.class);
        manquants.removeAll(debuts.keySet());
        if (!manquants.isEmpty()) {
            throw new IllegalStateException("measurementStart n'a pas d'entree pour " + manquants
                    + " dans " + path + " (null = pas encore mesure, mais la cle est obligatoire)");
        }
        for (Map.Entry<SuiviIndicator, String> debut : debuts.entrySet()) {
            if (debut.getValue() == null) continue;
            try {
                LocalDate.parse(debut.getValue());
            } catch (DateTimeParseException e) {
                throw new IllegalStateException("measurementStart." + debut.getKey()
                        + " n'est pas une date ISO (aaaa-mm-jj) dans " + path, e);
            }
        }
    }

    private static void fenetre(AnalyticsConfig.Window w, String cle, String path) {
        if (w == null || w.max() <= 0 || w.windowSeconds() <= 0) {
            throw new IllegalStateException(cle + " absent ou non positif dans " + path);
        }
    }

    private static void positif(int valeur, String cle, String path) {
        if (valeur <= 0) {
            throw new IllegalStateException(cle + " doit etre > 0 dans " + path);
        }
    }
}

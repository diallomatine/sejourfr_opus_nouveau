package com.sejourfr.app.service.journey;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sejourfr.app.enums.JourneyLotSelectionStrategy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;

import java.io.IOException;
import java.io.InputStream;

/**
 * Charge et <b>verifie</b> {@code plan/tcf-journey-config-vN.json} au demarrage
 * — meme doctrine que {@code PlanConfigLoader} et {@code ProgressionConfigLoader},
 * et pour la meme raison : une configuration incomplete qui demarrerait quand
 * meme viderait des files sans que rien n'echoue.
 *
 * <p>Cinq refus volontaires : une cle inconnue, une section absente, une valeur
 * nulle sur un primitif, un plafond negatif ou nul, et un
 * {@code journeyConfigVersion} different de celui demande.
 *
 * <p>Le chargeur <b>ne corrige rien</b> et n'ecrit jamais dans le fichier.
 */
@Slf4j
public final class TcfJourneyConfigLoader {

    private static final ObjectMapper MAPPER = new ObjectMapper()
            .enable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
            .enable(DeserializationFeature.FAIL_ON_NULL_FOR_PRIMITIVES);

    private TcfJourneyConfigLoader() {
    }

    /** Charge la version demandee depuis le classpath, ou echoue. */
    public static TcfJourneyConfig load(int configVersion) {
        String path = "plan/tcf-journey-config-v" + configVersion + ".json";
        TcfJourneyConfig config;
        try (InputStream in = new ClassPathResource(path).getInputStream()) {
            config = MAPPER.readValue(in, TcfJourneyConfig.class);
        } catch (IOException e) {
            throw new IllegalStateException("Configuration du parcours TCF illisible : " + path, e);
        }
        if (config.journeyConfigVersion() != configVersion) {
            throw new IllegalStateException(
                    "journeyConfigVersion=" + config.journeyConfigVersion() + " dans " + path
                            + " alors que la version demandee est " + configVersion);
        }
        if (config.display() == null) {
            throw new IllegalStateException("Section display absente de " + path);
        }
        // 🛑 Une strategie non supportee fait echouer le DEMARRAGE, jamais un
        // repli muet : servir TOP_SEVERITY a la place d'une rotation que
        // quelqu'un a cru activer serait pire qu'un boot rouge.
        if (config.lotSelectionStrategy() != JourneyLotSelectionStrategy.TOP_SEVERITY) {
            throw new IllegalStateException(
                    "lotSelectionStrategy=" + config.lotSelectionStrategy() + " dans " + path
                            + " : seule TOP_SEVERITY est supportee en V1");
        }
        positif(config.maxPrioritiesPerLot(), "maxPrioritiesPerLot", path);
        positif(config.trainSeriesQuota(), "trainSeriesQuota", path);
        positif(config.display().upcomingVisible(), "display.upcomingVisible", path);
        if (config.display().recentCompletedVisible() < 0) {
            throw new IllegalStateException(
                    "display.recentCompletedVisible negatif dans " + path);
        }
        log.info("Configuration du parcours TCF chargee (v{}) : {} priorites par lot, "
                        + "{} serie(s) de comprehension, timeline {} close(s) / {} a venir",
                config.journeyConfigVersion(), config.maxPrioritiesPerLot(),
                config.trainSeriesQuota(), config.display().recentCompletedVisible(),
                config.display().upcomingVisible());
        return config;
    }

    private static void positif(int valeur, String cle, String path) {
        if (valeur <= 0) {
            throw new IllegalStateException(cle + " doit etre > 0 dans " + path);
        }
    }
}

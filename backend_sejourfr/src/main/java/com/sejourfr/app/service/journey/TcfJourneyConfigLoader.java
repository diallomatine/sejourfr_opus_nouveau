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
 * <p>Six refus volontaires : une cle inconnue, une section absente, une valeur
 * nulle sur un primitif, un plafond negatif ou nul, une echappatoire de quota
 * <b>inferieure</b> au quota de reussite (D-16), et un
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
        positif(config.trainSeriesFallbackQuota(), "trainSeriesFallbackQuota", path);
        // 🛑 L'echappatoire de D-16 est un FILET, pas la regle : sous le quota de
        // reussite, elle closerait toujours la premiere et « 2 series reussies »
        // ne voudrait plus rien dire. Un boot rouge plutot qu'une regle
        // silencieusement inversee.
        if (config.trainSeriesFallbackQuota() < config.trainSeriesQuota()) {
            throw new IllegalStateException(
                    "trainSeriesFallbackQuota=" + config.trainSeriesFallbackQuota()
                            + " est inferieur a trainSeriesQuota=" + config.trainSeriesQuota()
                            + " dans " + path
                            + " : l'echappatoire ne peut pas preceder le quota de reussite");
        }
        // ⚠️ `display` N'A PLUS DE LECTEUR depuis P6 (cf. TcfJourneyConfig.Display),
        // mais les deux fichiers publies le declarent et le loader refuse une
        // cle inconnue : il reste donc valide comme le reste du fichier. Valider
        // ce qu'on ne lit pas coute une comparaison ; ne plus le valider
        // laisserait passer un fichier que la version suivante pourrait relire.
        positif(config.display().upcomingVisible(), "display.upcomingVisible", path);
        if (config.display().recentCompletedVisible() < 0) {
            throw new IllegalStateException(
                    "display.recentCompletedVisible negatif dans " + path);
        }
        log.info("Configuration du parcours TCF chargee (v{}) : {} priorites par lot, "
                        + "{} serie(s) reussie(s) ou {} terminee(s) en comprehension",
                config.journeyConfigVersion(), config.maxPrioritiesPerLot(),
                config.trainSeriesQuota(), config.trainSeriesFallbackQuota());
        return config;
    }

    private static void positif(int valeur, String cle, String path) {
        if (valeur <= 0) {
            throw new IllegalStateException(cle + " doit etre > 0 dans " + path);
        }
    }
}

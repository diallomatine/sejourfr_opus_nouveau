package com.sejourfr.app.service.plan;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanActionNature;
import com.sejourfr.app.enums.PlanDomainPriority;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;

import java.io.IOException;
import java.io.InputStream;
import java.util.EnumSet;
import java.util.Map;

/**
 * Charge et <b>verifie</b> {@code plan-config-vN.json} au demarrage — meme
 * doctrine que {@code ProgressionConfigLoader}, et pour la meme raison : une
 * configuration incomplete qui demarrerait quand meme viderait des ecrans sans
 * que rien n'echoue.
 *
 * <p>Quatre refus volontaires : une cle inconnue, une entree manquante dans une
 * table indexee par enum, un plafond negatif ou nul, et un
 * {@code planConfigVersion} different de celui demande.
 *
 * <p>Le chargeur <b>ne corrige rien</b> et n'ecrit jamais dans le fichier.
 */
@Slf4j
public final class PlanConfigLoader {

    private static final ObjectMapper MAPPER = new ObjectMapper()
            .enable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
            .enable(DeserializationFeature.FAIL_ON_NULL_FOR_PRIMITIVES);

    private PlanConfigLoader() {
    }

    /** Charge la version demandee depuis le classpath, ou echoue. */
    public static PlanConfig load(int configVersion) {
        String path = "plan/plan-config-v" + configVersion + ".json";
        PlanConfig config;
        try (InputStream in = new ClassPathResource(path).getInputStream()) {
            config = MAPPER.readValue(in, PlanConfig.class);
        } catch (IOException e) {
            throw new IllegalStateException("Configuration du Plan illisible : " + path, e);
        }
        if (config.planConfigVersion() != configVersion) {
            throw new IllegalStateException(
                    "planConfigVersion=" + config.planConfigVersion() + " dans " + path
                            + " alors que la version demandee est " + configVersion);
        }
        if (config.display() == null || config.ranking() == null) {
            throw new IllegalStateException("Sections display/ranking absentes de " + path);
        }
        positif(config.display().todayMaxActions(), "display.todayMaxActions", path);
        positif(config.display().prioritiesMaxActions(), "display.prioritiesMaxActions", path);
        if (config.display().todayMaxSecondaryDomainActions() < 0) {
            throw new IllegalStateException(
                    "display.todayMaxSecondaryDomainActions negatif dans " + path);
        }
        exhaustif(config.ranking().natureWeights(), PlanActionNature.class,
                "ranking.natureWeights", path);
        exhaustif(config.ranking().domainPriorityWeights(), PlanDomainPriority.class,
                "ranking.domainPriorityWeights", path);
        exhaustif(config.ranking().confidenceWeights(), ObservationConfidence.class,
                "ranking.confidenceWeights", path);
        log.info("Configuration du Plan chargee (v{}) : seance {} dont {} secondaire(s), "
                        + "priorites {}", config.planConfigVersion(),
                config.display().todayMaxActions(),
                config.display().todayMaxSecondaryDomainActions(),
                config.display().prioritiesMaxActions());
        return config;
    }

    private static void positif(int valeur, String cle, String path) {
        if (valeur <= 0) {
            throw new IllegalStateException(cle + " doit etre > 0 dans " + path);
        }
    }

    private static <E extends Enum<E>> void exhaustif(
            Map<E, Integer> table, Class<E> type, String cle, String path) {
        if (table == null) {
            throw new IllegalStateException(cle + " absente de " + path);
        }
        for (E valeur : EnumSet.allOf(type)) {
            if (!table.containsKey(valeur)) {
                throw new IllegalStateException(
                        cle + " n'a pas d'entree pour " + valeur + " dans " + path);
            }
        }
    }
}

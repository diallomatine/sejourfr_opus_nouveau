package com.sejourfr.app.progression.config;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;

import java.io.IOException;
import java.io.InputStream;
import java.time.Duration;
import java.time.Instant;
import java.util.EnumSet;
import java.util.Map;

import com.sejourfr.app.progression.domain.AssistanceLevel;
import com.sejourfr.app.progression.domain.EvidenceSourceType;
import com.sejourfr.app.progression.domain.IndependenceClass;
import com.sejourfr.app.progression.domain.ProgressionStateType;

/**
 * Charge et <b>verifie</b> {@code progression-config-vN.json} au demarrage.
 *
 * <p>Trois refus volontaires, tous pour la meme raison — une config incomplete
 * qui demarre quand meme produit des etats faux qu'on ne detecte que des mois
 * plus tard, sur des donnees deja materialisees :
 *
 * <ul>
 *   <li>une cle inconnue fait echouer la lecture (le JSON n'est pas
 *       « tolerant ») ;</li>
 *   <li>une entree manquante dans une table indexee par enum fait echouer le
 *       demarrage, plutot que de renvoyer {@code null} au premier calcul ;</li>
 *   <li>un {@code engineVersion} du fichier different de celui demande fait
 *       echouer le demarrage — c'est la garantie qu'une version active
 *       correspond bien au fichier qu'on croit avoir charge (§29).</li>
 * </ul>
 *
 * <p>Le chargeur <b>ne corrige rien</b> et n'ecrit jamais dans le fichier
 * (invariant I33).
 */
@Slf4j
public final class ProgressionConfigLoader {

    private static final ObjectMapper MAPPER = new ObjectMapper()
            .enable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
            .enable(DeserializationFeature.FAIL_ON_NULL_FOR_PRIMITIVES);

    private ProgressionConfigLoader() {
    }

    /** Charge la version demandee depuis le classpath, ou echoue. */
    public static ProgressionConfig load(int engineVersion) {
        String path = "progression/progression-config-v" + engineVersion + ".json";
        ProgressionConfig config;
        try (InputStream in = new ClassPathResource(path).getInputStream()) {
            config = MAPPER.readValue(in, ProgressionConfig.class);
        } catch (IOException e) {
            throw new IllegalStateException(
                    "Configuration de progression illisible : " + path, e);
        }
        validate(config, engineVersion, path);
        log.info("Progression : configuration v{} chargee ({}), epoch {}, demi-vie {} j",
                config.engineVersion(), path, config.weightEpoch(),
                config.recencyHalfLifeDays());
        return config;
    }

    /**
     * Les verifications structurelles que le typage ne peut pas porter.
     *
     * <p>Aucune n'est une regle metier : on ne verifie pas qu'un seuil « a l'air
     * raisonnable », on verifie qu'il <b>existe</b> et que le fichier est
     * coherent avec lui-meme.
     */
    static void validate(ProgressionConfig config, int expectedVersion, String path) {
        if (config.engineVersion() != expectedVersion) {
            throw new IllegalStateException(
                    "%s declare engineVersion=%d alors que la version demandee est %d"
                            .formatted(path, config.engineVersion(), expectedVersion));
        }
        requireComplete(config.sourceWeights(), EvidenceSourceType.class, "sourceWeights");
        requireComplete(config.visibleProgress().practicePoints(),
                EvidenceSourceType.class, "visibleProgress.practicePoints");
        requireComplete(config.assistanceFactors(), AssistanceLevel.class, "assistanceFactors");
        requireComplete(config.independenceFactors(),
                IndependenceClass.class, "independenceFactors");
        requireComplete(config.confidenceK(), ProgressionStateType.class, "confidenceK");
        requireComplete(config.strongEvidence(), ProgressionStateType.class, "strongEvidence");

        if (config.recencyHalfLifeDays() <= 0) {
            throw new IllegalStateException(path + " : recencyHalfLifeDays doit etre > 0");
        }
        ProgressionConfig.ReceptiveSeriesBlueprint blueprint = config.receptiveSeriesBlueprint();
        int bands = blueprint.easy() + blueprint.medium() + blueprint.hard();
        if (bands != blueprint.questionCount()) {
            throw new IllegalStateException(
                    "%s : blueprint %d/%d/%d ne totalise pas %d questions"
                            .formatted(path, blueprint.easy(), blueprint.medium(),
                                    blueprint.hard(), blueprint.questionCount()));
        }
        ProgressionConfig.VisibleProgress visible = config.visibleProgress();
        double weights = visible.coverageWeight() + visible.masteryWeight();
        if (Math.abs(weights - 1.0d) > 1e-9) {
            throw new IllegalStateException(
                    path + " : coverageWeight + masteryWeight doit valoir 1.0, vaut " + weights);
        }
    }

    /**
     * L'age de l'epoch, a confronter a {@code maintenance.maxEpochAgeDays}
     * (§27.2.2) : au-dela, un replay de re-basage est du, meme sans changement
     * de seuil, pour garder les accumulateurs dans une plage numerique
     * confortable.
     */
    public static Duration epochAge(ProgressionConfig config, Instant now) {
        return Duration.between(config.weightEpoch(), now);
    }

    private static <E extends Enum<E>, V> void requireComplete(
            Map<E, V> table, Class<E> type, String name) {
        if (table == null) {
            throw new IllegalStateException("Configuration de progression : " + name + " absent");
        }
        EnumSet<E> missing = EnumSet.allOf(type);
        missing.removeAll(table.keySet());
        if (!missing.isEmpty()) {
            throw new IllegalStateException(
                    "Configuration de progression : " + name + " incomplet, manque " + missing);
        }
    }
}

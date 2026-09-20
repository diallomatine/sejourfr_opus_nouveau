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
 * <p>Refus volontaires : une cle inconnue, une section absente, une valeur nulle
 * sur un primitif, un plafond negatif ou nul, une echappatoire de quota
 * <b>presente mais inferieure</b> au quota de reussite, un ratio de fin de cycle
 * <b>present mais hors de</b> {@code ]0 ; 1]}, et un {@code journeyConfigVersion}
 * different de celui demande.
 *
 * <h2>🛑 Deux cles OPTIONNELLES, et leur absence est une REGLE</h2>
 * <ul>
 *   <li>{@code trainSeriesFallbackQuota} absent ⇒ <b>aucune echappatoire</b> :
 *       seule la reussite clot une etape (v3, 2026-09-20) ;</li>
 *   <li>{@code finDeCycleExamenRatio} absent ⇒ <b>aucun deblocage anticipe</b> :
 *       l'examen de fin de cycle attend le cycle entier (regle d'avant v3).</li>
 * </ul>
 * <p>C'est ce qui rend v1 et v2 chargeables <b>a l'identique</b> sans les
 * reecrire. Le chargeur ne <b>corrige rien</b>, n'invente aucun defaut et
 * n'ecrit jamais dans le fichier.
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
        // 🛑 ABSENTE = « AUCUNE ECHAPPATOIRE », jamais « zero serie suffit ».
        // C'est une regle, pas un oubli : le proprietaire a supprime le filet le
        // 2026-09-20. Presente, elle reste un FILET -- donc jamais sous le quota
        // de reussite, sinon elle closerait toujours la premiere et « 2 series
        // reussies » ne voudrait plus rien dire.
        if (config.trainSeriesFallbackQuota() != null) {
            positif(config.trainSeriesFallbackQuota(), "trainSeriesFallbackQuota", path);
            if (config.trainSeriesFallbackQuota() < config.trainSeriesQuota()) {
                throw new IllegalStateException(
                        "trainSeriesFallbackQuota=" + config.trainSeriesFallbackQuota()
                                + " est inferieur a trainSeriesQuota=" + config.trainSeriesQuota()
                                + " dans " + path
                                + " : l'echappatoire ne peut pas preceder le quota de reussite");
            }
        }
        // 🛑 ABSENT = « LE CYCLE ENTIER » (la regle d'avant v3). Present, c'est
        // une PART : au-dela de 1 elle serait inatteignable, a 0 ou moins elle
        // ouvrirait l'examen de fin de cycle sur un cycle intact.
        if (config.finDeCycleExamenRatio() != null) {
            double ratio = config.finDeCycleExamenRatio();
            if (ratio <= 0 || ratio > 1) {
                throw new IllegalStateException(
                        "finDeCycleExamenRatio=" + ratio + " dans " + path
                                + " : une part se situe dans ]0 ; 1]");
            }
        }
        // ⚠️ `display` N'A PLUS DE LECTEUR depuis P6 (cf. TcfJourneyConfig.Display),
        // mais les fichiers publies le declarent et le loader refuse une cle
        // inconnue : il reste donc valide comme le reste du fichier. Valider ce
        // qu'on ne lit pas coute une comparaison ; ne plus le valider laisserait
        // passer un fichier que la version suivante pourrait relire.
        positif(config.display().upcomingVisible(), "display.upcomingVisible", path);
        if (config.display().recentCompletedVisible() < 0) {
            throw new IllegalStateException(
                    "display.recentCompletedVisible negatif dans " + path);
        }
        log.info("Configuration du parcours TCF chargee (v{}) : {} priorites par lot, "
                        + "{} serie(s) reussie(s) pour clore une etape, echappatoire={}, "
                        + "examen de fin de cycle a {}",
                config.journeyConfigVersion(), config.maxPrioritiesPerLot(),
                config.trainSeriesQuota(),
                config.trainSeriesFallbackQuota() == null
                        ? "aucune" : config.trainSeriesFallbackQuota() + " terminee(s)",
                config.finDeCycleExamenRatio() == null
                        ? "cycle entier" : (int) (config.finDeCycleExamenRatio() * 100) + " %");
        return config;
    }

    private static void positif(int valeur, String cle, String path) {
        if (valeur <= 0) {
            throw new IllegalStateException(cle + " doit etre > 0 dans " + path);
        }
    }
}

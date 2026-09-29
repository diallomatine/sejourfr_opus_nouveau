package com.sejourfr.app.calibration;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import tools.jackson.databind.ObjectMapper;

import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

/**
 * BANC DE MESURE de la notation IA — <b>opt-in strict</b>.
 *
 * <p>Il appelle un LLM payant et exige le reseau : il ne doit JAMAIS partir dans
 * un {@code ./mvnw verify}. Double garde : la condition JUnit sur la propriete
 * systeme {@code calibration.enabled} et un {@code assumeTrue} dans la methode.
 *
 * <pre>
 * # reference v3
 * ./mvnw -q test -Dtest=CalibrationBenchTest -DfailIfNoTests=false \
 *   -Dcalibration.enabled=true -Dcalibration.rubrics=v3 -Dcalibration.prompt=v1.5 -Dcalibration.label=v3
 * # v4
 * ./mvnw -q test -Dtest=CalibrationBenchTest -DfailIfNoTests=false \
 *   -Dcalibration.enabled=true -Dcalibration.rubrics=v4 -Dcalibration.prompt=v2 -Dcalibration.label=v4
 * # stabilite : 3 passes
 * ./mvnw -q test -Dtest=CalibrationBenchTest -DfailIfNoTests=false \
 *   -Dcalibration.enabled=true -Dcalibration.rubrics=v4 -Dcalibration.prompt=v2 \
 *   -Dcalibration.passes=3 -Dcalibration.label=v4-stabilite
 * </pre>
 *
 * <p>Proprietes reconnues : {@code calibration.rubrics}, {@code calibration.prompt},
 * {@code calibration.passes}, {@code calibration.parallelisme},
 * {@code calibration.limit}, {@code calibration.retries}, {@code calibration.label},
 * {@code calibration.env.file}, {@code calibration.temoin}.
 *
 * <p><b>{@code calibration.retries} est fige dans le rapport</b> et
 * {@code -Dcalibration.temoin=target/calibration/<temoin>.json} fait ECHOUER la
 * campagne si le temoin n'a pas tourne au meme nombre de reessais : c'est
 * exactement le defaut qui a fausse la comparaison v9-flash (9) / v9-pro (3) /
 * gpt-5.4 (1).
 */
@EnabledIfSystemProperty(named = "calibration.enabled", matches = "true")
class CalibrationBenchTest {

    private static String prop(String cle, String defaut) {
        String v = System.getProperty(cle);
        return v == null || v.isBlank() ? defaut : v.strip();
    }

    private static int propInt(String cle, int defaut) {
        String v = prop(cle, null);
        return v == null ? defaut : Integer.parseInt(v);
    }

    @Test
    void campagne() {
        assumeTrue("true".equals(System.getProperty("calibration.enabled")),
            "Banc de mesure desactive (passer -Dcalibration.enabled=true).");

        String rubrics = prop("calibration.rubrics", null);
        String promptVersion = prop("calibration.prompt", null);
        int passes = propInt("calibration.passes", 1);
        int parallelisme = propInt("calibration.parallelisme", 5);
        int limite = propInt("calibration.limit", 0);
        int retries = propInt("calibration.retries", 3);

        ObjectMapper objectMapper = new ObjectMapper();
        ProductionEvaluationProperties props = CalibrationEnv.properties(rubrics, promptVersion);
        CalibrationRunner runner = new CalibrationRunner(props, objectMapper, retries);

        List<GoldenSet.Cas> corpus = GoldenSet.load();
        if (limite > 0 && limite < corpus.size()) corpus = corpus.subList(0, limite);

        String label = prop("calibration.label",
            props.getRubricsVersion() + "-" + runner.promptVersion() + (passes > 1 ? "-x" + passes : ""));

        Map<String, Object> contexte = new LinkedHashMap<>();
        contexte.put("rubrics_version", props.getRubricsVersion());
        contexte.put("prompt_version", runner.promptVersion());
        contexte.put("provider", props.getProvider());
        contexte.put("modele", runner.modele());
        contexte.put("plafonds_actifs", props.getPlafonds().isEnabled());
        contexte.put("champs_requis", runner.champsRequis());
        contexte.put("corpus", GoldenSet.RESOURCE);
        contexte.put("cas", corpus.size());
        contexte.put("passes", passes);
        contexte.put("parallelisme", parallelisme);
        // FIGE DANS LE RAPPORT. Sans lui, deux campagnes se comparaient en
        // ignorant que l'une rejouait 9 fois et l'autre 1 : la colonne « cas
        // perdus » ne mesurait pas la meme chose, et un choix de modele a ete
        // fait dessus.
        contexte.put("retries", retries);

        // Garde-fou de comparabilite : -Dcalibration.temoin=<chemin du rapport>.
        String temoin = prop("calibration.temoin", null);
        if (temoin != null) {
            List<String> divergences = CalibrationReport.divergencesDeReglage(
                contexte, CalibrationReport.contexteDuRapport(Path.of(temoin)));
            System.out.println(CalibrationReport.bandeauComparabilite(divergences));
            assertThat(CalibrationReport.bloquant(divergences))
                .as("temoin %s non comparable : %s", temoin, divergences)
                .isFalse();
        }

        System.out.printf("%nCampagne '%s' : %d cas x %d passe(s), %d appels en vol, modele %s "
                + "(rubriques %s, prompt %s)%n",
            label, corpus.size(), passes, parallelisme, runner.modele(),
            props.getRubricsVersion(), runner.promptVersion());

        List<CaseRun> runs = runner.run(corpus, passes, parallelisme);
        Path fichier = CalibrationReport.ecrire(label, contexte, runs);
        CalibrationReport.console(label, contexte, runs, fichier);

        assertThat(runs).hasSize(corpus.size() * passes);
        assertThat(runs.stream().filter(CaseRun::exploitable).count())
            .as("aucun cas n'a pu etre mesure : campagne inexploitable")
            .isGreaterThan(0);
    }
}

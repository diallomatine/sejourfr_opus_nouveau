package com.sejourfr.app.calibration;

import com.sejourfr.app.config.CompetenceProperties;
import com.sejourfr.app.config.EvaluationConfigFixture;
import com.sejourfr.app.config.ProductionEvaluationProperties;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import tools.jackson.databind.ObjectMapper;

import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

/**
 * BANC DE MESURE du module « Competences TCF » — <b>opt-in strict</b>.
 *
 * <p>Jumeau de {@link CalibrationBenchTest}, sur un corpus different
 * ({@code golden-set-competences-v1.json}, 90 micro-productions annotees) et
 * deux grandeurs differentes : le <b>palier</b> ({@code level_reached}) et le
 * <b>verdict de critere</b> ({@code status}). <b>Aucune note sur 20</b> — le
 * module n'en produit pas.
 *
 * <p>Il appelle un LLM payant et exige le reseau : il ne doit JAMAIS partir dans
 * un {@code ./mvnw verify}. Double garde : la condition JUnit sur la propriete
 * systeme {@code calibration.enabled} et un {@code assumeTrue} dans la methode.
 *
 * <pre>
 * # pilote de 10 cas (2 par palier), VERSION ACTIVE du runtime
 * ./mvnw -q test -Dtest=CompetenceCalibrationBenchTest -DfailIfNoTests=false \
 *   -Dcalibration.enabled=true -Dcalibration.echantillon=paliers -Dcalibration.limit=10 \
 *   -Dcalibration.retries=1 -Dcalibration.label=competences-pilote
 * # campagne complete, version active
 * ./mvnw -q test -Dtest=CompetenceCalibrationBenchTest -DfailIfNoTests=false \
 *   -Dcalibration.enabled=true -Dcalibration.retries=1 -Dcalibration.label=competences-actif
 * # temoin sur une version anterieure : les DEUX versions se passent ensemble
 * ./mvnw -q test -Dtest=CompetenceCalibrationBenchTest -DfailIfNoTests=false \
 *   -Dcalibration.enabled=true -Dcalibration.rubrics=v5 -Dcalibration.schema=v4 \
 *   -Dcalibration.retries=1 -Dcalibration.label=competences-v5
 * # puis la campagne candidate, opposee a ce temoin
 * ./mvnw -q test -Dtest=CompetenceCalibrationBenchTest -DfailIfNoTests=false \
 *   -Dcalibration.enabled=true -Dcalibration.retries=1 \
 *   -Dcalibration.temoin=target/calibration/competences-v5.json \
 *   -Dcalibration.label=competences-actif
 * </pre>
 *
 * <p>Proprietes reconnues : {@code calibration.rubrics}, {@code calibration.schema},
 * {@code calibration.passes}, {@code calibration.parallelisme},
 * {@code calibration.limit}, {@code calibration.echantillon},
 * {@code calibration.temoins}, {@code calibration.retries},
 * {@code calibration.label}, {@code calibration.env.file},
 * {@code calibration.temoin}.
 *
 * <p><b>Le provider et le modele ne se surchargent pas</b> : ils viennent de la
 * meme configuration que le runtime ({@code sejourfr.production-evaluation}),
 * sinon on mesurerait un autre correcteur que celui qui note les candidats.
 *
 * <p><b>{@code calibration.retries} est fige dans le rapport</b> et
 * {@code -Dcalibration.temoin=<rapport.json>} fait ECHOUER la campagne si le
 * temoin n'a pas tourne au meme nombre de reessais.
 */
@EnabledIfSystemProperty(named = "calibration.enabled", matches = "true")
class CompetenceCalibrationBenchTest {

    /** Au-dela de 3 appels en vol, le fournisseur repond 429 et des cas se perdent. */
    private static final int PARALLELISME_MAX = 3;

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
        String schema = prop("calibration.schema", null);
        // Les consignes et le contrat de sortie vont PAR PAIRES, et la table des
        // paires est privee a CompetenceRubricsProvider : la recopier ici en
        // ferait une seconde source de verite, qui finirait par diverger. On
        // exige donc les deux ensemble plutot que d'en deviner une — meme
        // philosophie que le fail-fast au boot, jamais de repli muet.
        if ((rubrics == null) != (schema == null)) {
            throw new IllegalArgumentException(
                "calibration.rubrics et calibration.schema se passent ENSEMBLE (ex : -Dcalibration.rubrics=v5 "
                    + "-Dcalibration.schema=v4). Sans eux, la campagne mesure la version ACTIVE du runtime.");
        }
        int passes = propInt("calibration.passes", 1);
        int parallelisme = Math.min(propInt("calibration.parallelisme", 3), PARALLELISME_MAX);
        int limite = propInt("calibration.limit", 0);
        int retries = propInt("calibration.retries", 1);
        String echantillon = prop("calibration.echantillon", null);
        boolean avecTemoins = "true".equals(prop("calibration.temoins", "false"));

        ObjectMapper objectMapper = new ObjectMapper();
        CompetenceProperties props = CompetenceCalibrationEnv.competences(rubrics, schema);
        ProductionEvaluationProperties correcteur = CompetenceCalibrationEnv.correcteur();
        CompetenceCalibrationRunner runner =
            new CompetenceCalibrationRunner(correcteur, props, objectMapper, retries);

        List<CompetenceGoldenSet.Cas> corpus = echantillon(CompetenceGoldenSet.load(), echantillon);
        if (limite > 0 && limite < corpus.size()) corpus = corpus.subList(0, limite);
        int notes = corpus.size();
        if (avecTemoins) {
            corpus = new ArrayList<>(corpus);
            corpus.addAll(CompetenceGoldenSet.temoins());
        }

        String label = prop("calibration.label",
            "competences-" + runner.rubricsVersion() + "-" + runner.toolSchemaVersion()
                + (passes > 1 ? "-x" + passes : ""));

        Map<String, Object> contexte = new LinkedHashMap<>();
        contexte.put("module", "COMPETENCES_TCF");
        contexte.put("rubrics_version", runner.rubricsVersion());
        contexte.put("tool_schema_version", runner.toolSchemaVersion());
        contexte.put("preuve_du_niveau_exigee", runner.preuveExigee());
        contexte.put("provider", correcteur.getProvider());
        contexte.put("modele", runner.modele());
        // Les tarifs DATENT le chiffre de cout : le meme nombre de tokens ne
        // vaut pas le meme prix d'une grille a l'autre. Trois tarifs depuis le
        // 2026-08-16, l'entree servie par le cache de prefixe etant facturee a
        // part (31x moins cher chez DeepSeek).
        EvaluationConfigFixture.BlocProvider bloc = EvaluationConfigFixture.blocActif(correcteur);
        contexte.put("cout_entree_par_million_usd", bloc.coutEntree());
        contexte.put("cout_entree_cache_par_million_usd", bloc.coutEntreeCache());
        contexte.put("cout_sortie_par_million_usd", bloc.coutSortie());
        contexte.put("cles_attendues", runner.clesAttendues());
        contexte.put("corpus", CompetenceGoldenSet.RESOURCE);
        contexte.put("echantillon", echantillon == null ? "COMPLET" : echantillon);
        contexte.put("cas", notes);
        contexte.put("temoins_reels", corpus.size() - notes);
        contexte.put("passes", passes);
        contexte.put("parallelisme", parallelisme);
        // FIGE DANS LE RAPPORT. Sans lui, deux campagnes se comparent en
        // ignorant que l'une rejoue 9 fois et l'autre 1 : la colonne « cas
        // perdus » ne mesure alors pas la meme chose.
        contexte.put("retries", retries);

        String temoin = prop("calibration.temoin", null);
        if (temoin != null) {
            List<String> divergences = CompetenceCalibrationReport.divergencesDeReglage(
                contexte, CompetenceCalibrationReport.contexteDuRapport(Path.of(temoin)));
            System.out.println(CompetenceCalibrationReport.bandeauComparabilite(divergences));
            assertThat(CompetenceCalibrationReport.bloquant(divergences))
                .as("temoin %s non comparable : %s", temoin, divergences)
                .isFalse();
        }

        System.out.printf("%nCampagne '%s' : %d cas notes (+%d temoins) x %d passe(s), %d appels en vol, "
                + "modele %s (consignes %s, contrat %s)%n",
            label, notes, corpus.size() - notes, passes, parallelisme, runner.modele(),
            runner.rubricsVersion(), runner.toolSchemaVersion());

        List<CompetenceCaseRun> runs = runner.run(corpus, passes, parallelisme);
        Path fichier = CompetenceCalibrationReport.ecrire(label, contexte, runs);
        CompetenceCalibrationReport.console(label, contexte, runs, fichier);

        assertThat(runs).hasSize(corpus.size() * passes);
        assertThat(runs.stream().filter(CompetenceCaseRun::exploitable).count())
            .as("aucun cas n'a pu etre mesure : campagne inexploitable")
            .isGreaterThan(0);
    }

    /**
     * Sous-ensembles utiles quand on ne veut pas payer les 90 cas.
     *
     * <ul>
     *   <li>{@code paliers} : deux cas par palier, dans l'ordre des paliers. Un
     *       PILOTE doit couvrir toute l'echelle, sinon il ne prouve rien du
     *       point noir mesure (aucun B2 rendu) ;</li>
     *   <li>{@code echelles} : les 6 series du meme sujet a paliers croissants,
     *       c'est-a-dire le materiau de la mesure de sensibilite ;</li>
     *   <li>{@code pieges} : les seuls cas pieges.</li>
     * </ul>
     */
    private static List<CompetenceGoldenSet.Cas> echantillon(List<CompetenceGoldenSet.Cas> corpus,
                                                             String nom) {
        if (nom == null) return corpus;
        return switch (nom) {
            case "paliers" -> parPalier(corpus, 2);
            case "echelles" -> corpus.stream().filter(c -> c.echelle() != null && !c.echelle().isBlank()).toList();
            case "pieges" -> corpus.stream().filter(c -> !c.attendu().pieges().isEmpty()).toList();
            default -> throw new IllegalArgumentException(
                "calibration.echantillon inconnu : '" + nom + "' (paliers|echelles|pieges)");
        };
    }

    /**
     * {@code parNiveau} cas par palier, pris dans des TACHES DIFFERENTES.
     *
     * <p>Prendre simplement les premiers du corpus concentrerait tout
     * l'echantillon sur EE1 (le corpus est ordonne par tache) : un pilote dirait
     * alors quelque chose du message court et rien des cinq autres taches.
     */
    private static List<CompetenceGoldenSet.Cas> parPalier(List<CompetenceGoldenSet.Cas> corpus, int parNiveau) {
        List<CompetenceGoldenSet.Cas> out = new ArrayList<>();
        for (String niveau : CompetenceCalibrationMetrics.NIVEAUX) {
            List<CompetenceGoldenSet.Cas> duPalier = corpus.stream()
                .filter(c -> c.attendu().niveau().name().equals(niveau))
                .toList();
            List<String> tachesPrises = new ArrayList<>();
            for (CompetenceGoldenSet.Cas cas : duPalier) {
                if (tachesPrises.size() >= parNiveau) break;
                if (tachesPrises.contains(cas.groupe())) continue;
                tachesPrises.add(cas.groupe());
                out.add(cas);
            }
        }
        return List.copyOf(out);
    }
}

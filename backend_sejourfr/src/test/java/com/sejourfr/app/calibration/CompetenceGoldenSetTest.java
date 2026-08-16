package com.sejourfr.app.calibration;

import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SkillTaskCode;
import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Contrat du corpus de reference du module « Competences ». Ne declenche AUCUN
 * appel LLM : c'est un test de coherence du fichier, il tourne dans
 * {@code ./mvnw verify}.
 *
 * <p>Ce qu'il protege : la <b>couverture</b> (6 taches x 5 paliers, 3 cas
 * chacune) et la <b>separation stricte</b> entre les cas annotes et les
 * productions reelles servies en temoin. Une campagne future ne doit pas pouvoir
 * ameliorer ses chiffres en retirant des cas difficiles, en elargissant une
 * tolerance jusqu'a tout accepter, ou en laissant des lignes sans verite terrain
 * peser sur un taux d'accord.
 */
class CompetenceGoldenSetTest {

    private static final int CAS_PAR_COMBINAISON = 3;

    @Test
    void le_corpus_couvre_les_six_taches_et_les_cinq_paliers() {
        List<CompetenceGoldenSet.Cas> corpus = CompetenceGoldenSet.load();

        assertThat(corpus).hasSize(90);
        assertThat(corpus).extracting(CompetenceGoldenSet.Cas::taskCode).containsOnly(
            SkillTaskCode.EE1, SkillTaskCode.EE2, SkillTaskCode.EE3,
            SkillTaskCode.EO1, SkillTaskCode.EO2, SkillTaskCode.EO3);

        Map<String, Integer> combinaisons = new LinkedHashMap<>();
        for (CompetenceGoldenSet.Cas cas : corpus) {
            combinaisons.merge(cas.taskCode() + "/" + cas.attendu().niveau(), 1, Integer::sum);
        }
        for (SkillTaskCode tache : SkillTaskCode.values()) {
            for (NiveauCecrl niveau : List.of(NiveauCecrl.A1_NON_ATTEINT, NiveauCecrl.A1,
                NiveauCecrl.A2, NiveauCecrl.B1, NiveauCecrl.B2)) {
                assertThat(combinaisons.get(tache + "/" + niveau))
                    .as("cas pour %s au palier %s", tache, niveau)
                    .isEqualTo(CAS_PAR_COMBINAISON);
            }
        }
    }

    /**
     * Le TCF IRN plafonne au B2 : ni C1 ni C2 ne doivent apparaitre, ni dans le
     * palier attendu, ni dans une tolerance. Le tool-schema les exclut deja, mais
     * un corpus qui les contiendrait rendrait le banc incapable de mesurer quoi
     * que ce soit.
     */
    @Test
    void aucun_cas_ne_sort_du_profil_tcf_irn() {
        for (CompetenceGoldenSet.Cas cas : CompetenceGoldenSet.load()) {
            assertThat(CompetenceCalibrationMetrics.NIVEAUX)
                .as("%s : palier attendu dans le profil TCF IRN", cas.id())
                .contains(cas.attendu().niveau().name());
            assertThat(cas.attendu().tolerance())
                .as("%s : la tolerance contient le palier attendu", cas.id())
                .contains(cas.attendu().niveau());
            assertThat(cas.attendu().tolerance().size())
                .as("%s : une tolerance de 3 paliers accepterait presque tout", cas.id())
                .isLessThanOrEqualTo(2);
            assertThat(cas.attendu().statutTolerance())
                .as("%s : la tolerance de verdict contient le verdict attendu", cas.id())
                .contains(cas.attendu().statut());
        }
    }

    /**
     * ECHELLES : six series de cinq productions du MEME sujet, une par palier.
     * C'est le materiau de la mesure de sensibilite — la question du dossier,
     * puisque deux productions inegales avaient recu le meme A2 en base. Sans
     * elles, le banc ne peut plus repondre.
     */
    @Test
    void six_echelles_de_cinq_paliers_sur_un_meme_sujet() {
        Map<String, List<CompetenceGoldenSet.Cas>> echelles = new LinkedHashMap<>();
        for (CompetenceGoldenSet.Cas cas : CompetenceGoldenSet.load()) {
            if (cas.echelle() == null || cas.echelle().isBlank()) continue;
            echelles.computeIfAbsent(cas.echelle(), k -> new java.util.ArrayList<>()).add(cas);
        }

        assertThat(echelles).hasSize(6);
        echelles.forEach((sujet, cas) -> {
            assertThat(cas).as("echelle %s", sujet).hasSize(5);
            assertThat(cas).as("echelle %s : un cas par palier", sujet)
                .extracting(c -> c.attendu().niveau().name())
                .containsExactlyInAnyOrderElementsOf(CompetenceCalibrationMetrics.NIVEAUX);
            assertThat(cas).as("echelle %s : le sujet est identique", sujet)
                .extracting(CompetenceGoldenSet.Cas::promptCode).containsOnly(sujet);
        });
    }

    /**
     * Les pieges qui doivent rester dans le corpus, et pourquoi.
     *
     * <p>{@code HORS_SUJET_RICHE} est le plus important : langue manifestement
     * B2, critere non atteint. C'est le seul cas qui prouve que le verdict de
     * critere et le palier sont bien INDEPENDANTS — un correcteur qui aligne
     * l'un sur l'autre y echoue.
     */
    @Test
    void les_pieges_structurants_sont_presents() {
        List<CompetenceGoldenSet.Cas> corpus = CompetenceGoldenSet.load();
        List<String> pieges = corpus.stream().flatMap(c -> c.attendu().pieges().stream()).toList();

        assertThat(pieges).contains("AUTRE_LANGUE", "LANGUE_MELANGEE", "HORS_SUJET_RICHE",
            "BREVETE_SUFFISANTE", "TRANSCRIPTION_DEGRADEE", "B2_EN_DEUX_PHRASES",
            "RECOPIE_CONSIGNE", "SAISIE_VIDE", "TRANSCRIPTION_VIDE", "LONGUEUR_TROMPEUSE");

        assertThat(corpus.stream()
            .filter(c -> c.attendu().pieges().contains("HORS_SUJET_RICHE"))
            .toList())
            .as("une langue B2 dont le critere n'est PAS atteint : le test d'independance")
            .isNotEmpty()
            .allSatisfy(c -> {
                assertThat(c.attendu().niveau()).isEqualTo(NiveauCecrl.B2);
                assertThat(c.attendu().statut().name()).isEqualTo("NOT_VALIDATED");
            });
    }

    /**
     * Les productions REELLES ne sont jamais melangees aux cas annotes : elles
     * vivent dans un tableau separe, portent {@code horsScore} et n'ont aucune
     * verite terrain. C'est ce qui les empeche de peser sur un taux d'accord.
     */
    @Test
    void les_temoins_reels_sont_hors_score_et_sans_verite_terrain() {
        assertThat(CompetenceGoldenSet.load()).allSatisfy(cas -> {
            assertThat(cas.horsScore()).as("%s n'est pas un temoin", cas.id()).isFalse();
            assertThat(cas.attendu()).as("%s porte une reference", cas.id()).isNotNull();
        });

        List<CompetenceGoldenSet.Cas> temoins = CompetenceGoldenSet.temoins();
        assertThat(temoins).isNotEmpty();
        assertThat(temoins).allSatisfy(cas -> {
            assertThat(cas.horsScore()).as("%s est hors score", cas.id()).isTrue();
            assertThat(cas.attendu()).as("%s n'a aucune reference", cas.id()).isNull();
            assertThat(cas.production()).as("%s porte une production", cas.id()).isNotBlank();
        });
    }

    /**
     * Un cas hors score ne peut jamais devenir exploitable, donc jamais entrer
     * dans un agregat — quel que soit ce que le correcteur repond. Le garde-fou
     * est verifie ici, pas seulement decrit en commentaire.
     */
    @Test
    void un_run_hors_score_n_est_jamais_exploitable() {
        CompetenceCaseRun temoin = new CompetenceCaseRun(
            "REEL_EE1_01", "EE1", "EE1-C1-S1", null, 1, true, "OK", null,
            null, List.of(), "B2", null, List.of(), "VALIDATED", "verdict", false, false,
            Map.of(), List.of(), List.of(), 1, 0, 1, 0, List.of(), "modele", 100, 50, 1, 10L);

        assertThat(temoin.exploitable()).isFalse();
        assertThat(temoin.accordExactNiveau()).isFalse();
        assertThat(CompetenceCalibrationMetrics.agregat("GLOBAL", List.of(temoin)).exploitables())
            .isZero();
        assertThat(CompetenceCalibrationMetrics.conformite(List.of(temoin)).total()).isZero();
    }

    /**
     * La sensibilite ne se lit pas sur le taux d'accord : un correcteur qui
     * rendrait le meme palier partout peut afficher un accord honorable sur le
     * palier majoritaire tout en ne distinguant rien. Ce test fige la definition
     * des trois issues.
     */
    @Test
    void la_sensibilite_distingue_ordonnee_inversee_et_confondue() {
        List<CompetenceCaseRun> runs = List.of(
            run("A", "EE1-C3-S1", "A2", "A2"),
            run("B", "EE1-C3-S1", "B2", "B2"),
            run("C", "EE1-C3-S1", "B1", "A2"),
            run("D", "EE1-C3-S1", "A1", "B1"));

        CompetenceCalibrationMetrics.Sensibilite s =
            CompetenceCalibrationMetrics.sensibiliteParEchelle(runs);

        assertThat(s.paires()).as("4 cas de paliers distincts = 6 paires").isEqualTo(6);
        assertThat(s.confondues()).as("A/C rendent tous deux A2").isEqualTo(1);
        assertThat(s.inversees()).as("A/D et C/D sont classes a l'envers").isEqualTo(2);
        assertThat(s.ordonnees()).isEqualTo(3);
    }

    private static CompetenceCaseRun run(String id, String echelle, String attendu, String obtenu) {
        return new CompetenceCaseRun(id, "EE1", echelle, echelle, 1, false, "OK", null,
            attendu, List.of(attendu), obtenu, "VALIDATED", List.of("VALIDATED"), "VALIDATED",
            "verdict", false, false, Map.of(), List.of(), List.of(),
            1, 0, 1, 0, List.of(), "modele", 100, 50, 1, 10L);
    }
}

package com.sejourfr.app.service.adminproduction;

import com.sejourfr.app.dto.AdminProductionDetailDto.Calcul;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.AdminCalculStatut;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ProductionEvaluabilite;
import com.sejourfr.app.service.ProductionRubricsFixture;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Field;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Bloc « Calcul SejourFR » (F-5 A) : relu avec la grille de l'évaluation, par
 * les fonctions qui notent, sans rien inventer quand la règle n'est pas
 * traçable. Grille active : v15 (celle de la production).
 */
class AdminProductionCalculServiceTest {

    private final AdminProductionCalculService service =
            new AdminProductionCalculService(ProductionRubricsFixture.charge("v15"));

    private static ProductionTask task(EpreuveType epreuve, int tache) {
        ProductionTask t = new ProductionTask();
        t.setEpreuve(epreuve);
        t.setTacheNumero((short) tache);
        return t;
    }

    private static AiEvaluation eval(String rubrics, NiveauCecrl persiste, String note, Map<String, Number> notes) {
        AiEvaluation e = new AiEvaluation();
        e.setRubricsVersion(rubrics);
        e.setPromptVersion("v9");
        e.setNiveauCecrl(persiste);
        e.setNoteSur20(note == null ? null : new BigDecimal(note));
        List<Map<String, Object>> scores = new ArrayList<>();
        notes.forEach((code, n) -> {
            Map<String, Object> m = new HashMap<>();
            m.put("code", code);
            m.put("note_sur_20", n);
            scores.add(m);
        });
        Map<String, Object> feedback = new HashMap<>();
        feedback.put("scores_criteres", scores);
        e.setFeedbackJson(feedback);
        return e;
    }

    private static Map<String, Number> v5(Number communiquer, Number interagir, Number lexique, Number morpho) {
        Map<String, Number> m = new LinkedHashMap<>();
        m.put("communiquer", communiquer);
        m.put("interagir", interagir);
        m.put("lexique", lexique);
        m.put("morphosyntaxe", morpho);
        return m;
    }

    /** La trace EE de l'audit (§C.4) : 8 · 8 · 7 · 7 → 7,5 → B1. */
    @Test
    void trace_ee_v15_se_recalcule_jusqu_au_niveau_persiste() {
        AiEvaluation e = eval("v15", NiveauCecrl.B1, "7.5", v5(8, 8, 7, 7));

        AdminProductionCalculService.Explication x = service.expliquer(e, task(EpreuveType.TCF_EE, 2));
        Calcul c = x.calcul();

        assertThat(c.statut()).isEqualTo(AdminCalculStatut.CALCULE);
        assertThat(c.grilleActive()).isTrue();
        assertThat(c.noteRecalculee()).isEqualByComparingTo("7.5");
        assertThat(c.notePersistee()).isEqualByComparingTo("7.5");
        assertThat(c.criteresPorteursNiveau()).containsExactly("communiquer", "interagir", "lexique", "morphosyntaxe");
        assertThat(c.competence()).isEqualByComparingTo("7.5");
        assertThat(c.seuils().a2()).isEqualByComparingTo("2");
        assertThat(c.seuils().b1()).isEqualByComparingTo("6");
        assertThat(c.seuils().b2()).isEqualByComparingTo("10");
        assertThat(c.seuilsDeLaGrille()).isTrue();
        assertThat(c.niveauAvantPlafonds()).isEqualTo(NiveauCecrl.B1);
        assertThat(c.niveauRecalcule()).isEqualTo(NiveauCecrl.B1);
        assertThat(c.niveauPersiste()).isEqualTo(NiveauCecrl.B1);
        assertThat(c.coherent()).isTrue();
        assertThat(c.plafondsDeclenches()).isEmpty();
        // Couplage : plafond = moyenne(7, 7) + 1 = 8 ; la réalisation y est
        // EXACTEMENT, donc « possiblement ramenée » — sans l'affirmer.
        assertThat(c.couplage().actif()).isTrue();
        assertThat(c.couplage().ecartMax()).isEqualByComparingTo("1");
        assertThat(c.couplage().plafondRealisation()).isEqualByComparingTo("8");
        assertThat(c.couplage().criteresAuPlafond()).containsExactly("communiquer", "interagir");
        assertThat(x.poidsParCode()).containsOnlyKeys("communiquer", "interagir", "lexique", "morphosyntaxe");
        assertThat(x.poidsParCode().values()).allSatisfy(p -> assertThat(p).isEqualByComparingTo("0.25"));
        assertThat(c.regleNiveau()).contains("≥ 10 : B2").contains("≥ 6 : B1").contains("≥ 2 : A2");
    }

    @Test
    void un_niveau_persiste_different_du_calcul_relu_est_signale_jamais_corrige() {
        AiEvaluation e = eval("v15", NiveauCecrl.B2, "7.5", v5(8, 8, 7, 7));

        Calcul c = service.expliquer(e, task(EpreuveType.TCF_EE, 2)).calcul();

        assertThat(c.niveauRecalcule()).isEqualTo(NiveauCecrl.B1);
        assertThat(c.niveauPersiste()).isEqualTo(NiveauCecrl.B2);
        assertThat(c.coherent()).isFalse();
        assertThat(e.getNiveauCecrl()).isEqualTo(NiveauCecrl.B2);
    }

    /** T3 sans prise de position (communiquer ≤ 1) : le plafond A2 de la notation s'applique. */
    @Test
    void plafond_de_niveau_relu_par_la_regle_de_la_notation() {
        AiEvaluation e = eval("v15", NiveauCecrl.A2, "7.0", v5(1, 9, 9, 9));
        e.getFeedbackJson().put("plafond_niveau", "A2");

        Calcul c = service.expliquer(e, task(EpreuveType.TCF_EE, 3)).calcul();

        assertThat(c.niveauAvantPlafonds()).isEqualTo(NiveauCecrl.B1);
        assertThat(c.plafondsDeclenches()).singleElement()
                .satisfies(p -> {
                    assertThat(p.regle()).isEqualTo("PRISE_POSITION_T3");
                    assertThat(p.niveauMax()).isEqualTo(NiveauCecrl.A2);
                });
        assertThat(c.plafondPersiste()).isEqualTo(NiveauCecrl.A2);
        assertThat(c.niveauRecalcule()).isEqualTo(NiveauCecrl.A2);
        assertThat(c.coherent()).isTrue();
    }

    /** Une évaluation notée avec une ANCIENNE grille se relit avec ELLE, pas avec la grille active. */
    @Test
    void grille_historique_v3_relue_avec_ses_poids() {
        Map<String, Number> notes = new LinkedHashMap<>();
        notes.put("pertinence", 12);
        notes.put("lexique", 12);
        notes.put("morphosyntaxe", 12);
        notes.put("coherence", 12);
        AiEvaluation e = eval("v3", NiveauCecrl.B1, "12.0", notes);

        AdminProductionCalculService.Explication x = service.expliquer(e, task(EpreuveType.TCF_EE, 1));

        // Seuils, couplage et plafonds de v3 viennent de la configuration ACTUELLE :
        // calcul montré, mais partiel et jamais conclu.
        assertThat(x.calcul().statut()).isEqualTo(AdminCalculStatut.CALCUL_PARTIEL);
        assertThat(x.calcul().statutLabel()).contains("Calcul partiel").contains("non vérifiable");
        assertThat(x.calcul().coherent()).isNull();
        assertThat(x.calcul().grilleActive()).isFalse();
        assertThat(x.calcul().seuilsDeLaGrille()).isFalse();
        assertThat(x.calcul().noteRecalculee()).isEqualByComparingTo("12.0");
        assertThat(x.calcul().seuils().b2()).isEqualByComparingTo("15");
        assertThat(x.calcul().niveauRecalcule()).isEqualTo(NiveauCecrl.B1);
        assertThat(x.poidsParCode().get("pertinence")).isEqualByComparingTo("0.35");
    }

    /** DI-07 : un écart relu sur une grille partielle n'est JAMAIS déclaré incohérent. */
    @Test
    void grille_historique_partielle_ne_conclut_jamais_a_une_incoherence() {
        Map<String, Number> notes = new LinkedHashMap<>();
        notes.put("pertinence", 12);
        notes.put("lexique", 12);
        notes.put("morphosyntaxe", 12);
        notes.put("coherence", 12);
        for (String version : List.of("v3", "v4.2")) {
            AiEvaluation e = eval(version, NiveauCecrl.A2, "12.0", notes);

            Calcul c = service.expliquer(e, task(EpreuveType.TCF_EE, 1)).calcul();

            assertThat(c.statut()).as(version).isEqualTo(AdminCalculStatut.CALCUL_PARTIEL);
            assertThat(c.niveauRecalcule()).as(version).isNotEqualTo(NiveauCecrl.A2);
            assertThat(c.coherent()).as(version).isNull();
        }
        // v5 déclare ses seuils mais ni couplage ni plafonds : partiel aussi.
        AiEvaluation v5 = eval("v5", NiveauCecrl.B2, "7.5", v5(8, 8, 7, 7));
        Calcul c5 = service.expliquer(v5, task(EpreuveType.TCF_EE, 2)).calcul();
        assertThat(c5.statut()).isEqualTo(AdminCalculStatut.CALCUL_PARTIEL);
        assertThat(c5.seuilsDeLaGrille()).isTrue();
        assertThat(c5.coherent()).isNull();
    }

    /** Grille complète (seuils, couplage, plafonds, poids déclarés) : la cohérence est conclue. */
    @Test
    void grille_historique_complete_conclut_la_coherence() {
        Calcul ok = service.expliquer(eval("v12", NiveauCecrl.B1, "7.5", v5(8, 8, 7, 7)),
                task(EpreuveType.TCF_EE, 2)).calcul();
        Calcul ecart = service.expliquer(eval("v12", NiveauCecrl.B2, "7.5", v5(8, 8, 7, 7)),
                task(EpreuveType.TCF_EE, 2)).calcul();

        assertThat(ok.statut()).isEqualTo(AdminCalculStatut.CALCULE);
        assertThat(ok.grilleActive()).isFalse();
        assertThat(ok.coherent()).isTrue();
        assertThat(ecart.statut()).isEqualTo(AdminCalculStatut.CALCULE);
        assertThat(ecart.coherent()).isFalse();
    }

    @Test
    void version_inconnue_regle_non_tracable_niveau_persiste_seul() {
        AiEvaluation e = eval(null, NiveauCecrl.A2, "9.0", v5(9, 9, 9, 9));

        AdminProductionCalculService.Explication x = service.expliquer(e, task(EpreuveType.TCF_EE, 1));

        assertThat(x.calcul().statut()).isEqualTo(AdminCalculStatut.REGLE_NON_TRACABLE);
        assertThat(x.calcul().statutLabel()).contains("non traçable");
        assertThat(x.calcul().niveauPersiste()).isEqualTo(NiveauCecrl.A2);
        assertThat(x.calcul().notePersistee()).isEqualByComparingTo("9.0");
        assertThat(x.calcul().noteRecalculee()).isNull();
        assertThat(x.calcul().seuils()).isNull();
        assertThat(x.calcul().niveauRecalcule()).isNull();
        assertThat(x.calcul().coherent()).isNull();
        assertThat(x.poidsParCode()).isEmpty();
    }

    @Test
    void grille_non_livree_regle_non_tracable() {
        AiEvaluation e = eval("v99", NiveauCecrl.B1, "7.5", v5(8, 8, 7, 7));

        Calcul c = service.expliquer(e, task(EpreuveType.TCF_EE, 2)).calcul();

        assertThat(c.statut()).isEqualTo(AdminCalculStatut.REGLE_NON_TRACABLE);
        assertThat(c.rubricsVersion()).isEqualTo("v99");
        assertThat(c.niveauPersiste()).isEqualTo(NiveauCecrl.B1);
    }

    @Test
    void non_evaluable_et_sans_evaluation_ne_calculent_rien() {
        AiEvaluation e = eval("v15", null, null, Map.of());
        e.setEvaluabilite(ProductionEvaluabilite.NON_EVALUABLE);

        assertThat(service.expliquer(e, task(EpreuveType.TCF_EO, 1)).calcul().statut())
                .isEqualTo(AdminCalculStatut.NON_EVALUABLE);
        Calcul sans = service.expliquer(null, task(EpreuveType.TCF_EO, 1)).calcul();
        assertThat(sans.statut()).isEqualTo(AdminCalculStatut.SANS_EVALUATION);
        assertThat(sans.niveauPersiste()).isNull();
    }

    /**
     * Lecture passive par construction : ni le calcul ni la fiche ne tiennent
     * de client LLM, de runner de pipeline, ni de service candidat qui écrit.
     */
    @Test
    void la_console_ne_depend_d_aucun_client_llm_ni_d_aucun_service_qui_ecrit() {
        for (Class<?> c : List.of(AdminProductionService.class, AdminProductionCalculService.class)) {
            for (Field f : c.getDeclaredFields()) {
                String type = f.getType().getSimpleName();
                assertThat(type)
                        .as("%s.%s", c.getSimpleName(), f.getName())
                        .doesNotContain("Llm")
                        .doesNotContain("Client")
                        .doesNotContain("Runner")
                        .doesNotContain("Pipeline")
                        .doesNotContain("AiEvaluationService")
                        .doesNotContain("ProductionEvaluationService")
                        .doesNotContain("ProductionSubmissionService")
                        .doesNotContain("Journey");
            }
        }
    }
}

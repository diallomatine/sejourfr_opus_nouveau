package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.enums.ConfianceEvaluation;
import com.sejourfr.app.enums.NiveauCecrl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

/**
 * Regle de declenchement de la seconde passe (zone floue) et arbitrage entre
 * les deux passes. Unitaire pur : aucun appel LLM.
 */
class ProductionSecondePasseServiceTest {

    private ProductionEvaluationProperties props;
    private ProductionSecondePasseService service;

    @BeforeEach
    void setUp() {
        props = new ProductionEvaluationProperties();
        service = new ProductionSecondePasseService(props, mock(EvaluationLlmClient.class));
    }

    private static ProductionSecondePasseService.Passe passe(String note, NiveauCecrl calcule,
                                                             String confiance, String modele) {
        Map<String, Object> feedback = new LinkedHashMap<>();
        feedback.put("confiance", confiance);
        feedback.put("note_globale", new BigDecimal(note));
        return new ProductionSecondePasseService.Passe(
            feedback, new BigDecimal(note), NiveauCecrl.B1, calcule, modele);
    }

    // --------------------------------------------------------------- drapeau

    @Test
    void desactivee_par_defaut() {
        assertThat(service.isEnabled()).isFalse();
    }

    @Test
    void activable_par_config() {
        props.getSecondePasse().setEnabled(true);
        assertThat(service.isEnabled()).isTrue();
    }

    // ------------------------------------------------------------- zone floue

    @Test
    void zone_sure_aucune_raison() {
        // Competence 17.5 : a 2.5 pts du seuil B2 (15), confiance HAUTE, pas de
        // divergence de plus d'un palier.
        assertThat(service.raisonsZoneFloue(ConfianceEvaluation.HAUTE, new BigDecimal("17.5"),
            NiveauCecrl.B2, NiveauCecrl.B2)).isEmpty();
    }

    @Test
    void confiance_faible_declenche() {
        assertThat(service.raisonsZoneFloue(ConfianceEvaluation.FAIBLE, new BigDecimal("17.5"),
            NiveauCecrl.B2, NiveauCecrl.B2))
            .anyMatch(r -> r.contains("confiance FAIBLE"));
    }

    @Test
    void competence_a_la_frontiere_d_un_seuil_declenche() {
        // Seuil B1 = 12.0, marge = 1.0 -> 12.4 est a la frontiere.
        assertThat(service.raisonsZoneFloue(ConfianceEvaluation.HAUTE, new BigDecimal("12.4"),
            NiveauCecrl.B1, NiveauCecrl.B1))
            .anyMatch(r -> r.contains("frontiere"));
    }

    @Test
    void marge_de_frontiere_configurable() {
        props.getSecondePasse().setMargeSeuilNiveau(0.1);
        assertThat(service.raisonsZoneFloue(ConfianceEvaluation.HAUTE, new BigDecimal("12.4"),
            NiveauCecrl.B1, NiveauCecrl.B1)).isEmpty();
    }

    @Test
    void divergence_de_plus_d_un_palier_declenche() {
        // B2 (LLM) vs A2 (serveur) = 2 paliers.
        assertThat(service.raisonsZoneFloue(ConfianceEvaluation.HAUTE, new BigDecimal("10.0"),
            NiveauCecrl.B2, NiveauCecrl.A2))
            .anyMatch(r -> r.contains("divergent"));
    }

    @Test
    void divergence_d_un_seul_palier_ne_declenche_pas() {
        assertThat(service.raisonsZoneFloue(ConfianceEvaluation.HAUTE, new BigDecimal("10.0"),
            NiveauCecrl.B1, NiveauCecrl.A2)).isEmpty();
    }

    @Test
    void competence_nulle_ne_fait_pas_planter() {
        assertThat(service.raisonsZoneFloue(ConfianceEvaluation.HAUTE, null, null, null)).isEmpty();
    }

    // -------------------------------------------------------------- arbitrage

    @Test
    void arbitrage_retient_le_niveau_le_plus_bas() {
        ProductionSecondePasseService.Passe p1 = passe("14", NiveauCecrl.B1, "HAUTE", "m1");
        ProductionSecondePasseService.Passe p2 = passe("10", NiveauCecrl.A2, "HAUTE", "m2");

        ProductionSecondePasseService.Passe retenue =
            service.arbitrer(p1, p2, List.of("test"), UUID.randomUUID());

        assertThat(retenue).isSameAs(p2);
        assertThat(retenue.modele()).isEqualTo("m2");
    }

    @Test
    void arbitrage_a_niveau_egal_retient_la_note_la_plus_basse() {
        ProductionSecondePasseService.Passe p1 = passe("14", NiveauCecrl.B1, "HAUTE", "m1");
        ProductionSecondePasseService.Passe p2 = passe("12", NiveauCecrl.B1, "HAUTE", "m2");

        assertThat(service.arbitrer(p1, p2, List.of("test"), UUID.randomUUID())).isSameAs(p2);
    }

    @Test
    @SuppressWarnings("unchecked")
    void arbitrage_divergent_abaisse_la_confiance_d_un_cran() {
        ProductionSecondePasseService.Passe p1 = passe("14", NiveauCecrl.B1, "HAUTE", "m1");
        ProductionSecondePasseService.Passe p2 = passe("10", NiveauCecrl.A2, "HAUTE", "m2");

        ProductionSecondePasseService.Passe retenue =
            service.arbitrer(p1, p2, List.of("test"), UUID.randomUUID());

        assertThat(retenue.feedback().get("confiance")).isEqualTo("MOYENNE");
        assertThat((List<String>) retenue.feedback().get("confiance_raisons"))
            .anyMatch(r -> r.contains("deux évaluations indépendantes"));
    }

    @Test
    void arbitrage_identique_ne_touche_pas_la_confiance() {
        ProductionSecondePasseService.Passe p1 = passe("14", NiveauCecrl.B1, "HAUTE", "m1");
        ProductionSecondePasseService.Passe p2 = passe("14", NiveauCecrl.B1, "MOYENNE", "m2");

        ProductionSecondePasseService.Passe retenue =
            service.arbitrer(p1, p2, List.of("test"), UUID.randomUUID());

        assertThat(retenue).isSameAs(p1);
        assertThat(retenue.feedback().get("confiance")).isEqualTo("HAUTE");
    }

    @Test
    @SuppressWarnings("unchecked")
    void arbitrage_trace_le_comparatif_pour_le_banc() {
        ProductionSecondePasseService.Passe p1 = passe("14", NiveauCecrl.B1, "HAUTE", "m1");
        ProductionSecondePasseService.Passe p2 = passe("10", NiveauCecrl.A2, "HAUTE", "m2");

        ProductionSecondePasseService.Passe retenue =
            service.arbitrer(p1, p2, List.of("confiance FAIBLE"), UUID.randomUUID());

        Map<String, Object> trace = (Map<String, Object>) retenue.feedback().get("seconde_passe");
        assertThat(trace.get("declenchee")).isEqualTo(true);
        assertThat(trace.get("passe_retenue")).isEqualTo(2);
        assertThat(trace.get("divergente")).isEqualTo(true);
        assertThat((List<String>) trace.get("raisons")).containsExactly("confiance FAIBLE");
        assertThat((Map<String, Object>) trace.get("passe_1")).containsEntry("modele", "m1");
        assertThat((Map<String, Object>) trace.get("passe_2")).containsEntry("modele", "m2");
    }

    @Test
    void arbitrage_niveau_inconnu_n_est_jamais_le_plus_bas() {
        ProductionSecondePasseService.Passe connue = passe("14", NiveauCecrl.B1, "HAUTE", "m1");
        ProductionSecondePasseService.Passe inconnue = passe("10", null, "HAUTE", "m2");

        assertThat(service.arbitrer(connue, inconnue, List.of("test"), UUID.randomUUID()))
            .isSameAs(connue);
    }
}

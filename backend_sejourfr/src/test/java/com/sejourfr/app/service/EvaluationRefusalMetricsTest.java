package com.sejourfr.app.service;

import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Verrouille le COMPTEUR PAR MOTIF des refus. Il remplace un {@code log.warn}
 * dont l'information se perdait : sur 102 sorties refusees, 2 seulement avaient
 * un motif tracable.
 */
class EvaluationRefusalMetricsTest {

    private static Map<String, Object> feedbackAvecPreuves() {
        Map<String, Object> feedback = new LinkedHashMap<>();
        feedback.put("scores_criteres", List.of(
            Map.of("code", "communiquer", "preuve", "citation inventée absente"),
            Map.of("code", "interagir", "preuve", "autre citation absente"),
            Map.of("code", "lexique", "preuve", "un vrai passage"),
            Map.of("code", "morphosyntaxe", "preuve", "un autre vrai passage")));
        return feedback;
    }

    @Test
    void chaque_violation_est_rattachee_a_sa_famille() {
        assertThat(EvaluationRefusalMetrics.motif(
            "preuve[lexique] doit citer un passage reel de la production"))
            .isEqualTo(EvaluationRefusalMetrics.Motif.PREUVE_NON_RATTACHEE);
        assertThat(EvaluationRefusalMetrics.motif(
            "preuve[lexique] doit etre une chaine non vide"))
            .isEqualTo(EvaluationRefusalMetrics.Motif.PREUVE_ABSENTE);
        assertThat(EvaluationRefusalMetrics.motif(
            "suggestions" + EvaluationOutputValidator.ORAL_VIOLATION_MARKER + " — notion interdite"))
            .isEqualTo(EvaluationRefusalMetrics.Motif.GARDE_FOU_ORAL);
        assertThat(EvaluationRefusalMetrics.motif("criteres manquants : [communiquer]"))
            .isEqualTo(EvaluationRefusalMetrics.Motif.CRITERES);
        assertThat(EvaluationRefusalMetrics.motif(
            "niveau_cecrl doit appartenir au profil TCF IRN et ne jamais depasser B2"))
            .isEqualTo(EvaluationRefusalMetrics.Motif.NOTE_OU_NIVEAU);
        assertThat(EvaluationRefusalMetrics.motif("confiance invalide"))
            .isEqualTo(EvaluationRefusalMetrics.Motif.STRUCTURE_CONTRAT);
    }

    /**
     * Sans la citation refusee, on ne sait pas si le correcteur a invente sa
     * preuve ou si c'est notre rapprochement qui l'a manquee — c'est exactement
     * ce qui a rendu l'enquete impossible.
     */
    @Test
    void la_citation_refusee_est_conservee_critere_par_critere() {
        List<String> violations = List.of(
            "preuve[communiquer] doit citer un passage reel de la production",
            "preuve[interagir] doit citer un passage reel de la production");

        assertThat(EvaluationRefusalMetrics.citationsRefusees(violations, feedbackAvecPreuves()))
            .containsExactly(
                "communiquer : citation inventée absente",
                "interagir : autre citation absente");
    }

    @Test
    void une_violation_sans_preuve_ne_produit_aucune_citation() {
        assertThat(EvaluationRefusalMetrics.citationsRefusees(
            List.of("confiance invalide"), feedbackAvecPreuves())).isEmpty();
    }

    @Test
    void les_compteurs_cumulent_par_phase_et_par_motif() {
        EvaluationRefusalMetrics metrics = new EvaluationRefusalMetrics();
        metrics.enregistrer(EvaluationRefusalMetrics.Phase.PREMIER_APPEL, List.of(
            "preuve[communiquer] doit citer un passage reel de la production",
            "preuve[interagir] doit citer un passage reel de la production"),
            feedbackAvecPreuves());
        metrics.enregistrer(EvaluationRefusalMetrics.Phase.APRES_REESSAI, List.of(
            "suggestions" + EvaluationOutputValidator.ORAL_VIOLATION_MARKER + " — notion interdite"),
            feedbackAvecPreuves());

        assertThat(metrics.compteurs()).containsExactlyInAnyOrderEntriesOf(Map.of(
            "PREMIER_APPEL/PREUVE_NON_RATTACHEE", 2L,
            "APRES_REESSAI/GARDE_FOU_ORAL", 1L));
        assertThat(metrics.derniersRefus()).hasSize(2);
        assertThat(metrics.derniersRefus().get(0).citationsRefusees()).hasSize(2);
    }

    /** L'anneau de detail est BORNE : en production la memoire ne peut pas deriver. */
    @Test
    void le_detail_conserve_est_borne() {
        EvaluationRefusalMetrics metrics = new EvaluationRefusalMetrics();
        for (int i = 0; i < EvaluationRefusalMetrics.REFUS_CONSERVES + 5; i++) {
            metrics.enregistrer(EvaluationRefusalMetrics.Phase.PREMIER_APPEL,
                List.of("confiance invalide"), null);
        }

        assertThat(metrics.derniersRefus()).hasSize(EvaluationRefusalMetrics.REFUS_CONSERVES);
        assertThat(metrics.compteurs())
            .containsEntry("PREMIER_APPEL/STRUCTURE_CONTRAT",
                (long) EvaluationRefusalMetrics.REFUS_CONSERVES + 5);
    }

    @Test
    void le_reset_vide_le_detail_et_les_compteurs() {
        EvaluationRefusalMetrics metrics = new EvaluationRefusalMetrics();
        metrics.enregistrer(EvaluationRefusalMetrics.Phase.PREMIER_APPEL,
            List.of("confiance invalide"), null);
        metrics.reset();

        assertThat(metrics.derniersRefus()).isEmpty();
        assertThat(metrics.compteurs()).isEmpty();
    }
}

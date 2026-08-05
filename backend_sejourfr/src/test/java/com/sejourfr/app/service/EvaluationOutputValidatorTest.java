package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class EvaluationOutputValidatorTest {

    @Test
    void classifie_uniquement_une_preuve_non_rattachable_isolee_comme_degradable() {
        String unmatched = "preuve[communiquer] doit citer un passage reel de la production";

        assertThat(EvaluationOutputValidator.singleUnmatchedProofCode(List.of(unmatched)))
            .contains("communiquer");
        assertThat(EvaluationOutputValidator.singleUnmatchedProofCode(List.of(
            unmatched,
            "preuve[interagir] doit citer un passage reel de la production")))
            .isEmpty();
        assertThat(EvaluationOutputValidator.singleUnmatchedProofCode(List.of(
            "preuve[communiquer] doit etre une chaine non vide")))
            .isEmpty();
        assertThat(EvaluationOutputValidator.singleUnmatchedProofCode(List.of(
            unmatched, "confiance invalide")))
            .isEmpty();
    }

    private ProductionRubricsProvider rubrics;

    @BeforeEach
    void setUp() {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.setRubricsVersion("v7");
        rubrics = new ProductionRubricsProvider(props, new ObjectMapper());
        rubrics.load();
    }

    @Test
    void accepte_une_sortie_v4_tcf_irn_complete() {
        assertThat(EvaluationOutputValidator.violations(
            validFeedback(), task(EpreuveType.TCF_EE), rubrics, "v4")).isEmpty();
    }

    @Test
    void rejette_le_cas_reel_du_benchmark_avec_deux_criteres() {
        Map<String, Object> feedback = validFeedback();
        feedback.put("scores_criteres", List.of(
            score("lexique", 7), score("morphosyntaxe", 7)));

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubrics, "v4"))
            .anyMatch(v -> v.contains("exactement 4"))
            .anyMatch(v -> v.contains("criteres manquants"));
    }

    @Test
    void rejette_un_doublon_meme_si_la_liste_compte_quatre_entrees() {
        Map<String, Object> feedback = validFeedback();
        feedback.put("scores_criteres", List.of(
            score("communiquer", 7), score("interagir", 7),
            score("lexique", 7), score("lexique", 7)));

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubrics, "v4"))
            .anyMatch(v -> v.contains("duplique"));
    }

    @Test
    void rejette_un_champ_hors_contrat_avant_normalisation() {
        Map<String, Object> feedback = validFeedback();
        feedback.put("note_bonus", 2);

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubrics, "v4"))
            .anyMatch(v -> v.contains("champ inattendu : note_bonus"));
    }

    @Test
    void rejette_une_note_non_finie_et_un_niveau_superieur_a_b2() {
        Map<String, Object> feedback = validFeedback();
        feedback.put("niveau_cecrl", "C1");
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> scores = (List<Map<String, Object>>) feedback.get("scores_criteres");
        scores.get(0).put("note_sur_20", Double.NaN);

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubrics, "v4"))
            .anyMatch(v -> v.contains("ne jamais depasser B2"))
            .anyMatch(v -> v.contains("fini"));
    }

    @Test
    void rejette_le_feedback_oral_reel_fonde_sur_hesitations_et_fluidite() {
        Map<String, Object> feedback = validFeedback();
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> scores = (List<Map<String, Object>>) feedback.get("scores_criteres");
        scores.get(0).put("commentaire",
            "Le discours est haché par de nombreuses hésitations et manque de fluidité.");
        feedback.put("points_a_ameliorer", List.of(Map.of(
            "constat", "Votre débit rend la réponse difficile à suivre.",
            "comment", "Parlez plus vite et réduisez les répétitions.")));

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EO), rubrics, "v4"))
            .anyMatch(v -> v.contains("scores_criteres.commentaire"))
            .anyMatch(v -> v.contains("points_a_ameliorer"));
    }

    @Test
    void autorise_la_transcription_incertaine_uniquement_dans_la_confiance() {
        Map<String, Object> feedback = validFeedback();
        feedback.put("confiance", "MOYENNE");
        feedback.put("confiance_raisons", List.of(
            "transcription temps réel incertaine avec quelques répétitions"));

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EO), rubrics, "v4")).isEmpty();
    }

    @Test
    void distingue_la_duree_de_residence_du_temps_de_parole() {
        Map<String, Object> feedback = validFeedback();
        feedback.put("accomplissement", Map.of(
            "points_traites", List.of(Map.of(
                "libelle", "Durée de résidence en France indiquée", "obligatoire", true)),
            "points_oublies", List.of()));

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EO), rubrics, "v4")).isEmpty();

        feedback.put("justification_niveau",
            "La durée de l’enregistrement est trop courte pour démontrer le niveau.");
        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EO), rubrics, "v4"))
            .anyMatch(v -> v.contains("justification_niveau"));
    }

    @Test
    void accepte_le_debit_bancaire_mais_pas_le_debit_de_parole() {
        Map<String, Object> feedback = validFeedback();
        feedback.put("accomplissement", Map.of(
            "points_traites", List.of(Map.of(
                "libelle", "Différence entre carte à débit immédiat et différé expliquée",
                "obligatoire", true)),
            "points_oublies", List.of()));

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EO), rubrics, "v4")).isEmpty();

        feedback.put("justification_niveau", "Le débit de parole est trop lent.");
        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EO), rubrics, "v4"))
            .anyMatch(v -> v.contains("justification_niveau"));
    }

    @Test
    @SuppressWarnings("unchecked")
    void rejette_avant_post_traitement_une_preuve_vide_ou_inventee() {
        Map<String, Object> feedback = validFeedback();
        List<Map<String, Object>> scores =
            (List<Map<String, Object>>) feedback.get("scores_criteres");
        scores.get(0).put("preuve", "");
        scores.get(1).put("preuve", "citation inventée absente");

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubrics, "v4",
            "Voici la phrase du candidat."))
            .anyMatch(v -> v.contains("preuve[communiquer] doit etre une chaine non vide"))
            .anyMatch(v -> v.contains("preuve[interagir] doit citer un passage reel"));
    }

    @Test
    @SuppressWarnings("unchecked")
    void accepte_une_preuve_avec_une_seule_flexion_non_ambigue() {
        Map<String, Object> feedback = validFeedback();
        List<Map<String, Object>> scores =
            (List<Map<String, Object>>) feedback.get("scores_criteres");
        for (Map<String, Object> score : scores) {
            score.put("preuve", "protéger notre environnement local");
        }
        scores.get(0).put("preuve",
            "la solution proposée reste tels pour protéger notre environnement local");

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EE), rubrics, "v4",
            "La solution proposée reste telle pour protéger notre environnement local."))
            .isEmpty();
    }

    @Test
    @SuppressWarnings("unchecked")
    void rejette_une_preuve_prise_dans_un_tour_examinateur() {
        Map<String, Object> feedback = validFeedback();
        List<Map<String, Object>> scores =
            (List<Map<String, Object>>) feedback.get("scores_criteres");
        for (Map<String, Object> score : scores) {
            score.put("preuve", "mon appartement se trouve près du parc");
        }
        scores.get(0).put("preuve", "votre logement est près de la gare");

        assertThat(EvaluationOutputValidator.violations(
            feedback, task(EpreuveType.TCF_EO), rubrics, "v4",
            "Examinateur : Votre logement est près de la gare.\n"
                + "Candidat : Mon appartement se trouve près du parc."))
            .anyMatch(v -> v.contains("preuve[communiquer] doit citer un passage reel"));
    }

    private static ProductionTask task(EpreuveType epreuve) {
        ProductionTask task = new ProductionTask();
        task.setEpreuve(epreuve);
        task.setTacheNumero((short) 1);
        return task;
    }

    private static Map<String, Object> validFeedback() {
        Map<String, Object> feedback = new LinkedHashMap<>();
        feedback.put("note_globale", 7);
        feedback.put("niveau_cecrl", "B1");
        feedback.put("justification_niveau", "Les phrases sont développées et reliées par des connecteurs simples.");
        feedback.put("confiance", "HAUTE");
        feedback.put("confiance_raisons", List.of("marqueurs linguistiques nets"));
        feedback.put("accomplissement", Map.of(
            "points_traites", List.of(Map.of("libelle", "Consigne traitée", "obligatoire", true)),
            "points_oublies", List.of()));
        feedback.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", 7), score("interagir", 7),
            score("lexique", 7), score("morphosyntaxe", 7))));
        feedback.put("points_forts", List.of("Le message est clair et organisé."));
        feedback.put("points_a_ameliorer", List.of(Map.of(
            "constat", "Une idée reste peu développée.",
            "comment", "Ajoutez une raison introduite par « parce que » à cette idée.")));
        feedback.put("suggestions", List.of("Entraînez-vous à relier deux idées."));
        feedback.put("exemples_corriges", List.of(Map.of(
            "original", "Je travaille ici.",
            "corrige", "Je travaille ici parce que ce poste me plaît.",
            "explication", "La raison développe le message.",
            "gain", "La subordination montre une structure plus variée.")));
        return feedback;
    }

    private static Map<String, Object> score(String code, Number note) {
        Map<String, Object> score = new LinkedHashMap<>();
        score.put("code", code);
        score.put("note_sur_20", note);
        score.put("commentaire", "Commentaire centré sur le critère " + code + ".");
        score.put("preuve", "phrase du candidat");
        return score;
    }
}

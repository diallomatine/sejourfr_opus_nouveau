package com.sejourfr.app.service;

import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Verrouille le CONTENU du reessai unique. Mesure du diagnostic : sur 8 preuves
 * rejetees, l'ancien message (liste brute des violations) en reparait ZERO — le
 * correcteur resoumettait la meme citation, faute de savoir laquelle avait ete
 * refusee et pourquoi.
 */
class EvaluationRepairPromptTest {

    private static final String USER_PROMPT = "PRODUCTION DU CANDIDAT :\n\"Je travaille ici.\"";

    private static final String VIOLATION_LEXIQUE =
        "preuve[lexique] doit citer un passage reel de la production";
    private static final String VIOLATION_MORPHO =
        "preuve[morphosyntaxe] doit citer un passage reel de la production";

    @SafeVarargs
    private static Map<String, Object> feedback(Map<String, Object>... scores) {
        return Map.of("scores_criteres", List.of(scores));
    }

    private static Map<String, Object> score(String code, String preuve) {
        return Map.of("code", code, "note_sur_20", 8, "commentaire", "x", "preuve", preuve);
    }

    @Test
    void rappelle_la_citation_refusee_critere_par_critere() {
        String prompt = EvaluationRepairPrompt.build(
            USER_PROMPT,
            List.of(VIOLATION_LEXIQUE, VIOLATION_MORPHO),
            feedback(score("lexique", "je travaille beaucoup ici"),
                score("morphosyntaxe", "j'ai travaille... depuis longtemps"),
                score("communiquer", "Je travaille ici")),
            EpreuveType.TCF_EE);

        assertThat(prompt)
            .contains("critere lexique : tu as cite « je travaille beaucoup ici »")
            .contains("critere morphosyntaxe : tu as cite « j'ai travaille... depuis longtemps »")
            // Le critere dont la preuve a ete acceptee n'est pas rappele.
            .doesNotContain("critere communiquer");
    }

    @Test
    void enonce_la_regle_de_la_preuve_et_conseille_de_re_citer_plus_court() {
        String prompt = EvaluationRepairPrompt.build(
            USER_PROMPT, List.of(VIOLATION_LEXIQUE),
            feedback(score("lexique", "un passage invente")), EpreuveType.TCF_EE);

        assertThat(prompt)
            .contains("CONTIGU")
            .contains("TEL QU'IL APPARAIT")
            .contains("hesitations telles qu'elles sont ecrites")
            .contains("points de suspension")
            .contains("RE-CITE PLUS COURT");
    }

    @Test
    void rappelle_la_regle_du_tour_candidat_uniquement_a_l_oral() {
        Map<String, Object> feedback = feedback(score("lexique", "un passage invente"));

        assertThat(EvaluationRepairPrompt.build(
            USER_PROMPT, List.of(VIOLATION_LEXIQUE), feedback, EpreuveType.TCF_EO))
            .contains("UN SEUL tour")
            .contains("Candidat :");
        assertThat(EvaluationRepairPrompt.build(
            USER_PROMPT, List.of(VIOLATION_LEXIQUE), feedback, EpreuveType.TCF_EE))
            .doesNotContain("UN SEUL tour");
    }

    @Test
    void conserve_le_prompt_initial_et_la_liste_des_violations() {
        String prompt = EvaluationRepairPrompt.build(
            USER_PROMPT, List.of(VIOLATION_LEXIQUE, "confiance invalide"),
            feedback(score("lexique", "un passage invente")), EpreuveType.TCF_EE);

        assertThat(prompt)
            .startsWith(USER_PROMPT)
            .contains("TA SORTIE PRECEDENTE A ETE REJETEE PAR LE SERVEUR")
            .contains("- " + VIOLATION_LEXIQUE)
            .contains("- confiance invalide");
    }

    @Test
    void sans_rejet_de_preuve_le_message_reste_la_liste_des_violations() {
        String prompt = EvaluationRepairPrompt.build(
            USER_PROMPT, List.of("confiance invalide"), Map.of(), EpreuveType.TCF_EE);

        assertThat(prompt)
            .contains("- confiance invalide")
            .doesNotContain("CITATIONS REFUSEES")
            .doesNotContain("REGLE DE LA PREUVE");
    }

    @Test
    void une_preuve_vide_est_nommee_telle_quelle() {
        String prompt = EvaluationRepairPrompt.build(
            USER_PROMPT, List.of(VIOLATION_LEXIQUE),
            Map.of("scores_criteres", List.of(Map.of("code", "lexique", "note_sur_20", 8))),
            EpreuveType.TCF_EE);

        assertThat(prompt).contains("critere lexique : une preuve absente ou vide.");
    }
}

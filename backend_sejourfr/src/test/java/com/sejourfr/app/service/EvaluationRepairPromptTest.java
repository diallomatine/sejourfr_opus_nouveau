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

    /** Contrat de sortie ou {@code exemples_corriges} existe encore (jusqu'a v8). */
    private static final EvaluationToolSchema CONTRAT_V8 = EvaluationToolSchema.V8;

    /** Contrat de sortie ou les deux champs de restitution longue ont disparu. */
    private static final EvaluationToolSchema CONTRAT_V9 = EvaluationToolSchema.V9;

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
            EpreuveType.TCF_EE, CONTRAT_V8);

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
            feedback(score("lexique", "un passage invente")), EpreuveType.TCF_EE, CONTRAT_V8);

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
            USER_PROMPT, List.of(VIOLATION_LEXIQUE), feedback, EpreuveType.TCF_EO, CONTRAT_V8))
            .contains("UN SEUL tour")
            .contains("Candidat :");
        assertThat(EvaluationRepairPrompt.build(
            USER_PROMPT, List.of(VIOLATION_LEXIQUE), feedback, EpreuveType.TCF_EE, CONTRAT_V8))
            .doesNotContain("UN SEUL tour");
    }

    @Test
    void conserve_le_prompt_initial_et_la_liste_des_violations() {
        String prompt = EvaluationRepairPrompt.build(
            USER_PROMPT, List.of(VIOLATION_LEXIQUE, "confiance invalide"),
            feedback(score("lexique", "un passage invente")), EpreuveType.TCF_EE, CONTRAT_V8);

        assertThat(prompt)
            .startsWith(USER_PROMPT)
            .contains("TA SORTIE PRECEDENTE A ETE REJETEE PAR LE SERVEUR")
            .contains("- " + VIOLATION_LEXIQUE)
            .contains("- confiance invalide");
    }

    @Test
    void sans_rejet_de_preuve_le_message_reste_la_liste_des_violations() {
        String prompt = EvaluationRepairPrompt.build(
            USER_PROMPT, List.of("confiance invalide"), Map.of(), EpreuveType.TCF_EE, CONTRAT_V8);

        assertThat(prompt)
            .contains("- confiance invalide")
            .doesNotContain("CITATIONS REFUSEES")
            .doesNotContain("REGLE DE LA PREUVE")
            .doesNotContain("GARDE-FOU ORAL");
    }

    /**
     * Garde-fou oral : meme diagnostic que pour les preuves. Le 2026-08-06, une
     * tache d'examen blanc EO a ete perdue apres un reessai qui n'avait repare
     * AUCUNE des deux violations — le message ne disait ni quel passage ni
     * quelle notion. Le reessai les rappelle et donne la sortie sure.
     */
    @Test
    void rappelle_le_passage_rejete_et_la_conduite_a_tenir_sur_le_garde_fou_oral() {
        String violation = "exemples_corriges.explication"
            + EvaluationOutputValidator.ORAL_VIOLATION_MARKER
            + " — notion interdite « repetitions », dans : « Cette reformulation évite "
            + "les répétitions du début. »";

        String prompt = EvaluationRepairPrompt.build(
            USER_PROMPT, List.of(violation), Map.of(), EpreuveType.TCF_EO, CONTRAT_V8);

        assertThat(prompt)
            .contains("ELEMENTS NON EVALUABLES A L'ORAL")
            .contains(violation)
            .contains("TRANSCRIPTION AUTOMATIQUE")
            .contains("c'est la NOTION qui est interdite, pas le mot")
            .contains("SUPPRIME cet exemple")
            .contains("confiance_raisons")
            // Aucun controle relache : on n'invite jamais a garder la remarque.
            .doesNotContain("CITATIONS REFUSEES");
    }

    /**
     * SOUS LE CONTRAT v9, {@code exemples_corriges} n'existe plus : lui rappeler
     * qu'il peut le vider serait le meilleur moyen de le lui faire produire —
     * donc de faire echouer le reessai qu'on essaie de reparer. Tout le reste du
     * garde-fou oral, lui, est INCHANGE : aucun controle n'est relache.
     */
    @Test
    void ne_nomme_plus_les_exemples_corriges_sous_le_contrat_qui_les_a_retires() {
        String violation = "points_forts"
            + EvaluationOutputValidator.ORAL_VIOLATION_MARKER
            + " — notion interdite « fluidite », dans : « Bonne fluidité. »";

        String prompt = EvaluationRepairPrompt.build(
            USER_PROMPT, List.of(violation), Map.of(), EpreuveType.TCF_EO, CONTRAT_V9);

        assertThat(prompt)
            .doesNotContain("exemples_corriges")
            .contains("ELEMENTS NON EVALUABLES A L'ORAL")
            .contains(violation)
            .contains("TRANSCRIPTION AUTOMATIQUE")
            .contains("c'est la NOTION qui est interdite, pas le mot")
            .contains("confiance_raisons");
    }

    @Test
    void cumule_le_garde_fou_oral_et_les_citations_refusees() {
        String prompt = EvaluationRepairPrompt.build(
            USER_PROMPT,
            List.of(VIOLATION_LEXIQUE,
                "points_forts" + EvaluationOutputValidator.ORAL_VIOLATION_MARKER
                    + " — notion interdite « fluidite », dans : « Bonne fluidité. »"),
            feedback(score("lexique", "un passage invente")),
            EpreuveType.TCF_EO, CONTRAT_V8);

        assertThat(prompt)
            .contains("ELEMENTS NON EVALUABLES A L'ORAL")
            .contains("CITATIONS REFUSEES")
            .contains("REGLE DE LA PREUVE");
    }

    @Test
    void une_preuve_vide_est_nommee_telle_quelle() {
        String prompt = EvaluationRepairPrompt.build(
            USER_PROMPT, List.of(VIOLATION_LEXIQUE),
            Map.of("scores_criteres", List.of(Map.of("code", "lexique", "note_sur_20", 8))),
            EpreuveType.TCF_EE, CONTRAT_V8);

        assertThat(prompt).contains("critere lexique : une preuve absente ou vide.");
    }

    // ------------------------------------------- contrat v6 : preuve par numero

    /**
     * Sous v6, il n'y a plus de citation a reparer : rappeler « recopie plus
     * court » n'aurait aucun sens, puisqu'on ne demande plus de recopier. Le
     * message porte sur la seule erreur possible — un numero.
     */
    @Test
    void v6_rappelle_la_regle_du_numero_et_pas_celle_de_la_citation() {
        String prompt = EvaluationRepairPrompt.build(
            USER_PROMPT,
            List.of("preuve_segment[lexique] doit designer un segment numerote de la production"),
            Map.of("scores_criteres", List.of(Map.of(
                "code", "lexique", "note_sur_20", 8, "preuve_segment", 99))),
            EpreuveType.TCF_EO, CONTRAT_V8);

        assertThat(prompt)
            .contains("NUMERO DE SEGMENT INVALIDE")
            .contains("n'est PAS une citation")
            .contains("seuls les tours « Candidat : » portent un numero")
            .doesNotContain("REGLE DE LA PREUVE")
            .doesNotContain("RE-CITE PLUS COURT");
    }

    /** Le garde-fou oral continue de s'appliquer, il ne dependait pas de la preuve. */
    @Test
    void v6_conserve_le_rappel_du_garde_fou_oral() {
        String prompt = EvaluationRepairPrompt.build(
            USER_PROMPT,
            List.of("preuve_segment[lexique] doit etre un numero de segment entier",
                "points_forts" + EvaluationOutputValidator.ORAL_VIOLATION_MARKER
                    + " — notion interdite « fluidite », dans : « Bonne fluidité. »"),
            Map.of("scores_criteres", List.of(Map.of("code", "lexique", "note_sur_20", 8))),
            EpreuveType.TCF_EO, CONTRAT_V8);

        assertThat(prompt)
            .contains("ELEMENTS NON EVALUABLES A L'ORAL")
            .contains("NUMERO DE SEGMENT INVALIDE");
    }
}

package com.sejourfr.app.service;

import org.junit.jupiter.api.Test;

import java.text.Normalizer;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * L'audit d'accentuation est un CAPTEUR : il compte, il ne refuse rien. Ces
 * tests verrouillent les deux moities de sa promesse — il voit le defaut reel
 * constate en production, et il ne signale JAMAIS ce dont il n'est pas sur.
 */
class EvaluationAccentAuditTest {

    /** Verbatim reel d'une evaluation EE (tache 1, deepseek-v4-flash). */
    @Test
    void voit_le_francais_desaccentue_reellement_rendu_au_candidat() {
        Map<String, Object> feedback = new LinkedHashMap<>();
        feedback.put("points_forts", List.of(
            "Le passe compose est maitrise et employe a bon escient."));
        feedback.put("suggestions", List.of("J'espere que cette date te convient."));
        Map<String, Object> accomplissement = new LinkedHashMap<>();
        accomplissement.put("points_traites", List.of(
            Map.of("libelle", "Excuse formulee", "obligatoire", true),
            Map.of("libelle", "Nouvelle seance proposee", "obligatoire", true)));
        feedback.put("accomplissement", accomplissement);

        var audit = EvaluationAccentAudit.analyser(feedback);

        assertThat(audit.aDetecte()).isTrue();
        assertThat(audit.champsTouches()).isEqualTo(4);
        assertThat(audit.formes())
            .contains("maitrise", "espere", "formulee", "seance", "proposee");
    }

    @Test
    void ne_signale_rien_sur_un_rapport_correctement_accentue() {
        Map<String, Object> feedback = new LinkedHashMap<>();
        feedback.put("points_forts", List.of(
            "Le passé composé est maîtrisé et employé à bon escient."));
        feedback.put("suggestions", List.of(
            "J'espère que cette date te convient ; la séance proposée est claire."));
        feedback.put("justification_niveau",
            "Niveau B1 : les idées sont reliées et le récit reste très cohérent.");

        assertThat(EvaluationAccentAudit.analyser(feedback).aDetecte()).isFalse();
    }

    /**
     * LA regression a ne jamais introduire : les champs qui CITENT le candidat.
     * Sa graphie est la sienne — accents manquants compris — et la corriger
     * reviendrait a lui montrer une phrase qu'il n'a pas ecrite.
     */
    @Test
    void n_audite_jamais_ce_que_le_correcteur_cite_du_candidat() {
        Map<String, Object> feedback = new LinkedHashMap<>();
        feedback.put("points_a_ameliorer", List.of(Map.of(
            "constat", "Tes idées s'enchaînent sans lien.",
            "comment", "Relie tes phrases avec « parce que ».",
            "exemple", Map.of(
                "avant", "j'ai deja ete tres content apres la seance",
                "apres", "J'étais déjà très content après la séance."))));
        feedback.put("exemples_corriges", List.of(Map.of(
            "original", "la reponse etait tres necessaire",
            "corrige", "La réponse était nécessaire.",
            "explication", "La phrase devient plus précise.",
            "gain", "Cette version emploie une subordonnée.")));

        assertThat(EvaluationAccentAudit.analyser(feedback).aDetecte()).isFalse();
    }

    /** Un passage entre guillemets reprend les mots du candidat : jamais compte. */
    @Test
    void ignore_les_passages_entre_guillemets() {
        Map<String, Object> feedback = Map.of("suggestions", List.of(
            "La phrase « on va regler ca deja apres » reste vague : précise l'action."));

        assertThat(EvaluationAccentAudit.analyser(feedback).aDetecte()).isFalse();
    }

    /** Les champs poses par le SERVEUR ne disent rien de ce que rend le correcteur. */
    @Test
    void n_audite_ni_les_libelles_de_critere_ni_les_avertissements_du_serveur() {
        Map<String, Object> feedback = Map.of(
            "scores_criteres", List.of(Map.of(
                "code", "communiquer",
                "label", "Communiquer : accomplir la tache et enchainer les idees",
                "note_sur_20", 8,
                "commentaire", "Le message passe et reste clair.")),
            "avertissements", List.of("Evaluation fondee sur la transcription."));

        assertThat(EvaluationAccentAudit.analyser(feedback).aDetecte()).isFalse();
    }

    /**
     * EN CAS DE DOUTE, ON NE SIGNALE RIEN. Aucune forme de la liste ne doit
     * avoir de lecture francaise valable sans accent : « tache » (une salissure),
     * « cote », « a », « ou », « regle » n'y sont pas, et n'y entreront pas.
     */
    @Test
    void la_liste_fermee_exclut_toute_forme_ambigue() {
        assertThat(EvaluationAccentAudit.FORMES_DESACCENTUEES)
            .doesNotContain("a", "ou", "du", "sur", "la", "des", "ca",
                "tache", "taches", "cote", "cotes", "regle", "regler", "mur",
                "pratique", "note", "cause", "sale", "jeune", "marche");
    }

    /**
     * Chaque forme de la liste est bien la version DESACCENTUEE d'un mot
     * francais accentue : une entree deja accentuee, ou sans accent a rendre,
     * ne detecterait jamais rien et signalerait une erreur de saisie.
     */
    @Test
    void chaque_forme_de_la_liste_est_bien_une_forme_desaccentuee() {
        for (String forme : EvaluationAccentAudit.FORMES_DESACCENTUEES) {
            assertThat(Normalizer.normalize(forme, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", ""))
                .as("%s doit s'ecrire sans aucun signe diacritique", forme)
                .isEqualTo(forme);
            assertThat(forme).as("%s", forme)
                .isNotBlank()
                .isEqualTo(forme.toLowerCase(java.util.Locale.ROOT));
        }
    }

    /** L'audit ne modifie rien : c'est ce qui autorise a l'appeler en production. */
    @Test
    void ne_modifie_jamais_le_feedback() {
        Map<String, Object> feedback = new LinkedHashMap<>();
        feedback.put("suggestions", List.of("Revois le passe compose."));
        Map<String, Object> avant = Map.copyOf(feedback);

        EvaluationAccentAudit.analyser(feedback);

        assertThat(feedback).isEqualTo(avant);
    }
}

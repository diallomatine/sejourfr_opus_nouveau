package com.sejourfr.app.service;

import com.sejourfr.app.enums.NiveauCecrl;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FILET « marqueur A2 vendu comme levier d'un palier supérieur ».
 *
 * <p>Tous les verbatims marqués « RÉEL » viennent de la base de production
 * (138 évaluations, 707 champs de restitution). C'est sur ce corpus que les
 * frontières ont été calibrées : <b>5 phrases purgées, 0 faux positif</b>.
 */
class EvaluationPalierMarqueurFilterTest {

    // ------------------------------------------------------- ce qui est purgé

    /**
     * LE DÉFAUT SIGNALÉ, verbatim. Le propriétaire a suivi ce conseil, resoumis,
     * et obtenu exactement la même note : « parce que » est un marqueur A2 pour
     * notre propre rubrique (descripteur A2 de EE_T1, et plafond A2 qui exige
     * des connecteurs « au-delà de et / mais / parce que / après / aussi »).
     */
    @Test
    @DisplayName("RÉEL : « une subordonnée causale avec « parce que », marqueur attendu au B1 »")
    void gainQuiPresenteParceQueCommeUnMarqueurB1_estPurge() {
        Map<String, Object> feedback = feedback();
        feedback.put("exemples_corriges", listeDe(exemple(
            "Il y aura du monde tel que Balde et Ibrahim",
            "Il y aura du monde, comme Balde et Ibrahim, que tu apprécieras de retrouver",
            "cette version emploie une subordonnée causale avec « parce que », "
                + "marqueur attendu au B1.")));

        var resultat = EvaluationPalierMarqueurFilter.purge(feedback, NiveauCecrl.A2);

        assertThat(resultat.aPurge()).isTrue();
        assertThat(resultat.entreesRetirees()).isEqualTo(1);
        assertThat(liste(feedback, "exemples_corriges")).isEmpty();
    }

    /** RÉEL, même évaluation : la suggestion qui accompagnait ce gain. */
    @Test
    void suggestionQuiViseLeB1EnCitantParceQue_estPurgee() {
        Map<String, Object> feedback = feedback();
        feedback.put("suggestions", listeDe(
            "Pour viser le palier B1, essaie d'ajouter une subordonnée relative ou une "
                + "justification : par exemple « Fatima, qui est très jeune, est facile à vivre » "
                + "ou « j'aime discuter avec elle parce qu'elle est très agréable ».",
            "Relis ton message à voix haute pour vérifier la ponctuation."));

        var resultat = EvaluationPalierMarqueurFilter.purge(feedback, NiveauCecrl.A2);

        assertThat(resultat.remarquesRetirees()).isEqualTo(1);
        assertThat(liste(feedback, "suggestions"))
            .containsExactly("Relis ton message à voix haute pour vérifier la ponctuation.");
    }

    /** RÉEL : le marqueur cité seul, entre apostrophes simples. */
    @Test
    void suggestionQuiCiteParceQueSeulPourGagnerUnNiveau_estPurgee() {
        Map<String, Object> feedback = feedback();
        feedback.put("suggestions", listeDe(
            "Pour gagner un niveau, essaie de relier tes idees avec un connecteur logique "
                + "comme 'parce que' ou 'car' : par exemple 'viens, car on va feter ca ensemble'."));

        var resultat = EvaluationPalierMarqueurFilter.purge(feedback, NiveauCecrl.A2);

        assertThat(resultat.entreesRetirees()).isEqualTo(1);
        assertThat(liste(feedback, "suggestions")).isEmpty();
    }

    /** Un marqueur cité seul en guillemets français suffit, même sans « parce que ». */
    @Test
    void marqueurA2CiteSeulEtRattacheAuB2_estPurge() {
        Map<String, Object> feedback = feedback();
        feedback.put("suggestions", listeDe(
            "Pour atteindre le B2, enchaîne tes idées avec « et » et « mais »."));

        var resultat = EvaluationPalierMarqueurFilter.purge(feedback, NiveauCecrl.B1);

        assertThat(resultat.entreesRetirees()).isEqualTo(1);
    }

    /** Une priorité dont la technique tombe est retirée en entier, jamais à moitié. */
    @Test
    void prioriteDontLeCommentTombe_estRetireeEnEntier() {
        Map<String, Object> feedback = feedback();
        Map<String, Object> point = new LinkedHashMap<>();
        point.put("constat", "Les idées sont juxtaposées.");
        point.put("comment", "Pour viser le palier B1, relie-les avec « parce que ».");
        point.put("exemple", Map.of("avant", "Je suis fatigué. Je travaille beaucoup.",
            "apres", "Je suis fatigué car je travaille beaucoup."));
        feedback.put("points_a_ameliorer", listeDe(point));

        var resultat = EvaluationPalierMarqueurFilter.purge(feedback, NiveauCecrl.A2);

        assertThat(resultat.entreesRetirees()).isEqualTo(1);
        assertThat(liste(feedback, "points_a_ameliorer")).isEmpty();
    }

    /** La phrase fautive part, la phrase saine reste : on purge la phrase, pas le champ. */
    @Test
    void seuleLaPhraseFautivePart() {
        Map<String, Object> feedback = feedback();
        feedback.put("suggestions", listeDe(
            "Relis-toi avant d'envoyer. Pour viser le palier B1, ajoute « parce que ». "
                + "Pense aussi à saluer ton destinataire."));

        EvaluationPalierMarqueurFilter.purge(feedback, NiveauCecrl.A2);

        assertThat(liste(feedback, "suggestions")).containsExactly(
            "Relis-toi avant d'envoyer. Pense aussi à saluer ton destinataire.");
    }

    // -------------------------------------------------- ce qui n'est PAS purgé

    /**
     * FAUX POSITIF À NE JAMAIS PRODUIRE, verbatim RÉEL. Une variante plus large
     * (« marqueur A2 présent dans une citation ») supprimait ce conseil — qui
     * décrit exactement le test décisif B1 vs B2 de la rubrique (« objection
     * envisagée puis traitée »). Le « mais » y est une simple conjonction.
     */
    @Test
    void conseilB2QuiCiteUnExempleContenantMais_estConserve() {
        Map<String, Object> feedback = feedback();
        String conseil = "Pour viser le palier au-dessus, essaie d'envisager une objection d'un "
            + "auditeur et d'y répondre : par exemple 'On pourrait me dire que les grandes villes "
            + "offrent plus d'activités, mais à l'île, la qualité de vie compense largement.'";
        feedback.put("suggestions", listeDe(conseil));

        var resultat = EvaluationPalierMarqueurFilter.purge(feedback, NiveauCecrl.B1);

        assertThat(resultat.aPurge()).isFalse();
        assertThat(liste(feedback, "suggestions")).containsExactly(conseil);
    }

    /**
     * FAUX POSITIF À NE JAMAIS PRODUIRE, verbatim RÉEL. Une variante
     * « désignation + n'importe quel marqueur » supprimait ce conseil, où
     * « mais » relie deux moitiés de phrase.
     */
    @Test
    void conseilSurLePasseComposeQuiEmploieMais_estConserve() {
        Map<String, Object> feedback = feedback();
        Map<String, Object> point = new LinkedHashMap<>();
        point.put("constat", "Un seul temps est employé.");
        point.put("comment", "Pour viser le palier au-dessus, ajoute un second temps : par "
            + "exemple, pour parler de ce que vous faites d'habitude, tu peux employer le "
            + "présent, mais pour évoquer un souvenir précis, utilise le passé composé — "
            + "« hier, on a discuté pendant toute la pause ».");
        feedback.put("points_a_ameliorer", listeDe(point));

        var resultat = EvaluationPalierMarqueurFilter.purge(feedback, NiveauCecrl.A2);

        assertThat(resultat.aPurge()).isFalse();
        assertThat(liste(feedback, "points_a_ameliorer")).hasSize(1);
    }

    /**
     * FAUX POSITIF À NE JAMAIS PRODUIRE, verbatim RÉEL : « un lexique plus précis
     * ET une structure plus correcte » — le « et » y est incidental.
     */
    @Test
    void gainQuiContientUnEtIncidental_estConserve() {
        Map<String, Object> feedback = feedback();
        feedback.put("exemples_corriges", listeDe(exemple("avant", "après",
            "cette version emploie un lexique plus précis et une structure plus correcte, "
                + "marqueur attendu au B1.")));

        var resultat = EvaluationPalierMarqueurFilter.purge(feedback, NiveauCecrl.A2);

        assertThat(resultat.aPurge()).isFalse();
        assertThat(liste(feedback, "exemples_corriges")).hasSize(1);
    }

    /**
     * Conseiller « parce que » SANS promettre de palier est parfaitement
     * légitime : c'est le conseil que la rubrique elle-même donne en exemple.
     */
    @Test
    void conseilQuiCiteParceQueSansPromettreDePalier_estConserve() {
        Map<String, Object> feedback = feedback();
        String conseil = "Relie tes deux idées au lieu de les juxtaposer : remplace le point par "
            + "« parce que ».";
        feedback.put("suggestions", listeDe(conseil));

        var resultat = EvaluationPalierMarqueurFilter.purge(feedback, NiveauCecrl.A2);

        assertThat(resultat.aPurge()).isFalse();
        assertThat(liste(feedback, "suggestions")).containsExactly(conseil);
    }

    /**
     * DEPUIS A1, viser le palier suivant avec « parce que » est JUSTE : le
     * palier suivant est A2, et une ancre de la rubrique active l'ordonne
     * (« Le palier suivant se joue sur les phrases longues : relie deux idées
     * avec "parce que" ou "même si" »).
     */
    @Test
    void depuisA1_gagnerUnNiveauAvecParceQue_estConserve() {
        Map<String, Object> feedback = feedback();
        String conseil = "Pour gagner un niveau, relie deux idées avec « parce que ».";
        feedback.put("suggestions", listeDe(conseil));

        var resultat = EvaluationPalierMarqueurFilter.purge(feedback, NiveauCecrl.A1);

        assertThat(resultat.aPurge()).isFalse();
        assertThat(liste(feedback, "suggestions")).containsExactly(conseil);
    }

    /** Viser A2 nommément depuis A1 : légitime, quel que soit le marqueur. */
    @Test
    void viserA2NommementAvecUnMarqueurA2_estConserve() {
        Map<String, Object> feedback = feedback();
        String conseil = "Le A2 demande des phrases reliées : ajoute « parce que » entre tes "
            + "deux idées.";
        feedback.put("suggestions", listeDe(conseil));

        assertThat(EvaluationPalierMarqueurFilter.purge(feedback, NiveauCecrl.A1).aPurge()).isFalse();
    }

    /** Un vrai levier B1/B2 nommé n'est jamais touché. */
    @Test
    void vraiLevierB2_estConserve() {
        Map<String, Object> feedback = feedback();
        String conseil = "Pour viser le B2, emploie des connecteurs qui organisent le propos : "
            + "« d'abord », « en revanche », « c'est pourquoi ».";
        feedback.put("suggestions", listeDe(conseil));

        assertThat(EvaluationPalierMarqueurFilter.purge(feedback, NiveauCecrl.B1).aPurge()).isFalse();
    }

    // ---------------------------------------------------- champs hors périmètre

    /**
     * {@code justification_niveau} est le raisonnement INTERNE du correcteur,
     * expurgé avant le front : le filet n'y touche pas. Les champs de CITATION
     * non plus — ils recopient le candidat, dont la production contient
     * évidemment des « parce que ».
     */
    @Test
    void justificationEtCitationsNeSontJamaisTouchees() {
        Map<String, Object> feedback = feedback();
        feedback.put("justification_niveau",
            "Le candidat emploie « parce que », marqueur qui ne suffit pas pour le B1.");
        Map<String, Object> point = new LinkedHashMap<>();
        point.put("constat", "Les idées sont juxtaposées.");
        point.put("comment", "Relie-les.");
        Map<String, Object> exemple = new LinkedHashMap<>();
        exemple.put("avant", "Je suis fatigué parce que je travaille. Pour viser le B1.");
        exemple.put("apres", "Je suis fatigué car je travaille beaucoup.");
        point.put("exemple", exemple);
        feedback.put("points_a_ameliorer", listeDe(point));

        var resultat = EvaluationPalierMarqueurFilter.purge(feedback, NiveauCecrl.A2);

        assertThat(resultat.aPurge()).isFalse();
        assertThat(feedback.get("justification_niveau")).asString().contains("parce que");
    }

    /** Le filet ne touche NI la note, NI le niveau, NI un seuil. */
    @Test
    void niLaNoteNiLeNiveauNeBougent() {
        Map<String, Object> feedback = feedback();
        feedback.put("suggestions", listeDe("Pour viser le palier B1, ajoute « parce que »."));

        EvaluationPalierMarqueurFilter.purge(feedback, NiveauCecrl.A2);

        assertThat(feedback.get("note_globale")).isEqualTo("4.5");
        assertThat(feedback.get("niveau_cecrl")).isEqualTo("A2");
        assertThat(feedback.get("scores_criteres")).isNotNull();
    }

    /** Niveau constaté inconnu : seules les revendications NOMMÉES sont traitées. */
    @Test
    void niveauConstateInconnu_laFormuleRelativeNeDeclencheRien() {
        Map<String, Object> feedback = feedback();
        String conseil = "Pour gagner un niveau, ajoute « parce que ».";
        feedback.put("suggestions", listeDe(conseil));

        assertThat(EvaluationPalierMarqueurFilter.purge(feedback, null).aPurge()).isFalse();
    }

    // ------------------------------------------------------------- fixtures

    private static Map<String, Object> feedback() {
        Map<String, Object> feedback = new LinkedHashMap<>();
        feedback.put("note_globale", "4.5");
        feedback.put("niveau_cecrl", "A2");
        feedback.put("scores_criteres", List.of(Map.of("code", "lexique", "note_sur_20", 4)));
        return feedback;
    }

    @SuppressWarnings("unchecked")
    private static List<Object> liste(Map<String, Object> feedback, String champ) {
        return (List<Object>) feedback.get(champ);
    }

    private static List<Object> listeDe(Object... elements) {
        return new ArrayList<>(List.of(elements));
    }

    private static Map<String, Object> exemple(String original, String corrige, String gain) {
        Map<String, Object> exemple = new LinkedHashMap<>();
        exemple.put("original", original);
        exemple.put("corrige", corrige);
        exemple.put("gain", gain);
        return exemple;
    }
}

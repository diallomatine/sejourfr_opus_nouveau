package com.sejourfr.app.service;

import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FILET DETERMINISTE de la restitution orale, mesure sur l'incident REEL du
 * 2026-08-06 (submission EO T3 {@code be605a85-24f2-4300-acbc-fcfc18ddb644}).
 *
 * <p>Le candidat avait dit <b>Lille</b>, <b>sachant qu'à Paris</b> et
 * <b>pour traverser</b> ; la transcription portait <b>l'île</b>,
 * <b>ça sent qu'à Paris</b> et <b>par travers</b>. Le correcteur a impute ces
 * trois artefacts au candidat dans cinq champs, sans employer un seul des mots
 * du garde-fou lexical existant.
 *
 * <p>Ces tests fixent AUSSI la frontiere assumee du filet : il reconnait le
 * reproche qui ne nomme qu'UN mot, pas l'artefact etale sur plusieurs mots, que
 * rien ne distingue d'une vraie faute sans lexique du francais. Ce cas-la est
 * traite par la consigne des rubriques v9, mesuree au banc.
 */
class EvaluationOralArtifactFilterTest {

    /** Transcription REELLE (reconstituee) : les trois artefacts y figurent. */
    private static final String TRANSCRIPTION =
        "Examinateur : Bonjour, pourquoi souhaitez-vous déménager ?\n"
            + "Candidat : je veux aller habiter à l'île parce que le loyer est moins cher, "
            + "ça sent qu'à Paris tout est très cher pour une famille\n"
            + "Examinateur : Et les transports, cela vous inquiète ?\n"
            + "Candidat : non il y a le tramway et je prends le pont par travers la ville "
            + "donc je mets vingt minutes";

    // ------------------------------------------------------- artefacts reels

    /** Artefact 1 : « l'île » pour « Lille ». Un seul mot porteur de sens. */
    @Test
    void purge_un_commentaire_de_critere_bati_sur_un_mot_mal_transcrit() {
        Map<String, Object> feedback = feedback();
        score(feedback, "lexique").put("commentaire",
            "Le lexique du logement est employé correctement. "
                + "En revanche « l'île » est impropre pour désigner une ville.");

        var resultat = EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION);

        assertThat(resultat.aPurge()).isTrue();
        assertThat(score(feedback, "lexique").get("commentaire"))
            .isEqualTo("Le lexique du logement est employé correctement.");
    }

    /** Artefact 3 : « par travers » pour « pour traverser ». « par » est un mot-outil. */
    @Test
    void purge_une_suggestion_batie_sur_un_mot_mal_transcrit() {
        Map<String, Object> feedback = feedback();
        feedback.put("suggestions", new ArrayList<>(List.of(
            "Révisez les prépositions : on ne dit pas « par travers ».",
            "Entraînez-vous à relier deux idées avec « parce que ».")));

        EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION);

        assertThat(feedback.get("suggestions")).asInstanceOf(
            org.assertj.core.api.InstanceOfAssertFactories.list(String.class))
            .containsExactly("Entraînez-vous à relier deux idées avec « parce que ».");
    }

    /**
     * FRONTIERE ASSUMEE — artefact 2 : « ça sent qu'à Paris » pour « sachant
     * qu'à Paris ». Trois mots porteurs de sens : sans lexique du francais,
     * aucun controle deterministe ne peut le distinguer d'une vraie faute de
     * construction, et une heuristique plus large supprimerait de VRAIES
     * corrections. C'est la section orale des rubriques v9 qui traite ce cas.
     */
    @Test
    void ne_purge_pas_un_artefact_etale_sur_plusieurs_mots() {
        Map<String, Object> feedback = feedback();
        String commentaire = "La construction « ça sent qu'à Paris » n'est pas correcte.";
        score(feedback, "morphosyntaxe").put("commentaire", commentaire);

        EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION);

        assertThat(score(feedback, "morphosyntaxe").get("commentaire")).isEqualTo(commentaire);
    }

    // ----------------------------------------------------------- priorites

    /** La priorite entiere tombe : elle ne tenait que par le mot mal transcrit. */
    @Test
    void supprime_une_priorite_entiere_batie_sur_un_mot_mal_transcrit() {
        Map<String, Object> feedback = feedback();
        feedback.put("points_a_ameliorer", new ArrayList<>(List.of(
            new LinkedHashMap<>(Map.of(
                "constat", "Vous employez « l'île » à la place du nom de la ville.",
                "comment", "Nommez la ville : remplacez « l'île » par son nom.")),
            new LinkedHashMap<>(Map.of(
                "constat", "Vos idées sont juxtaposées.",
                "comment", "Reliez-les avec « parce que ».")))));

        EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION);

        assertThat(feedback.get("points_a_ameliorer")).asInstanceOf(
            org.assertj.core.api.InstanceOfAssertFactories.LIST)
            .hasSize(1)
            .allSatisfy(p -> assertThat(((Map<?, ?>) p).get("constat"))
                .isEqualTo("Vos idées sont juxtaposées."));
    }

    /** Un commentaire entierement purge n'est jamais vide : on dit pourquoi. */
    @Test
    void remplace_un_commentaire_entierement_purge() {
        Map<String, Object> feedback = feedback();
        score(feedback, "lexique").put("commentaire", "Le mot « l'île » n'existe pas ici.");

        EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION);

        assertThat(score(feedback, "lexique").get("commentaire"))
            .isEqualTo(EvaluationOralArtifactFilter.COMMENTAIRE_CRITERE_PURGE);
    }

    // -------------------------------------------------- ce qui n'est PAS purge

    /** Une remarque de PHRASE, meme citee, reste : elle porte sur la construction. */
    @Test
    void ne_purge_pas_une_remarque_au_niveau_de_la_phrase() {
        Map<String, Object> feedback = feedback();
        String commentaire = "Vos idées sont juxtaposées : « le loyer est moins cher » "
            + "gagnerait à être relié à ce qui précède.";
        score(feedback, "morphosyntaxe").put("commentaire", commentaire);

        EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION);

        assertThat(score(feedback, "morphosyntaxe").get("commentaire")).isEqualTo(commentaire);
    }

    /**
     * Un mot cite qui n'est PAS dans la transcription (exemple pedagogique,
     * mot-outil propose au candidat) n'est jamais un artefact : rien n'est purge.
     */
    @Test
    void ne_purge_pas_un_mot_qui_ne_vient_pas_de_la_transcription() {
        Map<String, Object> feedback = feedback();
        String commentaire = "Une concession, avec « pourtant », enrichirait le propos.";
        score(feedback, "communiquer").put("commentaire", commentaire);

        var resultat = EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION);

        assertThat(resultat.remarquesRetirees()).isZero();
        assertThat(score(feedback, "communiquer").get("commentaire")).isEqualTo(commentaire);
    }

    /**
     * LE NARROWING QUI COMPTE : un CONSEIL qui cite un mot present dans la
     * production n'est pas un reproche. Sans cette condition, le filet effacait
     * « relie tes idees avec "parce que" » — exactement ce qu'on veut garder.
     */
    @Test
    void ne_purge_pas_un_conseil_qui_cite_un_mot_de_la_production() {
        Map<String, Object> feedback = feedback();
        String conseil = "Relie tes deux idées avec « parce que ».";
        feedback.put("suggestions", new ArrayList<>(List.of(conseil)));

        var resultat = EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION);

        assertThat(resultat.remarquesRetirees()).isZero();
        assertThat(feedback.get("suggestions")).asInstanceOf(
            org.assertj.core.api.InstanceOfAssertFactories.list(String.class))
            .containsExactly(conseil);
    }

    /** Un mot pris dans un tour EXAMINATEUR n'est pas un passage du candidat. */
    @Test
    void ne_purge_pas_un_mot_pris_dans_un_tour_de_l_examinateur() {
        Map<String, Object> feedback = feedback();
        String commentaire = "Vous ne reprenez jamais le thème des « transports ».";
        score(feedback, "communiquer").put("commentaire", commentaire);

        EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION);

        assertThat(score(feedback, "communiquer").get("commentaire")).isEqualTo(commentaire);
    }

    // ------------------------------------------- exemples corriges (volet 3)

    /** Une explication fondee sur une notion orale interdite : l'entree saute. */
    @Test
    void supprime_un_exemple_corrige_fonde_sur_une_notion_orale_interdite() {
        Map<String, Object> feedback = feedback();
        feedback.put("exemples_corriges", new ArrayList<>(List.of(
            Map.of("original", "je je veux aller", "corrige", "je veux aller",
                "explication", "Cette version évite les répétitions du début.",
                "gain", "un propos plus direct"),
            Map.of("original", "le loyer est moins cher",
                "corrige", "le loyer est moins cher qu'à Paris",
                "explication", "La comparaison précise le propos.",
                "gain", "une comparaison construite, marqueur attendu au B1"))));

        var resultat = EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION);

        assertThat(resultat.exemplesRetires()).isEqualTo(1);
        assertThat(feedback.get("exemples_corriges")).asInstanceOf(
            org.assertj.core.api.InstanceOfAssertFactories.LIST).hasSize(1);
    }

    // -------------------------------------------------------------- fixtures

    private static Map<String, Object> feedback() {
        Map<String, Object> f = new LinkedHashMap<>();
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer"), score("interagir"),
            score("lexique"), score("morphosyntaxe"))));
        f.put("points_a_ameliorer", new ArrayList<>());
        f.put("suggestions", new ArrayList<>());
        f.put("exemples_corriges", new ArrayList<>());
        return f;
    }

    private static Map<String, Object> score(String code) {
        Map<String, Object> s = new LinkedHashMap<>();
        s.put("code", code);
        s.put("note_sur_20", 7);
        s.put("commentaire", "Commentaire neutre sur " + code + ".");
        s.put("preuve", "le loyer est moins cher");
        return s;
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> score(Map<String, Object> feedback, String code) {
        for (Object raw : (List<Object>) feedback.get("scores_criteres")) {
            Map<String, Object> s = (Map<String, Object>) raw;
            if (code.equals(s.get("code"))) return s;
        }
        throw new IllegalArgumentException("critere absent : " + code);
    }
}

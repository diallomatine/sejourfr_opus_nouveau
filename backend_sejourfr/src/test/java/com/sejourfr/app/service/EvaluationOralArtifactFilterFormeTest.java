package com.sejourfr.app.service;

import org.assertj.core.api.InstanceOfAssertFactories;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * VOLET FORME du filet oral, mesure sur l'incident REEL du 2026-08-08.
 *
 * <p>Le candidat avait dit « <b>j'habite à Lille</b> » ; la transcription temps
 * reel a mange le « j'h » et le correcteur a ecrit, dans le critere
 * {@code morphosyntaxe} : « quelques erreurs perceptibles : « <b>abit à Lille</b> »
 * (j'habite)… ». On reprochait au candidat un defaut de NOTRE chaine technique,
 * et ce reproche pesait sur la lecture de sa note.
 *
 * <p><b>La regle verrouillee ici</b> : a l'oral, une faute de grammaire est une
 * STRUCTURE. Elle se cite soit sur au moins trois mots pleins, soit sur des
 * mots-outils seuls (« pour ne pas que ») — jamais sur une ou deux formes
 * isolees, qui sont precisement ce que la reconnaissance vocale fabrique, et qui
 * de toute facon ne s'entendent pas.
 *
 * <p><b>Les faux positifs a ne JAMAIS declencher</b> sont testes ici aussi : la
 * meme mesure appliquee au critere {@code lexique} produisait deux faux positifs
 * reels ({@code chronoposte}, {@code ESN}) — dont un cite en POINT FORT.
 */
class EvaluationOralArtifactFilterFormeTest {

    /** Transcription REELLE (reconstituee) du 2026-08-08 : « abit » y figure. */
    private static final String TRANSCRIPTION = """
        Examinateur : Bonjour, pouvez-vous vous présenter ?
        Candidat : Oui, bonjour, je me nomme Diallo, j'ai 21 ans et je suis d'origine guinéenne. je suis un étudiant en informatique à licence 3 et puis abit à Lille et étudier également à l'université de Lille.
        Examinateur : Et vos projets après le master ?
        Candidat : oui, j'aimerais bien que start up, une start-up comme ça, je vais toucher vraiment à l'ensemble de l'écosystème de la programmation, pour ne pas que ça prenne trop de temps.
        Examinateur : Et vos loisirs ?
        Candidat : aussi au foot ensemble avec par exemple le samedi chaque samedi on se rend compte et puis à 11 jours ensemble les samedi avec mes amis de la fac.
        """;

    /** Meme production, plus deux mots que le correcteur a reellement cites. */
    private static final String TRANSCRIPTION_AVEC_SIGLES = TRANSCRIPTION
        + "Candidat : j'ai envoyé le dossier par chronoposte express et j'ai travaillé en ESN parisienne.\n";

    // -------------------------------------------------------- l'incident

    /** LE cas : « abit à Lille » ne nomme que deux mots pleins. */
    @Test
    void purge_le_reproche_de_grammaire_bati_sur_une_forme_mal_transcrite() {
        Map<String, Object> feedback = feedback();
        score(feedback, "morphosyntaxe").put("commentaire",
            "Phrases simples correctement construites dans l'ensemble. "
                + "On relève quelques erreurs perceptibles : « abit à Lille » (j'habite).");

        var resultat = EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION, false);

        assertThat(resultat.remarquesFormeRetirees()).isEqualTo(1);
        assertThat(score(feedback, "morphosyntaxe").get("commentaire"))
            .isEqualTo("Phrases simples correctement construites dans l'ensemble.");
    }

    /** Meme artefact la veille : « Habite à Lille », le sujet mange par la machine. */
    @Test
    void purge_aussi_la_variante_du_lendemain_habite_a_lille() {
        Map<String, Object> feedback = feedback();
        score(feedback, "morphosyntaxe").put("commentaire",
            "Des erreurs perceptibles : « abit à Lille » sans sujet.");

        var resultat = EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION, false);

        assertThat(resultat.remarquesFormeRetirees()).isEqualTo(1);
        assertThat(score(feedback, "morphosyntaxe").get("commentaire"))
            .isEqualTo(EvaluationOralArtifactFilter.COMMENTAIRE_CRITERE_PURGE_FORME);
    }

    // ------------------------------------------------- ce qu'on ne purge pas

    /**
     * Une VRAIE faute de structure, citee sur trois mots pleins ou plus, reste
     * reprochee. C'est la frontiere : le volet retire des formes, pas des
     * structures.
     */
    @Test
    void conserve_un_reproche_de_structure_cite_sur_trois_mots_pleins() {
        Map<String, Object> feedback = feedback();
        String commentaire = "Erreurs perceptibles : « je vais toucher vraiment à l'ensemble » "
            + "est une construction fautive.";
        score(feedback, "morphosyntaxe").put("commentaire", commentaire);

        var resultat = EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION, false);

        assertThat(resultat.remarquesFormeRetirees()).isZero();
        assertThat(score(feedback, "morphosyntaxe").get("commentaire")).isEqualTo(commentaire);
    }

    /**
     * Une citation faite UNIQUEMENT de mots-outils (« et puis à ») ne nomme aucun
     * mot plein : c'est une structure pure, et le cas reel « pour ne pas que »
     * montre que ce sont de vrais reproches de grammaire. On les conserve.
     */
    @Test
    void conserve_un_reproche_cite_sur_des_mots_outils_seuls() {
        Map<String, Object> feedback = feedback();
        String commentaire = "La construction « pour ne pas que » est fautive : "
            + "on dit « pour éviter que ».";
        score(feedback, "morphosyntaxe").put("commentaire", commentaire);

        var resultat = EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION, false);

        assertThat(resultat.remarquesFormeRetirees()).isZero();
        assertThat(score(feedback, "morphosyntaxe").get("commentaire")).isEqualTo(commentaire);
    }

    /**
     * FAUX POSITIF MESURE 1 : « chronoposte » cite dans un reproche de LEXIQUE.
     * Une remarque de vocabulaire porte legitimement sur un mot ; le volet FORME
     * ne s'applique qu'a la grammaire.
     */
    @Test
    void ne_touche_jamais_un_reproche_de_lexique() {
        Map<String, Object> feedback = feedback();
        String commentaire = "Le terme « chronoposte express » est impropre : "
            + "on dit « Chronopost ».";
        score(feedback, "lexique").put("commentaire", commentaire);

        var resultat = EvaluationOralArtifactFilter.purge(
            feedback, TRANSCRIPTION_AVEC_SIGLES, false);

        assertThat(resultat.remarquesFormeRetirees()).isZero();
        assertThat(score(feedback, "lexique").get("commentaire")).isEqualTo(commentaire);
    }

    /**
     * FAUX POSITIF MESURE 2 : « ESN » cite en POINT FORT. Le volet FORME ne
     * regarde ni {@code points_forts} ni {@code suggestions}.
     */
    @Test
    void ne_touche_jamais_un_point_fort_qui_cite_un_sigle() {
        Map<String, Object> feedback = feedback();
        String pointFort = "Vocabulaire professionnel précis : « ESN parisienne » est "
            + "employé à bon escient.";
        feedback.put("points_forts", new ArrayList<>(List.of(pointFort)));

        EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION_AVEC_SIGLES, false);

        assertThat(feedback.get("points_forts"))
            .asInstanceOf(InstanceOfAssertFactories.list(String.class))
            .containsExactly(pointFort);
    }

    /** Un conseil de grammaire qui cite un mot SANS rien reprocher est conserve. */
    @Test
    void conserve_un_conseil_de_grammaire_qui_ne_reproche_rien() {
        Map<String, Object> feedback = feedback();
        String commentaire = "Le conditionnel « j'aimerais » est employé correctement, "
            + "à plusieurs reprises.";
        score(feedback, "morphosyntaxe").put("commentaire", commentaire);

        var resultat = EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION, false);

        assertThat(resultat.aPurge()).isFalse();
        assertThat(score(feedback, "morphosyntaxe").get("commentaire")).isEqualTo(commentaire);
    }

    /** Un reproche de grammaire qui ne cite RIEN de la production n'est pas ancre. */
    @Test
    void conserve_un_reproche_dont_la_citation_n_est_pas_dans_la_production() {
        Map<String, Object> feedback = feedback();
        String commentaire = "La forme « les enfant » serait incorrecte au pluriel.";
        score(feedback, "morphosyntaxe").put("commentaire", commentaire);

        var resultat = EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION, false);

        assertThat(resultat.aPurge()).isFalse();
        assertThat(score(feedback, "morphosyntaxe").get("commentaire")).isEqualTo(commentaire);
    }

    // ------------------------------------------------ transcription degradee

    /**
     * Transcription mesuree DEGRADEE : le correcteur n'a pas lu ce que le
     * candidat a dit, donc AUCUN reproche de grammaire ancre n'est opposable —
     * meme cite sur une structure complete.
     */
    @Test
    void sur_une_transcription_degradee_tout_reproche_de_grammaire_ancre_tombe() {
        Map<String, Object> feedback = feedback();
        score(feedback, "morphosyntaxe").put("commentaire",
            "Erreurs perceptibles : « je vais toucher vraiment à l'ensemble » est fautif.");

        var resultat = EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION, true);

        assertThat(resultat.remarquesFormeRetirees()).isEqualTo(1);
    }

    /** Meme en mode degrade, le lexique reste intact : on ne purge que la grammaire. */
    @Test
    void meme_degradee_la_transcription_ne_fait_pas_purger_le_lexique() {
        Map<String, Object> feedback = feedback();
        String commentaire = "Le terme « start up » est impropre ici, on dit « start-up ».";
        score(feedback, "lexique").put("commentaire", commentaire);

        EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION, true);

        assertThat(score(feedback, "lexique").get("commentaire")).isEqualTo(commentaire);
    }

    // ------------------------------------------------------ points a ameliorer

    /** Une priorite qui relit le reproche de grammaire suit le meme sort. */
    @Test
    void purge_une_priorite_de_grammaire_batie_sur_une_forme_mal_transcrite() {
        Map<String, Object> feedback = feedback();
        feedback.put("points_a_ameliorer", new ArrayList<>(List.of(new LinkedHashMap<>(Map.of(
            "constat", "L'accord du verbe est fautif dans « abit à Lille ».",
            "comment", "Révisez la conjugaison du présent.")))));

        var resultat = EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION, false);

        assertThat(resultat.remarquesFormeRetirees()).isPositive();
        assertThat(feedback.get("points_a_ameliorer"))
            .asInstanceOf(InstanceOfAssertFactories.LIST).isEmpty();
    }

    /**
     * Une priorite de CONTENU qui cite un passage court n'est pas touchee : rien
     * ne la rattache au critere de grammaire.
     */
    @Test
    void ne_touche_pas_une_priorite_de_contenu_qui_cite_un_passage_court() {
        Map<String, Object> feedback = feedback();
        Map<String, Object> priorite = new LinkedHashMap<>(Map.of(
            "constat", "Il manque un exemple concret après « chaque samedi ».",
            "comment", "Ajoutez une phrase qui illustre votre propos."));
        feedback.put("points_a_ameliorer", new ArrayList<>(List.of(priorite)));

        var resultat = EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION, false);

        assertThat(resultat.remarquesFormeRetirees()).isZero();
        assertThat(feedback.get("points_a_ameliorer"))
            .asInstanceOf(InstanceOfAssertFactories.LIST).hasSize(1);
    }

    // ------------------------------------------------------------- fixtures

    private static Map<String, Object> feedback() {
        Map<String, Object> f = new LinkedHashMap<>();
        List<Map<String, Object>> scores = new ArrayList<>();
        for (String code : List.of("communiquer", "interagir", "lexique", "morphosyntaxe")) {
            Map<String, Object> s = new LinkedHashMap<>();
            s.put("code", code);
            s.put("note_sur_20", 6);
            s.put("commentaire", "Commentaire neutre sur " + code + ".");
            scores.add(s);
        }
        f.put("scores_criteres", scores);
        f.put("points_forts", new ArrayList<>());
        f.put("suggestions", new ArrayList<>());
        f.put("points_a_ameliorer", new ArrayList<>());
        f.put("exemples_corriges", new ArrayList<>());
        return f;
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> score(Map<String, Object> feedback, String code) {
        for (Object raw : (List<Object>) feedback.get("scores_criteres")) {
            Map<String, Object> s = (Map<String, Object>) raw;
            if (code.equals(s.get("code"))) return s;
        }
        throw new IllegalStateException("critere absent : " + code);
    }
}

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

    // ============================================================ volet LANGUE
    // Verbatims REELS, releves dans les 5 evaluations EO fautives en base
    // (2026-08-07). La cause est le transcripteur temps reel, qui change de
    // langue tout seul : 6 transcriptions realtime sur 39 portent une ecriture
    // non latine, contre 0 sur 36 cote Whisper.

    /** Verbatim reel, champ {@code suggestions}. */
    @Test
    void purge_une_suggestion_qui_reproche_une_autre_langue() {
        Map<String, Object> feedback = feedback();
        feedback.put("suggestions", new ArrayList<>(List.of(
            "Éviter de passer à une autre langue pendant l'épreuve : rester en français "
                + "même si c'est difficile.",
            "Entraînez-vous à relier deux idées avec « parce que ».")));

        var resultat = EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION_NEERLANDAIS);

        assertThat(resultat.remarquesLangueRetirees()).isEqualTo(1);
        assertThat(feedback.get("suggestions")).asInstanceOf(
            org.assertj.core.api.InstanceOfAssertFactories.list(String.class))
            .containsExactly("Entraînez-vous à relier deux idées avec « parce que ».");
    }

    /** Verbatim reel, commentaire de critere. La phrase saine est conservee. */
    @Test
    void purge_un_commentaire_qui_impute_une_langue_etrangere_au_candidat() {
        Map<String, Object> feedback = feedback();
        score(feedback, "communiquer").put("commentaire",
            "Le propos suit un fil clair du début à la fin. "
                + "Plusieurs passages sont inaudibles ou en langue étrangère, ce qui bloque "
                + "la communication.");

        EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION_NEERLANDAIS);

        assertThat(score(feedback, "communiquer").get("commentaire"))
            .isEqualTo("Le propos suit un fil clair du début à la fin.");
    }

    /**
     * Verbatim reel, et le piege de decoupage qu'il porte : la citation contient
     * un point (« 'Ja. Dus kan nog...' »). Un decoupage naif coupait la phrase en
     * deux, purgeait la premiere moitie et rendait le debris au candidat.
     */
    @Test
    void purge_la_phrase_entiere_meme_quand_la_citation_contient_un_point() {
        Map<String, Object> feedback = feedback();
        score(feedback, "interagir").put("commentaire",
            "Un passage en néerlandais ('Ja. Dus kan nog sorteer de weekenden') qui interrompt "
                + "la communication en français. L'échange reste globalement conduit.");

        EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION_NEERLANDAIS);

        assertThat(score(feedback, "interagir").get("commentaire"))
            .isEqualTo("L'échange reste globalement conduit.");
    }

    /** Verbatim reel, dans une priorite : elle ne tenait que par l'artefact. */
    @Test
    void supprime_une_priorite_entiere_batie_sur_un_reproche_de_langue() {
        Map<String, Object> feedback = feedback();
        feedback.put("points_a_ameliorer", new ArrayList<>(List.of(
            new LinkedHashMap<>(Map.of(
                "constat", "Propos très décousu : le candidat passe d'une idée à l'autre, "
                    + "avec des passages en russe et des bruits.",
                "comment", "Rester en français du début à la fin.")),
            new LinkedHashMap<>(Map.of(
                "constat", "Vos idées sont juxtaposées.",
                "comment", "Reliez-les avec « parce que ».")))));

        EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION_CYRILLIQUE);

        assertThat(feedback.get("points_a_ameliorer")).asInstanceOf(
            org.assertj.core.api.InstanceOfAssertFactories.LIST)
            .hasSize(1)
            .allSatisfy(p -> assertThat(((Map<?, ?>) p).get("constat"))
                .isEqualTo("Vos idées sont juxtaposées."));
    }

    /** Commentaire integralement purge : phrase serveur PROPRE au volet langue. */
    @Test
    void remplace_un_commentaire_entierement_purge_par_la_phrase_de_langue() {
        Map<String, Object> feedback = feedback();
        score(feedback, "lexique").put("commentaire",
            "Le candidat bascule en anglais à plusieurs reprises.");

        EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION_NEERLANDAIS);

        assertThat(score(feedback, "lexique").get("commentaire"))
            .isEqualTo(EvaluationOralArtifactFilter.COMMENTAIRE_CRITERE_PURGE_LANGUE);
    }

    /** {@code points_forts} et {@code accomplissement.objectif_resume} sont couverts. */
    @Test
    void purge_aussi_les_points_forts_et_le_resume_d_objectif() {
        Map<String, Object> feedback = feedback();
        feedback.put("points_forts", new ArrayList<>(List.of(
            "Le message passe malgré le passage en néerlandais.",
            "Les questions sont posées dans l'ordre.")));
        Map<String, Object> accomplissement = new LinkedHashMap<>();
        accomplissement.put("objectif", "PARTIELLEMENT_ATTEINT");
        accomplissement.put("objectif_resume",
            "Tu poses tes questions, mais tu passes à une autre langue au milieu.");
        feedback.put("accomplissement", accomplissement);

        EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION_NEERLANDAIS);

        assertThat(feedback.get("points_forts")).asInstanceOf(
            org.assertj.core.api.InstanceOfAssertFactories.list(String.class))
            .containsExactly("Les questions sont posées dans l'ordre.");
        assertThat(accomplissement.get("objectif_resume"))
            .isEqualTo(EvaluationOralArtifactFilter.OBJECTIF_RESUME_PURGE_LANGUE);
        // Le VERDICT n'est jamais touche par ce filet.
        assertThat(accomplissement.get("objectif")).isEqualTo("PARTIELLEMENT_ATTEINT");
    }

    /** Verbatim reel, dans {@code exemples_corriges} : l'entree saute. */
    @Test
    void supprime_un_exemple_corrige_fonde_sur_un_reproche_de_langue() {
        Map<String, Object> feedback = feedback();
        feedback.put("exemples_corriges", new ArrayList<>(List.of(
            Map.of("original", "Ja. Dus kan nog sorteer de weekenden",
                "corrige", "Le week-end, je fais du sport.",
                "explication", "Suppression du passage en anglais et reformulation en français simple.",
                "gain", "un propos entièrement francophone"),
            Map.of("original", "je fais du sport", "corrige", "je fais du sport chaque samedi",
                "explication", "La précision de temps situe l'action.",
                "gain", "un repère temporel, attendu au B1"))));

        var resultat = EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION_NEERLANDAIS);

        assertThat(resultat.exemplesRetires()).isEqualTo(1);
        assertThat(feedback.get("exemples_corriges")).asInstanceOf(
            org.assertj.core.api.InstanceOfAssertFactories.LIST).hasSize(1);
    }

    // ------------------------------------------- LE GARDE-FOU : vraie bascule

    /**
     * <b>LE TEST QUI COMPTE.</b> Production du corpus de calibration
     * {@code EO_T3_PIEGE_01} : le candidat bascule REELLEMENT en espagnol. C'est
     * une non-realisation, elle doit remonter — rien n'est purge.
     *
     * <p>Mesure de cette production : 12,5 % de mots-outils etrangers, contre
     * 1,4 % au pire sur les 75 transcriptions reelles en base.
     */
    @Test
    void ne_purge_rien_quand_le_candidat_a_vraiment_bascule_de_langue() {
        Map<String, Object> feedback = feedback();
        String commentaire = "Le candidat bascule en espagnol dès la deuxième phrase : "
            + "la position n'est pas défendue en français.";
        score(feedback, "communiquer").put("commentaire", commentaire);
        feedback.put("suggestions", new ArrayList<>(List.of(
            "Éviter de passer à une autre langue pendant l'épreuve.")));

        var resultat = EvaluationOralArtifactFilter.purge(feedback, PRODUCTION_ESPAGNOLE);

        assertThat(resultat.remarquesLangueRetirees()).isZero();
        assertThat(score(feedback, "communiquer").get("commentaire")).isEqualTo(commentaire);
        assertThat(feedback.get("suggestions")).asInstanceOf(
            org.assertj.core.api.InstanceOfAssertFactories.LIST).hasSize(1);
    }

    /** Les DEUX cotes de la frontiere, sur des productions identiques a k mots pres. */
    @Test
    void la_frontiere_de_matiere_etrangere_est_franche() {
        // 6 mots-outils etrangers sur 106 = 5,7 % <= 6 % : artefact, on purge.
        assertThat(purgeLangue(productionAvecMotsEtrangers(6))).isTrue();
        // 10 sur 110 = 9,1 % > 6 % : bascule de langue, on ne purge plus.
        assertThat(purgeLangue(productionAvecMotsEtrangers(10))).isFalse();
    }

    /** Trace d'ecriture non latine = artefact ; ecriture non latine massive = non. */
    @Test
    void la_frontiere_d_ecriture_non_latine_est_franche() {
        assertThat(purgeLangue(TRANSCRIPTION_CYRILLIQUE)).isTrue();
        assertThat(purgeLangue(PRODUCTION_MASSIVEMENT_CYRILLIQUE)).isFalse();
    }

    /**
     * Production trop courte pour etre mesuree : on ne purge pas. Un seul token
     * y peserait plus que le seuil, et c'est justement la qu'une vraie bascule de
     * langue est la plus plausible.
     */
    @Test
    void ne_purge_rien_quand_la_production_est_trop_courte_pour_etre_mesuree() {
        assertThat(purgeLangue("Candidat : bonjour euh je sais pas euh désolé")).isFalse();
    }

    // -------------------------------------------- ce que le volet ne touche PAS

    /**
     * CONTRE-EXEMPLE REEL, et le bon comportement : quand la langue etrangere est
     * traitee comme une limite d'OBSERVATION, elle vit dans les raisons de
     * confiance. Ce champ n'est JAMAIS purge.
     */
    @Test
    void ne_purge_jamais_les_raisons_de_confiance() {
        Map<String, Object> feedback = feedback();
        List<String> raisons = new ArrayList<>(List.of(
            "Transcription temps réel partiellement incertaine (passages en russe et en "
                + "néerlandais, artefacts de reconnaissance vocale)"));
        feedback.put("confiance_raisons", raisons);

        EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION_CYRILLIQUE);

        assertThat(feedback.get("confiance_raisons")).isEqualTo(raisons);
    }

    /**
     * Une remarque de LEXIQUE FRANCAIS qui nomme un emprunt n'est pas un reproche
     * de langue : les marqueurs sont ancres sur « en &lt;langue&gt; », jamais sur le
     * seul nom de la langue.
     */
    @Test
    void ne_purge_pas_une_remarque_de_lexique_qui_nomme_un_emprunt() {
        Map<String, Object> feedback = feedback();
        String commentaire = "Le mot anglais « meeting » gagnerait à être remplacé par "
            + "« réunion ».";
        score(feedback, "lexique").put("commentaire", commentaire);

        var resultat = EvaluationOralArtifactFilter.purge(feedback, TRANSCRIPTION_NEERLANDAIS);

        assertThat(resultat.remarquesLangueRetirees()).isZero();
        assertThat(score(feedback, "lexique").get("commentaire")).isEqualTo(commentaire);
    }

    // -------------------------------------------------------------- fixtures

    /** Vrai si au moins une remarque de LANGUE a ete retiree pour cette production. */
    private static boolean purgeLangue(String production) {
        Map<String, Object> feedback = feedback();
        feedback.put("suggestions", new ArrayList<>(List.of(
            "Éviter de passer à une autre langue pendant l'épreuve.")));
        return EvaluationOralArtifactFilter.purge(feedback, production)
            .remarquesLangueRetirees() > 0;
    }

    /** Production francaise de 100 mots + {@code k} mots-outils etrangers. */
    private static String productionAvecMotsEtrangers(int k) {
        String[] etrangers = {"dus", "kan", "nog", "you", "the", "that", "porque", "muy",
            "however", "wenn"};
        StringBuilder sb = new StringBuilder("Candidat : ");
        for (int i = 0; i < 10; i++) {
            sb.append("je travaille beaucoup pendant la semaine et je fais du sport ");
        }
        sb.append('\n').append("Candidat :");
        for (int i = 0; i < k; i++) {
            sb.append(' ').append(etrangers[i % etrangers.length]);
        }
        return sb.toString();
    }

    /** Artefact neerlandais REEL au milieu d'une production francaise. */
    private static final String TRANSCRIPTION_NEERLANDAIS =
        "Examinateur : Bonjour, parlez-moi de votre week-end.\n"
            + "Candidat : oui alors moi je travaille beaucoup pendant la semaine et le samedi "
            + "je fais du sport avec mes amis, on va souvent à la piscine ou bien on joue au "
            + "football dans le parc à côté de chez moi\n"
            + "Candidat : Ja. Dus kan nog sorteer de weekenden\n"
            + "Examinateur : Et avec votre famille ?\n"
            + "Candidat : après on mange tous ensemble chez ma sœur qui habite juste à côté "
            + "et on regarde un film le dimanche soir avant de rentrer";

    /** Artefact cyrillique REEL (24 caracteres) au milieu d'une production francaise. */
    private static final String TRANSCRIPTION_CYRILLIQUE =
        "Examinateur : Bonjour, présentez-vous.\n"
            + "Candidat : bonjour je viens de arriver en France et je veux devenir français "
            + "parce que ma famille habite ici depuis longtemps et je travaille dans un "
            + "restaurant au centre de la ville\n"
            + "Candidat : КатеринекакварнаКатерине\n"
            + "Examinateur : Que faites-vous de vos journées ?\n"
            + "Candidat : je fais du sport le matin et après je vais au cours de français "
            + "avec les autres étudiants de mon quartier";

    /** Production reellement redigee en cyrillique : jamais purgee. */
    private static final String PRODUCTION_MASSIVEMENT_CYRILLIQUE =
        "Candidat : я хочу жить во Франции потому что моя семья живёт здесь уже давно "
            + "и я работаю в ресторане в центре города каждый день с утра до вечера "
            + "и мне очень нравится этот город bonjour merci";

    /**
     * Production du corpus de calibration {@code EO_T3_PIEGE_01}, recopiee telle
     * quelle : le candidat bascule VRAIMENT en espagnol. C'est la reference qui
     * fixe le seuil, on ne la retouche pas.
     */
    private static final String PRODUCTION_ESPAGNOLE =
        "euh alors euh le travail euh au bureau euh euh yo creo que euh es mejor euh trabajar "
            + "euh desde casa euh porque euh euh comment on dit euh euh el transporte euh es "
            + "muy euh cansado euh euh moi euh une heure euh le matin euh une heure euh le soir "
            + "euh euh y euh además euh en casa euh me concentro euh mucho euh mejor euh euh "
            + "pero euh también euh hay euh un problema euh porque euh la gente euh se siente "
            + "euh sola euh euh je sais pas euh comment dire euh en français euh désolé euh euh "
            + "entonces euh yo prefiero euh dos días euh en la oficina euh y euh tres días euh "
            + "en casa euh euh voilà euh";

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

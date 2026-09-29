package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.DouteValidite;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.ValiditeProduction;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Controles deterministes pre-LLM : langue dominante, recopiage de la consigne,
 * production vide. Chaque famille est testee avec un cas PASSANT et un cas
 * BLOQUANT — les seuils sont des heuristiques, la marge doit rester confortable
 * des deux cotes.
 */
class ProductionValidityServiceTest {

    private static final String CONSIGNE =
        "Vous venez d'emménager dans un nouvel appartement. Vous écrivez à un ami "
            + "pour lui annoncer la nouvelle, décrire votre logement et l'inviter à venir vous voir.";

    /** ~34 % de l'énoncé recopié, le reste en français personnel : AUTHENTICITE seule. */
    private static final String RECOPIAGE_PARTIEL =
        "Vous venez d'emménager dans un nouvel appartement. Vous écrivez à un ami "
            + "pour lui annoncer la nouvelle. Salut Paul, mon logement est clair et calme, il y a "
            + "deux chambres et une cuisine. Passe me voir dimanche si tu es libre, on mangera ensemble.";

    /** Français très minoritaire (~15 % de mots-outils), rien de recopié : OBSERVATION seule. */
    private static final String LANGUE_DOUTEUSE =
        "Hello Paul, I write you today about mon new apartment. Very nice place, big kitchen, "
            + "two bedrooms, small garden behind. Come visit next Saturday, we eat together, "
            + "je suis très content de la nouvelle.";

    /** Énoncé recopié PUIS poursuivi en anglais : les deux doutes à la fois. */
    private static final String RECOPIAGE_ET_LANGUE_DOUTEUSE =
        "Vous venez d'emménager dans un nouvel appartement. Vous écrivez à un ami "
            + "pour lui annoncer la nouvelle, décrire votre logement et l'inviter à venir vous voir. "
            + "Hello Paul, I moved last week to a new apartment near the station, very bright, "
            + "two bedrooms, big kitchen and a small garden behind the building. Come visit soon, "
            + "we will cook together and my neighbours are really friendly people, everything works "
            + "perfectly well here now in this city.";

    private final ProductionEvaluationProperties props = new ProductionEvaluationProperties();
    private final ProductionValidityService service = new ProductionValidityService(props);

    private static ProductionTask task(EpreuveType epreuve, int tache) {
        ProductionTask t = new ProductionTask();
        t.setEpreuve(epreuve);
        t.setTacheNumero((short) tache);
        t.setConsigne(CONSIGNE);
        return t;
    }

    // ------------------------------------------------------------------ langue

    @Test
    void production_francaise_courante_est_valide() {
        String texte = "Bonjour Marie, je t'écris pour te dire que j'ai enfin trouvé un "
            + "nouvel appartement dans le centre de la ville. Il est très joli et il y a "
            + "deux chambres avec un grand balcon. Je t'invite à venir le voir samedi prochain.";

        var verdict = service.evaluer(task(EpreuveType.TCF_EE, 1), texte);

        assertThat(verdict.statut()).isEqualTo(ValiditeProduction.VALIDE);
        assertThat(verdict.raisons()).isEmpty();
    }

    @Test
    void production_en_anglais_est_invalide() {
        String texte = "Hello Mary, I am writing to tell you that I finally found a new "
            + "apartment in the city center. It is very nice and it has two bedrooms with "
            + "a big balcony. I invite you to come and see it next Saturday.";

        var verdict = service.evaluer(task(EpreuveType.TCF_EE, 1), texte);

        assertThat(verdict.statut()).isEqualTo(ValiditeProduction.INVALIDE);
        assertThat(verdict.raisons()).anyMatch(r -> r.contains("n'est pas rédigé en français"));
    }

    @Test
    void production_en_alphabet_non_latin_est_invalide() {
        String texte = "مرحبا ماري، أكتب إليك لأخبرك أنني وجدت أخيرا شقة جديدة في وسط "
            + "المدينة. إنها جميلة جدا وفيها غرفتان مع شرفة كبيرة.";

        var verdict = service.evaluer(task(EpreuveType.TCF_EE, 1), texte);

        assertThat(verdict.statut()).isEqualTo(ValiditeProduction.INVALIDE);
        assertThat(verdict.raisons()).anyMatch(r -> r.contains("un autre alphabet"));
    }

    @Test
    void texte_court_sous_le_seuil_d_analyse_n_est_pas_juge_sur_la_langue() {
        // 6 mots : au-dessus du minimum exploitable (5), sous le seuil d'analyse
        // de la langue (12) -> aucun verdict sur la langue.
        var verdict = service.evaluer(task(EpreuveType.TCF_EE, 1), "Hello Mary how are you today");

        assertThat(verdict.statut()).isEqualTo(ValiditeProduction.VALIDE);
    }

    // ------------------------------------------------- plancher du diagnostic

    /**
     * LE CAS MESURE EN BASE : 4 secondes d'audio, 7 caracteres transcrits. Le
     * plancher generique (5 mots) le refusait deja — c'est le juge qui n'etait
     * pas appele sur la voie diagnostic.
     */
    @Test
    void une_transcription_de_quatre_secondes_est_invalide_pour_le_diagnostic() {
        var verdict = service.evaluerDiagnostic(task(EpreuveType.TCF_EO, 3), "Bonjour.");

        assertThat(verdict.statut()).isEqualTo(ValiditeProduction.INVALIDE);
        assertThat(verdict.raisons()).anyMatch(r -> r.contains("vide ou trop courte"));
    }

    /**
     * Le plancher du DIAGNOSTIC est plus haut que le plancher generique, parce
     * que sa consequence l'est : cette production fixe le niveau d'un DOMAINE
     * entier. Huit mots suffisent pour commenter un entrainement, pas pour
     * situer un palier.
     */
    @Test
    void le_plancher_du_diagnostic_est_plus_haut_que_le_plancher_generique() {
        String huitMots = "Je vais bien et je suis content aujourd'hui";

        assertThat(service.evaluer(task(EpreuveType.TCF_EO, 3), huitMots).statut())
            .isEqualTo(ValiditeProduction.VALIDE);
        assertThat(service.evaluerDiagnostic(task(EpreuveType.TCF_EO, 3), huitMots).statut())
            .isEqualTo(ValiditeProduction.INVALIDE);
    }

    /**
     * LE FAUX POSITIF EST LE RISQUE PRINCIPAL. Un A1 authentique produit peu :
     * une production nettement plus courte que les 100-120 mots demandes doit
     * rester analysee. La frontiere n'est pas « c'est mauvais », c'est « il n'y
     * a rien a observer ».
     */
    @Test
    void une_production_courte_mais_reelle_reste_analysee_par_le_diagnostic() {
        String vingtCinqMots = "Bonjour, je voudrais savoir les horaires de la piscine et "
            + "aussi le tarif pour les enfants, parce que je viens avec ma fille le samedi.";

        var verdict = service.evaluerDiagnostic(task(EpreuveType.TCF_EO, 3), vingtCinqMots);

        assertThat(verdict.invalide()).isFalse();
    }

    // -------------------------------------------------------------------- vide

    @Test
    void production_vide_est_invalide() {
        var verdict = service.evaluer(task(EpreuveType.TCF_EE, 1), "   \n  ");

        assertThat(verdict.statut()).isEqualTo(ValiditeProduction.INVALIDE);
        assertThat(verdict.raisons()).anyMatch(r -> r.contains("vide ou trop courte"));
    }

    @Test
    void production_quasi_vide_est_invalide() {
        var verdict = service.evaluer(task(EpreuveType.TCF_EE, 1), "Bonjour merci");

        assertThat(verdict.statut()).isEqualTo(ValiditeProduction.INVALIDE);
    }

    @Test
    void dialogue_sans_tour_candidat_exploitable_est_invalide() {
        String dialogue = """
            Examinateur : Bonjour, pouvez-vous vous présenter en quelques mots ?
            Candidat : euh
            Examinateur : Prenez votre temps, parlez-moi de votre travail et de votre ville.
            """;

        var verdict = service.evaluer(task(EpreuveType.TCF_EO, 1), dialogue);

        assertThat(verdict.statut()).isEqualTo(ValiditeProduction.INVALIDE);
        assertThat(verdict.raisons()).anyMatch(r -> r.contains("aucune prise de parole"));
    }

    @Test
    void dialogue_avec_tours_candidat_est_valide() {
        String dialogue = """
            Examinateur : Bonjour, pouvez-vous vous présenter ?
            Candidat : Bonjour, je m'appelle Karim et je viens du Maroc. Je travaille comme
            cuisinier dans un restaurant à Lyon depuis deux ans.
            Examinateur : Et que faites-vous pendant votre temps libre ?
            Candidat : J'aime beaucoup faire du sport avec mes amis et je vais souvent au cinéma.
            """;

        var verdict = service.evaluer(task(EpreuveType.TCF_EO, 1), dialogue);

        assertThat(verdict.statut()).isEqualTo(ValiditeProduction.VALIDE);
    }

    @Test
    void dialogue_les_mots_de_l_examinateur_ne_comptent_pas() {
        // Seul l'examinateur parle francais ; le candidat repond en anglais.
        String dialogue = """
            Examinateur : Bonjour, pouvez-vous vous présenter et me parler de votre travail ?
            Candidat : Hello, my name is John and I work as a cook in a restaurant downtown
            since two years, I really like my job and my colleagues there.
            """;

        var verdict = service.evaluer(task(EpreuveType.TCF_EO, 1), dialogue);

        assertThat(verdict.statut()).isEqualTo(ValiditeProduction.INVALIDE);
        assertThat(verdict.raisons()).anyMatch(r -> r.contains("n'est pas rédigé en français"));
    }

    // --------------------------------------------------------------- recopiage

    @Test
    void consigne_recopiee_integralement_est_invalide() {
        var verdict = service.evaluer(task(EpreuveType.TCF_EE, 1), CONSIGNE);

        assertThat(verdict.statut()).isEqualTo(ValiditeProduction.INVALIDE);
        assertThat(verdict.raisons()).anyMatch(r -> r.contains("mot pour mot"));
    }

    @Test
    void recopiage_partiel_de_la_consigne_declenche_un_avertissement() {
        // ~34 % de la production recopie l'enonce : evaluable, mais signale.
        var verdict = service.evaluer(task(EpreuveType.TCF_EE, 1), RECOPIAGE_PARTIEL);

        assertThat(verdict.statut()).isEqualTo(ValiditeProduction.AVERTISSEMENT);
        assertThat(verdict.raisons()).anyMatch(r -> r.contains("recopie l'énoncé"));
    }

    // ------------------------------------------------------- nature du doute

    /**
     * LA distinction : recopier l'énoncé n'empêche pas d'observer la langue du
     * candidat (on écarte les mots recopiés, le reste se lit très bien). C'est
     * un doute d'AUTHENTICITE, jamais d'observation — donc il ne plafonne pas
     * la confiance de la correction (cf. {@code AiEvaluationService}).
     */
    @Test
    void le_recopiage_est_un_doute_d_authenticite_pas_d_observation() {
        var verdict = service.evaluer(task(EpreuveType.TCF_EE, 1), RECOPIAGE_PARTIEL);

        assertThat(verdict.statut()).isEqualTo(ValiditeProduction.AVERTISSEMENT);
        assertThat(verdict.doutes()).containsExactly(DouteValidite.AUTHENTICITE);
        assertThat(verdict.douteObservation()).isFalse();
    }

    /** Une langue à moitié étrangère, elle, empêche vraiment d'observer. */
    @Test
    void une_langue_douteuse_est_un_doute_d_observation() {
        var verdict = service.evaluer(task(EpreuveType.TCF_EE, 1), LANGUE_DOUTEUSE);

        assertThat(verdict.statut()).isEqualTo(ValiditeProduction.AVERTISSEMENT);
        assertThat(verdict.doutes()).containsExactly(DouteValidite.OBSERVATION);
        assertThat(verdict.douteObservation()).isTrue();
    }

    /** Les deux à la fois : l'obstacle à l'observation reste, donc il compte. */
    @Test
    void les_deux_doutes_cumules_gardent_l_obstacle_a_l_observation() {
        var verdict = service.evaluer(task(EpreuveType.TCF_EE, 1), RECOPIAGE_ET_LANGUE_DOUTEUSE);

        assertThat(verdict.statut()).isEqualTo(ValiditeProduction.AVERTISSEMENT);
        assertThat(verdict.doutes())
            .containsExactlyInAnyOrder(DouteValidite.OBSERVATION, DouteValidite.AUTHENTICITE);
        assertThat(verdict.douteObservation()).isTrue();
    }

    @Test
    void une_production_valide_ne_porte_aucun_doute() {
        String texte = "Salut Paul ! J'ai une bonne nouvelle : j'ai enfin déménagé la semaine "
            + "dernière. Mon logement se trouve près de la gare, il est lumineux et calme.";

        var verdict = service.evaluer(task(EpreuveType.TCF_EE, 1), texte);

        assertThat(verdict.doutes()).isEmpty();
        assertThat(verdict.douteObservation()).isFalse();
    }

    @Test
    void production_personnelle_ne_declenche_aucun_recopiage() {
        String texte = "Salut Paul ! J'ai une bonne nouvelle : j'ai enfin déménagé la semaine "
            + "dernière. Mon logement se trouve près de la gare, il est lumineux et il y a un "
            + "petit jardin derrière. Viens passer le week-end quand tu veux, il y a de la place.";

        var verdict = service.evaluer(task(EpreuveType.TCF_EE, 1), texte);

        assertThat(verdict.statut()).isEqualTo(ValiditeProduction.VALIDE);
    }

    @Test
    void consigne_absente_desactive_le_controle_de_recopiage() {
        ProductionTask t = task(EpreuveType.TCF_EE, 1);
        t.setConsigne(null);

        var verdict = service.evaluer(t, CONSIGNE);

        assertThat(verdict.statut()).isEqualTo(ValiditeProduction.VALIDE);
    }

    // ------------------------------------------------------------- primitives

    @Test
    void toursDuCandidat_ne_garde_que_les_repliques_du_candidat() {
        String dialogue = """
            Examinateur : Question une ?
            Candidat : Réponse une.
            suite de la réponse une.
            Examinateur : Question deux ?
            Candidat : Réponse deux.
            """;

        String candidat = ProductionValidityService.toursDuCandidat(dialogue);

        assertThat(candidat).contains("Réponse une.", "suite de la réponse une.", "Réponse deux.");
        assertThat(candidat).doesNotContain("Question une", "Question deux");
    }

    @Test
    void motsNormalises_deplie_les_elisions_et_retire_les_accents() {
        assertThat(ProductionValidityService.motsNormalises("L'été, à Paris !"))
            .containsExactly("l", "ete", "a", "paris");
    }

    @Test
    void ratioRecopiage_est_nul_quand_les_textes_sont_plus_courts_que_le_ngramme() {
        assertThat(ProductionValidityService.ratioRecopiage(
            ProductionValidityService.motsNormalises("un deux trois"), "un deux trois", 5))
            .isZero();
    }

    // ------------------------------------------------ mots-outils ETRANGERS

    @Test
    void ratioMotsEtrangers_est_nul_sur_du_francais_courant() {
        assertThat(ProductionValidityService.ratioMotsEtrangers(
            ProductionValidityService.motsNormalises(
                "Je travaille beaucoup pendant la semaine et le week-end je fais du sport "
                    + "avec mes amis, on va souvent à la piscine.")))
            .isZero();
    }

    @Test
    void ratioMotsEtrangers_compte_les_mots_outils_d_une_autre_langue() {
        assertThat(ProductionValidityService.ratioMotsEtrangers(
            ProductionValidityService.motsNormalises("dus kan nog")))
            .isEqualTo(1.0);
    }

    /**
     * INVARIANT DE COMPOSITION — les deux listes doivent rester disjointes. Un
     * mot present des deux cotes ferait monter la « matiere etrangere » d'une
     * production francaise banale et desactiverait la purge de
     * {@link EvaluationOralArtifactFilter}. Cf. le javadoc de
     * {@code MOTS_OUTILS_ETRANGERS}.
     */
    @Test
    void aucun_mot_outil_etranger_n_est_aussi_un_mot_outil_francais() {
        assertThat(ProductionValidityService.MOTS_OUTILS_ETRANGERS)
            .doesNotContainAnyElementsOf(ProductionValidityService.MOTS_OUTILS_FR);
    }

    /** Meme invariant, cote longueur : en dessous de 3 lettres, c'est du debris. */
    @Test
    void les_mots_outils_etrangers_font_au_moins_trois_lettres() {
        assertThat(ProductionValidityService.MOTS_OUTILS_ETRANGERS)
            .allSatisfy(mot -> assertThat(mot).hasSizeGreaterThanOrEqualTo(3));
    }

    /**
     * Ces mots sont recherches sous leur forme NORMALISEE : un accent ou une
     * apostrophe dans la liste ne pourrait jamais matcher.
     */
    @Test
    void les_mots_outils_etrangers_sont_deja_normalises() {
        assertThat(ProductionValidityService.MOTS_OUTILS_ETRANGERS)
            .allSatisfy(mot -> assertThat(ProductionValidityService.motsNormalises(mot))
                .containsExactly(mot));
    }
}

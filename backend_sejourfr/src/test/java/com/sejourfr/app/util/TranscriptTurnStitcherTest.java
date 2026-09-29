package com.sejourfr.app.util;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Recollage des tours consecutifs d'un meme locuteur. Ce que verrouille cette
 * classe : ce qui fusionne, ce qui ne fusionne JAMAIS, la jonction, et le fait
 * que tout ce qui n'est pas une frontiere fusionnee ressort octet pour octet.
 */
class TranscriptTurnStitcherTest {

    private static TranscriptTurnStitcher stitcher(boolean enabled) {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.getRecollageTours().setEnabled(enabled);
        return new TranscriptTurnStitcher(props);
    }

    private static String stitch(String transcript) {
        return stitcher(true).stitch(transcript);
    }

    // --------------------------------------------------------------- fusion

    @Test
    void deux_tours_candidat_consecutifs_sont_recolles() {
        String brut = """
            Examinateur : Bonjour, je vous écoute.
            Candidat : Je voudrais louer une voiture
            Candidat : si vous en avez s'il vous plaît.""";

        assertThat(stitch(brut)).isEqualTo("""
            Examinateur : Bonjour, je vous écoute.
            Candidat : Je voudrais louer une voiture si vous en avez s'il vous plaît.""");
    }

    @Test
    void trois_tours_candidat_consecutifs_ne_font_plus_qu_un() {
        String brut = """
            Candidat : je suis un étudiant
            Candidat : guinéen à l'université
            Candidat : de Rennes.""";

        assertThat(stitch(brut))
            .isEqualTo("Candidat : je suis un étudiant guinéen à l'université de Rennes.");
    }

    @Test
    void les_tours_de_l_examinateur_fusionnent_aussi_entre_eux() {
        String brut = """
            Examinateur : Voici la deuxième
            Examinateur : partie. Je suis le guichetier.
            Candidat : Bonjour.""";

        assertThat(stitch(brut)).isEqualTo("""
            Examinateur : Voici la deuxième partie. Je suis le guichetier.
            Candidat : Bonjour.""");
    }

    // ------------------------------------------------------ garde-fous durs

    @Test
    void un_tour_examinateur_intercale_coupe_net_la_fusion() {
        String brut = """
            Candidat : je voudrais une voiture
            Examinateur : Pour combien de jours ?
            Candidat : pour trois jours""";

        // Sans ce garde-fou, on fabriquerait « je voudrais une voiture pour
        // trois jours » : une phrase que le candidat n'a jamais dite d'un trait.
        assertThat(stitch(brut)).isEqualTo(brut);
    }

    /**
     * Cas reel {@code f42873b7} (2026-08-04) : le candidat pose sa question,
     * puis la REPOSE. Deux tentatives distinctes — les coller donnerait une
     * prise de parole que personne n'a faite.
     */
    @Test
    void une_phrase_achevee_suivie_d_un_nouveau_depart_ne_fusionne_pas() {
        String brut = """
            Candidat : oui, j'aimerais savoir c'est quoi le tarif de l'abonnement s'il vous plaît.
            Candidat : Oui, c'est quoi le tarif de l'abonnement.""";

        assertThat(stitch(brut)).isSameAs(brut);
    }

    /** Cas reel {@code bb227368} (2026-07-12). */
    @Test
    void une_phrase_achevee_suivie_d_une_majuscule_ne_fusionne_pas_meme_sur_du_bruit() {
        String brut = """
            Candidat : Je veux devenir français.
            Candidat : No similar.""";

        assertThat(stitch(brut)).isSameAs(brut);
    }

    /**
     * Le garde-fou exige les DEUX conditions. La fragmentation qu'on corrige
     * laisse presque toujours le second morceau en minuscule : c'est le cas
     * cible, il doit continuer de fusionner.
     */
    @Test
    void une_ponctuation_forte_suivie_d_une_minuscule_fusionne_toujours() {
        String brut = """
            Candidat : qui m'ont poussé à l'air. Ah.
            Candidat : aller vers l'informatique.""";

        assertThat(stitch(brut))
            .isEqualTo("Candidat : qui m'ont poussé à l'air. Ah. aller vers l'informatique.");
    }

    @Test
    void une_majuscule_sans_ponctuation_forte_fusionne_toujours() {
        // Fin de fragment sans ponctuation : la phrase n'est pas achevee, la
        // majuscule est celle d'un nom propre ou d'un artefact de transcription.
        String brut = """
            Candidat : je voudrais aller à
            Candidat : Perpignan le week-end prochain.""";

        assertThat(stitch(brut))
            .isEqualTo("Candidat : je voudrais aller à Perpignan le week-end prochain.");
    }

    /**
     * Cas reel {@code 2e598209} (2026-08-05) : sans ce garde-fou, la vraie
     * reponse du candidat repartait derriere « . . . . ».
     */
    @Test
    void un_fragment_sans_aucun_alphanumerique_reste_un_tour_isole() {
        String brut = """
            Candidat : Qui
            Candidat : . . . .
            Candidat : une star top, je vais pouvoir toucher à tout.""";

        // Ni absorbe a gauche, ni absorbe a droite — et pas retire non plus :
        // le recollage n'enleve que des frontieres, jamais du contenu.
        assertThat(stitch(brut)).isSameAs(brut);
    }

    @Test
    void un_transcript_deja_propre_ressort_strictement_inchange() {
        String brut = """
            Examinateur : Bonjour, présentez-vous.
            Candidat : Bonjour, je m'appelle Amina et j'habite à Lyon.
            Examinateur : Merci, et que faites-vous ?
            Candidat : Je suis infirmière dans un hôpital public.""";

        assertThat(stitch(brut)).isSameAs(brut);
    }

    @Test
    void un_monologue_sans_marqueur_de_tour_ressort_strictement_inchange() {
        // Transcription Whisper (voie asynchrone) : aucun role explicite.
        String brut = "Je vais vous parler de mon quartier. Il est calme.\n"
            + "J'y habite depuis trois ans avec ma famille.";

        assertThat(stitch(brut)).isSameAs(brut);
    }

    @Test
    void le_drapeau_eteint_rend_l_entree_a_l_identique() {
        String brut = """
            Candidat : Je voudrais louer une voiture
            Candidat : si vous en avez s'il vous plaît.""";

        assertThat(stitcher(false).stitch(brut)).isSameAs(brut);
    }

    @Test
    void un_texte_vide_ou_null_traverse_sans_bruit() {
        assertThat(stitch(null)).isNull();
        assertThat(stitch("   ")).isEqualTo("   ");
    }

    @Test
    void les_mots_coupes_en_deux_ne_sont_jamais_repares() {
        // Bug de transcription corrige en amont le 2026-07-04 : les espaces
        // parasites sont DANS la donnee. Les deviner serait une reecriture.
        String brut = """
            Candidat : Je vou
            Candidat : drais sa voir le type de voi ture""";

        assertThat(stitch(brut)).isEqualTo("Candidat : Je vou drais sa voir le type de voi ture");
    }

    // ------------------------------------------------------------- jonction

    @Test
    void une_ponctuation_forte_de_fin_de_fragment_est_conservee() {
        // Cas reel : « … poussé à l'air. Ah. » / « aller vers l'informatique. »
        // La retirer serait un pari sur ce que le candidat a dit ; la garder
        // n'a aucun effet sur les preuves (le matcher ne tokenise pas la
        // ponctuation).
        String brut = """
            Candidat : qui m'ont poussé à l'air. Ah.
            Candidat : aller vers l'informatique.""";

        assertThat(stitch(brut))
            .isEqualTo("Candidat : qui m'ont poussé à l'air. Ah. aller vers l'informatique.");
    }

    @Test
    void aucun_espace_devant_une_ponctuation_collee_a_gauche() {
        String brut = """
            Candidat : des berlines
            Candidat : , des SUV.""";

        assertThat(stitch(brut)).isEqualTo("Candidat : des berlines, des SUV.");
    }

    @Test
    void aucun_espace_apres_une_elision_ou_un_trait_d_union() {
        assertThat(stitch("Candidat : Je suis l'\nCandidat : employé de l'agence"))
            .isEqualTo("Candidat : Je suis l'employé de l'agence");
        assertThat(stitch("Candidat : Est-ce que vous avez rendez-\nCandidat : vous demain ?"))
            .isEqualTo("Candidat : Est-ce que vous avez rendez-vous demain ?");
    }

    @Test
    void aucune_ponctuation_n_est_inventee_a_la_jonction() {
        String recolle = stitch("Candidat : je travaille\nCandidat : dans un hôpital");

        assertThat(recolle).isEqualTo("Candidat : je travaille dans un hôpital");
        assertThat(recolle).doesNotContain(".").doesNotContain(",");
    }

    @Test
    void les_espaces_de_la_frontiere_ne_produisent_jamais_d_espace_double() {
        String brut = "Candidat : je travaille   \n   Candidat :    dans un hôpital";

        assertThat(stitch(brut)).isEqualTo("Candidat : je travaille dans un hôpital");
    }

    @Test
    void un_tour_vide_ne_laisse_ni_espace_en_trop_ni_mot_colle() {
        assertThat(stitch("Candidat :\nCandidat : bonjour madame"))
            .isEqualTo("Candidat : bonjour madame");
        assertThat(stitch("Candidat : bonjour madame\nCandidat :\nExaminateur : Bonjour."))
            .isEqualTo("Candidat : bonjour madame\nExaminateur : Bonjour.");
    }

    @Test
    void seule_la_frontiere_fusionnee_change_le_reste_est_identique() {
        String brut = """
            Examinateur : Bonjour, bienvenue à la mairie, je vous écoute.
            Candidat : bonjour madame je voudrais des renseignements
            Candidat : pour une inscription
            Examinateur : Très bien, pour qui souhaitez-vous inscrire ?
            Candidat : pour ma fille elle a six ans""";

        assertThat(stitch(brut)).isEqualTo("""
            Examinateur : Bonjour, bienvenue à la mairie, je vous écoute.
            Candidat : bonjour madame je voudrais des renseignements pour une inscription
            Examinateur : Très bien, pour qui souhaitez-vous inscrire ?
            Candidat : pour ma fille elle a six ans""");
    }
}

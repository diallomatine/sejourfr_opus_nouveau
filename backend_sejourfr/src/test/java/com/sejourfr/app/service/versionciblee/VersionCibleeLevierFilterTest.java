package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.enums.TargetLevel;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FILET « levier {@code version_ciblee.ce_qui_manque} qui vend un moyen A2 comme
 * la marche vers le palier visé ».
 *
 * <p>Les verbatims marqués <b>RÉEL</b> viennent de la base : les deux seuls blocs
 * {@code version_ciblee} livrés, six leviers au total, dont <b>un</b> porte la
 * violation. Les autres sont les faux positifs à ne jamais produire — dont un
 * verbatim de notre propre ancre few-shot.
 */
class VersionCibleeLevierFilterTest {

    // ------------------------------------------------------- ce qui est purgé

    /**
     * LE DÉFAUT SIGNALÉ, verbatim, dans un bloc {@code niveau_vise: B1}. « et » et
     * « mais » sont classés A2 par notre propre rubrique, qui exige justement,
     * pour dépasser A2, des connecteurs « au-delà de et / mais / parce que /
     * après / aussi ». Le levier était structurellement incapable de faire
     * progresser le candidat.
     */
    @Test
    @DisplayName("RÉEL : « Relier les phrases avec des connecteurs simples : « et », « mais », « donc » »")
    void levierQuiProposeEtEtMaisPourAtteindreLeB1_estRetire() {
        String fautif = "Relier les phrases avec des connecteurs simples : « et », « mais », "
            + "« donc » au lieu de juxtaposer des idées sans lien.";

        var resultat = VersionCibleeLevierFilter.purge(List.of(fautif,
            "Préciser le lexique : « jolie » remplace « belle ».",
            "Introduire une nuance entre l'apparence et le caractère."), TargetLevel.B1);

        assertThat(resultat.retires()).containsExactly(fautif);
        assertThat(resultat.gardes()).hasSize(2);
    }

    /** « parce que » désigné comme le moyen d'atteindre le B2 : même défaut. */
    @Test
    void levierQuiProposeParceQuePourAtteindreLeB2_estRetire() {
        String fautif = "Relier les deux idées avec « parce que » pour justifier votre choix.";

        var resultat = VersionCibleeLevierFilter.purge(
            List.of(fautif, "Annoncer une objection puis y répondre."), TargetLevel.B2);

        assertThat(resultat.retires()).containsExactly(fautif);
        assertThat(resultat.gardes()).hasSize(1);
    }

    /** Sans citation : le mot de désignation suffit pour « parce que ». */
    @Test
    void levierQuiEmploieParceQueSansGuillemets_estRetire() {
        String fautif = "Employer parce que pour relier vos deux phrases sur le déménagement.";

        assertThat(VersionCibleeLevierFilter.purge(List.of(fautif, "Autre levier."), TargetLevel.B1)
            .retires()).containsExactly(fautif);
    }

    // -------------------------------------------------- ce qui n'est PAS purgé

    /**
     * FAUX POSITIF À NE JAMAIS PRODUIRE — c'est l'ANCRE FEW-SHOT de notre propre
     * prompt. Le « mais » y est cité pour dire ce qu'il faut arrêter de faire, et
     * le moyen recommandé (annoncer l'objection avant d'y répondre) est bien
     * au-dessus du A2. Une règle sans coupure au premier rejet aurait supprimé
     * notre propre contenu de référence.
     */
    @Test
    void ancreFewShot_quiCiteMaisPourLeRejeter_estConservee() {
        String legitime = "Annoncer l'objection avant d'y répondre : « On objectera que… ; c'est "
            + "vrai, mais… » au lieu de poser « mais » seul.";

        var resultat = VersionCibleeLevierFilter.purge(
            List.of(legitime, "Conditionner votre accord : « à condition que… »."), TargetLevel.B2);

        assertThat(resultat.retires()).isEmpty();
        assertThat(resultat.gardes()).hasSize(2);
    }

    /**
     * FAUX POSITIF À NE JAMAIS PRODUIRE, verbatim RÉEL du second bloc livré : la
     * citation CONTIENT un marqueur sans s'y réduire, et « car » n'est pas un
     * marqueur A2 (la grille le range parmi les connecteurs qui organisent le
     * propos).
     */
    @Test
    void levierReelQuiCiteUneTournureContenantMais_estConserve() {
        List<String> reels = List.of(
            "Relier les idées avec des connecteurs : « mais ce que j'apprécie surtout », "
                + "« car » remplacent les phrases courtes juxtaposées.",
            "Préciser le lexique : « jolie », « souriante », « on ne s'ennuie jamais » "
                + "remplacent « belle », « agréable », « je l'aime bien ».",
            "Introduire une nuance entre l'apparence et le caractère : « Physiquement… mais… » "
                + "structure la description en deux temps.");

        var resultat = VersionCibleeLevierFilter.purge(reels, TargetLevel.B1);

        assertThat(resultat.retires()).isEmpty();
        assertThat(resultat.gardes()).isEqualTo(reels);
    }

    /**
     * VISER A2 : « parce que » est alors EXACTEMENT le moyen à conseiller — une
     * ancre de la grille de notation l'ordonne. Rien n'est purgé.
     */
    @Test
    void versLeA2_unMarqueurA2EstLeBonConseil_rienNEstRetire() {
        List<String> leviers = List.of(
            "Relier vos deux idées avec « parce que » plutôt que de les juxtaposer.",
            "Employer « et » pour enchaîner les faits de la journée.");

        var resultat = VersionCibleeLevierFilter.purge(leviers, TargetLevel.A2);

        assertThat(resultat.retires()).isEmpty();
        assertThat(resultat.gardes()).isEqualTo(leviers);
    }

    /** Un vrai levier B1/B2 n'est jamais touché. */
    @Test
    void vraiLevierAuDessusDuA2_estConserve() {
        List<String> leviers = List.of(
            "Subordonner au lieu de juxtaposer : « mes horaires ne me le permettant pas ».",
            "Organiser le propos avec « d'abord », « en revanche », « c'est pourquoi ».");

        assertThat(VersionCibleeLevierFilter.purge(leviers, TargetLevel.B2).retires()).isEmpty();
    }

    /** Niveau visé absent : on ne peut rien conclure, donc on ne purge rien. */
    @Test
    void sansNiveauVise_rienNEstRetire() {
        List<String> leviers = List.of("Relier avec « parce que ».", "Autre levier.");

        assertThat(VersionCibleeLevierFilter.purge(leviers, null).gardes()).isEqualTo(leviers);
    }

    /** L'ORDRE des leviers conservés est celui du modèle : le plus rentable d'abord. */
    @Test
    void lOrdreDesLeviersConservesEstPreserve() {
        var resultat = VersionCibleeLevierFilter.purge(List.of(
            "Un.", "Relier avec « et » et « mais ».", "Trois."), TargetLevel.B1);

        assertThat(resultat.gardes()).containsExactly("Un.", "Trois.");
    }
}

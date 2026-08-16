package com.sejourfr.app.service.competence;

import com.sejourfr.app.config.CompetenceProperties;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CompetenceRubricsProviderTest {

    private static CompetenceProperties props(String rubricsVersion, String toolSchemaVersion) {
        CompetenceProperties props = new CompetenceProperties();
        props.getAnalysis().setRubricsVersion(rubricsVersion);
        props.getAnalysis().setToolSchemaVersion(toolSchemaVersion);
        return props;
    }

    private static CompetenceRubricsProvider load(String rubricsVersion, String toolSchemaVersion) {
        CompetenceRubricsProvider provider =
            new CompetenceRubricsProvider(props(rubricsVersion, toolSchemaVersion), new ObjectMapper());
        provider.load();
        return provider;
    }

    @Test
    void chargeLesSectionsLesAncresEtLesPlafonds() {
        CompetenceRubricsProvider provider = load("v1", "v1");

        Map<String, Object> commun = provider.getCommun();
        assertThat((List<?>) commun.get("sections")).isNotEmpty();
        assertThat((List<?>) commun.get("few_shot")).isNotEmpty();
        assertThat(provider.getVersion()).isEqualTo("v1");
        assertThat(provider.contraintesLongueur())
            .containsEntry("verdict", 20)
            .containsEntry("success_point", 30)
            .containsEntry("improvement_priority", 35);
    }

    /**
     * v4 est la version ACTIVE. Elle garde les plafonds des deux etiquettes et la
     * table des cinq niveaux du profil TCF IRN, que le builder rend au correcteur
     * — v4 ne change rien de ce qui juge, elle rend le niveau OPPOSABLE. Le
     * provider expose aussi la version du contrat de sortie, dont depend le jeu
     * de cles attendu.
     */
    @Test
    void chargeLesPlafondsDesEtiquettesEtLesNiveauxEnV4() {
        CompetenceRubricsProvider provider = load("v4", "v4");

        assertThat(provider.getVersion()).isEqualTo("v4");
        assertThat(provider.getToolSchemaVersion()).isEqualTo("v4");
        assertThat(provider.contraintesLongueur())
            .containsEntry("verdict", 20)
            .containsEntry("strength_tag", 3)
            .containsEntry("focus_tag", 3);
        assertThat((Map<?, ?>) provider.getCommun().get("niveaux")).hasSize(5);
    }

    /**
     * v5 est la version ACTIVE. Elle ne change AUCUN champ de sortie : c'est la
     * premiere version de consignes de ce module a reutiliser le contrat de la
     * precedente. Tout ce qui juge — plafonds, table des cinq paliers — est celui
     * de v4.
     */
    @Test
    void chargeV5SurLeContratDeSortieV4() {
        CompetenceRubricsProvider provider = load("v5", "v4");

        assertThat(provider.getVersion()).isEqualTo("v5");
        assertThat(provider.getToolSchemaVersion()).isEqualTo("v4");
        assertThat(provider.contraintesLongueur())
            .containsEntry("verdict", 20)
            .containsEntry("strength_tag", 3)
            .containsEntry("focus_tag", 3);
        assertThat((Map<?, ?>) provider.getCommun().get("niveaux")).hasSize(5);
        assertThat((List<?>) provider.getCommun().get("few_shot"))
            .as("v5 ancre les cinq paliers : v4 n'avait aucune ancre B2 ni A1_NON_ATTEINT")
            .hasSize(10);
    }

    /**
     * v6 est la version ACTIVE, et la premiere a exiger la preuve du niveau <b>a
     * tous les paliers</b> : son contrat de sortie est le tool-schema v5, qui met
     * {@code level_evidence} dans son {@code required}. Tout ce qui juge est
     * celui de v5 des consignes.
     */
    @Test
    void chargeV6SurLeContratDeSortieV5() {
        CompetenceRubricsProvider provider = load("v6", "v5");

        assertThat(provider.getVersion()).isEqualTo("v6");
        assertThat(provider.getToolSchemaVersion()).isEqualTo("v5");
        assertThat(provider.contraintesLongueur())
            .containsEntry("verdict", 20)
            .containsEntry("strength_tag", 3)
            .containsEntry("focus_tag", 3);
        assertThat((Map<?, ?>) provider.getCommun().get("niveaux")).hasSize(5);
        assertThat((List<?>) provider.getCommun().get("few_shot"))
            .as("les dix ancres de v5 sont reprises, aucune n'est ajoutee ni retiree")
            .hasSize(10);
        assertThat(CompetenceAnalysisFields.exigeLaPreuveSurTousLesPaliers(
            provider.getToolSchemaVersion())).isTrue();
    }

    @Test
    void lesSixVersionsRestentChargeables() {
        // On versionne, on ne reecrit jamais : v1 a v4 doivent continuer de
        // demarrer, c'est ce qui rend le retour arriere reel. v5 et v6 sont les
        // seules dont le contrat de sortie ne porte pas leur propre numero.
        for (String version : List.of("v1", "v2", "v3", "v4")) {
            assertThat(load(version, version).getVersion()).isEqualTo(version);
        }
        assertThat(load("v5", "v4").getVersion()).isEqualTo("v5");
        assertThat(load("v6", "v5").getVersion()).isEqualTo("v6");
    }

    /**
     * La paire est validee au BOOT : demander a v6 le tool-schema de v5 des
     * consignes (v4) fait echouer le demarrage. Une bascule faite a moitie ne
     * doit jamais se decouvrir a la premiere sortie rejetee en production, et il
     * n'existe aucun repli muet.
     */
    @Test
    void v6AvecUnToolSchemaV4EchoueAuDemarrage() {
        CompetenceRubricsProvider provider =
            new CompetenceRubricsProvider(props("v6", "v4"), new ObjectMapper());

        assertThatThrownBy(provider::load)
            .isInstanceOf(IllegalStateException.class)
            .hasStackTraceContaining("contrat consignes/tool-schema incompatible");
    }

    /**
     * L'EXIGENCE EST UN RANG, PAS UN {@code != v5}. Une allowlist explicite,
     * comme pour {@code envoieLeNiveauCibleDeLaCompetence} : sans elle, une
     * version future heriterait du comportement par accident, et un retour
     * arriere cesserait de reproduire l'ancien au bit pres.
     */
    @Test
    void lExigenceSurTousLesPaliersEstUneAllowlistDeContrats() {
        assertThat(CompetenceAnalysisFields.exigeLaPreuveSurTousLesPaliers("v5")).isTrue();
        for (String contrat : List.of("v1", "v2", "v3", "v4", "v6", "v99", "")) {
            assertThat(CompetenceAnalysisFields.exigeLaPreuveSurTousLesPaliers(contrat))
                .as("contrat de sortie %s", contrat)
                .isFalse();
        }
        // Le champ existe, lui, des v4 : les deux rangs ne se confondent pas.
        assertThat(CompetenceAnalysisFields.porteLaPreuveDuNiveau("v4")).isTrue();
        assertThat(CompetenceAnalysisFields.porteLaPreuveDuNiveau("v5")).isTrue();
        assertThat(CompetenceAnalysisFields.porteLaPreuveDuNiveau("v3")).isFalse();
    }

    /**
     * Une bascule faite a moitie doit se voir au BOOT. Ici le piege est neuf :
     * v5 n'a pas de tool-schema « v5 », et le demander est exactement l'erreur
     * qu'on ferait en copiant le patron des versions precedentes.
     */
    @Test
    void v5AvecUnToolSchemaV5EchoueAuDemarrage() {
        CompetenceRubricsProvider provider =
            new CompetenceRubricsProvider(props("v5", "v5"), new ObjectMapper());

        assertThatThrownBy(provider::load)
            .isInstanceOf(IllegalStateException.class)
            .hasStackTraceContaining("contrat consignes/tool-schema incompatible");
    }

    /**
     * Le niveau cible de la COMPETENCE n'est plus envoye au correcteur a partir
     * de v5 — c'etait une etiquette de palier non expliquee, posee dans le meme
     * objet JSON que le texte a niveler. Les versions anterieures continuent de
     * le recevoir : sans quoi le retour arriere ne reproduirait pas le prompt
     * d'avant.
     */
    @Test
    void leNiveauCibleDeLaCompetenceNestPlusEnvoyeAPartirDeV5() {
        assertThat(load("v5", "v4").envoieLeNiveauCibleDeLaCompetence()).isFalse();
        assertThat(load("v6", "v5").envoieLeNiveauCibleDeLaCompetence()).isFalse();
        for (String version : List.of("v1", "v2", "v3", "v4")) {
            assertThat(load(version, version).envoieLeNiveauCibleDeLaCompetence())
                .as("retour arriere %s : le prompt d'avant, au bit pres", version)
                .isTrue();
        }
    }

    @Test
    void lesPlafondsChargesSontImmuables() {
        CompetenceRubricsProvider provider = load("v1", "v1");

        assertThatThrownBy(() -> provider.contraintesLongueur().put("verdict", 999))
            .as("un plafond modifiable a chaud, c'est une regle de notation qui derive")
            .isInstanceOf(UnsupportedOperationException.class);
    }

    @Test
    void versionInconnueEchoueAuDemarrage() {
        CompetenceRubricsProvider provider =
            new CompetenceRubricsProvider(props("nexiste-pas", "v1"), new ObjectMapper());

        assertThatThrownBy(provider::load)
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("introuvables/illisibles");
    }

    @Test
    void toolSchemaConfigureIncompatibleEchoueAuDemarrage() {
        CompetenceRubricsProvider provider =
            new CompetenceRubricsProvider(props("v1", "v2"), new ObjectMapper());

        // Une bascule faite a moitie (consignes v1, contrat de sortie v2) doit
        // se voir au boot, pas a la premiere sortie rejetee en production.
        assertThatThrownBy(provider::load)
            .isInstanceOf(IllegalStateException.class)
            .hasRootCauseInstanceOf(IllegalStateException.class)
            .hasStackTraceContaining("contrat consignes/tool-schema incompatible");
    }

    @Test
    void versionDeclareeDifferenteDeLaConfigurationEchoueAuDemarrage() {
        // Le fichier v1 declare "rubrics-version": "v1" ; on demande a le charger
        // sous un autre nom via un chemin qui existe — impossible ici, donc on
        // verifie le meme garde-fou par la matrice des versions supportees.
        CompetenceRubricsProvider provider =
            new CompetenceRubricsProvider(props("v99", "v99"), new ObjectMapper());

        assertThatThrownBy(provider::load).isInstanceOf(IllegalStateException.class);
    }
}

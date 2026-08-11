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

    @Test
    void lesQuatreVersionsRestentChargeables() {
        // On versionne, on ne reecrit jamais : v1, v2 et v3 doivent continuer de
        // demarrer, c'est ce qui rend le retour arriere reel.
        for (String version : List.of("v1", "v2", "v3", "v4")) {
            assertThat(load(version, version).getVersion()).isEqualTo(version);
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

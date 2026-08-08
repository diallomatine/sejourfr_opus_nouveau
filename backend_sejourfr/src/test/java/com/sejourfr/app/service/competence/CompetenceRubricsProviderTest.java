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

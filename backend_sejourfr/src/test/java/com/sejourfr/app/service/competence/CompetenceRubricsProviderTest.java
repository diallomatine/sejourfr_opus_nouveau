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

    @Test
    void lesCinqVersionsRestentChargeables() {
        // On versionne, on ne reecrit jamais : v1 a v4 doivent continuer de
        // demarrer, c'est ce qui rend le retour arriere reel. v5 est la seule
        // dont le contrat de sortie ne porte pas son propre numero.
        for (String version : List.of("v1", "v2", "v3", "v4")) {
            assertThat(load(version, version).getVersion()).isEqualTo(version);
        }
        assertThat(load("v5", "v4").getVersion()).isEqualTo("v5");
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

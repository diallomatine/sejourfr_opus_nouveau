package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ProductionRubricsProviderTest {

    private ProductionRubricsProvider load(String version) {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.setRubricsVersion(version);
        ProductionRubricsProvider provider =
                new ProductionRubricsProvider(props, new ObjectMapper());
        provider.load();
        return provider;
    }

    @Test
    void load_v3_populatesCommunAndRubrics() {
        ProductionRubricsProvider provider = load("v3");

        Map<String, Object> commun = provider.getCommun();
        assertThat(commun.get("sections")).isInstanceOf(List.class);
        assertThat((List<?>) commun.get("sections")).isNotEmpty();
        assertThat(commun.get("few_shot")).isInstanceOf(List.class);

        assertThat(provider.all()).isNotEmpty().containsKey("EE_T1");
    }

    @Test
    void getTask_existingKey_present() {
        ProductionRubricsProvider provider = load("v3");

        assertThat(provider.getTask(EpreuveType.TCF_EE, 1)).isPresent();
        assertThat(provider.find(EpreuveType.TCF_EO, 1)).isPresent();
    }

    @Test
    void getTask_nullEpreuve_empty() {
        assertThat(load("v3").getTask(null, 1)).isEmpty();
    }

    @Test
    void key_stripsTcfPrefixAndSuffixesTache() {
        assertThat(ProductionRubricsProvider.key(EpreuveType.TCF_EE, 1)).isEqualTo("EE_T1");
        assertThat(ProductionRubricsProvider.key(EpreuveType.TCF_EO, 3)).isEqualTo("EO_T3");
    }

    @Test
    void load_unknownVersion_failsFast() {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.setRubricsVersion("does-not-exist");
        ProductionRubricsProvider provider =
                new ProductionRubricsProvider(props, new ObjectMapper());

        assertThatThrownBy(provider::load).isInstanceOf(IllegalStateException.class);
    }

    // ------------------------------------------------------------------------
    // Grille d'une version donnee (console admin « Productions IA », F-5 A)
    // ------------------------------------------------------------------------

    @Test
    void grilleDeVersion_active_est_la_grille_qui_note() {
        ProductionRubricsProvider provider = load("v15");

        ProductionRubricsProvider.Grille g = provider.grilleDeVersion("v15").orElseThrow();

        assertThat(g.niveauCecrl().getSeuilB2()).isEqualTo(10.0);
        assertThat(g.niveauCecrl().getSeuilB1()).isEqualTo(6.0);
        assertThat(g.niveauCecrl().getSeuilA2()).isEqualTo(2.0);
        assertThat(g.niveauDepuisLaGrille()).isTrue();
        assertThat(g.niveauCecrl().getSeuilB1()).isEqualTo(provider.niveauCecrl().getSeuilB1());
        assertThat(g.couplage().getEcartMax()).isEqualTo(provider.couplage().getEcartMax());
        assertThat(provider.versionActive()).isEqualTo("v15");
    }

    @Test
    void grilleDeVersion_historique_relue_par_la_meme_fusion() {
        ProductionRubricsProvider provider = load("v15");

        ProductionRubricsProvider.Grille v3 = provider.grilleDeVersion("v3").orElseThrow();

        // v3 ne declare pas de bloc commun.niveau : seuils de la configuration.
        assertThat(v3.niveauDepuisLaGrille()).isFalse();
        assertThat(v3.niveauCecrl().getSeuilB2()).isEqualTo(15.0);
        assertThat(v3.tache(com.sejourfr.app.enums.EpreuveType.TCF_EE, 1)).isPresent();
        // La grille active, elle, n'a pas bouge.
        assertThat(provider.niveauCecrl().getSeuilB2()).isEqualTo(10.0);
        assertThat(provider.grilleDeVersion("v3")).containsSame(v3);
    }

    @Test
    void grilleDeVersion_inconnue_ou_mal_formee_ne_devine_rien() {
        ProductionRubricsProvider provider = load("v15");

        assertThat(provider.grilleDeVersion(null)).isEmpty();
        assertThat(provider.grilleDeVersion(" ")).isEmpty();
        assertThat(provider.grilleDeVersion("v99")).isEmpty();
        assertThat(provider.grilleDeVersion("../application")).isEmpty();
        assertThat(provider.grilleDeVersion("v1.5")).isEmpty();
    }
}

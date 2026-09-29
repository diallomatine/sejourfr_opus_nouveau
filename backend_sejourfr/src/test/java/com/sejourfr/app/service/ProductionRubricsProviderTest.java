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
}

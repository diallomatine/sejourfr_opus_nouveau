package com.sejourfr.app.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.core.io.ClassPathResource;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ProductionEvaluationContractTest {

    private static final Set<String> CODES = Set.of(
        "communiquer", "interagir", "lexique", "morphosyntaxe");
    private static final List<String> NIVEAUX = List.of(
        "A1_NON_ATTEINT", "A1", "A2", "B1", "B2");
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void v7AndV4FormOneStrictTcfIrnContract() throws Exception {
        Map<String, Object> v7 = resource("prompts/production-rubrics-v7.json");
        Map<String, Object> v4 = resource("prompts/production-evaluation-tool-schema-v4.json");
        String rawV7 = resourceText("prompts/production-rubrics-v7.json");

        assertThat(v7)
            .containsEntry("rubrics-version", "v7")
            .containsEntry("profile", "TCF_IRN")
            .containsEntry("tool_schema_version", "v4")
            .containsEntry("niveau_max", "B2");
        assertThat(rawV7).doesNotContain("\"C1\"", "\"C2\"");

        Map<String, Object> commun = map(v7.get("commun"));
        Map<String, Object> niveau = map(commun.get("niveau"));
        assertThat(niveau)
            .containsEntry("seuil_b2", 10)
            .containsEntry("seuil_b1", 6)
            .containsEntry("seuil_a2", 2);
        assertThat(map(commun.get("couplage"))).containsEntry("ecart_max", 1);
        assertThat(map(commun.get("bandes_criteres")))
            .containsEntry("tres_bonne_maitrise", 10)
            .containsEntry("satisfaisant", 6)
            .containsEntry("en_cours_acquisition", 2);

        Map<String, Object> rubrics = map(v7.get("rubrics"));
        assertThat(rubrics.keySet()).containsExactlyInAnyOrder(
            "EE_T1", "EE_T2", "EE_T3", "EO_T1", "EO_T2", "EO_T3");
        for (Map.Entry<String, Object> entry : rubrics.entrySet()) {
            List<?> criteres = list(map(entry.getValue()).get("criteres"));
            assertThat(criteres).as(entry.getKey()).hasSize(4);
            assertThat(criteres.stream().map(c -> map(c).get("code").toString()).toList())
                .containsExactly("communiquer", "interagir", "lexique", "morphosyntaxe");
            assertThat(criteres.stream()
                .mapToDouble(c -> ((Number) map(c).get("poids")).doubleValue()).sum())
                .isEqualTo(1.0);
        }
        assertBounds(rubrics, "EE_T1", 30, 60);
        assertBounds(rubrics, "EE_T2", 60, 90);
        assertBounds(rubrics, "EE_T3", 60, 90);

        assertThat(v4.get("additionalProperties")).isEqualTo(false);
        assertThat(strings(map(map(v4.get("properties")).get("niveau_cecrl")).get("enum")))
            .containsExactlyElementsOf(NIVEAUX);
        Map<String, Object> scores = map(map(v4.get("properties")).get("scores_criteres"));
        assertThat(scores).containsEntry("minItems", 4).containsEntry("maxItems", 4);
        assertThat(strings(map(map(scores.get("items")).get("properties"))
            .get("code") instanceof Map<?, ?> code ? code.get("enum") : null))
            .containsExactlyInAnyOrderElementsOf(CODES);
        Map<String, Object> scoreProperties = map(map(scores.get("items")).get("properties"));
        Map<String, Object> preuve = map(scoreProperties.get("preuve"));
        assertThat(preuve).containsEntry("minLength", 1);
        assertThat(rawV7).doesNotContain("mets une chaine vide");
        assertAllObjectsClosed(v4, "root");
    }

    @Test
    void v7RefusesAnOldToolSchemaAtLoadTime() {
        var props = new com.sejourfr.app.config.ProductionEvaluationProperties();
        props.setRubricsVersion("v7");
        props.setProvider("deepseek");
        props.getDeepseek().setPromptVersion("v3");

        assertThatThrownBy(() -> new ProductionRubricsProvider(props, objectMapper).load())
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("Rubriques production introuvables/illisibles")
            .hasRootCauseMessage("contrat rubriques/tool-schema incompatible : rubriques v7 -> v4, "
                + "provider deepseek -> v3");
    }

    @ParameterizedTest
    @CsvSource({
        "v3, v2",
        "v4, v2",
        "v4.1, v2",
        "v4.2, v2",
        "v5, v3",
        "v6, v3",
        "v7, v4"
    })
    void chaqueVersionDeRubriquesAccepteUniquementSonToolSchema(
            String rubricsVersion, String toolSchemaVersion) {
        var props = new com.sejourfr.app.config.ProductionEvaluationProperties();
        props.setRubricsVersion(rubricsVersion);
        props.setProvider("deepseek");
        props.getDeepseek().setPromptVersion(toolSchemaVersion);

        new ProductionRubricsProvider(props, objectMapper).load();
    }

    @ParameterizedTest
    @CsvSource({
        "v3, v3, v2",
        "v4, v3, v2",
        "v4.1, v3, v2",
        "v4.2, v3, v2",
        "v5, v2, v3",
        "v6, v4, v3",
        "v7, v3, v4"
    })
    void unePaireRubriquesToolSchemaIncompatibleEchoueAuChargement(
            String rubricsVersion, String activeSchema, String expectedSchema) {
        var props = new com.sejourfr.app.config.ProductionEvaluationProperties();
        props.setRubricsVersion(rubricsVersion);
        props.setProvider("deepseek");
        props.getDeepseek().setPromptVersion(activeSchema);

        assertThatThrownBy(() -> new ProductionRubricsProvider(props, objectMapper).load())
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("Rubriques production introuvables/illisibles")
            .hasRootCauseMessage("contrat rubriques/tool-schema incompatible : rubriques "
                + rubricsVersion + " -> " + expectedSchema + ", provider deepseek -> " + activeSchema);
    }

    private void assertBounds(Map<String, Object> rubrics, String key, int min, int max) {
        Map<String, Object> bounds = map(map(rubrics.get(key)).get("bornes_mots_indicatives"));
        assertThat(bounds).as(key).containsEntry("min", min).containsEntry("max", max);
    }

    private void assertAllObjectsClosed(Object node, String path) {
        if (node instanceof Map<?, ?> map) {
            if ("object".equals(map.get("type"))) {
                assertThat(map.get("additionalProperties")).as(path).isEqualTo(false);
            }
            for (Map.Entry<?, ?> entry : map.entrySet()) {
                assertAllObjectsClosed(entry.getValue(), path + "." + entry.getKey());
            }
        } else if (node instanceof List<?> list) {
            for (int i = 0; i < list.size(); i++) assertAllObjectsClosed(list.get(i), path + "[" + i + "]");
        }
    }

    private Map<String, Object> resource(String path) throws Exception {
        try (var input = new ClassPathResource(path).getInputStream()) {
            return objectMapper.readValue(input, new TypeReference<Map<String, Object>>() {});
        }
    }

    private String resourceText(String path) throws Exception {
        try (var input = new ClassPathResource(path).getInputStream()) {
            return new String(input.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> map(Object value) {
        return (Map<String, Object>) value;
    }

    private static List<?> list(Object value) {
        return (List<?>) value;
    }

    private static List<String> strings(Object value) {
        return list(value).stream().map(Object::toString).toList();
    }
}

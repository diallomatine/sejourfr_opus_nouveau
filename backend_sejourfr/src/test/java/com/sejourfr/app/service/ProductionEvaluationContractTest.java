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

    /**
     * v8 = v7 pour TOUT ce qui note, v5 = v4 pour tout ce qui note. Ce test est
     * le verrou de cette promesse : si une future retouche de restitution
     * deplacait un seuil, une pondération, un critere ou une borne, il casse.
     */
    @Test
    void v8NeChangeQueLaRestitution_paseLeBareme() throws Exception {
        Map<String, Object> v7 = resource("prompts/production-rubrics-v7.json");
        Map<String, Object> v8 = resource("prompts/production-rubrics-v8.json");

        assertThat(v8)
            .containsEntry("rubrics-version", "v8")
            .containsEntry("profile", "TCF_IRN")
            .containsEntry("tool_schema_version", "v5")
            .containsEntry("niveau_max", "B2");
        assertThat(resourceText("prompts/production-rubrics-v8.json")).doesNotContain("\"C1\"", "\"C2\"");

        Map<String, Object> communV7 = map(v7.get("commun"));
        Map<String, Object> communV8 = map(v8.get("commun"));
        for (String bloc : List.of("niveau", "couplage", "plafonds", "bandes_criteres", "few_shot")) {
            assertThat(communV8.get(bloc))
                .as("v8 ne touche pas a commun." + bloc + " : la notation est celle de v7")
                .isEqualTo(communV7.get(bloc));
        }

        Map<String, Object> rubricsV7 = map(v7.get("rubrics"));
        Map<String, Object> rubricsV8 = map(v8.get("rubrics"));
        assertThat(rubricsV8.keySet()).isEqualTo(rubricsV7.keySet());
        for (String cle : rubricsV7.keySet()) {
            Map<String, Object> taskV7 = map(rubricsV7.get(cle));
            Map<String, Object> taskV8 = map(rubricsV8.get(cle));
            for (String champ : taskV7.keySet()) {
                if ("consignes_correcteur".equals(champ)) continue;
                assertThat(taskV8.get(champ)).as(cle + "." + champ).isEqualTo(taskV7.get(champ));
            }
            // Les consignes ne font que S'ETOFFER d'un rappel de restitution.
            assertThat(taskV8.get("consignes_correcteur").toString())
                .as(cle + " : rappel de restitution ajoute, consignes de notation intactes")
                .startsWith(taskV7.get("consignes_correcteur").toString().stripTrailing())
                .contains("RESTITUTION v8")
                .contains("accomplissement.objectif");
            assertThat(taskV8.get("consignes_correcteur").toString())
                .as(cle + " : la version amelioree n'existe qu'a l'ecrit")
                .contains(cle.startsWith("EE_")
                    ? "VERSION AMELIOREE obligatoire"
                    : "AUCUNE version_amelioree sur une tache orale");
        }
    }

    /** Le contrat de sortie v5 : celui de v4, plus les seules cles de restitution. */
    @Test
    void v5AjouteLeVerdictLaVersionAmelioreeEtLesPlafondsDeRestitution() throws Exception {
        Map<String, Object> v4 = resource("prompts/production-evaluation-tool-schema-v4.json");
        Map<String, Object> v5 = resource("prompts/production-evaluation-tool-schema-v5.json");

        assertThat(strings(v5.get("required")))
            .as("les champs obligatoires a la racine ne bougent pas : "
                + "version_amelioree n'est exigee que sur les taches ecrites, cote serveur")
            .containsExactlyElementsOf(strings(v4.get("required")));

        Map<String, Object> props = map(v5.get("properties"));
        assertThat(props.keySet())
            .containsAll(map(v4.get("properties")).keySet())
            .contains("version_amelioree");
        assertThat(map(props.get("version_amelioree")))
            .containsEntry("type", "string")
            .containsEntry("minLength", 1);

        Map<String, Object> accomplissement = map(props.get("accomplissement"));
        assertThat(strings(accomplissement.get("required")))
            .containsExactlyInAnyOrder("objectif", "objectif_resume", "points_traites", "points_oublies");
        assertThat(strings(map(map(accomplissement.get("properties")).get("objectif")).get("enum")))
            .containsExactly("ATTEINT", "PARTIELLEMENT_ATTEINT", "NON_ATTEINT");
        assertThat(map(map(accomplissement.get("properties")).get("objectif_resume")))
            .containsEntry("minLength", 1);

        assertThat(map(props.get("points_forts"))).containsEntry("maxItems", 2);
        assertThat(map(props.get("points_a_ameliorer"))).containsEntry("maxItems", 2);
        assertThat(map(props.get("exemples_corriges"))).containsEntry("maxItems", 3);

        // Rien de ce qui porte la NOTE n'a bouge entre v4 et v5 : seules les
        // consignes de restitution (commentaire, confiance, suggestions...) ont
        // ete reecrites.
        Map<String, Object> propsV4 = map(v4.get("properties"));
        for (String champ : List.of("note_globale", "niveau_cecrl")) {
            assertThat(props.get(champ)).as(champ).isEqualTo(propsV4.get(champ));
        }
        Map<String, Object> scoresV5 = map(props.get("scores_criteres"));
        Map<String, Object> scoresV4 = map(propsV4.get("scores_criteres"));
        assertThat(scoresV5).containsEntry("minItems", 4).containsEntry("maxItems", 4);
        Map<String, Object> itemsV5 = map(scoresV5.get("items"));
        Map<String, Object> itemsV4 = map(scoresV4.get("items"));
        assertThat(strings(itemsV5.get("required"))).containsExactlyElementsOf(strings(itemsV4.get("required")));
        for (String champ : List.of("code", "note_sur_20", "preuve")) {
            assertThat(map(itemsV5.get("properties")).get(champ)).as("scores_criteres." + champ)
                .isEqualTo(map(itemsV4.get("properties")).get(champ));
        }
        assertThat(v5.get("additionalProperties")).isEqualTo(false);
        assertAllObjectsClosed(v5, "root");
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
        "v7, v4",
        "v8, v5"
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
        "v7, v3, v4",
        "v8, v4, v5"
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

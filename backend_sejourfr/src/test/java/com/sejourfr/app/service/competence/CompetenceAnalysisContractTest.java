package com.sejourfr.app.service.competence;

import com.sejourfr.app.config.CompetenceProperties;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.config.YamlPropertiesFactoryBean;
import org.springframework.core.io.ClassPathResource;
import org.springframework.util.StreamUtils;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Properties;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FIGE le contrat de l'analyse ciblee : la paire consignes v1 / tool-schema v1,
 * et le budget de tokens.
 *
 * <p>Ce que ce test protege vraiment : le module promet au candidat un retour
 * COURT et SANS NOTE. Un champ ajoute au schema (une note, un niveau, une liste
 * de remarques) changerait cette promesse sans qu'aucun test fonctionnel ne
 * bronche — le JSON serait valide, l'analyse persisterait, et la carte de
 * resultat mentirait sur ce qu'un micro-exercice permet de dire.
 */
class CompetenceAnalysisContractTest {

    private static final List<String> CLES = List.of(
        "status", "verdict", "success_point", "improvement_priority", "improved_version");
    private static final List<String> STATUTS = List.of("VALIDATED", "PARTIAL", "NOT_VALIDATED");

    /**
     * Cinq champs courts : 600 tokens de sortie laissent une marge large. C'est
     * un PLAFOND, pas une consommation — mais le relever sans raison ouvrirait
     * la porte a des sorties bavardes que le contrat n'attend pas, et le
     * descendre couperait un JSON en plein milieu (analyse perdue, quota deja
     * consomme).
     */
    private static final int PLAFOND_TOKENS_ATTENDU = 600;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void leToolSchemaV1NExposeQueLesCinqChampsDuContrat() {
        Map<String, Object> schema = resource("prompts/competence-analysis-tool-schema-v1.json");

        assertThat(schema.get("additionalProperties"))
            .as("un champ hors contrat doit etre refuse par le fournisseur, pas seulement par nous")
            .isEqualTo(false);
        assertThat(strings(schema.get("required"))).containsExactlyElementsOf(CLES);

        Map<String, Object> properties = map(schema.get("properties"));
        assertThat(properties.keySet()).containsExactlyInAnyOrderElementsOf(CLES);

        assertThat(strings(map(properties.get("status")).get("enum")))
            .containsExactlyElementsOf(STATUTS);

        for (String cle : CLES.subList(1, CLES.size())) {
            assertThat(map(properties.get(cle)).get("maxLength"))
                .as("%s doit etre borde en longueur", cle)
                .isInstanceOf(Number.class);
            assertThat(map(properties.get(cle)).get("minLength"))
                .as("%s ne doit jamais etre vide", cle)
                .isEqualTo(1);
        }
    }

    @Test
    void leToolSchemaV1NePrevoitNiNoteNiNiveauCecrl() {
        String brut = resourceText("prompts/competence-analysis-tool-schema-v1.json")
            .toLowerCase(Locale.ROOT);

        assertThat(brut).doesNotContain("note_globale", "niveau_cecrl", "scores_criteres", "/20");
        Map<String, Object> properties = map(resource(
            "prompts/competence-analysis-tool-schema-v1.json").get("properties"));
        assertThat(properties.keySet().stream().filter(k -> k.contains("note") || k.contains("niveau")))
            .as("aucun champ de note ni de niveau : un micro-exercice n'en porte pas")
            .isEmpty();
    }

    @Test
    void lesConsignesV1DeclarentLeToolSchemaV1EtLeProfilTcfIrn() {
        Map<String, Object> rubrics = resource("prompts/competence-analysis-rubrics-v1.json");

        assertThat(rubrics)
            .containsEntry("rubrics-version", "v1")
            .containsEntry("tool_schema_version", "v1")
            .containsEntry("profile", "TCF_IRN");
    }

    @Test
    void lesConsignesV1PortentLesPlafondsDeLongueurEtLesTroisVerdicts() {
        Map<String, Object> commun = map(
            resource("prompts/competence-analysis-rubrics-v1.json").get("commun"));

        assertThat(map(commun.get("contraintes_longueur")))
            .containsEntry("verdict", 20)
            .containsEntry("success_point", 30)
            .containsEntry("improvement_priority", 35);
        assertThat(map(commun.get("statuts")).keySet())
            .containsExactlyInAnyOrderElementsOf(STATUTS);
        assertThat(list(commun.get("sections"))).isNotEmpty();
    }

    @Test
    void chaqueAncreFewShotRespecteLeContratDeSortie() {
        Map<String, Object> commun = map(
            resource("prompts/competence-analysis-rubrics-v1.json").get("commun"));
        List<?> fewShot = list(commun.get("few_shot"));

        assertThat(fewShot)
            .as("les deux exemples de la specification, plus les ancres des cas difficiles")
            .hasSizeGreaterThanOrEqualTo(4);

        Set<String> verdictsCouverts = new java.util.LinkedHashSet<>();
        for (Object ancre : fewShot) {
            Map<String, Object> attendu = map(map(ancre).get("attendu"));
            assertThat(attendu.keySet())
                .as("une ancre qui ne respecte pas le contrat apprend au correcteur a le violer")
                .containsExactlyInAnyOrderElementsOf(CLES);
            assertThat(STATUTS).contains(String.valueOf(attendu.get("status")));
            verdictsCouverts.add(String.valueOf(attendu.get("status")));
        }
        assertThat(verdictsCouverts)
            .as("les trois verdicts doivent etre ancres, sinon un seul est appris")
            .containsExactlyInAnyOrderElementsOf(STATUTS);
    }

    @Test
    void leBudgetDeTokensEstFigeEtIdentiqueEntreLeYamlEtLePojo() {
        Properties yaml = applicationYaml();

        assertThat(yaml.getProperty("sejourfr.competences.analysis.max-tokens"))
            .isEqualTo(String.valueOf(PLAFOND_TOKENS_ATTENDU));
        assertThat(new CompetenceProperties().getAnalysis().getMaxTokens())
            .as("le POJO et le YAML ne doivent pas diverger : sinon le comportement depend "
                + "de la presence d'une cle")
            .isEqualTo(PLAFOND_TOKENS_ATTENDU);
    }

    @Test
    void laTemperatureEstNulleDesDeuxCotes() {
        Properties yaml = applicationYaml();

        assertThat(Double.parseDouble(yaml.getProperty("sejourfr.competences.analysis.temperature")))
            .as("un verdict de critere doit etre reproductible")
            .isZero();
        assertThat(new CompetenceProperties().getAnalysis().getTemperature()).isZero();
    }

    @Test
    void lesVersionsParDefautDuPojoDesignentLesFichiersLivres() {
        CompetenceProperties.Analysis analysis = new CompetenceProperties().getAnalysis();
        Properties yaml = applicationYaml();

        assertThat(analysis.getRubricsVersion()).isEqualTo("v1");
        assertThat(analysis.getToolSchemaVersion()).isEqualTo("v1");
        assertThat(yaml.getProperty("sejourfr.competences.analysis.rubrics-version"))
            .isEqualTo("${COMPETENCE_RUBRICS_VERSION:v1}");
        assertThat(yaml.getProperty("sejourfr.competences.analysis.tool-schema-version"))
            .isEqualTo("${COMPETENCE_TOOL_SCHEMA_VERSION:v1}");
    }

    private static Properties applicationYaml() {
        YamlPropertiesFactoryBean yaml = new YamlPropertiesFactoryBean();
        yaml.setResources(new ClassPathResource("application.yaml"));
        Properties props = yaml.getObject();
        assertThat(props).isNotNull();
        return props;
    }

    private Map<String, Object> resource(String path) {
        return objectMapper.readValue(resourceText(path), new TypeReference<Map<String, Object>>() {});
    }

    private static String resourceText(String path) {
        try (InputStream is = new ClassPathResource(path).getInputStream()) {
            return StreamUtils.copyToString(is, StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new IllegalStateException("ressource illisible : " + path, e);
        }
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> map(Object o) {
        assertThat(o).isInstanceOf(Map.class);
        return (Map<String, Object>) o;
    }

    private static List<?> list(Object o) {
        assertThat(o).isInstanceOf(List.class);
        return (List<?>) o;
    }

    private static List<String> strings(Object o) {
        return list(o).stream().map(String::valueOf).toList();
    }
}

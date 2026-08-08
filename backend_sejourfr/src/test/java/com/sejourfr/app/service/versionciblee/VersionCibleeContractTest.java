package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.util.ProductionTextBounds;
import com.sejourfr.app.service.EvaluationPromptBuilder;
import com.sejourfr.app.service.ProductionRubricsFixture;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le contrat du SECOND appel « version au niveau visé ».
 *
 * <p>Ce que verrouille cette classe :
 * <ul>
 *   <li>la paire consignes v1 / tool-schema v1 est cohérente et déclarée ;</li>
 *   <li>la sortie ne prévoit AUCUN champ où loger une note ou un niveau — comme
 *       pour les Compétences, l'interdiction est portée par le schéma, pas par
 *       une consigne ;</li>
 *   <li>les plafonds (2 à 3 leviers, longueurs) sont dans le SCHÉMA ;</li>
 *   <li>le français des prompts est ACCENTUÉ (leçon des rubriques v13 : un LLM
 *       imite la langue de son prompt) ;</li>
 *   <li><b>le prompt de NOTATION est intact</b> : il n'apprend jamais quel
 *       niveau vise le candidat.</li>
 * </ul>
 */
class VersionCibleeContractTest {

    /** Bornes de la tâche de test — résolues, jamais écrites en dur dans un prompt. */
    private static final ProductionTextBounds BORNES = ProductionTextBounds.of(40, 90, 10, 300);

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void lesConsignesEtLeSchemaFormentUnePaireDeclaree() throws Exception {
        Map<String, Object> rubriques =
            resource("prompts/production-version-ciblee-rubrics-v1.json");

        assertThat(rubriques)
            .containsEntry("rubrics-version", "v1")
            .containsEntry("tool_schema_version", "v1")
            .containsEntry("profile", "TCF_IRN");

        Map<String, Object> commun = map(rubriques.get("commun"));
        assertThat((List<?>) commun.get("sections")).isNotEmpty();
        assertThat((List<?>) commun.get("few_shot")).isNotEmpty();
        assertThat(map(commun.get("contraintes_longueur")))
            .containsEntry(VersionCibleeFields.CE_QUI_MANQUE, 25);
    }

    /**
     * L'interdiction « ni note, ni niveau » est portée par le SCHÉMA :
     * {@code additionalProperties:false} plus exactement deux champs. Une
     * consigne serait un vœu ; un champ absent du schéma ne peut pas être
     * produit.
     */
    @Test
    void leSchemaNePrevoitAucunChampPourUneNoteOuUnNiveau() throws Exception {
        Map<String, Object> schema =
            resource("prompts/production-version-ciblee-tool-schema-v1.json");

        assertThat(schema).containsEntry("additionalProperties", false);
        assertThat((List<Object>) schema.get("required"))
            .containsExactlyInAnyOrder(VersionCibleeFields.TEXTE, VersionCibleeFields.CE_QUI_MANQUE);

        Map<String, Object> properties = map(schema.get("properties"));
        assertThat(properties.keySet())
            .containsExactlyInAnyOrder(VersionCibleeFields.TEXTE, VersionCibleeFields.CE_QUI_MANQUE);
        assertThat(properties).doesNotContainKeys(
            "note_globale", "note", "niveau_cecrl", "niveau", "scores_criteres", "confiance");
    }

    @Test
    void lesPlafondsSontDansLeSchema() throws Exception {
        Map<String, Object> schema =
            resource("prompts/production-version-ciblee-tool-schema-v1.json");
        Map<String, Object> properties = map(schema.get("properties"));

        Map<String, Object> leviers = map(properties.get(VersionCibleeFields.CE_QUI_MANQUE));
        assertThat(leviers)
            .containsEntry("type", "array")
            .containsEntry("minItems", 2)
            .containsEntry("maxItems", 3);
        assertThat(map(leviers.get("items"))).containsEntry("maxLength", 220);

        Map<String, Object> texte = map(properties.get(VersionCibleeFields.TEXTE));
        assertThat(texte).containsEntry("type", "string").containsEntry("minLength", 1);
        assertThat((Integer) texte.get("maxLength")).isPositive();
    }

    /**
     * La consigne DIT ce que le serveur VÉRIFIE — dans cet ordre de confiance.
     * Le contrôle dur ({@code VersionCibleeLevierFilter}) est ce qui tient la
     * règle ; cette section-ci évite seulement de la faire violer à chaque appel.
     * Elle a été ajoutée après avoir relevé en base un bloc {@code niveau_vise: B1}
     * qui proposait « et », « mais » comme les connecteurs à employer — deux
     * moyens que notre propre grille classe A2.
     */
    @Test
    void lesConsignesInterdisentDeProposerUnMoyenDejaAcquis() throws Exception {
        String consignes = resourceText("prompts/production-version-ciblee-rubrics-v1.json");

        assertThat(consignes)
            .contains("jamais un moyen déjà acquis")
            .contains("sont des moyens du niveau A2")
            .contains("ne les propose JAMAIS comme le moyen d'y arriver");
    }

    /**
     * Leçon des rubriques v13 : nos propres prompts étaient écrits sans accents
     * (ratio 0,0002 sur 96 k lettres), et un LLM imite la langue de son prompt.
     * Ces deux fichiers-ci naissent accentués.
     */
    @Test
    void leFrancaisDesPromptsEstAccentue() throws Exception {
        for (String chemin : List.of(
                "prompts/production-version-ciblee-rubrics-v1.json",
                "prompts/production-version-ciblee-tool-schema-v1.json")) {
            String texte = resourceText(chemin);
            long accents = texte.chars().filter(VersionCibleeContractTest::estAccentuee).count();
            long lettres = texte.chars().filter(Character::isLetter).count();
            assertThat((double) accents / lettres)
                .as("ratio d'accents de %s", chemin)
                .isGreaterThan(0.01);
        }
    }

    /**
     * L'INVARIANT DE LA FONCTIONNALITÉ. Le correcteur ne doit jamais apprendre
     * quel niveau vise le candidat : sinon il aligne sa note dessus. Le prompt
     * de notation ne parle que du niveau cible de la TÂCHE (une donnée du
     * sujet), jamais du palier visé par la personne.
     */
    @Test
    void lePromptDeNotationNApprendJamaisLeNiveauViseParLeCandidat() {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.setRubricsVersion("v13");
        EvaluationPromptBuilder notation = new EvaluationPromptBuilder(
            objectMapper, ProductionRubricsFixture.charge(props));

        ProductionTask task = task();
        String promptNotation = notation.buildSystemPrompt()
            + notation.buildUserPrompt(task, "Ma production.", false, null);

        assertThat(promptNotation)
            .doesNotContain("niveau_vise")
            .doesNotContain("NIVEAU VISÉ PAR LE CANDIDAT")
            .doesNotContain("TargetLevel");

        // ... alors que le second appel, lui, le reçoit explicitement.
        VersionCibleeRubricsProvider rubriquesCiblees =
            new VersionCibleeRubricsProvider(props, objectMapper);
        rubriquesCiblees.load();
        String promptCible = new VersionCibleePromptBuilder(objectMapper, rubriquesCiblees)
            .buildUserPrompt(task, "Ma production.", NiveauCecrl.A2, TargetLevel.B2, BORNES);
        assertThat(promptCible).contains("\"niveau_vise\":\"B2\"");
    }

    /** Le second appel reçoit un contexte MINIMAL : pas la grille de notation. */
    @Test
    void leSecondAppelNeRecoitPasLaGrilleDeNotation() {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        VersionCibleeRubricsProvider rubriques =
            new VersionCibleeRubricsProvider(props, objectMapper);
        rubriques.load();
        VersionCibleePromptBuilder builder =
            new VersionCibleePromptBuilder(objectMapper, rubriques);

        String user = builder.buildUserPrompt(
            task(), "Ma production.", NiveauCecrl.A2, TargetLevel.B2, BORNES);

        assertThat(user)
            .doesNotContain("GRILLE D'ÉVALUATION")
            .doesNotContain("morphosyntaxe")
            .doesNotContain("BARÈME")
            .doesNotContain("note_sur_20");
        // Les bornes de mots restent celles de production_tasks, jamais une
        // valeur ecrite en dur dans une consigne.
        assertThat(user).contains("40 à 90 mots");
    }

    private static ProductionTask task() {
        ProductionTask t = new ProductionTask();
        t.setId(UUID.randomUUID());
        t.setEpreuve(EpreuveType.TCF_EE);
        t.setTacheNumero((short) 2);
        t.setNiveauCible("B1");
        t.setConsigne("Vous venez d'emménager. Écrivez à un ami.");
        t.setMotsMin(40);
        t.setMotsMax(90);
        return t;
    }

    private static boolean estAccentuee(int c) {
        return "éèêëàâäùûüîïôöçÉÈÊËÀÂÄÙÛÜÎÏÔÖÇ".indexOf(c) >= 0;
    }

    private Map<String, Object> resource(String path) throws Exception {
        return objectMapper.readValue(resourceText(path), new TypeReference<Map<String, Object>>() {});
    }

    private static String resourceText(String path) throws Exception {
        try (var is = new ClassPathResource(path).getInputStream()) {
            return new String(is.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> map(Object o) {
        return (Map<String, Object>) o;
    }
}

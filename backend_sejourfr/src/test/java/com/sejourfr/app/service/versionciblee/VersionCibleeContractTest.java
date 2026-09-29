package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.util.ProductionTextBounds;
import com.sejourfr.app.service.EvaluationProductionSegments;
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
 *   <li>les paires consignes ⇄ tool-schema sont cohérentes et déclarées, v1
 *       comprise — <b>on versionne, on ne réécrit jamais</b> ;</li>
 *   <li>la sortie ne prévoit AUCUN champ où loger une note ou un niveau — comme
 *       pour les Compétences, l'interdiction est portée par le schéma, pas par
 *       une consigne ;</li>
 *   <li>les plafonds (2 à 3 leviers, longueurs en mots) sont déclarés par la
 *       GRILLE et doublés d'un {@code maxLength} dans le SCHÉMA ;</li>
 *   <li>à l'ORAL, la production n'est jamais réécrite : le schéma ne prévoit
 *       aucun texte complet, et la preuve se désigne par NUMÉRO ;</li>
 *   <li>le français des prompts est ACCENTUÉ (leçon des rubriques v13 : un LLM
 *       imite la langue de son prompt) ;</li>
 *   <li><b>le prompt de NOTATION est intact</b> : il n'apprend jamais quel
 *       niveau vise le candidat.</li>
 * </ul>
 */
class VersionCibleeContractTest {

    private static final String RUBRICS_V1 = "prompts/production-version-ciblee-rubrics-v1.json";
    private static final String SCHEMA_V1 =
        "prompts/production-version-ciblee-tool-schema-v1.json";
    private static final String RUBRICS_V2 = "prompts/production-version-ciblee-rubrics-v2.json";
    private static final String SCHEMA_V2 =
        "prompts/production-version-ciblee-tool-schema-v2.json";
    private static final String SCHEMA_ORAL_V2 =
        "prompts/production-version-ciblee-tool-schema-oral-v2.json";

    /** Bornes de la tâche de test — résolues, jamais écrites en dur dans un prompt. */
    private static final ProductionTextBounds BORNES = ProductionTextBounds.of(40, 90, 10, 300);

    private final ObjectMapper objectMapper = new ObjectMapper();

    // ------------------------------------------------------------ les paires

    @Test
    void lesConsignesEtLeSchemaFormentUnePaireDeclaree() throws Exception {
        Map<String, Object> rubriques = resource(RUBRICS_V2);

        assertThat(rubriques)
            .containsEntry("rubrics-version", "v2")
            .containsEntry("tool_schema_version", "v2")
            .containsEntry("profile", "TCF_IRN");

        Map<String, Object> commun = map(rubriques.get("commun"));
        assertThat((List<?>) commun.get("sections")).isNotEmpty();
        assertThat((List<?>) commun.get("few_shot")).isNotEmpty();
    }

    /**
     * RETOUR ARRIÈRE. v1 reste chargeable et cohérente : c'est ce qui fait qu'un
     * retour arrière est une paire de variables d'environnement, sans migration.
     */
    @Test
    void leContratV1ResteChargeableEtCoherent() throws Exception {
        Map<String, Object> rubriques = resource(RUBRICS_V1);
        assertThat(rubriques)
            .containsEntry("rubrics-version", "v1")
            .containsEntry("tool_schema_version", "v1");
        assertThat(map(map(rubriques.get("commun")).get("contraintes_longueur")))
            .containsEntry(VersionCibleeFields.CE_QUI_MANQUE, 25);

        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.getVersionCiblee().setRubricsVersion("v1");
        props.getVersionCiblee().setToolSchemaVersion("v1");
        VersionCibleeRubricsProvider rubrics =
            new VersionCibleeRubricsProvider(props, objectMapper);
        rubrics.load();

        assertThat(rubrics.contrat()).isEqualTo(VersionCibleeContrat.V1);
        assertThat(rubrics.contrat().planDAction()).isFalse();
        assertThat(rubrics.contrat().oral()).isFalse();
    }

    /** Une version inconnue du registre n'existe pas : échec BRUYANT, jamais un repli muet. */
    @Test
    void uneVersionInconnueDuRegistreEchoueBruyamment() {
        assertThat(VersionCibleeContrat.find("v99")).isEmpty();
        org.assertj.core.api.Assertions
            .assertThatThrownBy(() -> VersionCibleeContrat.of("v99"))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("inconnu");
    }

    // ---------------------------------------------------- ni note, ni niveau

    /**
     * L'interdiction « ni note, ni niveau » est portée par le SCHÉMA :
     * {@code additionalProperties:false} plus exactement les champs prévus. Une
     * consigne serait un vœu ; un champ absent du schéma ne peut pas être
     * produit.
     */
    @Test
    @SuppressWarnings("unchecked")
    void aucunSchemaNePrevoitUnChampPourUneNoteOuUnNiveau() throws Exception {
        for (String chemin : List.of(SCHEMA_V1, SCHEMA_V2, SCHEMA_ORAL_V2)) {
            Map<String, Object> schema = resource(chemin);
            assertThat(schema).as(chemin).containsEntry("additionalProperties", false);
            assertThat(map(schema.get("properties"))).as(chemin).doesNotContainKeys(
                "note_globale", "note", "note_sur_20", "niveau_cecrl", "niveau", "niveau_vise",
                "niveau_constate", "scores_criteres", "confiance");
            assertThat(objectMapper.writeValueAsString(schema))
                .as("%s ne doit prevoir aucun champ de note", chemin)
                .doesNotContain("\"note_globale\"").doesNotContain("\"niveau_cecrl\"");
        }

        Map<String, Object> ecrit = resource(SCHEMA_V2);
        assertThat((List<Object>) ecrit.get("required")).containsExactlyInAnyOrder(
            VersionCibleeFields.LEVIERS, VersionCibleeFields.EXEMPLE_CIBLE,
            VersionCibleeFields.A_RETENIR);
        assertThat(map(ecrit.get("properties")).keySet()).containsExactlyInAnyOrder(
            VersionCibleeFields.LEVIERS, VersionCibleeFields.EXEMPLE_CIBLE,
            VersionCibleeFields.A_RETENIR);

        Map<String, Object> oral = resource(SCHEMA_ORAL_V2);
        assertThat((List<Object>) oral.get("required")).containsExactlyInAnyOrder(
            VersionCibleeFields.LEVIERS, VersionCibleeFields.REFORMULATIONS,
            VersionCibleeFields.A_RETENIR);
        assertThat(map(oral.get("properties")).keySet()).containsExactlyInAnyOrder(
            VersionCibleeFields.LEVIERS, VersionCibleeFields.REFORMULATIONS,
            VersionCibleeFields.A_RETENIR);
    }

    // ------------------------------------------------------------- plafonds

    /**
     * Chaque plafond est déclaré EN MOTS par la grille ET doublé d'un
     * {@code maxLength} en caractères dans le schéma. C'est la contrainte dure
     * qui tient la brièveté, jamais la consigne : un champ qui ne peut pas
     * dépasser 70 caractères ne peut pas contenir une dissertation.
     */
    @Test
    void lesPlafondsSontDeclaresEnMotsParLaGrilleEtDoublesDansLeSchema() throws Exception {
        Map<String, Object> contraintes =
            map(map(resource(RUBRICS_V2).get("commun")).get("contraintes_longueur"));
        assertThat(contraintes)
            .containsEntry(VersionCibleeFields.ACTION, 6)
            .containsEntry(VersionCibleeFields.EXEMPLE, 5)
            .containsEntry(VersionCibleeFields.APPORT, 3)
            .containsEntry(VersionCibleeFields.FORMULE, 8)
            .containsEntry(VersionCibleeFields.EXPLICATION, 14);

        Map<String, Object> ecrit = map(resource(SCHEMA_V2).get("properties"));
        Map<String, Object> leviers = map(ecrit.get(VersionCibleeFields.LEVIERS));
        assertThat(leviers).containsEntry("type", "array")
            .containsEntry("minItems", 2).containsEntry("maxItems", 3);
        Map<String, Object> levier = map(map(leviers.get("items")).get("properties"));
        assertThat(map(levier.get(VersionCibleeFields.ACTION)).get("maxLength")).isEqualTo(70);
        assertThat(map(levier.get(VersionCibleeFields.EXEMPLE)).get("maxLength")).isEqualTo(60);

        Map<String, Object> exempleCible = map(ecrit.get(VersionCibleeFields.EXEMPLE_CIBLE));
        Map<String, Object> champs = map(exempleCible.get("properties"));
        Map<String, Object> segments = map(champs.get(VersionCibleeFields.SEGMENTS));
        assertThat(segments).containsEntry("minItems", 2).containsEntry("maxItems", 3);
        Map<String, Object> segment = map(map(segments.get("items")).get("properties"));
        assertThat(map(segment.get(VersionCibleeFields.APPORT)).get("maxLength")).isEqualTo(40);
        assertThat((Integer) map(champs.get(VersionCibleeFields.TEXTE)).get("maxLength"))
            .isPositive();

        Map<String, Object> aRetenir =
            map(map(ecrit.get(VersionCibleeFields.A_RETENIR)).get("properties"));
        assertThat(map(aRetenir.get(VersionCibleeFields.FORMULE)).get("maxLength")).isEqualTo(90);
        assertThat(map(aRetenir.get(VersionCibleeFields.EXPLICATION)).get("maxLength"))
            .isEqualTo(150);
    }

    /**
     * À L'ORAL, LA PRODUCTION N'EST JAMAIS RÉÉCRITE. Le schéma ne prévoit aucun
     * texte complet, et la désignation se fait par un ENTIER — technique du
     * contrat de correction v12, qui a fait tomber le premier poste de refus
     * oral (preuve non rattachée, 42,9 % des appels).
     */
    @Test
    void aLOralLeSchemaNePrevoitAucunTexteReecritEtDesignePasUnNumero() throws Exception {
        Map<String, Object> oral = map(resource(SCHEMA_ORAL_V2).get("properties"));
        assertThat(oral).doesNotContainKey(VersionCibleeFields.EXEMPLE_CIBLE);

        Map<String, Object> reformulations = map(oral.get(VersionCibleeFields.REFORMULATIONS));
        assertThat(reformulations).containsEntry("minItems", 2).containsEntry("maxItems", 3);
        Map<String, Object> items = map(reformulations.get("items"));
        assertThat(items).containsEntry("additionalProperties", false);
        assertThat(map(items.get("properties")).keySet()).containsExactlyInAnyOrder(
            VersionCibleeFields.SEGMENT_NUMERO, VersionCibleeFields.REFORMULE,
            VersionCibleeFields.APPORT);
        Map<String, Object> numero =
            map(map(items.get("properties")).get(VersionCibleeFields.SEGMENT_NUMERO));
        assertThat(numero).containsEntry("type", "integer").containsEntry("minimum", 1);
        // Le champ résolu par le serveur n'est JAMAIS demandé au modèle : il ne
        // recopie rien, sinon on retrouverait les citations introuvables.
        assertThat(map(items.get("properties"))).doesNotContainKey(VersionCibleeFields.ORIGINAL);
    }

    // -------------------------------------------------------- les consignes

    /**
     * La consigne DIT ce que le serveur VÉRIFIE — dans cet ordre de confiance.
     * Le contrôle dur ({@code VersionCibleeLevierFilter}) est ce qui tient la
     * règle ; cette section-ci évite seulement de la faire violer à chaque appel.
     */
    @Test
    void lesConsignesInterdisentDeProposerUnMoyenDejaAcquis() throws Exception {
        assertThat(resourceText(RUBRICS_V2))
            .contains("jamais un moyen déjà acquis")
            .contains("sont des moyens du niveau A2")
            .contains("ne les propose JAMAIS comme le moyen d'y arriver");
    }

    /**
     * L'EXIGENCE DU PROPRIÉTAIRE, écrite dans la grille : à l'oral, on reformule
     * la formulation d'une phrase, jamais un mot que la transcription a pu
     * déformer. Le contrôle dur reste
     * {@code VersionCibleeReformulationFilter} — la consigne n'est que le
     * premier filet.
     */
    @Test
    void lesConsignesOralesInterdisentDeCorrigerUneErreurDeTranscription() throws Exception {
        String consignes = resourceText(RUBRICS_V2);
        assertThat(consignes)
            .contains("on ne réécrit pas une production orale")
            .contains("TRANSCRIPTION AUTOMATIQUE")
            .contains("la prononciation, l'accent, l'intonation, le débit, la fluidité")
            .contains("les hésitations transcrites")
            .contains("Une reformulation utile change une STRUCTURE");
    }

    /**
     * Leçon des rubriques v13 : nos propres prompts étaient écrits sans accents
     * (ratio 0,0002 sur 96 k lettres), et un LLM imite la langue de son prompt.
     * Ces fichiers-ci naissent accentués.
     */
    @Test
    void leFrancaisDesPromptsEstAccentue() throws Exception {
        for (String chemin : List.of(RUBRICS_V1, SCHEMA_V1, RUBRICS_V2, SCHEMA_V2,
                SCHEMA_ORAL_V2)) {
            String texte = resourceText(chemin);
            long accents = texte.chars().filter(VersionCibleeContractTest::estAccentuee).count();
            long lettres = texte.chars().filter(Character::isLetter).count();
            assertThat((double) accents / lettres)
                .as("ratio d'accents de %s", chemin)
                .isGreaterThan(0.01);
        }
    }

    // ------------------------------------------------ l'invariant du montage

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

        ProductionTask task = task(EpreuveType.TCF_EE);
        String promptNotation = notation.buildSystemPrompt()
            + notation.buildUserPrompt(task, "Ma production.", false, null);

        assertThat(promptNotation)
            .doesNotContain("niveau_vise")
            .doesNotContain("NIVEAU VISÉ PAR LE CANDIDAT")
            .doesNotContain("TargetLevel");

        // ... alors que le second appel, lui, le reçoit explicitement.
        String promptCible = builder(new ProductionEvaluationProperties())
            .buildUserPrompt(task, "Ma production.", NiveauCecrl.A2, TargetLevel.B2, BORNES);
        assertThat(promptCible).contains("\"niveau_vise\":\"B2\"");
    }

    /** Le second appel reçoit un contexte MINIMAL : pas la grille de notation. */
    @Test
    void leSecondAppelNeRecoitPasLaGrilleDeNotation() {
        VersionCibleePromptBuilder builder = builder(new ProductionEvaluationProperties());

        String user = builder.buildUserPrompt(
            task(EpreuveType.TCF_EE), "Ma production.", NiveauCecrl.A2, TargetLevel.B2, BORNES);

        assertThat(user)
            .doesNotContain("GRILLE D'ÉVALUATION")
            .doesNotContain("morphosyntaxe")
            .doesNotContain("BARÈME")
            .doesNotContain("note_sur_20");
        // Les bornes de mots restent celles de production_tasks, jamais une
        // valeur ecrite en dur dans une consigne.
        assertThat(user).contains("40 à 90 mots");
    }

    /**
     * MÊME EXIGENCE À L'ORAL, plus une : la DURÉE n'est jamais envoyée. Le prompt
     * ne porte que la transcription découpée, et l'examinateur n'y est pas
     * numéroté — donc pas reformulable.
     */
    @Test
    void leSecondAppelOralNeRecoitNiGrilleNiDuree() {
        String transcription = "Examinateur : Bonjour, vous vouliez me voir ?\n"
            + "Candidat : Oui bonjour, je viens d'arriver dans l'immeuble.\n"
            + "Examinateur : Le local est au sous-sol.\n"
            + "Candidat : D'accord, et je fais comment pour le badge ?";
        EvaluationProductionSegments segments =
            EvaluationProductionSegments.of(transcription, EpreuveType.TCF_EO);

        String user = builder(new ProductionEvaluationProperties())
            .buildUserPromptOral(task(EpreuveType.TCF_EO), segments, NiveauCecrl.A2,
                TargetLevel.B1);

        assertThat(user)
            .doesNotContain("GRILLE D'ÉVALUATION")
            .doesNotContain("morphosyntaxe")
            .doesNotContain("duree")
            .doesNotContain("durée")
            .doesNotContain("secondes");
        assertThat(user).contains("[1]").contains("[2]").contains("\"niveau_vise\":\"B1\"");
        // Les tours de l'examinateur sont MONTRES, mais sans numero : les citer
        // devient impossible par construction, pas « interdit ».
        assertThat(user).contains("Examinateur : Bonjour").doesNotContain("[3]");
    }

    // -------------------------------------------------------------- fixtures

    private VersionCibleePromptBuilder builder(ProductionEvaluationProperties props) {
        VersionCibleeRubricsProvider rubriques =
            new VersionCibleeRubricsProvider(props, objectMapper);
        rubriques.load();
        return new VersionCibleePromptBuilder(objectMapper, rubriques);
    }

    private static ProductionTask task(EpreuveType epreuve) {
        ProductionTask t = new ProductionTask();
        t.setId(UUID.randomUUID());
        t.setEpreuve(epreuve);
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

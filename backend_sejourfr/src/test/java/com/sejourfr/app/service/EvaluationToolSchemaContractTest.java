package com.sejourfr.app.service;

import com.sejourfr.app.config.EvaluationConfigFixture;
import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.core.io.ClassPathResource;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * LE FILET QUI MANQUAIT. Le tool-schema v7 est entre en service (rubriques v13)
 * sans etre enregistre dans le code qui applique le contrat : validation stricte
 * desactivee, controles de restitution desactives, production servie NON
 * DECOUPEE a un correcteur a qui le schema reclamait un numero de segment, et
 * numero jamais resolu en texte avant les fronts. Boot vert, tests verts,
 * regression invisible — parce que « version inconnue » valait « on ne valide
 * rien ».
 *
 * <p>Ce test verrouille trois choses, dans cet ordre d'importance :
 * <ol>
 *   <li>la version SERVIE PAR LA CONFIGURATION LIVREE est appliquee par le
 *       validateur, et son comportement correspond a ce que son fichier de
 *       schema declare reellement ;</li>
 *   <li>toute paire declaree CHARGEABLE (reversibilite non negociable) l'est
 *       encore, et son contrat est applique de la meme facon ;</li>
 *   <li>une version non enregistree ECHOUE, elle ne degrade pas.</li>
 * </ol>
 *
 * <p>Les capacites attendues ne sont pas recopiees a la main : elles sont LUES
 * dans le fichier de schema (marqueurs observables ci-dessous). Un futur schema
 * v9 devra donc etre enregistre, et ses drapeaux seront confrontes a son propre
 * contenu — pas a une table d'a-cote qu'on oublie de mettre a jour.
 */
class EvaluationToolSchemaContractTest {

    /** Toutes les paires rubriques -> tool-schema declarees chargeables. */
    private static final String PAIRES_CHARGEABLES = """
        v3, v2
        v4, v2
        v4.1, v2
        v4.2, v2
        v5, v3
        v6, v3
        v7, v4
        v8, v5
        v9, v5
        v10, v5
        v11, v5
        v12, v6
        v13, v7
        v14, v8
        """;

    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * LA REGRESSION, prise a la source : ce que le backend sert par defaut doit
     * etre ce que le backend sait appliquer. Sur le commit fautif, ce test
     * echoue des la premiere assertion (« v7 » absent du registre).
     */
    @Test
    void laVersionLivreeParDefautEstAppliqueeParLeValidateur() {
        ProductionEvaluationProperties defauts = EvaluationConfigFixture.defautsYaml();
        String schemaActif = EvaluationConfigFixture.versionPromptActive(defauts);

        assertThat(EvaluationToolSchema.find(schemaActif))
            .as("le tool-schema servi par application.yaml doit etre enregistre "
                + "dans EvaluationToolSchema, sinon la validation retombe en silence")
            .isPresent();

        assertContratConformeAuFichier(schemaActif);

        // La paire livree doit charger : c'est le boot reel, sans contexte Spring.
        new ProductionRubricsProvider(props(defauts.getRubricsVersion(), schemaActif), objectMapper)
            .load();
    }

    /**
     * Meme exigence sur la configuration EFFECTIVE (processus + {@code .env} +
     * yaml) : un retour arriere se fait par variables d'environnement, il ne
     * doit jamais pouvoir poser une version que le code n'applique pas.
     */
    @Test
    void laVersionEffectivementConfigureeEstEnregistree() {
        String schemaActif = EvaluationConfigFixture.versionPromptActive(
            EvaluationConfigFixture.resolue());

        assertThat(EvaluationToolSchema.find(schemaActif))
            .as("EVAL_PROMPT_VERSION=" + schemaActif + " n'est applique par aucun contrat")
            .isPresent();
    }

    /**
     * REVERSIBILITE : chaque paire encore chargeable garde son contrat, et ce
     * contrat correspond a son fichier. Un rollback ne doit ni echouer, ni
     * silencieusement valider autre chose.
     */
    @ParameterizedTest
    @CsvSource(textBlock = PAIRES_CHARGEABLES)
    void chaquePaireChargeableVoitSonContratApplique(String rubricsVersion, String schemaVersion) {
        new ProductionRubricsProvider(props(rubricsVersion, schemaVersion), objectMapper).load();

        assertContratConformeAuFichier(schemaVersion);
    }

    /**
     * La preuve par NUMERO vaut « v6 et au-dela », pas « v6 » — c'est ce que
     * disait deja le javadoc, et c'est ce qui manquait. La decoupe en segments
     * et la resolution du numero en texte suivent le meme drapeau : sans lui,
     * le correcteur recevait une production non numerotee et les fronts
     * recevaient un entier a la place de la citation promise.
     */
    @Test
    void laPreuveParNumeroVautPourV6EtAuDela() {
        assertThat(AiEvaluationService.preuveParNumero("v6")).isTrue();
        assertThat(AiEvaluationService.preuveParNumero("v7")).isTrue();
        assertThat(AiEvaluationService.preuveParNumero("v8")).isTrue();
        assertThat(AiEvaluationService.preuveParNumero("v5")).isFalse();
        assertThat(AiEvaluationService.preuveParNumero("v4")).isFalse();
    }

    /**
     * {@code version_amelioree} est la premiere capacite qu'une version
     * POSTERIEURE retire. Elle vaut donc « v5 a v7 », bornee des deux cotes —
     * et le retrait serveur du champ suit exactement ce drapeau.
     */
    @Test
    void laVersionAmelioreeVautDeV5AV7EtPlusApres() {
        assertThat(AiEvaluationService.versionAmelioree("v4")).isFalse();
        assertThat(AiEvaluationService.versionAmelioree("v5")).isTrue();
        assertThat(AiEvaluationService.versionAmelioree("v6")).isTrue();
        assertThat(AiEvaluationService.versionAmelioree("v7")).isTrue();
        assertThat(AiEvaluationService.versionAmelioree("v8")).isFalse();
    }

    /**
     * ECHEC BRUYANT, jamais de mode degrade muet : ni au boot, ni a l'usage.
     * C'est la contrainte dure qui remplace la consigne « pense a mettre a jour
     * les trois ensembles ».
     */
    @Test
    void uneVersionNonEnregistreeEchoueAuLieuDeDegrader() {
        assertThatThrownBy(() -> EvaluationToolSchema.of("v99"))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("contrat de sortie inconnu du validateur : v99");

        assertThatThrownBy(() -> EvaluationOutputValidator.violations(
            Map.of(), tacheEcrite(), null, "v99"))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("v99");

        assertThatThrownBy(() -> AiEvaluationService.preuveParNumero("v99"))
            .isInstanceOf(IllegalStateException.class);
    }

    // ------------------------------------------------------------------ outils

    /**
     * Confronte les drapeaux du registre aux MARQUEURS OBSERVABLES du fichier de
     * schema, seule reference qui ne peut pas diverger de ce que le correcteur
     * recoit :
     * <ul>
     *   <li>structure verifiee champ par champ ⇔ schema ferme
     *       ({@code additionalProperties: false}) ;</li>
     *   <li>controles de restitution ⇔ {@code accomplissement.objectif} au
     *       contrat ;</li>
     *   <li>{@code version_amelioree} exigee ⇔ propriete presente dans le
     *       schema. Cette capacite-la s'OUVRE en v5 et se REFERME en v8 : la
     *       lire sur {@code restitution()} rendrait le registre faux des que le
     *       champ disparait ;</li>
     *   <li>preuve par numero ⇔ {@code preuve_segment} exige sur chaque
     *       critere.</li>
     * </ul>
     */
    private void assertContratConformeAuFichier(String schemaVersion) {
        EvaluationToolSchema schema = EvaluationToolSchema.of(schemaVersion);
        Map<String, Object> fichier = schemaFile(schemaVersion);
        Map<String, Object> proprietes = map(fichier.get("properties"));
        Map<String, Object> critere = map(map(proprietes.get("scores_criteres")).get("items"));
        List<String> requisParCritere = strings(critere.get("required"));

        assertThat(schema.preuveParNumero())
            .as(schemaVersion + " : preuve par numero <-> preuve_segment exige par le schema")
            .isEqualTo(requisParCritere.contains("preuve_segment"));
        assertThat(schema.preuveParNumero())
            .as(schemaVersion + " : une preuve est un numero OU une citation, jamais les deux")
            .isNotEqualTo(requisParCritere.contains("preuve"));

        assertThat(schema.versionAmelioree())
            .as(schemaVersion + " : version_amelioree exigee <-> version_amelioree au contrat")
            .isEqualTo(proprietes.containsKey("version_amelioree"));
        assertThat(schema.restitution())
            .as(schemaVersion + " : restitution <-> accomplissement.objectif au contrat")
            .isEqualTo(map(map(proprietes.get("accomplissement")).get("properties"))
                .containsKey("objectif"));

        assertThat(schema.strict())
            .as(schemaVersion + " : structure verifiee <-> schema ferme")
            .isEqualTo(Boolean.FALSE.equals(fichier.get("additionalProperties")));
    }

    private static ProductionEvaluationProperties props(String rubricsVersion, String schemaVersion) {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.setRubricsVersion(rubricsVersion);
        props.setProvider("deepseek");
        props.getDeepseek().setPromptVersion(schemaVersion);
        return props;
    }

    private static ProductionTask tacheEcrite() {
        ProductionTask task = new ProductionTask();
        task.setEpreuve(EpreuveType.TCF_EE);
        task.setTacheNumero((short) 1);
        return task;
    }

    private Map<String, Object> schemaFile(String version) {
        String path = "prompts/production-evaluation-tool-schema-" + version + ".json";
        try (var is = new ClassPathResource(path).getInputStream()) {
            return objectMapper.readValue(new String(is.readAllBytes(), StandardCharsets.UTF_8),
                new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            throw new IllegalStateException("tool-schema illisible : " + path, e);
        }
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> map(Object node) {
        return node instanceof Map<?, ?> m ? (Map<String, Object>) m : Map.of();
    }

    private static List<String> strings(Object node) {
        return node instanceof List<?> list ? list.stream().map(String::valueOf).toList() : List.of();
    }
}

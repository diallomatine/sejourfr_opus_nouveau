package com.sejourfr.app.service.diagnostic.exemplecible;

import com.sejourfr.app.config.DiagnosticProperties;
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

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Le contrat du SECOND appel du diagnostic, « avant / apres ».
 *
 * <p>Ce que verrouille cette classe :
 * <ul>
 *   <li>la paire consignes v1 / tool-schema v1 est coherente et declaree, et une
 *       paire inconnue echoue au <b>BOOT</b> — jamais de repli muet ;</li>
 *   <li>la sortie ne prevoit AUCUN champ ou loger une note, un verdict ou un
 *       niveau — l'interdiction est portee par le schema, pas par une consigne,
 *       et c'est le serveur qui pose {@code niveau_vise} ;</li>
 *   <li>la phrase du candidat se DESIGNE par un entier : le schema n'offre aucun
 *       champ ou la recopier, donc l'inventer devient impossible par
 *       construction ;</li>
 *   <li><b>le contrat d'ANALYSE n'a pas bouge</b> : le correcteur du diagnostic
 *       n'apprend nulle part qu'on va reecrire quoi que ce soit ;</li>
 *   <li>le français des prompts est ACCENTUE (leçon des rubriques v13 : un LLM
 *       imite la langue de son prompt).</li>
 * </ul>
 */
class DiagnosticExempleCibleContractTest {

    private static final String RUBRIQUES = "prompts/diagnostic-exemple-cible-rubrics-v1.json";
    private static final String SCHEMA = "prompts/diagnostic-exemple-cible-tool-schema-v1.json";
    private static final String ANALYSE_SCHEMA = "prompts/diagnostic-analysis-tool-schema-v1.json";
    private static final String ANALYSE_RUBRIQUES = "prompts/diagnostic-analysis-rubrics-v1.json";

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void lesConsignesEtLeSchemaFormentUnePaireDeclaree() {
        Map<String, Object> rubriques = resource(RUBRIQUES);

        assertThat(rubriques)
            .containsEntry("rubrics-version", "v1")
            .containsEntry("tool_schema_version", "v1")
            .containsEntry("profile", "TCF_IRN");

        Map<String, Object> commun = map(rubriques.get("commun"));
        assertThat(list(commun.get("sections"))).isNotEmpty();
        assertThat(list(commun.get("few_shot"))).isNotEmpty();
    }

    /**
     * FAIL-FAST AU BOOT. Une bascule faite a moitie (consignes v2, tool-schema
     * v1) passerait sinon inaperçue jusqu'a la premiere sortie rejetee —
     * c'est-a-dire jusqu'a un ecran de conversion silencieusement vide.
     */
    @Test
    void unePaireDeVersionsInconnueFaitEchouerLeDemarrage() {
        DiagnosticProperties props = new DiagnosticProperties();
        props.getExempleCible().setRubricsVersion("v999");
        DiagnosticExempleCibleRubricsProvider provider =
            new DiagnosticExempleCibleRubricsProvider(props, objectMapper);

        assertThatThrownBy(provider::load)
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("sejourfr.diagnostic.exemple-cible.rubrics-version");
    }

    @Test
    void unToolSchemaIncompatibleAvecLesConsignesFaitEchouerLeDemarrage() {
        DiagnosticProperties props = new DiagnosticProperties();
        props.getExempleCible().setToolSchemaVersion("v2");
        DiagnosticExempleCibleRubricsProvider provider =
            new DiagnosticExempleCibleRubricsProvider(props, objectMapper);

        assertThatThrownBy(provider::load).isInstanceOf(IllegalStateException.class);
    }

    /**
     * L'interdiction « ni note, ni verdict, ni niveau » est portee par le SCHEMA :
     * {@code additionalProperties:false} plus exactement trois champs racine. Une
     * consigne serait un vœu ; un champ absent du schema ne peut pas etre produit.
     */
    @Test
    void leSchemaNePrevoitAucunChampPourUneNoteUnVerdictOuUnNiveau() {
        Map<String, Object> schema = resource(SCHEMA);

        assertThat(schema).containsEntry("additionalProperties", false);
        assertThat(strings(schema.get("required"))).containsExactlyInAnyOrder(
            DiagnosticExempleCibleFields.SEGMENT_NUMERO,
            DiagnosticExempleCibleFields.TEXTE,
            DiagnosticExempleCibleFields.SEGMENTS);
        assertThat(map(schema.get("properties")).keySet()).containsExactlyInAnyOrder(
            DiagnosticExempleCibleFields.SEGMENT_NUMERO,
            DiagnosticExempleCibleFields.TEXTE,
            DiagnosticExempleCibleFields.SEGMENTS);

        String brut = resourceText(SCHEMA).toLowerCase(Locale.ROOT);
        assertThat(brut).doesNotContain("note_globale", "niveau_cecrl", "scores_criteres", "/20");
        assertThat(brut)
            .as("le serveur pose lui-meme les niveaux ET la phrase du candidat")
            .doesNotContain("\"niveau_vise\"", "\"niveau_constate\"", "\"original\"",
                "\"level_estimate\"");
    }

    /**
     * LA PHRASE SE DESIGNE, ELLE NE SE RECOPIE PAS — technique du contrat v12 des
     * productions, qui a supprime la categorie entiere des citations
     * introuvables. Le champ est un ENTIER : il n'y a aucun endroit ou loger une
     * phrase inventee.
     */
    @Test
    void laPhraseDuCandidatSeDesignePArUnEntier() {
        Map<String, Object> numero = map(map(resource(SCHEMA).get("properties"))
            .get(DiagnosticExempleCibleFields.SEGMENT_NUMERO));

        assertThat(numero)
            .containsEntry("type", "integer")
            .containsEntry("minimum", 1);
    }

    @Test
    void lesPlafondsDeStructureSontDansLeSchema() {
        Map<String, Object> properties = map(resource(SCHEMA).get("properties"));

        Map<String, Object> texte = map(properties.get(DiagnosticExempleCibleFields.TEXTE));
        assertThat(texte.get("minLength")).isEqualTo(1);
        assertThat(texte.get("maxLength")).isInstanceOf(Number.class);

        Map<String, Object> segments = map(properties.get(DiagnosticExempleCibleFields.SEGMENTS));
        assertThat(segments)
            .containsEntry("type", "array")
            .containsEntry("minItems", 2)
            .containsEntry("maxItems", 3);
        Map<String, Object> segment = map(segments.get("items"));
        assertThat(segment).containsEntry("additionalProperties", false);
        Map<String, Object> champs = map(segment.get("properties"));
        assertThat(champs.keySet()).containsExactlyInAnyOrder(
            DiagnosticExempleCibleFields.EXTRAIT, DiagnosticExempleCibleFields.APPORT);
        for (String cle : champs.keySet()) {
            assertThat(map(champs.get(cle)).get("minLength")).isEqualTo(1);
            assertThat(map(champs.get(cle)).get("maxLength")).isInstanceOf(Number.class);
        }
    }

    /**
     * Le plafond de l'etiquette est declare EN MOTS par la grille — c'est elle qui
     * porte la regle pedagogique, et le filet de surlignage la lit de la. Aucun
     * nombre en dur dans le Java.
     */
    @Test
    void laGrilleDeclareLePlafondEnMots() {
        Map<String, Object> contraintes =
            map(map(resource(RUBRIQUES).get("commun")).get("contraintes_longueur"));

        assertThat(contraintes).containsEntry(DiagnosticExempleCibleFields.APPORT, 3);
    }

    /**
     * LE CONTRAT D'ANALYSE NE BOUGE PAS D'UN OCTET. C'est la raison d'etre du
     * montage en deux appels : le depot a mesure qu'ajouter un bloc a une grille
     * qui juge fait tomber l'accord exact de 81,8 % a 75,6 % (v10/v11). Le
     * correcteur du diagnostic ne doit apprendre nulle part qu'on va reecrire
     * quoi que ce soit.
     */
    @Test
    void leContratDAnalyseIgnoreToutDeLaReecriture() {
        String schema = resourceText(ANALYSE_SCHEMA).toLowerCase(Locale.ROOT);
        String rubriques = resourceText(ANALYSE_RUBRIQUES).toLowerCase(Locale.ROOT);

        for (String texte : List.of(schema, rubriques)) {
            assertThat(texte).doesNotContain(
                DiagnosticExempleCibleFields.BLOC,
                DiagnosticExempleCibleFields.SEGMENT_NUMERO,
                "niveau_vise", "reecri", "réécri");
        }
    }

    /**
     * Leçon des rubriques v13 : nos propres prompts etaient ecrits sans accents
     * (ratio 0,0002 sur 96 k lettres), et un LLM imite la langue de son prompt.
     * Ces deux fichiers-ci naissent accentues.
     */
    @Test
    void leFrancaisDesPromptsEstAccentue() {
        for (String chemin : List.of(RUBRIQUES, SCHEMA)) {
            String texte = resourceText(chemin);
            long accents = texte.chars()
                .filter(DiagnosticExempleCibleContractTest::estAccentuee).count();
            long lettres = texte.chars().filter(Character::isLetter).count();
            assertThat((double) accents / lettres)
                .as("ratio d'accents de %s", chemin)
                .isGreaterThan(0.01);
        }
    }

    /**
     * Les ancres respectent le contrat qu'elles enseignent — y compris le controle
     * qui n'existe nulle part ailleurs : chaque extrait est bien une sous-chaine
     * exacte de sa propre phrase reecrite, et le numero designe une phrase qui
     * existe reellement dans la production montree. Une ancre fautive apprendrait
     * au modele a violer le controle serveur.
     */
    @Test
    void chaqueAncreRespecteLeContratQuElleEnseigne() {
        List<?> fewShot = list(map(resource(RUBRIQUES).get("commun")).get("few_shot"));

        assertThat(fewShot).hasSizeGreaterThanOrEqualTo(2);
        for (Object ancre : fewShot) {
            Map<String, Object> item = map(ancre);
            Map<String, Object> attendu = map(item.get("attendu"));
            assertThat(attendu.keySet()).containsExactlyInAnyOrder(
                DiagnosticExempleCibleFields.SEGMENT_NUMERO,
                DiagnosticExempleCibleFields.TEXTE,
                DiagnosticExempleCibleFields.SEGMENTS);

            String production = String.valueOf(item.get("production"));
            int numero = (int) attendu.get(DiagnosticExempleCibleFields.SEGMENT_NUMERO);
            assertThat(production)
                .as("l'ancre designe le numero [%d], il doit exister dans sa production", numero)
                .contains("[" + numero + "]");

            String texte = String.valueOf(attendu.get(DiagnosticExempleCibleFields.TEXTE));
            List<?> segments = list(attendu.get(DiagnosticExempleCibleFields.SEGMENTS));
            assertThat(segments).hasSizeBetween(2, 3);
            for (Object segment : segments) {
                String extrait =
                    String.valueOf(map(segment).get(DiagnosticExempleCibleFields.EXTRAIT));
                assertThat(texte)
                    .as("l'extrait « %s » doit se retrouver mot pour mot dans le texte", extrait)
                    .contains(extrait);
                assertThat(mots(map(segment).get(DiagnosticExempleCibleFields.APPORT)))
                    .isLessThanOrEqualTo(3);
            }
        }
    }

    /** Le POJO et le YAML ne divergent pas : sinon le comportement depend d'une cle. */
    @Test
    void lesReglagesParDefautSontIdentiquesEntreLeYamlEtLePojo() {
        Properties yaml = applicationYaml();
        DiagnosticProperties.ExempleCible pojo = new DiagnosticProperties().getExempleCible();

        assertThat(yaml.getProperty("sejourfr.diagnostic.exemple-cible.enabled"))
            .isEqualTo("${DIAGNOSTIC_EXEMPLE_CIBLE_ENABLED:true}");
        assertThat(yaml.getProperty("sejourfr.diagnostic.exemple-cible.rubrics-version"))
            .isEqualTo("${DIAGNOSTIC_EXEMPLE_CIBLE_RUBRICS_VERSION:v1}");
        assertThat(yaml.getProperty("sejourfr.diagnostic.exemple-cible.tool-schema-version"))
            .isEqualTo("${DIAGNOSTIC_EXEMPLE_CIBLE_TOOL_SCHEMA_VERSION:v1}");
        assertThat(yaml.getProperty("sejourfr.diagnostic.exemple-cible.max-tokens"))
            .isEqualTo(String.valueOf(pojo.getMaxTokens()));
        assertThat(Double.parseDouble(
            yaml.getProperty("sejourfr.diagnostic.exemple-cible.temperature")))
            .as("deux lectures de la meme production doivent rendre la meme phrase")
            .isZero();
        assertThat(pojo.getTemperature()).isZero();
        assertThat(pojo.isEnabled())
            .as("livre ACTIF : c'est la piece de conversion de l'ecran, pas une experimentation")
            .isTrue();
        assertThat(pojo.getRubricsVersion()).isEqualTo("v1");
        assertThat(pojo.getToolSchemaVersion()).isEqualTo("v1");
    }

    // ------------------------------------------------------------- outillage

    private static int mots(Object valeur) {
        String texte = String.valueOf(valeur).trim();
        return texte.isEmpty() ? 0 : texte.split("\\s+").length;
    }

    private static boolean estAccentuee(int c) {
        return "éèêëàâäùûüîïôöçÉÈÊËÀÂÄÙÛÜÎÏÔÖÇ".indexOf(c) >= 0;
    }

    private static Properties applicationYaml() {
        YamlPropertiesFactoryBean yaml = new YamlPropertiesFactoryBean();
        yaml.setResources(new ClassPathResource("application.yaml"));
        Properties props = yaml.getObject();
        assertThat(props).isNotNull();
        return props;
    }

    private Map<String, Object> resource(String path) {
        return objectMapper.readValue(resourceText(path),
            new TypeReference<Map<String, Object>>() {});
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

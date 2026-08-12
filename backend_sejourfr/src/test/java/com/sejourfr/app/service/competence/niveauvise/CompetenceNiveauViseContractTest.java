package com.sejourfr.app.service.competence.niveauvise;

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

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le contrat du SECOND appel du module Competences, « pour viser X ».
 *
 * <p>Ce que verrouille cette classe :
 * <ul>
 *   <li>la paire consignes v1 / tool-schema v1 est coherente et declaree ;</li>
 *   <li>la sortie ne prevoit AUCUN champ ou loger une note, un verdict ou un
 *       niveau — l'interdiction est portee par le schema, pas par une consigne,
 *       et c'est le serveur qui pose {@code niveau_vise} ;</li>
 *   <li>les plafonds (2 a 3 leviers, 2 a 3 segments, longueurs en mots) sont
 *       dans le SCHEMA autant que dans la grille ;</li>
 *   <li>la regle des extraits recopies mot pour mot est ECRITE, puisqu'elle est
 *       VERIFIEE ;</li>
 *   <li>le français des prompts est ACCENTUE (leçon des rubriques v13 : un LLM
 *       imite la langue de son prompt).</li>
 * </ul>
 */
class CompetenceNiveauViseContractTest {

    private static final String RUBRIQUES = "prompts/competence-niveau-vise-rubrics-v1.json";
    private static final String SCHEMA = "prompts/competence-niveau-vise-tool-schema-v1.json";

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
     * Les plafonds sont declares EN MOTS par la grille — c'est elle qui porte la
     * regle pedagogique, et le validateur la lit de la. Aucun nombre en dur dans
     * le Java.
     */
    @Test
    void laGrilleDeclareLesPlafondsEnMots() {
        Map<String, Object> contraintes =
            map(map(resource(RUBRIQUES).get("commun")).get("contraintes_longueur"));

        assertThat(contraintes)
            .containsEntry(CompetenceNiveauViseFields.ACTION, 6)
            .containsEntry(CompetenceNiveauViseFields.EXEMPLE, 5)
            .containsEntry(CompetenceNiveauViseFields.APPORT, 3)
            .containsEntry(CompetenceNiveauViseFields.FORMULE, 8)
            .containsEntry(CompetenceNiveauViseFields.EXPLICATION, 14);
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
            CompetenceNiveauViseFields.LEVIERS,
            CompetenceNiveauViseFields.EXEMPLE_CIBLE,
            CompetenceNiveauViseFields.A_RETENIR);

        Map<String, Object> properties = map(schema.get("properties"));
        assertThat(properties.keySet()).containsExactlyInAnyOrder(
            CompetenceNiveauViseFields.LEVIERS,
            CompetenceNiveauViseFields.EXEMPLE_CIBLE,
            CompetenceNiveauViseFields.A_RETENIR);

        String brut = resourceText(SCHEMA).toLowerCase(Locale.ROOT);
        assertThat(brut).doesNotContain("note_globale", "niveau_cecrl", "scores_criteres", "/20");
        assertThat(brut)
            .as("le serveur pose lui-meme le niveau : le modele n'a aucun champ pour l'ecrire")
            .doesNotContain("\"niveau_vise\"", "\"niveau_constate\"", "\"status\"");
    }

    @Test
    void lesPlafondsDeStructureSontDansLeSchema() {
        Map<String, Object> properties = map(resource(SCHEMA).get("properties"));

        Map<String, Object> leviers = map(properties.get(CompetenceNiveauViseFields.LEVIERS));
        assertThat(leviers)
            .containsEntry("type", "array")
            .containsEntry("minItems", 2)
            .containsEntry("maxItems", 3);
        Map<String, Object> levier = map(leviers.get("items"));
        assertThat(levier).containsEntry("additionalProperties", false);
        assertThat(map(levier.get("properties")).keySet()).containsExactlyInAnyOrder(
            CompetenceNiveauViseFields.ACTION, CompetenceNiveauViseFields.EXEMPLE);

        Map<String, Object> exemple = map(properties.get(CompetenceNiveauViseFields.EXEMPLE_CIBLE));
        assertThat(exemple).containsEntry("additionalProperties", false);
        Map<String, Object> segments =
            map(map(exemple.get("properties")).get(CompetenceNiveauViseFields.SEGMENTS));
        assertThat(segments)
            .containsEntry("type", "array")
            .containsEntry("minItems", 2)
            .containsEntry("maxItems", 3);
        Map<String, Object> segment = map(segments.get("items"));
        assertThat(map(segment.get("properties")).keySet()).containsExactlyInAnyOrder(
            CompetenceNiveauViseFields.EXTRAIT, CompetenceNiveauViseFields.APPORT);

        Map<String, Object> aRetenir = map(properties.get(CompetenceNiveauViseFields.A_RETENIR));
        assertThat(aRetenir).containsEntry("additionalProperties", false);
        assertThat(map(aRetenir.get("properties")).keySet()).containsExactlyInAnyOrder(
            CompetenceNiveauViseFields.FORMULE, CompetenceNiveauViseFields.EXPLICATION);
    }

    /**
     * Chaque champ terminal est borde EN CARACTERES par le schema, en plus du
     * plafond en mots de la grille. Le premier est le filet dur — il ne depend
     * d'aucune cooperation du modele.
     */
    @Test
    void chaqueChampTerminalEstBordeEnCaracteres() {
        Map<String, Object> properties = map(resource(SCHEMA).get("properties"));

        Map<String, Object> levier =
            map(map(properties.get(CompetenceNiveauViseFields.LEVIERS)).get("items"));
        bornes(map(levier.get("properties")), CompetenceNiveauViseFields.ACTION);
        bornes(map(levier.get("properties")), CompetenceNiveauViseFields.EXEMPLE);

        Map<String, Object> exemple =
            map(map(properties.get(CompetenceNiveauViseFields.EXEMPLE_CIBLE)).get("properties"));
        bornes(exemple, CompetenceNiveauViseFields.TEXTE);
        Map<String, Object> segment =
            map(map(exemple.get(CompetenceNiveauViseFields.SEGMENTS)).get("items"));
        bornes(map(segment.get("properties")), CompetenceNiveauViseFields.EXTRAIT);
        bornes(map(segment.get("properties")), CompetenceNiveauViseFields.APPORT);

        Map<String, Object> aRetenir =
            map(map(properties.get(CompetenceNiveauViseFields.A_RETENIR)).get("properties"));
        bornes(aRetenir, CompetenceNiveauViseFields.FORMULE);
        bornes(aRetenir, CompetenceNiveauViseFields.EXPLICATION);
    }

    /**
     * La consigne DIT ce que le serveur VERIFIE — dans cet ordre de confiance. Le
     * controle dur est ce qui tient la regle ; ces sections evitent seulement de
     * la faire violer a chaque appel.
     */
    @Test
    void lesConsignesDisentCeQueLeServeurVerifie() {
        String consignes = resourceText(RUBRIQUES);

        assertThat(consignes)
            .as("l'extrait est recopie caractere pour caractere, et le serveur le cherche")
            .contains("CARACTÈRE POUR CARACTÈRE")
            .contains("le serveur RECHERCHE chaque extrait dans ton texte");
        assertThat(consignes)
            .as("un levier ne vend jamais un moyen deja acquis")
            .contains("jamais un moyen déjà acquis")
            .contains("sont des moyens du niveau A2")
            .contains("ne les propose JAMAIS comme le moyen d'y arriver");
        assertThat(consignes)
            .as("garde-fou oral, identique a celui de l'analyse")
            .contains("la prononciation, l'accent, le débit, la fluidité");
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
                .filter(CompetenceNiveauViseContractTest::estAccentuee).count();
            long lettres = texte.chars().filter(Character::isLetter).count();
            assertThat((double) accents / lettres)
                .as("ratio d'accents de %s", chemin)
                .isGreaterThan(0.01);
        }
    }

    /**
     * Les ancres respectent le contrat qu'elles enseignent — y compris le
     * controle qui n'existe nulle part ailleurs : chaque extrait est bien une
     * sous-chaine exacte de son propre texte modele. Une ancre fautive
     * apprendrait au correcteur a violer le controle serveur.
     */
    @Test
    void chaqueAncreRespecteLeContratQuElleEnseigne() {
        List<?> fewShot = list(map(resource(RUBRIQUES).get("commun")).get("few_shot"));

        assertThat(fewShot).hasSizeGreaterThanOrEqualTo(2);
        for (Object ancre : fewShot) {
            Map<String, Object> attendu = map(map(ancre).get("attendu"));
            assertThat(attendu.keySet()).containsExactlyInAnyOrder(
                CompetenceNiveauViseFields.LEVIERS,
                CompetenceNiveauViseFields.EXEMPLE_CIBLE,
                CompetenceNiveauViseFields.A_RETENIR);

            List<?> leviers = list(attendu.get(CompetenceNiveauViseFields.LEVIERS));
            assertThat(leviers).hasSizeBetween(2, 3);
            for (Object levier : leviers) {
                assertThat(mots(map(levier).get(CompetenceNiveauViseFields.ACTION)))
                    .isLessThanOrEqualTo(6);
                assertThat(mots(map(levier).get(CompetenceNiveauViseFields.EXEMPLE)))
                    .isLessThanOrEqualTo(5);
            }

            Map<String, Object> exemple = map(attendu.get(CompetenceNiveauViseFields.EXEMPLE_CIBLE));
            String texte = String.valueOf(exemple.get(CompetenceNiveauViseFields.TEXTE));
            List<?> segments = list(exemple.get(CompetenceNiveauViseFields.SEGMENTS));
            assertThat(segments).hasSizeBetween(2, 3);
            for (Object segment : segments) {
                String extrait =
                    String.valueOf(map(segment).get(CompetenceNiveauViseFields.EXTRAIT));
                assertThat(texte)
                    .as("l'extrait « %s » doit se retrouver mot pour mot dans le texte", extrait)
                    .contains(extrait);
                assertThat(mots(map(segment).get(CompetenceNiveauViseFields.APPORT)))
                    .isLessThanOrEqualTo(3);
            }

            Map<String, Object> aRetenir = map(attendu.get(CompetenceNiveauViseFields.A_RETENIR));
            assertThat(mots(aRetenir.get(CompetenceNiveauViseFields.FORMULE)))
                .isLessThanOrEqualTo(8);
            assertThat(mots(aRetenir.get(CompetenceNiveauViseFields.EXPLICATION)))
                .isLessThanOrEqualTo(14);
        }
    }

    /** Le POJO et le YAML ne divergent pas : sinon le comportement depend d'une cle. */
    @Test
    void lesReglagesParDefautSontIdentiquesEntreLeYamlEtLePojo() {
        Properties yaml = applicationYaml();
        CompetenceProperties.NiveauVise pojo = new CompetenceProperties().getNiveauVise();

        assertThat(yaml.getProperty("sejourfr.competences.niveau-vise.rubrics-version"))
            .isEqualTo("${COMPETENCE_NIVEAU_VISE_RUBRICS_VERSION:v1}");
        assertThat(yaml.getProperty("sejourfr.competences.niveau-vise.tool-schema-version"))
            .isEqualTo("${COMPETENCE_NIVEAU_VISE_TOOL_SCHEMA_VERSION:v1}");
        assertThat(yaml.getProperty("sejourfr.competences.niveau-vise.max-tokens"))
            .isEqualTo(String.valueOf(pojo.getMaxTokens()));
        assertThat(yaml.getProperty("sejourfr.competences.niveau-vise.max-leviers"))
            .isEqualTo(String.valueOf(pojo.getMaxLeviers()));
        assertThat(Double.parseDouble(
            yaml.getProperty("sejourfr.competences.niveau-vise.temperature")))
            .as("deux lectures de la meme production doivent rendre le meme plan")
            .isZero();
        assertThat(pojo.getTemperature()).isZero();
        assertThat(pojo.isEnabled())
            .as("livre ACTIF : c'est le cœur du nouvel ecran, pas une experimentation")
            .isTrue();
        assertThat(pojo.getRubricsVersion()).isEqualTo("v1");
        assertThat(pojo.getToolSchemaVersion()).isEqualTo("v1");
    }

    // ------------------------------------------------------------- outillage

    private static void bornes(Map<String, Object> properties, String cle) {
        Map<String, Object> champ = map(properties.get(cle));
        assertThat(champ.get("minLength")).as("%s ne doit jamais etre vide", cle).isEqualTo(1);
        assertThat(champ.get("maxLength")).as("%s doit etre borde", cle)
            .isInstanceOf(Number.class);
    }

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

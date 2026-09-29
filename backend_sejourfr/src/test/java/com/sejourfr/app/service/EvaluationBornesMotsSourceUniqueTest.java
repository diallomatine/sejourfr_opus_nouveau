package com.sejourfr.app.service;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.config.YamlPropertiesFactoryBean;
import org.springframework.core.io.ClassPathResource;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Properties;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * GARDE-FOU ANTI-RECHUTE : les bornes de mots d'une tache EE n'ont qu'UNE source
 * de verite, {@code production_tasks.mots_min/mots_max}, injectee dans l'enonce
 * par {@link EvaluationPromptBuilder} sous « LONGUEUR ATTENDUE ». Ni la grille
 * ACTIVE ni le tool-schema ACTIF ne doivent en recopier une deuxieme.
 *
 * <p>Pourquoi ce test existe. Les bornes ont ete recopiees en dur dans les
 * grilles pendant des mois (« tache 1 : 30 a 60 mots ; taches 2 et 3 : 60 a 90
 * mots ») ET dans la description de {@code version_amelioree}. Quand la
 * migration V724 a corrige le minimum reel de T2/T3 (60 -> 40, il refusait des
 * copies recevables), la base et la grille se sont mises a dire deux choses
 * differentes : le correcteur recevait « LONGUEUR ATTENDUE : 40 a 90 » et, dans
 * le meme prompt, « bornes respectees exactement — 60 a 90 ». Consequence
 * concrete pour le candidat : la version amelioree qu'on lui rend visait 60-90
 * mots meme pour une copie de 45 mots parfaitement valide.
 *
 * <p>Mettre le chiffre a jour aux quatre endroits n'aurait fait que reporter le
 * probleme au prochain changement de bornes. La grille RENVOIE desormais au bloc
 * injecte ; ce test interdit qu'on y remette un chiffre. Depuis le tool-schema
 * v8, {@code version_amelioree} a quitte le contrat : le schema ne parle plus du
 * tout de longueur, ce qui clot le sujet de son cote.
 *
 * <p>Il porte sur les versions ACTIVES lues dans {@code application.yaml}, donc
 * il protege aussi les versions futures. Les versions LIVREES (v8..v11, schema
 * v5) gardent volontairement leurs bornes historiques : c'est la trace exacte de
 * ce avec quoi les copies deja notees l'ont ete, et on ne reecrit pas une grille
 * livree.
 */
class EvaluationBornesMotsSourceUniqueTest {

    /**
     * Une plage de longueur de production : deux nombres d'au moins deux
     * chiffres separes par « a / à / - » et suivis de « mots ». Le seuil de deux
     * chiffres ecarte volontairement « un libelle court (5 a 12 mots) », qui
     * decrit la taille d'une puce du rapport, pas la longueur d'une copie.
     */
    private static final Pattern PLAGE_DE_MOTS = Pattern.compile(
        "\\b\\d{2,3}\\s*(?:a|à|-|–)\\s*\\d{2,3}\\s*mots", Pattern.CASE_INSENSITIVE);

    private static final Pattern PLACEHOLDER = Pattern.compile("^\\$\\{[^:}]+:([^}]*)}$");

    @Test
    void la_grille_active_ne_recopie_aucune_borne_de_mots() throws Exception {
        String version = versionActive("sejourfr.production-evaluation.rubrics-version");
        String grille = texte("prompts/production-rubrics-" + version + ".json");

        assertThat(plagesTrouvees(grille))
            .as("grille active (%s) : une borne recopiee ici contredira "
                + "production_tasks des la prochaine migration", version)
            .isEmpty();
        assertThat(grille)
            .as("grille active (%s) : la cle bornes_mots_indicatives dupliquait "
                + "production_tasks sans jamais etre lue nulle part", version)
            .doesNotContain("bornes_mots_indicatives");
        assertThat(grille)
            .as("grille active (%s) : elle doit RENVOYER aux bornes injectees", version)
            .contains("LONGUEUR ATTENDUE");
    }

    @Test
    void le_tool_schema_actif_ne_recopie_aucune_borne_de_mots() throws Exception {
        for (String cle : List.of(
                "sejourfr.production-evaluation.openai.prompt-version",
                "sejourfr.production-evaluation.anthropic.prompt-version",
                "sejourfr.production-evaluation.deepseek.prompt-version")) {
            String version = versionActive(cle);
            String schema = texte("prompts/production-evaluation-tool-schema-" + version + ".json");

            assertThat(plagesTrouvees(schema))
                .as("tool-schema actif (%s, via %s)", version, cle)
                .isEmpty();
            // Le RENVOI n'a de sens que si le schema reclame encore un texte
            // dont la longueur compte. Depuis v8, `version_amelioree` a quitte
            // le contrat : il n'y a plus de longueur a annoncer, donc plus rien
            // a renvoyer — et c'est la meilleure garantie possible contre la
            // rechute, un chiffre qu'on n'ecrit pas ne peut pas se contredire.
            if (schema.contains("version_amelioree")) {
                assertThat(schema)
                    .as("tool-schema actif (%s) : il doit RENVOYER aux bornes injectees", version)
                    .contains("LONGUEUR ATTENDUE");
            } else {
                assertThat(schema)
                    .as("tool-schema actif (%s) : plus aucun champ de longueur, "
                        + "donc plus aucune borne a annoncer", version)
                    .doesNotContain("LONGUEUR ATTENDUE");
            }
        }
    }

    /**
     * Le seul endroit qui a le droit de porter des chiffres de bornes : le bloc
     * construit a partir de l'entite, donc de la base.
     */
    @Test
    void seul_le_prompt_builder_ecrit_des_bornes_et_il_les_lit_dans_la_tache() {
        String source = texteFichier(
            "src/main/java/com/sejourfr/app/service/EvaluationPromptBuilder.java");

        assertThat(source)
            .contains("\"LONGUEUR ATTENDUE : \" + task.getMotsMin() + \" à \" + task.getMotsMax()");
        assertThat(plagesTrouvees(source))
            .as("aucune borne en dur dans le builder : elles viennent de la tache")
            .isEmpty();
    }

    private static List<String> plagesTrouvees(String contenu) {
        return PLAGE_DE_MOTS.matcher(contenu).results()
            .map(java.util.regex.MatchResult::group)
            .toList();
    }

    private static String versionActive(String cle) {
        YamlPropertiesFactoryBean yaml = new YamlPropertiesFactoryBean();
        yaml.setResources(new ClassPathResource("application.yaml"));
        Properties props = yaml.getObject();
        assertThat(props).as("application.yaml").isNotNull();
        String brut = props.getProperty(cle);
        assertThat(brut).as(cle).isNotNull();
        Matcher m = PLACEHOLDER.matcher(brut.trim());
        return m.matches() ? m.group(1) : brut.trim();
    }

    private static String texte(String classpath) throws Exception {
        try (var in = new ClassPathResource(classpath).getInputStream()) {
            return new String(in.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    private static String texteFichier(String chemin) {
        try {
            return java.nio.file.Files.readString(
                java.nio.file.Path.of(chemin), StandardCharsets.UTF_8);
        } catch (java.io.IOException e) {
            throw new AssertionError("source introuvable : " + chemin, e);
        }
    }
}

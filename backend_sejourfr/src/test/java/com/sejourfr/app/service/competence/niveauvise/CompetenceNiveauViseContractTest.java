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
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Properties;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

/**
 * Le contrat du SECOND appel du module Competences, « pour viser X » — version
 * ACTIVE v2, et le retour arriere v1.
 *
 * <p>Ce que verrouille cette classe :
 * <ul>
 *   <li>la paire consignes v2 / tool-schema v2 est coherente et declaree ;</li>
 *   <li>la sortie ne prevoit AUCUN champ ou loger une note, un verdict ou un
 *       niveau — l'interdiction est portee par le schema, pas par une consigne,
 *       et c'est le serveur qui pose {@code niveau_vise} ;</li>
 *   <li><b>le palier est EXIGIBLE</b> : le contrat requiert des
 *       {@code marqueurs_du_palier} typés dans une enumeration fermee, miroir de
 *       {@link MarqueurPalier}. Un champ requis et verifiable force le contenu ;
 *       une consigne ne serait qu'un vœu ;</li>
 *   <li>la consigne ne demande plus « une longueur proche » de la production du
 *       candidat — elle etait en contradiction directe avec la demonstration
 *       d'un palier sur une production de vingt-huit mots ;</li>
 *   <li><b>v1 reste chargeable</b> : le tool-schema v2 se reconstruit en v1 par
 *       une liste ENUMEREE d'editions, et le provider charge encore la paire
 *       v1/v1 ;</li>
 *   <li>le français des prompts est ACCENTUE (leçon des rubriques v13 : un LLM
 *       imite la langue de son prompt).</li>
 * </ul>
 */
class CompetenceNiveauViseContractTest {

    private static final String RUBRIQUES = "prompts/competence-niveau-vise-rubrics-v3.json";
    private static final String SCHEMA = "prompts/competence-niveau-vise-tool-schema-v3.json";
    private static final String RUBRIQUES_V2 = "prompts/competence-niveau-vise-rubrics-v2.json";
    private static final String SCHEMA_V2 = "prompts/competence-niveau-vise-tool-schema-v2.json";
    private static final String RUBRIQUES_V1 = "prompts/competence-niveau-vise-rubrics-v1.json";
    private static final String SCHEMA_V1 = "prompts/competence-niveau-vise-tool-schema-v1.json";

    /** Titre de LA section editee par v3 — la seule qui bouge. */
    private static final String SECTION_LEVIERS = "Les leviers : ce qu'on fait, et avec quels mots";

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void lesConsignesEtLeSchemaFormentUnePaireDeclaree() {
        Map<String, Object> rubriques = resource(RUBRIQUES);

        assertThat(rubriques)
            .containsEntry("rubrics-version", "v3")
            .containsEntry("tool_schema_version", "v3")
            .containsEntry("profile", "TCF_IRN");

        Map<String, Object> commun = map(rubriques.get("commun"));
        assertThat(list(commun.get("sections"))).isNotEmpty();
        assertThat(list(commun.get("few_shot"))).isNotEmpty();
    }

    /**
     * Les plafonds sont declares EN MOTS par la grille — c'est elle qui porte la
     * regle pedagogique, et le validateur la lit de la. Aucun nombre en dur dans
     * le Java, et v2 ne les touche pas.
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
        assertThat(contraintes)
            .as("les plafonds pedagogiques ne bougent pas d'une v1 a l'autre")
            .isEqualTo(map(map(resource(RUBRIQUES_V1).get("commun")).get("contraintes_longueur")));
    }

    /**
     * LA TABLE DES PROCEDES EST UN MIROIR de {@link MarqueurPalier} — et le
     * provider les oppose au BOOT, donc une divergence fait echouer le demarrage
     * plutot que de purger en silence.
     */
    @Test
    void laGrilleDeclareLaMemeTableDeProcedesQueLEnum() {
        Map<String, Object> declares =
            map(map(resource(RUBRIQUES).get("commun")).get("marqueurs_palier"));

        assertThat(declares).containsExactlyInAnyOrderEntriesOf(
            new LinkedHashMap<String, Object>(MarqueurPalier.table()));
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

    /**
     * LE PALIER DEVIENT EXIGIBLE — la contrainte dure avant la consigne. Le
     * modele doit placer la matiere du palier dans son texte puis la designer, et
     * le serveur verifie que le passage s'y trouve. Sans ce champ, le texte
     * modele n'etait qu'une chaine bornee en caracteres : un candidat l'a recopie
     * tel quel, resoumis, et le correcteur l'a reevalue A2.
     */
    @Test
    void leSchemaExigeDesMarqueursDuPalierTypesDansUneEnumerationFermee() {
        Map<String, Object> exemple = map(map(resource(SCHEMA).get("properties"))
            .get(CompetenceNiveauViseFields.EXEMPLE_CIBLE));

        assertThat(strings(exemple.get("required")))
            .contains(CompetenceNiveauViseFields.MARQUEURS_PALIER);

        Map<String, Object> marqueurs =
            map(map(exemple.get("properties")).get(CompetenceNiveauViseFields.MARQUEURS_PALIER));
        assertThat(marqueurs)
            .containsEntry("type", "array")
            .containsEntry("minItems", 2)
            .containsEntry("maxItems", 3);

        Map<String, Object> item = map(marqueurs.get("items"));
        assertThat(item).containsEntry("additionalProperties", false);
        assertThat(strings(item.get("required"))).containsExactlyInAnyOrder(
            CompetenceNiveauViseFields.EXTRAIT, CompetenceNiveauViseFields.TYPE);

        Map<String, Object> type =
            map(map(item.get("properties")).get(CompetenceNiveauViseFields.TYPE));
        assertThat(strings(type.get("enum")))
            .containsExactlyInAnyOrderElementsOf(MarqueurPalier.table().keySet());
    }

    /**
     * UN LEVIER EST RATTACHE A UNE OPERATION DE LANGUE PAR LE SCHEMA, pas par une
     * consigne — contrat v3. Le champ est <b>requis</b> et typé dans la MEME
     * enumeration fermee que les marqueurs du palier : le modele ne peut plus
     * produire « rends ton invitation plus chaleureuse » sans devoir dire quel
     * moyen de langue le porte. Une consigne, elle, ne serait qu'un vœu.
     */
    @Test
    void leSchemaExigeUnProcedeDeLevierTypeDansLaMemeEnumerationQueLesMarqueurs() {
        Map<String, Object> item = map(map(map(resource(SCHEMA).get("properties"))
            .get(CompetenceNiveauViseFields.LEVIERS)).get("items"));

        assertThat(strings(item.get("required")))
            .containsExactlyInAnyOrder(CompetenceNiveauViseFields.ACTION,
                CompetenceNiveauViseFields.EXEMPLE, CompetenceNiveauViseFields.PROCEDE);

        Map<String, Object> procede =
            map(map(item.get("properties")).get(CompetenceNiveauViseFields.PROCEDE));
        assertThat(procede).containsEntry("type", "string");
        assertThat(strings(procede.get("enum")))
            .as("une seule table de procedes, partagee avec les marqueurs du palier")
            .containsExactlyInAnyOrderElementsOf(MarqueurPalier.table().keySet());

        Map<String, Object> marqueur = map(map(map(map(map(resource(SCHEMA).get("properties"))
            .get(CompetenceNiveauViseFields.EXEMPLE_CIBLE)).get("properties"))
            .get(CompetenceNiveauViseFields.MARQUEURS_PALIER)).get("items"));
        assertThat(strings(procede.get("enum")))
            .as("les deux champs lisent LA MEME enumeration, jamais deux copies")
            .containsExactlyInAnyOrderElementsOf(strings(map(map(marqueur.get("properties"))
                .get(CompetenceNiveauViseFields.TYPE)).get("enum")));
    }

    /**
     * LA CONSIGNE MONTRE LA TRANSFORMATION ATTENDUE, sur le cas reel qui a motive
     * v3 : trois leviers vers le B2 qui etaient des conseils de ton. Une regle
     * enoncee sans exemple se respecte moins bien qu'une regle montree.
     */
    @Test
    void laConsigneMontreLaTransformationAttendueDUnLevierDeTon() {
        String leviers = String.valueOf(section(resource(RUBRIQUES), SECTION_LEVIERS)
            .get("contenu"));

        assertThat(leviers)
            .as("le cas refuse est nomme, et il vient de la production")
            .contains("Rends ton invitation plus chaleureuse")
            .as("la version acceptee nomme son procede et le montre")
            .contains("Subordonne ta demande à sa disponibilité")
            .contains("si jamais tu es libre")
            .contains("SUBORDINATION");
        assertThat(leviers)
            .as("les six procedes sont expliques la ou le modele ecrit ses leviers")
            .contains(MarqueurPalier.table().keySet());
        assertThat(leviers)
            .as("le modele doit savoir qu'un procede fautif ne lui coute pas son levier")
            .contains("Le serveur ne retire jamais un levier à cause de son procédé");
    }

    /**
     * LA CONSIGNE CONTRADICTOIRE EST LEVEE. « Longueur PROCHE de la sienne » et
     * « jamais une performance litteraire » demandaient au modele de rester au
     * format d'une production de vingt-huit mots tout en demontrant un palier
     * superieur : les deux ne peuvent pas etre vrais ensemble. La reference est
     * desormais la fourchette du SUJET.
     */
    @Test
    void laConsigneNeDemandePlusDeGarderLaLongueurDeLaProduction() {
        String consignes = resourceText(RUBRIQUES);

        assertThat(consignes)
            .doesNotContain("Longueur PROCHE de la sienne")
            .doesNotContain("jamais une performance littéraire");
        assertThat(consignes)
            .as("c'est la fourchette du sujet qui fait reference, et le serveur la recompte")
            .contains("c'est la fourchette de mots DU SUJET qui fait référence")
            .contains("`mots_min`")
            .contains("`mots_max`");
        assertThat(resourceText(SCHEMA))
            .as("le schema aussi portait la consigne contradictoire")
            .doesNotContain("Longueur PROCHE de la sienne");
    }

    /**
     * UN LEVIER NOMME UN MOYEN DE LANGUE, jamais un effet de ton. Cas reel : les
     * trois leviers servis etaient « rends ton invitation plus chaleureuse »,
     * « propose une alternative concrete », « termine par une formule
     * engageante » — on peut etre tres chaleureux en A2.
     */
    @Test
    void laConsigneInterditLesLeviersDeTon() {
        assertThat(resourceText(RUBRIQUES))
            .contains("UN LEVIER NOMME UN MOYEN DE LANGUE, JAMAIS UN EFFET DE TON")
            .contains("on peut être très chaleureux en A2");
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
            CompetenceNiveauViseFields.ACTION, CompetenceNiveauViseFields.EXEMPLE,
            CompetenceNiveauViseFields.PROCEDE);

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
        Map<String, Object> marqueur =
            map(map(exemple.get(CompetenceNiveauViseFields.MARQUEURS_PALIER)).get("items"));
        bornes(map(marqueur.get("properties")), CompetenceNiveauViseFields.EXTRAIT);

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
            .as("un extrait introuvable ne coute plus que son surlignage — dire l'inverse "
                + "serait un mensonge au modele")
            .doesNotContain("tout le bloc est refusé, et le candidat ne voit rien");
        assertThat(consignes)
            .as("un levier ne vend jamais un moyen deja acquis")
            .contains("jamais un moyen déjà acquis")
            .contains("sont des moyens du niveau A2")
            .contains("ne les propose JAMAIS comme le moyen d'y arriver");
        assertThat(consignes)
            .as("garde-fou oral, identique a celui de l'analyse")
            .contains("la prononciation, l'accent, le débit, la fluidité");
        assertThat(consignes)
            .as("le palier cible est la MARCHE SUIVANTE, et le modele doit le savoir")
            .contains("le palier JUSTE AU-DESSUS de ce qui a été observé");
    }

    /**
     * Leçon des rubriques v13 : nos propres prompts etaient ecrits sans accents
     * (ratio 0,0002 sur 96 k lettres), et un LLM imite la langue de son prompt.
     * Ces fichiers-ci naissent accentues.
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
     * Les ancres respectent le contrat qu'elles enseignent — y compris les deux
     * controles serveur : chaque extrait, de {@code segments} comme de
     * {@code marqueurs_du_palier}, est une sous-chaine exacte de son propre texte
     * modele, et aucun procede ne sur-vend le palier de l'ancre. Une ancre
     * fautive apprendrait au correcteur a violer le controle serveur.
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

            String cible = String.valueOf(map(ancre).get("niveau_vise"));
            List<?> leviers = list(attendu.get(CompetenceNiveauViseFields.LEVIERS));
            assertThat(leviers).hasSizeBetween(2, 3);
            for (Object levier : leviers) {
                assertThat(mots(map(levier).get(CompetenceNiveauViseFields.ACTION)))
                    .isLessThanOrEqualTo(6);
                assertThat(mots(map(levier).get(CompetenceNiveauViseFields.EXEMPLE)))
                    .isLessThanOrEqualTo(5);
                // Une ancre dont le levier n'aurait pas de procede, ou en aurait un
                // qui sur-vend son palier, apprendrait au modele l'anomalie qu'on
                // vient de rendre mesurable.
                MarqueurPalier procede = MarqueurPalier.de(
                    String.valueOf(map(levier).get(CompetenceNiveauViseFields.PROCEDE)))
                    .orElse(null);
                assertThat(procede).as("procede inconnu ou absent dans une ancre").isNotNull();
                assertThat(procede.demontre(com.sejourfr.app.enums.TargetLevel.valueOf(cible)))
                    .as("le levier d'une ancre %s ne doit pas sur-vendre son palier", cible)
                    .isTrue();
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

            List<?> marqueurs = list(exemple.get(CompetenceNiveauViseFields.MARQUEURS_PALIER));
            assertThat(marqueurs).hasSizeBetween(2, 3);
            for (Object marqueur : marqueurs) {
                String extrait =
                    String.valueOf(map(marqueur).get(CompetenceNiveauViseFields.EXTRAIT));
                assertThat(texte)
                    .as("le marqueur « %s » doit se retrouver mot pour mot dans le texte", extrait)
                    .contains(extrait);
                MarqueurPalier type = MarqueurPalier.de(
                    String.valueOf(map(marqueur).get(CompetenceNiveauViseFields.TYPE))).orElse(null);
                assertThat(type).as("procede inconnu dans une ancre").isNotNull();
                assertThat(type.demontre(com.sejourfr.app.enums.TargetLevel.valueOf(cible)))
                    .as("l'ancre %s ne doit pas sur-vendre son palier", cible)
                    .isTrue();
            }

            Map<String, Object> aRetenir = map(attendu.get(CompetenceNiveauViseFields.A_RETENIR));
            assertThat(mots(aRetenir.get(CompetenceNiveauViseFields.FORMULE)))
                .isLessThanOrEqualTo(8);
            assertThat(mots(aRetenir.get(CompetenceNiveauViseFields.EXPLICATION)))
                .isLessThanOrEqualTo(14);
        }
    }

    // ------------------------------------------------------- retour arriere

    /**
     * ON VERSIONNE, ON NE REECRIT JAMAIS. Le tool-schema v2 se reconstruit en v1
     * par une liste ENUMEREE d'editions — la propriete ajoutee, son entree
     * {@code required} et les descriptions retouchees. Tout le reste doit etre
     * strictement egal : si une borne, une cardinalite ou un champ avait bouge en
     * passant, ce test le dirait.
     */
    /**
     * ON VERSIONNE, ON NE REECRIT JAMAIS — v3 ⇄ v2. Le tool-schema v3 se
     * reconstruit en v2 par une liste ENUMEREE d'editions : la propriete
     * {@code procede} ajoutee, son entree {@code required}, et trois descriptions
     * retouchees. Tout le reste — bornes, cardinalites, marqueurs du palier,
     * {@code exemple_cible}, {@code a_retenir} — doit etre strictement egal.
     */
    @Test
    void leToolSchemaV3SeReconstruitEnV2ParUneListeEnumereeDEditions() {
        Map<String, Object> v2 = resource(SCHEMA_V2);
        Map<String, Object> reconstruit = resource(SCHEMA);

        // (1) La propriete ajoutee et son caractere obligatoire.
        Map<String, Object> leviers =
            map(map(reconstruit.get("properties")).get(CompetenceNiveauViseFields.LEVIERS));
        Map<String, Object> item = map(leviers.get("items"));
        map(item.get("properties")).remove(CompetenceNiveauViseFields.PROCEDE);
        List<Object> requis = new ArrayList<>(list(item.get("required")));
        requis.remove(CompetenceNiveauViseFields.PROCEDE);
        item.put("required", requis);

        // (2) Les descriptions retouchees, restaurees une par une.
        assertThat(String.valueOf(reconstruit.get("description")))
            .as("la description racine s'etoffe, elle ne se reecrit pas")
            .startsWith(String.valueOf(v2.get("description")));
        reconstruit.put("title", v2.get("title"));
        reconstruit.put("description", v2.get("description"));
        leviers.put("description", description(v2, CompetenceNiveauViseFields.LEVIERS));

        assertThat(reconstruit).isEqualTo(v2);
    }

    /**
     * MEMES EDITIONS, COTE CONSIGNES : v3 n'edite que la section des leviers et
     * n'ajoute qu'un {@code procede} a chaque levier des ancres. Le role, les
     * marqueurs du palier, les segments, l'exemple cible, la tournure a retenir,
     * les interdictions et l'accentuation sont ceux de v2, au bit pres.
     */
    @Test
    void lesConsignesV3SeReconstruisentEnV2ParUneListeEnumereeDEditions() {
        Map<String, Object> v2 = resource(RUBRIQUES_V2);
        Map<String, Object> reconstruit = resource(RUBRIQUES);

        // (1) La paire de versions declaree.
        reconstruit.put("rubrics-version", "v2");
        reconstruit.put("tool_schema_version", "v2");

        // (2) LA section editee — une seule.
        Map<String, Object> commun = map(reconstruit.get("commun"));
        Map<String, Object> leviersV2 = section(v2, SECTION_LEVIERS);
        section(reconstruit, SECTION_LEVIERS).put("contenu", leviersV2.get("contenu"));

        // (3) Le procede ajoute a chaque levier des ancres.
        for (Object ancre : list(commun.get("few_shot"))) {
            Map<String, Object> attendu = map(map(ancre).get("attendu"));
            for (Object levier : list(attendu.get(CompetenceNiveauViseFields.LEVIERS))) {
                map(levier).remove(CompetenceNiveauViseFields.PROCEDE);
            }
        }

        assertThat(reconstruit).isEqualTo(v2);
    }

    @Test
    void leToolSchemaV2SeReconstruitEnV1ParUneListeEnumereeDEditions() {
        Map<String, Object> v1 = resource(SCHEMA_V1);
        Map<String, Object> reconstruit = resource(SCHEMA_V2);

        // (1) La propriete ajoutee et son caractere obligatoire.
        Map<String, Object> exemple = map(map(reconstruit.get("properties"))
            .get(CompetenceNiveauViseFields.EXEMPLE_CIBLE));
        map(exemple.get("properties")).remove(CompetenceNiveauViseFields.MARQUEURS_PALIER);
        List<Object> requis = new ArrayList<>(list(exemple.get("required")));
        requis.remove(CompetenceNiveauViseFields.MARQUEURS_PALIER);
        exemple.put("required", requis);

        // (2) Les descriptions retouchees, restaurees une par une.
        reconstruit.put("title", v1.get("title"));
        reconstruit.put("description", v1.get("description"));
        map(map(reconstruit.get("properties")).get(CompetenceNiveauViseFields.LEVIERS))
            .put("description", description(v1, CompetenceNiveauViseFields.LEVIERS));
        exemple.put("description", description(v1, CompetenceNiveauViseFields.EXEMPLE_CIBLE));
        Map<String, Object> proprietes = map(exemple.get("properties"));
        map(proprietes.get(CompetenceNiveauViseFields.TEXTE)).put("description",
            map(map(map(map(v1.get("properties")).get(CompetenceNiveauViseFields.EXEMPLE_CIBLE))
                .get("properties")).get(CompetenceNiveauViseFields.TEXTE)).get("description"));
        map(proprietes.get(CompetenceNiveauViseFields.SEGMENTS)).put("description",
            map(map(map(map(v1.get("properties")).get(CompetenceNiveauViseFields.EXEMPLE_CIBLE))
                .get("properties")).get(CompetenceNiveauViseFields.SEGMENTS)).get("description"));

        assertThat(reconstruit).isEqualTo(v1);
    }

    /**
     * LE RETOUR ARRIERE EST REEL : sous v2, le procede n'est ni demande, ni
     * admis, ni compte. Les marqueurs du palier, eux, restent exiges — les deux
     * chantiers se defont separement.
     */
    @Test
    void laPaireV2ResteChargeableEtIgnoreLeProcede() {
        CompetenceProperties props = new CompetenceProperties();
        props.getNiveauVise().setRubricsVersion("v2");
        props.getNiveauVise().setToolSchemaVersion("v2");
        CompetenceNiveauViseRubricsProvider provider =
            new CompetenceNiveauViseRubricsProvider(props, objectMapper);

        assertThatCode(provider::load).doesNotThrowAnyException();
        assertThat(provider.leviersPortentUnProcede())
            .as("sous v2, le chantier du procede reste INERTE")
            .isFalse();
        assertThat(provider.marqueursDuPalierExiges()).isTrue();
        assertThat(resourceText(SCHEMA_V2))
            .as("le contrat v2 ne nomme nulle part le procede d'un levier")
            .doesNotContain("\"procede\"");
    }

    /** Sous v3, le champ est bien demande — l'allowlist n'est pas un test sur v3. */
    @Test
    void laPaireActiveExigeLeProcedeDesLeviers() {
        CompetenceNiveauViseRubricsProvider provider =
            new CompetenceNiveauViseRubricsProvider(new CompetenceProperties(), objectMapper);
        provider.load();

        assertThat(provider.leviersPortentUnProcede()).isTrue();
        assertThat(provider.marqueursDuPalierExiges()).isTrue();
        assertThat(CompetenceNiveauViseFields.porteLeProcedeDesLeviers("v4"))
            .as("une version future n'herite pas du champ par accident")
            .isFalse();
    }

    /** Le retour arriere est REEL : la paire v1/v1 se charge encore, sans marqueurs. */
    @Test
    void laPaireV1ResteChargeable() {
        CompetenceProperties props = new CompetenceProperties();
        props.getNiveauVise().setRubricsVersion("v1");
        props.getNiveauVise().setToolSchemaVersion("v1");
        CompetenceNiveauViseRubricsProvider provider =
            new CompetenceNiveauViseRubricsProvider(props, objectMapper);

        assertThatCode(provider::load).doesNotThrowAnyException();
        assertThat(provider.marqueursDuPalierExiges())
            .as("sous v1, tout le chantier du palier exigible reste INERTE")
            .isFalse();
        assertThat(resource(RUBRIQUES_V1))
            .containsEntry("rubrics-version", "v1")
            .containsEntry("tool_schema_version", "v1");
        assertThat(map(resource(RUBRIQUES_V1).get("commun")))
            .doesNotContainKey("marqueurs_palier");
    }

    /** Une version inconnue echoue au BOOT — jamais de repli muet. */
    @Test
    void uneVersionInconnueFaitEchouerLeDemarrage() {
        CompetenceProperties props = new CompetenceProperties();
        props.getNiveauVise().setRubricsVersion("v42");
        CompetenceNiveauViseRubricsProvider provider =
            new CompetenceNiveauViseRubricsProvider(props, objectMapper);

        assertThatCode(provider::load).isInstanceOf(IllegalStateException.class);
    }

    /** Une paire incoherente (consignes v2, tool-schema v1) echoue au BOOT. */
    @Test
    void unePaireIncoherenteFaitEchouerLeDemarrage() {
        CompetenceProperties props = new CompetenceProperties();
        props.getNiveauVise().setRubricsVersion("v2");
        props.getNiveauVise().setToolSchemaVersion("v1");
        CompetenceNiveauViseRubricsProvider provider =
            new CompetenceNiveauViseRubricsProvider(props, objectMapper);

        assertThatCode(provider::load).isInstanceOf(IllegalStateException.class);
    }

    /** Le POJO et le YAML ne divergent pas : sinon le comportement depend d'une cle. */
    @Test
    void lesReglagesParDefautSontIdentiquesEntreLeYamlEtLePojo() {
        Properties yaml = applicationYaml();
        CompetenceProperties.NiveauVise pojo = new CompetenceProperties().getNiveauVise();

        assertThat(yaml.getProperty("sejourfr.competences.niveau-vise.rubrics-version"))
            .isEqualTo("${COMPETENCE_NIVEAU_VISE_RUBRICS_VERSION:v3}");
        assertThat(yaml.getProperty("sejourfr.competences.niveau-vise.tool-schema-version"))
            .isEqualTo("${COMPETENCE_NIVEAU_VISE_TOOL_SCHEMA_VERSION:v3}");
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
        assertThat(pojo.getRubricsVersion()).isEqualTo("v3");
        assertThat(pojo.getToolSchemaVersion()).isEqualTo("v3");
    }

    // ------------------------------------------------------------- outillage

    private static Object description(Map<String, Object> schema, String propriete) {
        return map(map(schema.get("properties")).get(propriete)).get("description");
    }

    /** LA section de consignes portant ce titre — une seule, sinon le test echoue. */
    private static Map<String, Object> section(Map<String, Object> rubriques, String titre) {
        List<Map<String, Object>> trouvees =
            list(map(rubriques.get("commun")).get("sections")).stream()
                .map(CompetenceNiveauViseContractTest::map)
                .filter(s -> titre.equals(String.valueOf(s.get("titre"))))
                .toList();
        assertThat(trouvees).as("section « %s »", titre).hasSize(1);
        return trouvees.get(0);
    }

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

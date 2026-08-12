package com.sejourfr.app.service.competence;

import com.sejourfr.app.config.CompetenceProperties;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.service.EvaluationProductionSegments;
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
 * FIGE le contrat de l'analyse ciblee : les paires consignes/tool-schema v1, v2
 * et v3, et le budget de tokens.
 *
 * <p>Ce que ce test protege vraiment : le module promet au candidat un retour
 * COURT et <b>SANS NOTE</b>. Un champ de note ajoute au schema changerait cette
 * promesse sans qu'aucun test fonctionnel ne bronche — le JSON serait valide,
 * l'analyse persisterait, et la carte de resultat mentirait sur ce qu'un
 * micro-exercice permet de dire.
 *
 * <p><b>Le NIVEAU CECRL, lui, est desormais autorise</b> et meme obligatoire
 * (v3, champ {@code level_reached}). L'ancienne regle « ni note, ni niveau » est
 * revoquee sur ce point seulement : le candidat vient chercher « ou j'en suis ».
 * L'interdiction de la note, elle, ne bouge pas d'un pouce.
 */
class CompetenceAnalysisContractTest {

    /** Contrat v1/v2. */
    private static final List<String> CLES = List.of(
        "status", "verdict", "success_point", "improvement_priority", "improved_version");
    /** Contrat v3, dans l'ordre du schema. */
    private static final List<String> CLES_V3 = List.of(
        "status", "level_reached", "verdict", "strength_tag", "focus_tag");
    /** Contrat v4 : ceux de v3, plus la preuve du niveau — la seule cle OPTIONNELLE. */
    private static final List<String> CLES_V4 = List.of(
        "status", "level_reached", "level_evidence", "verdict", "strength_tag", "focus_tag");
    /** Les deux seules sections que v4 edite, et le titre renumerote. */
    private static final String TITRE_CHAMPS_V3 = "Les cinq champs à produire";
    private static final String TITRE_CHAMPS_V4 = "Les six champs à produire";
    private static final String TITRE_INTERDICTIONS = "Interdictions absolues";
    private static final List<String> STATUTS = List.of("VALIDATED", "PARTIAL", "NOT_VALIDATED");
    /** Profil TCF IRN : plafonne au B2, jamais C1 ni C2. */
    private static final List<String> NIVEAUX =
        List.of("A1_NON_ATTEINT", "A1", "A2", "B1", "B2");

    /**
     * Sections de v2 que v3 doit reprendre AU BIT PRES : ce sont celles qui
     * JUGENT. Le role et le perimetre, la definition des trois verdicts et leur
     * regle de decision, la brievete qui n'est pas un defaut, et le garde-fou
     * oral. v3 change ce que le correcteur PRODUIT, jamais la façon dont il juge
     * — sans ce verrou, une refonte de la restitution pourrait deplacer un seuil
     * sans que personne ne le voie.
     */
    private static final List<String> SECTIONS_QUI_JUGENT = List.of(
        "Rôle et périmètre",
        "Les trois verdicts",
        "Quand la production est courte",
        "Productions orales : ce que la transcription permet de dire");

    /** L'enumeration des champs, la SEULE difference de la section d'accentuation. */
    private static final String ENUM_CHAMPS_V2 =
        "Tes quatre champs de texte — `verdict`, `success_point`, "
            + "`improvement_priority`, `improved_version` —";
    private static final String ENUM_CHAMPS_V3 =
        "Tes trois champs de texte — `verdict`, `strength_tag`, `focus_tag` —";
    /** Derniere phrase de v2, qui parle d'un champ que v3 n'a plus. */
    private static final String QUEUE_V2 =
        " `improved_version` n'est pas une citation : c'est TA reformulation, elle est donc "
            + "entièrement accentuée, même quand elle reprend ses idées.";

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

        assertThat(analysis.getRubricsVersion()).isEqualTo("v4");
        assertThat(analysis.getToolSchemaVersion()).isEqualTo("v4");
        assertThat(yaml.getProperty("sejourfr.competences.analysis.rubrics-version"))
            .isEqualTo("${COMPETENCE_RUBRICS_VERSION:v4}");
        assertThat(yaml.getProperty("sejourfr.competences.analysis.tool-schema-version"))
            .isEqualTo("${COMPETENCE_TOOL_SCHEMA_VERSION:v4}");
    }

    /**
     * v2 = v1 pour TOUT ce qui juge : memes plafonds de longueur, memes trois
     * verdicts, memes ancres, memes huit sections. Elle n'ajoute qu'une neuvieme
     * section, en fin de bloc commun : le francais rendu au candidat doit etre
     * ACCENTUE, et ce qu'on cite de lui se recopie tel quel.
     */
    @Test
    void lesConsignesV2NAjoutentQueLaRegleDAccentuation() {
        Map<String, Object> v1 = resource("prompts/competence-analysis-rubrics-v1.json");
        Map<String, Object> v2 = resource("prompts/competence-analysis-rubrics-v2.json");

        assertThat(v2)
            .containsEntry("rubrics-version", "v2")
            .containsEntry("tool_schema_version", "v2")
            .containsEntry("profile", "TCF_IRN");

        Map<String, Object> communV1 = map(v1.get("commun"));
        Map<String, Object> communV2 = map(v2.get("commun"));
        for (String bloc : List.of("contraintes_longueur", "statuts", "few_shot")) {
            assertThat(communV2.get(bloc))
                .as("v2 ne touche pas a commun." + bloc)
                .isEqualTo(communV1.get(bloc));
        }

        List<?> sectionsV1 = list(communV1.get("sections"));
        List<?> sectionsV2 = list(communV2.get("sections"));
        assertThat(sectionsV2)
            .as("une seule section ajoutee, aucune reecrite")
            .hasSize(sectionsV1.size() + 1);
        assertThat(sectionsV2.subList(0, sectionsV1.size()))
            .as("les sections precedentes sont reprises telles quelles, dans l'ordre")
            .isEqualTo(sectionsV1);

        String contenu = String.valueOf(map(sectionsV2.get(sectionsV2.size() - 1)).get("contenu"));
        assertThat(contenu)
            .contains("NE CHANGE RIEN À TON VERDICT")
            .contains("ACCENTUÉS")
            .as("l'exception des citations est explicite")
            .contains("UNE SEULE EXCEPTION : les mots du candidat");
    }

    /**
     * Le contrat de sortie v2 : celui de v1, ses descriptions ACCENTUEES.
     * Verrou : egalite apres repli des accents — aucune reformulation ne peut se
     * glisser dans la passe d'accentuation. Ni champ ajoute, ni champ retire.
     */
    @Test
    void leToolSchemaV2NAccentueQueLesDescriptionsDeV1() {
        Map<String, Object> v1 = resource("prompts/competence-analysis-tool-schema-v1.json");
        Map<String, Object> v2 = resource("prompts/competence-analysis-tool-schema-v2.json");

        assertThat(strings(v2.get("required"))).containsExactlyElementsOf(CLES);
        assertThat(map(v2.get("properties")).keySet())
            .containsExactlyInAnyOrderElementsOf(CLES);
        assertThat(v2.get("additionalProperties")).isEqualTo(false);

        for (String cle : CLES) {
            Map<String, Object> champV1 = map(map(v1.get("properties")).get(cle));
            Map<String, Object> champV2 = map(map(v2.get("properties")).get(cle));
            for (String contrainte : List.of("type", "minLength", "maxLength", "enum")) {
                assertThat(champV2.get(contrainte))
                    .as("%s.%s : le contrat ne bouge pas", cle, contrainte)
                    .isEqualTo(champV1.get(contrainte));
            }
            String replie = sansAccents(String.valueOf(champV2.get("description")));
            assertThat(replie)
                .as("%s : on accentue, on ne reecrit pas", cle)
                .startsWith(String.valueOf(champV1.get("description")));
        }
        assertThat(String.valueOf(v2.get("description")))
            .as("la regle vit aussi dans la description du contrat")
            .contains("ACCENTUÉ")
            .contains("recopient tels quels");
    }

    // ======================================================== contrat v3 ====

    @Test
    void lesConsignesV3DeclarentLeToolSchemaV3EtLeProfilTcfIrn() {
        assertThat(resource("prompts/competence-analysis-rubrics-v3.json"))
            .containsEntry("rubrics-version", "v3")
            .containsEntry("tool_schema_version", "v3")
            .containsEntry("profile", "TCF_IRN");
    }

    /**
     * LE VERROU CENTRAL DE v3 : elle est v2 <b>au bit pres</b> partout ou l'on
     * juge. Meme technique que {@code ProductionEvaluationContractTest}, qui
     * reconstruit v13 depuis v14 en y remettant les fragments retires : ici on
     * compare directement les blocs qui n'avaient aucune raison de bouger.
     *
     * <p>Ce qui change dans v3, et rien d'autre : les champs produits, leurs
     * plafonds, la section qui explique comment attribuer {@code level_reached},
     * et les trois sections qui NOMMENT les champs (perimetre, ton,
     * interdictions, accentuation).
     */
    @Test
    void lesConsignesV3SontV2AuBitPresPourToutCeQuiJuge() {
        Map<String, Object> communV2 = map(
            resource("prompts/competence-analysis-rubrics-v2.json").get("commun"));
        Map<String, Object> communV3 = map(
            resource("prompts/competence-analysis-rubrics-v3.json").get("commun"));

        assertThat(communV3.get("statuts"))
            .as("les trois verdicts et leurs definitions ne bougent pas d'un caractere")
            .isEqualTo(communV2.get("statuts"));

        Map<String, Object> sectionsV2 = sectionsParTitre(communV2);
        Map<String, Object> sectionsV3 = sectionsParTitre(communV3);
        for (String titre : SECTIONS_QUI_JUGENT) {
            assertThat(sectionsV3.get(titre))
                .as("la section « %s » juge : elle est reprise telle quelle", titre)
                .isEqualTo(sectionsV2.get(titre));
        }
    }

    /**
     * La regle d'ACCENTUATION est elle aussi celle de v2, a deux editions pres —
     * et le test les inverse pour reconstruire v2. Sans cette reconstruction,
     * n'importe quelle reformulation pourrait se glisser dans le pretexte d'un
     * renommage de champ.
     */
    @Test
    void laRegleDAccentuationDeV3EstCelleDeV2AuxNomsDeChampsPres() {
        String titre = "Le français que TU écris : accentuation obligatoire";
        String v2 = contenuSection(
            map(resource("prompts/competence-analysis-rubrics-v2.json").get("commun")), titre);
        String v3 = contenuSection(
            map(resource("prompts/competence-analysis-rubrics-v3.json").get("commun")), titre);

        assertThat(v3)
            .as("v3 enumere ses propres champs")
            .contains(ENUM_CHAMPS_V3)
            .doesNotContain("improved_version");

        String reconstruit = v3.replace(ENUM_CHAMPS_V3, ENUM_CHAMPS_V2) + QUEUE_V2;
        assertThat(reconstruit)
            .as("on renomme les champs, on ne reecrit pas la regle")
            .isEqualTo(v2);
    }

    /**
     * Le niveau est LOGE DANS SON PROPRE CHAMP, borne aux cinq valeurs du profil
     * TCF IRN. C'est le schema qui l'impose, pas une consigne : un C1 ne peut pas
     * etre produit, il n'existe pas dans l'enum.
     */
    @Test
    void leToolSchemaV3ExposeExactementLesCinqChampsDeV3() {
        Map<String, Object> schema = resource("prompts/competence-analysis-tool-schema-v3.json");

        assertThat(schema.get("additionalProperties"))
            .as("un champ hors contrat doit etre refuse par le fournisseur, pas seulement par nous")
            .isEqualTo(false);
        assertThat(strings(schema.get("required"))).containsExactlyElementsOf(CLES_V3);

        Map<String, Object> properties = map(schema.get("properties"));
        assertThat(properties.keySet()).containsExactlyInAnyOrderElementsOf(CLES_V3);
        assertThat(strings(map(properties.get("status")).get("enum")))
            .containsExactlyElementsOf(STATUTS);
        assertThat(strings(map(properties.get("level_reached")).get("enum")))
            .as("profil TCF IRN : cinq valeurs, jamais C1 ni C2")
            .containsExactlyElementsOf(NIVEAUX);

        for (String cle : List.of("verdict", "strength_tag", "focus_tag")) {
            assertThat(map(properties.get(cle)).get("maxLength"))
                .as("%s doit etre borde en longueur", cle)
                .isInstanceOf(Number.class);
            assertThat(map(properties.get(cle)).get("minLength"))
                .as("%s ne doit jamais etre vide", cle)
                .isEqualTo(1);
        }
    }

    /**
     * L'interdiction de la NOTE survit a l'arrivee du niveau. C'est la seule
     * chose de l'ancienne regle « ni note, ni niveau » qui ne bouge pas : le
     * contrat ne prevoit aucun champ ou loger une note, et un nom de propriete
     * contenant « note » suffit a faire echouer ce test.
     */
    @Test
    void leToolSchemaV3NePrevoitAucunChampDeNote() {
        String brut = resourceText("prompts/competence-analysis-tool-schema-v3.json")
            .toLowerCase(Locale.ROOT);
        assertThat(brut).doesNotContain("note_globale", "niveau_cecrl", "scores_criteres", "/20");

        Map<String, Object> properties = map(resource(
            "prompts/competence-analysis-tool-schema-v3.json").get("properties"));
        assertThat(properties.keySet().stream().filter(k -> k.contains("note")))
            .as("aucun champ de note : un micro-exercice n'en porte pas")
            .isEmpty();
    }

    /**
     * Les etiquettes tiennent en TROIS MOTS, et c'est la grille qui le declare —
     * pas le Java. Le schema double la contrainte en caracteres : c'est le
     * plafond dur, celui qui ne depend d'aucune cooperation du modele.
     */
    @Test
    void lesConsignesV3PortentLesPlafondsDesEtiquettesEtLesCinqNiveaux() {
        Map<String, Object> commun = map(
            resource("prompts/competence-analysis-rubrics-v3.json").get("commun"));

        assertThat(map(commun.get("contraintes_longueur")))
            .containsEntry("verdict", 20)
            .containsEntry("strength_tag", 3)
            .containsEntry("focus_tag", 3)
            .as("les champs de v1/v2 n'ont plus de plafond : ils n'existent plus")
            .doesNotContainKeys("success_point", "improvement_priority");
        assertThat(map(commun.get("niveaux")).keySet())
            .containsExactlyElementsOf(NIVEAUX);
    }

    /**
     * Une ancre qui ne respecte pas le contrat apprend au correcteur a le
     * violer. Sous v3, chaque ancre porte les CINQ nouvelles cles — dont le
     * niveau — et les trois verdicts restent tous ancres.
     */
    @Test
    void chaqueAncreV3PorteLesCinqClesEtLesTroisVerdictsRestentCouverts() {
        Map<String, Object> commun = map(
            resource("prompts/competence-analysis-rubrics-v3.json").get("commun"));
        List<?> fewShot = list(commun.get("few_shot"));

        assertThat(fewShot).hasSizeGreaterThanOrEqualTo(4);

        Set<String> verdictsCouverts = new java.util.LinkedHashSet<>();
        for (Object ancre : fewShot) {
            Map<String, Object> attendu = map(map(ancre).get("attendu"));
            assertThat(attendu.keySet()).containsExactlyInAnyOrderElementsOf(CLES_V3);
            assertThat(STATUTS).contains(String.valueOf(attendu.get("status")));
            assertThat(NIVEAUX).contains(String.valueOf(attendu.get("level_reached")));
            assertThat(motsDe(attendu.get("strength_tag")))
                .as("une etiquette de plus de trois mots n'est plus une etiquette")
                .isLessThanOrEqualTo(3);
            assertThat(motsDe(attendu.get("focus_tag"))).isLessThanOrEqualTo(3);
            verdictsCouverts.add(String.valueOf(attendu.get("status")));
        }
        assertThat(verdictsCouverts)
            .as("les trois verdicts doivent etre ancres, sinon un seul est appris")
            .containsExactlyInAnyOrderElementsOf(STATUTS);
    }

    /**
     * L'INVARIANT DU MONTAGE A DEUX APPELS : les consignes d'analyse ne parlent
     * jamais du palier que le candidat VISE. Le depot a mesure sur les
     * productions completes qu'un correcteur qui apprend l'objectif aligne son
     * jugement dessus (v10/v11 : accord exact 81,8 % → 75,6 %).
     */
    @Test
    void lesConsignesV3NeParlentJamaisDuNiveauViseParLeCandidat() {
        String consignes = resourceText("prompts/competence-analysis-rubrics-v3.json");

        assertThat(consignes)
            .doesNotContain("niveau_vise")
            .doesNotContain("NIVEAU VISÉ PAR LE CANDIDAT")
            .doesNotContain("TargetProcedure");
        assertThat(consignes)
            .as("elles le disent meme explicitement au correcteur")
            .contains("Tu ne sais pas quel niveau ce candidat VISE");
    }

    // ======================================================== contrat v4 ====

    @Test
    void lesConsignesV4DeclarentLeToolSchemaV4EtLeProfilTcfIrn() {
        assertThat(resource("prompts/competence-analysis-rubrics-v4.json"))
            .containsEntry("rubrics-version", "v4")
            .containsEntry("tool_schema_version", "v4")
            .containsEntry("profile", "TCF_IRN");
    }

    /**
     * LE VERROU CENTRAL DE v4 : elle est v3 <b>au bit pres</b> partout ou l'on
     * juge. Meme technique de reconstruction inverse que
     * {@code ProductionEvaluationContractTest}, qui rebatit v13 depuis v14 en y
     * remettant ce qui a ete retire : ici on rebatit v3 depuis v4 en retirant les
     * deux seules editions autorisees.
     *
     * <p>v4 rend le niveau OPPOSABLE ; elle ne deplace <b>aucun</b> critere de
     * jugement. Sans ce verrou, une refonte de la preuve pourrait faire bouger un
     * verdict, un descripteur de palier ou le garde-fou oral sans que personne ne
     * le voie.
     */
    @Test
    void lesConsignesV4SontV3AuBitPresPourToutCeQuiJuge() {
        Map<String, Object> communV3 = map(
            resource("prompts/competence-analysis-rubrics-v3.json").get("commun"));
        Map<String, Object> communV4 = map(
            resource("prompts/competence-analysis-rubrics-v4.json").get("commun"));

        for (String bloc : List.of("statuts", "niveaux", "contraintes_longueur")) {
            assertThat(communV4.get(bloc))
                .as("v4 ne touche pas a commun.%s : rien de ce qui note ne bouge", bloc)
                .isEqualTo(communV3.get(bloc));
        }

        Map<String, Object> sectionsV3 = sectionsParTitre(communV3);
        Map<String, Object> sectionsV4 = sectionsParTitre(communV4);
        assertThat(sectionsV4)
            .as("une seule section ajoutee, aucune supprimee")
            .hasSize(sectionsV3.size() + 1);

        for (Map.Entry<String, Object> attendue : sectionsV3.entrySet()) {
            String titre = attendue.getKey();
            if (TITRE_CHAMPS_V3.equals(titre) || TITRE_INTERDICTIONS.equals(titre)) continue;
            assertThat(sectionsV4.get(titre))
                .as("la section « %s » juge, ou nomme la regle : reprise telle quelle", titre)
                .isEqualTo(attendue.getValue());
        }
    }

    /**
     * Les DEUX SEULES editions autorisees dans les sections existantes : la
     * section qui enumere les champs gagne un paragraphe (et passe de cinq a six),
     * et les interdictions comptent six champs au lieu de cinq. Le test les
     * inverse pour reconstruire v3 caractere par caractere — aucune reformulation
     * ne peut se glisser derriere le pretexte d'un champ ajoute.
     */
    @Test
    void lesDeuxSectionsEditeesParV4SeReconstruisentExactementEnV3() {
        Map<String, Object> communV3 = map(
            resource("prompts/competence-analysis-rubrics-v3.json").get("commun"));
        Map<String, Object> communV4 = map(
            resource("prompts/competence-analysis-rubrics-v4.json").get("commun"));

        assertThat(sectionsParTitre(communV4)).doesNotContainKey(TITRE_CHAMPS_V3);
        String champsV4 = contenuSection(communV4, TITRE_CHAMPS_V4);
        assertThat(champsV4)
            .as("le nouveau champ est decrit la ou les autres le sont")
            .contains("`level_evidence`");
        int coupe = champsV4.indexOf("\n\n`level_evidence` —");
        assertThat(coupe).as("le paragraphe ajoute doit etre en FIN de section").isPositive();
        assertThat(champsV4.substring(0, coupe))
            .as("on ajoute un paragraphe, on ne reecrit pas les cinq autres")
            .isEqualTo(contenuSection(communV3, TITRE_CHAMPS_V3));

        String interdictionsV4 = contenuSection(communV4, TITRE_INTERDICTIONS);
        assertThat(interdictionsV4.replace(
            "Aucun champ en dehors des six prévus.", "Aucun champ en dehors des cinq prévus."))
            .as("une seule phrase change, et seulement pour compter les champs")
            .isEqualTo(contenuSection(communV3, TITRE_INTERDICTIONS));
    }

    /**
     * La section AJOUTEE porte la technique : preuve par NUMERO, ce qui demontre
     * quoi, et le rappel — deja present en v3 — que la brievete n'est pas un
     * plafond. On n'abaisse pas pour cause de longueur, on abaisse faute de
     * demonstration.
     */
    @Test
    void laSectionAjouteeParV4DecritLaPreuveParNumeroEtPasUneCitation() {
        String contenu = contenuSection(
            map(resource("prompts/competence-analysis-rubrics-v4.json").get("commun")),
            "La preuve du niveau : `level_evidence`");

        assertThat(contenu)
            .as("le correcteur DESIGNE, il ne recopie pas — c'est ce qui rend l'invention "
                + "impossible par construction")
            .contains("SEGMENTS NUMÉROTÉS")
            .contains("ce NUMÉRO, un entier")
            .contains("jamais une citation");
        assertThat(contenu)
            .as("ce qui demontre quoi : le B2 par une idee developpee ou une objection traitee, "
                + "le B1 par la subordination et l'enchainement")
            .contains("B2 : une idée annoncée puis développée")
            .contains("objection envisagée puis traitée")
            .contains("B1 : une subordonnée")
            .contains("enchaînement explicite");
        assertThat(contenu)
            .as("A2 et en dessous n'ont rien a demontrer")
            .contains("omets `level_evidence`");
        assertThat(contenu)
            .as("a l'oral, l'examinateur n'est pas designable")
            .contains("seuls les tours « Candidat : » portent un numéro");
        assertThat(contenu)
            .as("regle conservee de v3, mot pour mot : on abaisse faute de preuve, "
                + "jamais pour cause de longueur")
            .contains("LA BRIÈVETÉ N'EST TOUJOURS PAS UN PLAFOND");
    }

    /**
     * Le contrat de sortie v4 : celui de v3, plus {@code level_evidence}. Les
     * cinq champs de v3 ne bougent pas d'un caractere, {@code required} non plus
     * — le nouveau champ est OPTIONNEL, parce que A2 et en dessous n'ont rien a
     * demontrer et qu'exiger le champ partout obligerait le correcteur a designer
     * un segment « par defaut », exactement ce que la grille lui interdit.
     */
    @Test
    void leToolSchemaV4EstCeluiDeV3PlusUnChampDePreuveOPTIONNEL() {
        Map<String, Object> v3 = resource("prompts/competence-analysis-tool-schema-v3.json");
        Map<String, Object> v4 = resource("prompts/competence-analysis-tool-schema-v4.json");

        assertThat(v4.get("additionalProperties")).isEqualTo(false);
        assertThat(strings(v4.get("required")))
            .as("level_evidence n'est PAS requis : un A2 n'a rien a demontrer")
            .containsExactlyElementsOf(strings(v3.get("required")))
            .doesNotContain("level_evidence");

        Map<String, Object> propsV3 = map(v3.get("properties"));
        Map<String, Object> propsV4 = map(v4.get("properties"));
        assertThat(propsV4.keySet())
            .containsExactlyInAnyOrderElementsOf(CLES_V4);
        for (String cle : CLES_V3) {
            assertThat(propsV4.get(cle))
                .as("%s : le contrat de v3 ne bouge pas d'un caractere", cle)
                .isEqualTo(propsV3.get(cle));
        }

        Map<String, Object> preuve = map(propsV4.get("level_evidence"));
        assertThat(preuve.get("type"))
            .as("un ENTIER : le seul defaut possible devient un numero hors bornes")
            .isEqualTo("integer");
        assertThat(preuve.get("minimum")).isEqualTo(1);
        assertThat(String.valueOf(preuve.get("description")))
            .contains("NUMÉRO")
            .contains("jamais une citation");

        assertThat(String.valueOf(v4.get("description")))
            .as("on etoffe la description racine, on ne la reecrit pas")
            .startsWith(String.valueOf(v3.get("description")))
            .contains("abaisse le niveau d'un palier")
            .contains("il ne le relève jamais");
    }

    /** L'interdiction de la NOTE survit a v4, comme elle a survecu a v3. */
    @Test
    void leToolSchemaV4NePrevoitToujoursAucunChampDeNote() {
        String brut = resourceText("prompts/competence-analysis-tool-schema-v4.json")
            .toLowerCase(Locale.ROOT);
        assertThat(brut).doesNotContain("note_globale", "niveau_cecrl", "scores_criteres", "/20");

        Map<String, Object> properties = map(resource(
            "prompts/competence-analysis-tool-schema-v4.json").get("properties"));
        assertThat(properties.keySet().stream().filter(k -> k.contains("note")))
            .as("aucun champ de note : un micro-exercice n'en porte pas")
            .isEmpty();
    }

    /**
     * Les ancres de v3 sont reprises telles quelles, a la seule preuve pres. Une
     * ancre reecrite reapprendrait un jugement au correcteur ; on ne lui apprend
     * qu'a designer.
     */
    @Test
    void lesAncresDeV4SontCellesDeV3AuNumeroDePreuvePres() {
        List<?> v3 = list(map(
            resource("prompts/competence-analysis-rubrics-v3.json").get("commun")).get("few_shot"));
        List<?> v4 = list(map(
            resource("prompts/competence-analysis-rubrics-v4.json").get("commun")).get("few_shot"));

        assertThat(v4).as("une ancre ajoutee, aucune retiree").hasSize(v3.size() + 1);
        for (int i = 0; i < v3.size(); i++) {
            Map<String, Object> reconstruite = new java.util.LinkedHashMap<>(map(v4.get(i)));
            Map<String, Object> attendu = new java.util.LinkedHashMap<>(
                map(reconstruite.get("attendu")));
            attendu.remove("level_evidence");
            reconstruite.put("attendu", attendu);
            assertThat(reconstruite)
                .as("ancre %d : on ajoute la preuve, on ne retouche pas le jugement", i + 1)
                .isEqualTo(v3.get(i));
        }
    }

    /**
     * Une ancre qui ne respecte pas le contrat apprend au correcteur a le violer.
     * Ici c'est plus fort qu'une question de cles : chaque preuve d'ancre doit
     * DESIGNER UN SEGMENT QUI EXISTE — et le decoupage utilise est celui du
     * serveur, {@link EvaluationProductionSegments}, pas une relecture a l'oeil.
     */
    @Test
    void chaqueAncreV4DemontreSonPalierParUnNumeroDeSegmentReel() {
        List<?> fewShot = list(map(
            resource("prompts/competence-analysis-rubrics-v4.json").get("commun")).get("few_shot"));

        Set<String> verdictsCouverts = new java.util.LinkedHashSet<>();
        boolean auMoinsUnePreuve = false;
        for (Object brut : fewShot) {
            Map<String, Object> ancre = map(brut);
            Map<String, Object> attendu = map(ancre.get("attendu"));
            assertThat(CLES_V4).containsAll(attendu.keySet());
            assertThat(attendu.keySet()).containsAll(CLES_V3);
            assertThat(STATUTS).contains(String.valueOf(attendu.get("status")));
            String niveau = String.valueOf(attendu.get("level_reached"));
            assertThat(NIVEAUX).contains(niveau);
            verdictsCouverts.add(String.valueOf(attendu.get("status")));

            Object preuve = attendu.get("level_evidence");
            boolean aDemontrer = List.of("B1", "B2").contains(niveau);
            if (!aDemontrer) {
                assertThat(preuve)
                    .as("A2 et en dessous n'ont rien a demontrer : le champ est omis")
                    .isNull();
                continue;
            }
            auMoinsUnePreuve = true;
            assertThat(preuve)
                .as("une ancre B1/B2 sans preuve apprendrait au correcteur a s'en passer")
                .isInstanceOf(Integer.class);

            EvaluationProductionSegments segments = EvaluationProductionSegments.of(
                String.valueOf(ancre.get("production")),
                "EO".equals(String.valueOf(ancre.get("section")))
                    ? EpreuveType.TCF_EO : EpreuveType.TCF_EE);
            assertThat(segments.texte((Integer) preuve))
                .as("l'ancre « %s » designe le segment %s d'une production qui n'en a que %d",
                    ancre.get("titre"), preuve, segments.taille())
                .isPresent();
        }
        assertThat(auMoinsUnePreuve)
            .as("sans une seule ancre qui designe, la technique n'est jamais montree")
            .isTrue();
        assertThat(verdictsCouverts)
            .as("les trois verdicts doivent rester ancres")
            .containsExactlyInAnyOrderElementsOf(STATUTS);
    }

    /** L'invariant du montage a deux appels survit a v4. */
    @Test
    void lesConsignesV4NeParlentJamaisDuNiveauViseParLeCandidat() {
        String consignes = resourceText("prompts/competence-analysis-rubrics-v4.json");

        assertThat(consignes)
            .doesNotContain("niveau_vise")
            .doesNotContain("NIVEAU VISÉ PAR LE CANDIDAT")
            .doesNotContain("TargetProcedure");
        assertThat(consignes).contains("Tu ne sais pas quel niveau ce candidat VISE");
    }

    private static int motsDe(Object valeur) {
        String texte = String.valueOf(valeur).trim();
        return texte.isEmpty() ? 0 : texte.split("\\s+").length;
    }

    private static Map<String, Object> sectionsParTitre(Map<String, Object> commun) {
        Map<String, Object> out = new java.util.LinkedHashMap<>();
        for (Object section : list(commun.get("sections"))) {
            out.put(String.valueOf(map(section).get("titre")), section);
        }
        return out;
    }

    private static String contenuSection(Map<String, Object> commun, String titre) {
        Object section = sectionsParTitre(commun).get(titre);
        assertThat(section).as("section « %s » absente", titre).isNotNull();
        return String.valueOf(map(section).get("contenu"));
    }

    private static String sansAccents(String texte) {
        return java.text.Normalizer.normalize(texte, java.text.Normalizer.Form.NFD)
            .replaceAll("\\p{M}+", "");
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

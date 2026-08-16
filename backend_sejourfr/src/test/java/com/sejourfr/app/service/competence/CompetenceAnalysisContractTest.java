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
    /** La seule section que v5 edite. */
    private static final String TITRE_NIVEAU = "Le niveau de langue démontré : `level_reached`";
    /**
     * L'UNIQUE fragment que v5 remplace. Il annoncait une FREQUENCE ATTENDUE,
     * c'est-a-dire une consigne de repartition : mesure en base, le correcteur
     * n'a jamais rendu un seul B2 sur 18 tentatives reelles.
     */
    private static final String FRAGMENT_NIVEAU_V4 =
        "Un critère peut être VALIDATED en A2 — c'est même le cas le plus fréquent, "
            + "et c'est normal : le candidat a fait exactement ce qu'on lui demandait, avec "
            + "les moyens qu'il a.";
    private static final String FRAGMENT_NIVEAU_V5 =
        "Un critère peut être VALIDATED en A2 comme en B2 : le verdict dit ce que le "
            + "candidat a fait, le niveau dit avec quels moyens. Aucun palier n'est plus "
            + "« attendu » qu'un autre et tu n'as aucune répartition à respecter — tu "
            + "décris cette production-ci, pas une moyenne.";
    /** Section ajoutee par v4, editee par v6. */
    private static final String TITRE_PREUVE = "La preuve du niveau : `level_evidence`";

    /**
     * LES QUATRE SEULES EDITIONS de v6 dans la section de la preuve, {v6 → v5}.
     * Les inverser doit rendre v5 caractere par caractere : c'est la technique de
     * {@code ProductionEvaluationContractTest}, et c'est ce qui interdit qu'une
     * reformulation se glisse derriere le pretexte d'une regle etendue.
     */
    private static final List<String[]> EDITIONS_PREUVE_V6 = List.of(
        new String[]{
            "Quel que soit le palier que tu annonces — B2 comme A1_NON_ATTEINT —, tu "
                + "désignes le passage de la production sur lequel tu le fondes.",
            "Quand tu annonces B1 ou B2, tu désignes le passage de la production qui le "
                + "démontre."},
        new String[]{
            "\n- A2 : une phrase simple, juxtaposée ou reliée par « et », « mais », "
                + "« parce que », qui fait passer le message dans une situation familière."
                + "\n- A1 : des mots juxtaposés, une formule apprise, une phrase sans verbe "
                + "conjugué."
                + "\n- A1_NON_ATTEINT : le passage qui montre qu'il n'y a rien d'exploitable "
                + "en français, ou qu'on ne comprend pas ce qui est dit.",
            ""},
        new String[]{
            "annonce le palier inférieur, et désigne le segment qui fonde CE palier-là.",
            "annonce le palier inférieur."},
        new String[]{
            "CE CHAMP EST TOUJOURS ATTENDU. Aucun palier n'est dispensé de désignation, pas "
                + "même A1_NON_ATTEINT. Désigner un A2 te coûte exactement ce que te coûte de "
                + "désigner un B2, et c'est voulu : le confort d'un palier ne doit jamais venir "
                + "de ce qu'il est moins exigeant à justifier. Un palier bas se fonde sur un "
                + "passage comme un palier haut — celui qui montre le mieux ce que cette "
                + "production sait faire, ou ne sait pas faire.",
            "QUAND CE CHAMP N'EST PAS ATTENDU. Pour A2, A1 et A1_NON_ATTEINT, tu n'as rien à "
                + "démontrer : omets `level_evidence`. Ces paliers se lisent sur l'ensemble de "
                + "la production, pas sur un passage."});

    /** Les deux seules editions de v6 dans la section qui enumere les champs. */
    private static final List<String[]> EDITIONS_CHAMPS_V6 = List.of(
        new String[]{
            "Obligatoire à CHAQUE analyse, quel que soit le palier annoncé.",
            "Obligatoire dès que `level_reached` vaut B1 ou B2, à omettre en dessous."},
        new String[]{
            "s'il ne désigne rien sur un B1 ou un B2, il abaisse le niveau d'un palier",
            "s'il ne désigne rien, il abaisse le niveau d'un palier"});

    /** Phrase ajoutee au « pourquoi » de la seule ancre A1_NON_ATTEINT. */
    private static final String PHRASE_ANCRE_V6 =
        " La preuve, elle, se donne comme partout ailleurs : le segment désigné est celui qui "
            + "MONTRE que le palier n'est pas atteint — ici la phrase entière, qui n'est pas "
            + "en français.";

    /** Les deux editions de la description de {@code level_evidence}, {v5 → v4}. */
    private static final List<String[]> EDITIONS_DESCRIPTION_PREUVE_V5 = List.of(
        new String[]{
            "OBLIGATOIRE À CHAQUE ANALYSE, quel que soit le palier annoncé : désigner coûte le "
                + "même effort en haut et en bas de l'échelle, et aucun palier n'est plus "
                + "confortable qu'un autre.",
            "OBLIGATOIRE dès que `level_reached` vaut B1 ou B2 ; à OMETTRE pour A2, A1 et "
                + "A1_NON_ATTEINT, qui n'ont rien à démontrer."},
        new String[]{
            "une subordination et un enchaînement, pour le A2 une phrase simple qui fait passer "
                + "le message, pour le A1 des mots juxtaposés sans verbe tenu, pour "
                + "A1_NON_ATTEINT le passage qui montre que rien n'est exploitable en français.",
            "une subordination et un enchaînement."});

    /** Les quatre editions de la description RACINE du contrat, {v5 → v4}. */
    private static final List<String[]> EDITIONS_DESCRIPTION_RACINE_V5 = List.of(
        new String[]{
            "d'une micro-compétence : six champs, et AUCUN champ",
            "d'une micro-compétence : cinq champs, et AUCUN champ"},
        new String[]{
            "quel que soit le palier, il se DÉSIGNE",
            "dès qu'il vaut B1 ou B2, il se DÉSIGNE"},
        new String[]{
            "Désigner coûte donc le même effort à tous les paliers — annoncer un A2 n'est pas "
                + "plus confortable qu'annoncer un B2. Faute de désignation exploitable sur un "
                + "B1 ou un B2, le serveur",
            "Faute de désignation exploitable, le serveur"},
        new String[]{
            "il ne le relève jamais, il ne sanctionne rien en dessous du B1, et il ne perd "
                + "jamais l'analyse pour autant.",
            "il ne le relève jamais, et il ne perd jamais l'analyse pour autant."});

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

        assertThat(analysis.getRubricsVersion()).isEqualTo("v6");
        assertThat(analysis.getToolSchemaVersion())
            .as("v6 ne change AUCUN champ de sortie ; elle en rend un OBLIGATOIRE, "
                + "et c'est le tool-schema v5 qui le porte")
            .isEqualTo("v5");
        assertThat(yaml.getProperty("sejourfr.competences.analysis.rubrics-version"))
            .isEqualTo("${COMPETENCE_RUBRICS_VERSION:v6}");
        assertThat(yaml.getProperty("sejourfr.competences.analysis.tool-schema-version"))
            .isEqualTo("${COMPETENCE_TOOL_SCHEMA_VERSION:v5}");
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

    // ======================================================== contrat v5 ====

    /**
     * v5 <b>ne change aucun champ de sortie</b> : elle declare le tool-schema v4.
     * C'est la premiere version de consignes de ce module qui reutilise le
     * contrat de la precedente — deux consignes differentes peuvent produire le
     * meme JSON, et rien n'obligeait a fabriquer un cinquieme schema identique.
     */
    @Test
    void lesConsignesV5DeclarentLeToolSchemaV4EtLeProfilTcfIrn() {
        assertThat(resource("prompts/competence-analysis-rubrics-v5.json"))
            .containsEntry("rubrics-version", "v5")
            .containsEntry("tool_schema_version", "v4")
            .containsEntry("profile", "TCF_IRN");
    }

    /**
     * LE VERROU CENTRAL DE v5 : elle est v4 <b>au bit pres</b> partout ou l'on
     * juge. Meme technique de reconstruction inverse que pour v4 depuis v3.
     *
     * <p>v5 ne corrige que des BIAIS lisibles dans le prompt : deux paliers sans
     * la moindre ancre, et une frequence attendue ecrite noir sur blanc. Aucun
     * verdict, aucun descripteur de palier, aucune regle de preuve ne bouge —
     * sans ce verrou, un ajout d'ancres pourrait faire glisser un seuil sans que
     * personne ne le voie.
     */
    @Test
    void lesConsignesV5SontV4AuBitPresPourToutCeQuiJuge() {
        Map<String, Object> communV4 = map(
            resource("prompts/competence-analysis-rubrics-v4.json").get("commun"));
        Map<String, Object> communV5 = map(
            resource("prompts/competence-analysis-rubrics-v5.json").get("commun"));

        for (String bloc : List.of("statuts", "niveaux", "contraintes_longueur")) {
            assertThat(communV5.get(bloc))
                .as("v5 ne touche pas a commun.%s : rien de ce qui juge ne bouge", bloc)
                .isEqualTo(communV4.get(bloc));
        }

        Map<String, Object> sectionsV4 = sectionsParTitre(communV4);
        Map<String, Object> sectionsV5 = sectionsParTitre(communV5);
        assertThat(sectionsV5.keySet())
            .as("aucune section ajoutee, aucune supprimee, aucune renommee")
            .containsExactlyElementsOf(sectionsV4.keySet());

        for (Map.Entry<String, Object> attendue : sectionsV4.entrySet()) {
            if (TITRE_NIVEAU.equals(attendue.getKey())) continue;
            assertThat(sectionsV5.get(attendue.getKey()))
                .as("la section « %s » est reprise telle quelle", attendue.getKey())
                .isEqualTo(attendue.getValue());
        }
    }

    /**
     * L'UNIQUE edition d'une section existante : le prior vers le A2 disparait.
     * Le test l'inverse pour reconstruire v4 caractere par caractere — aucune
     * reformulation ne peut se glisser derriere le pretexte d'un biais retire.
     *
     * <p>Ce qu'on retire est une <b>consigne de repartition</b> (« c'est meme le
     * cas le plus frequent, et c'est normal »), pas l'idee qu'elle portait : un
     * critere peut toujours etre valide a un palier modeste, et le verdict reste
     * independant du niveau.
     */
    @Test
    void laSeuleSectionEditeeParV5SeReconstruitExactementEnV4() {
        Map<String, Object> communV4 = map(
            resource("prompts/competence-analysis-rubrics-v4.json").get("commun"));
        Map<String, Object> communV5 = map(
            resource("prompts/competence-analysis-rubrics-v5.json").get("commun"));

        String v5 = contenuSection(communV5, TITRE_NIVEAU);
        assertThat(v5)
            .as("aucune frequence attendue : ce serait une instruction de repartition")
            .doesNotContain("le cas le plus fréquent")
            .contains(FRAGMENT_NIVEAU_V5)
            .as("l'independance verdict/niveau, elle, est conservee")
            .contains("LE NIVEAU EST INDÉPENDANT DU VERDICT")
            .contains("NOT_VALIDATED alors que la langue est B1");

        assertThat(v5.replace(FRAGMENT_NIVEAU_V5, FRAGMENT_NIVEAU_V4))
            .as("une seule edition, et elle se defait exactement")
            .isEqualTo(contenuSection(communV4, TITRE_NIVEAU));
    }

    /**
     * Les sept ancres de v4 sont reprises TELLES QUELLES, dans l'ordre : une ancre
     * reecrite reapprendrait un jugement au correcteur. v5 en AJOUTE trois, sur
     * les deux paliers que v4 n'ancrait pas du tout.
     */
    @Test
    void lesAncresDeV4SontReprisesTellesQuellesEtTroisSAjoutent() {
        List<?> v4 = list(map(
            resource("prompts/competence-analysis-rubrics-v4.json").get("commun")).get("few_shot"));
        List<?> v5 = list(map(
            resource("prompts/competence-analysis-rubrics-v5.json").get("commun")).get("few_shot"));

        assertThat(v5).hasSize(v4.size() + 3);
        assertThat(v5.subList(0, v4.size()))
            .as("on ajoute des ancres, on n'en retouche aucune")
            .isEqualTo(v4);
    }

    /**
     * LE DEFAUT QUE v5 CORRIGE, fige ici : v4 comptait 4 ancres A2, 2 B1, 1 A1 —
     * et <b>zero</b> sur B2 comme sur A1_NON_ATTEINT. Le correcteur n'avait donc
     * jamais vu a quoi ressemblent ces deux paliers dans ce format, et la base
     * locale le montrait : 0 B2 sur 18 tentatives reelles.
     *
     * <p>On exige que les CINQ paliers soient demontres, pas que le B2 devienne
     * facile : le A2 reste majoritaire dans les ancres, c'est voulu.
     */
    @Test
    void lesCinqPaliersSontDesormaisTousAncres() {
        List<?> fewShot = list(map(
            resource("prompts/competence-analysis-rubrics-v5.json").get("commun")).get("few_shot"));

        Map<String, Integer> parNiveau = new java.util.LinkedHashMap<>();
        for (Object brut : fewShot) {
            String niveau = String.valueOf(map(map(brut).get("attendu")).get("level_reached"));
            parNiveau.merge(niveau, 1, Integer::sum);
        }

        assertThat(parNiveau.keySet())
            .as("un palier sans ancre est un palier que le correcteur ne rendra jamais")
            .containsExactlyInAnyOrderElementsOf(NIVEAUX);
        assertThat(parNiveau.get("B2")).isGreaterThanOrEqualTo(2);
        assertThat(parNiveau.get("A1_NON_ATTEINT")).isGreaterThanOrEqualTo(1);
        assertThat(parNiveau.get("A2"))
            .as("on ouvre le haut de l'echelle, on ne bascule pas le prior vers le B2")
            .isGreaterThanOrEqualTo(parNiveau.get("B2"));
    }

    /**
     * Les ancres ajoutees respectent le contrat v4 au meme titre que les autres :
     * memes cles, etiquettes de trois mots, et surtout une preuve qui DESIGNE UN
     * SEGMENT REEL — decoupe par le serveur ({@link EvaluationProductionSegments}),
     * pas relue a l'oeil.
     */
    @Test
    void chaqueAncreV5DemontreSonPalierParUnNumeroDeSegmentReel() {
        List<?> fewShot = list(map(
            resource("prompts/competence-analysis-rubrics-v5.json").get("commun")).get("few_shot"));

        Set<String> verdictsCouverts = new java.util.LinkedHashSet<>();
        for (Object brut : fewShot) {
            Map<String, Object> ancre = map(brut);
            Map<String, Object> attendu = map(ancre.get("attendu"));
            assertThat(CLES_V4).containsAll(attendu.keySet());
            assertThat(attendu.keySet()).containsAll(CLES_V3);
            assertThat(STATUTS).contains(String.valueOf(attendu.get("status")));
            String niveau = String.valueOf(attendu.get("level_reached"));
            assertThat(NIVEAUX).contains(niveau);
            assertThat(motsDe(attendu.get("strength_tag"))).isLessThanOrEqualTo(3);
            assertThat(motsDe(attendu.get("focus_tag"))).isLessThanOrEqualTo(3);
            verdictsCouverts.add(String.valueOf(attendu.get("status")));

            Object preuve = attendu.get("level_evidence");
            if (!List.of("B1", "B2").contains(niveau)) {
                assertThat(preuve)
                    .as("A2 et en dessous n'ont rien a demontrer : le champ est omis")
                    .isNull();
                continue;
            }
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
        assertThat(verdictsCouverts)
            .as("les trois verdicts doivent rester ancres")
            .containsExactlyInAnyOrderElementsOf(STATUTS);
    }

    /** L'invariant du montage a deux appels survit a v5. */
    @Test
    void lesConsignesV5NeParlentJamaisDuNiveauViseParLeCandidat() {
        String consignes = resourceText("prompts/competence-analysis-rubrics-v5.json");

        assertThat(consignes)
            .doesNotContain("niveau_vise")
            .doesNotContain("NIVEAU VISÉ PAR LE CANDIDAT")
            .doesNotContain("TargetProcedure");
        assertThat(consignes).contains("Tu ne sais pas quel niveau ce candidat VISE");
    }

    // ======================================================== contrat v6 ====

    /**
     * v6 est la premiere version de consignes de ce module a exiger un CHAMP de
     * plus qu'avant sans en ajouter aucun : {@code level_evidence} existait deja
     * sous v4, elle le rend obligatoire — d'ou un tool-schema neuf, le v5.
     */
    @Test
    void lesConsignesV6DeclarentLeToolSchemaV5EtLeProfilTcfIrn() {
        assertThat(resource("prompts/competence-analysis-rubrics-v6.json"))
            .containsEntry("rubrics-version", "v6")
            .containsEntry("tool_schema_version", "v5")
            .containsEntry("profile", "TCF_IRN");
    }

    /**
     * LE VERROU CENTRAL DE v6 : elle est v5 <b>au bit pres</b> partout ou l'on
     * juge. Meme technique de reconstruction inverse que pour v5 depuis v4.
     *
     * <p>v6 corrige une asymetrie du MECANISME, pas un critere : nommer un B1/B2
     * coutait un numero de segment et risquait un abaissement, nommer un A2 ne
     * coutait rien. Aucun verdict, aucun descripteur de palier, aucun plafond ne
     * bouge — et le nombre de sections ne bouge pas non plus.
     */
    @Test
    void lesConsignesV6SontV5AuBitPresPourToutCeQuiJuge() {
        Map<String, Object> communV5 = map(
            resource("prompts/competence-analysis-rubrics-v5.json").get("commun"));
        Map<String, Object> communV6 = map(
            resource("prompts/competence-analysis-rubrics-v6.json").get("commun"));

        for (String bloc : List.of("statuts", "niveaux", "contraintes_longueur")) {
            assertThat(communV6.get(bloc))
                .as("v6 ne touche pas a commun.%s : rien de ce qui juge ne bouge", bloc)
                .isEqualTo(communV5.get(bloc));
        }

        Map<String, Object> sectionsV5 = sectionsParTitre(communV5);
        Map<String, Object> sectionsV6 = sectionsParTitre(communV6);
        assertThat(sectionsV6.keySet())
            .as("aucune section ajoutee, aucune supprimee, aucune renommee")
            .containsExactlyElementsOf(sectionsV5.keySet());

        for (Map.Entry<String, Object> attendue : sectionsV5.entrySet()) {
            String titre = attendue.getKey();
            if (TITRE_PREUVE.equals(titre) || TITRE_CHAMPS_V4.equals(titre)) continue;
            assertThat(sectionsV6.get(titre))
                .as("la section « %s » est reprise telle quelle", titre)
                .isEqualTo(attendue.getValue());
        }
    }

    /**
     * LES DEUX SEULES SECTIONS EDITEES se reconstruisent exactement en v5, par la
     * liste ENUMEREE des editions ci-dessous — aucune reformulation ne peut se
     * glisser derriere le pretexte d'une regle etendue.
     */
    @Test
    void lesDeuxSectionsEditeesParV6SeReconstruisentExactementEnV5() {
        Map<String, Object> communV5 = map(
            resource("prompts/competence-analysis-rubrics-v5.json").get("commun"));
        Map<String, Object> communV6 = map(
            resource("prompts/competence-analysis-rubrics-v6.json").get("commun"));

        String preuve = contenuSection(communV6, TITRE_PREUVE);
        for (String[] edition : EDITIONS_PREUVE_V6) {
            assertThat(preuve).as("fragment attendu dans v6 : %s", edition[0]).contains(edition[0]);
            preuve = preuve.replace(edition[0], edition[1]);
        }
        assertThat(preuve)
            .as("quatre editions, et elles se defont exactement")
            .isEqualTo(contenuSection(communV5, TITRE_PREUVE));

        String champs = contenuSection(communV6, TITRE_CHAMPS_V4);
        for (String[] edition : EDITIONS_CHAMPS_V6) {
            assertThat(champs).contains(edition[0]);
            champs = champs.replace(edition[0], edition[1]);
        }
        assertThat(champs).isEqualTo(contenuSection(communV5, TITRE_CHAMPS_V4));
    }

    /**
     * LE DEFAUT QUE v6 CORRIGE, ecrit noir sur blanc dans la grille : plus aucun
     * palier n'est dispense de designation, et la raison est nommee — le confort
     * d'un palier ne doit jamais venir de ce qu'il est moins exigeant a
     * justifier.
     */
    @Test
    void laSectionDeLaPreuveDeV6NeDispensePlusAucunPalier() {
        String contenu = contenuSection(
            map(resource("prompts/competence-analysis-rubrics-v6.json").get("commun")),
            TITRE_PREUVE);

        assertThat(contenu)
            .as("l'ancienne dispense a disparu, elle ne peut plus etre lue")
            .doesNotContain("omets `level_evidence`")
            .doesNotContain("QUAND CE CHAMP N'EST PAS ATTENDU")
            .contains("CE CHAMP EST TOUJOURS ATTENDU")
            .contains("Désigner un A2 te coûte exactement ce que te coûte de désigner un B2");
        assertThat(contenu)
            .as("les cinq paliers disent ce qui les demontre, pas seulement B1 et B2")
            .contains("- B2 : une idée annoncée puis développée")
            .contains("- B1 : une subordonnée")
            .contains("- A2 : une phrase simple")
            .contains("- A1 : des mots juxtaposés")
            .contains("- A1_NON_ATTEINT : le passage qui montre");
        assertThat(contenu)
            .as("ce qui rend l'invention impossible par construction ne bouge pas")
            .contains("SEGMENTS NUMÉROTÉS")
            .contains("ce NUMÉRO, un entier")
            .contains("jamais une citation")
            .contains("seuls les tours « Candidat : » portent un numéro")
            .contains("LA BRIÈVETÉ N'EST TOUJOURS PAS UN PLAFOND");
    }

    /**
     * Les dix ancres de v5 sont reprises TELLES QUELLES, a la preuve pres : une
     * ancre reecrite reapprendrait un jugement au correcteur. Les six qui n'en
     * portaient pas en gagnent une, et celle d'A1_NON_ATTEINT explique en plus ce
     * qu'on designe quand le palier n'est pas atteint.
     */
    @Test
    void lesAncresDeV6SontCellesDeV5ALaPreuveAjouteePres() {
        List<?> v5 = list(map(
            resource("prompts/competence-analysis-rubrics-v5.json").get("commun")).get("few_shot"));
        List<?> v6 = list(map(
            resource("prompts/competence-analysis-rubrics-v6.json").get("commun")).get("few_shot"));

        assertThat(v6).as("aucune ancre ajoutee ni retiree").hasSize(v5.size());

        int completees = 0;
        for (int i = 0; i < v5.size(); i++) {
            Map<String, Object> attenduV5 = map(map(v5.get(i)).get("attendu"));
            Map<String, Object> reconstruite = new java.util.LinkedHashMap<>(map(v6.get(i)));
            if (!attenduV5.containsKey("level_evidence")) {
                completees++;
                Map<String, Object> attendu = new java.util.LinkedHashMap<>(
                    map(reconstruite.get("attendu")));
                attendu.remove("level_evidence");
                reconstruite.put("attendu", attendu);
            }
            reconstruite.put("pourquoi",
                String.valueOf(reconstruite.get("pourquoi")).replace(PHRASE_ANCRE_V6, ""));
            assertThat(reconstruite)
                .as("ancre %d : on ajoute la preuve, on ne retouche pas le jugement", i + 1)
                .isEqualTo(v5.get(i));
        }
        assertThat(completees)
            .as("v5 laissait six ancres sans preuve : ce sont exactement les paliers "
                + "que le correcteur pouvait nommer gratuitement")
            .isEqualTo(6);
    }

    /**
     * L'EXIGENCE EST ANCREE PARTOUT, et chaque preuve DESIGNE UN SEGMENT QUI
     * EXISTE — decoupe par le serveur ({@link EvaluationProductionSegments}), pas
     * relue a l'oeil. Une ancre qui omettrait la preuve apprendrait au correcteur
     * a s'en passer, exactement la ou v6 veut qu'il ne s'en passe plus.
     */
    @Test
    void chaqueAncreV6DesigneUnSegmentReelQuelQueSoitSonPalier() {
        List<?> fewShot = list(map(
            resource("prompts/competence-analysis-rubrics-v6.json").get("commun")).get("few_shot"));

        Set<String> paliersCouverts = new java.util.LinkedHashSet<>();
        Set<String> verdictsCouverts = new java.util.LinkedHashSet<>();
        for (Object brut : fewShot) {
            Map<String, Object> ancre = map(brut);
            Map<String, Object> attendu = map(ancre.get("attendu"));
            assertThat(attendu.keySet())
                .as("ancre « %s » : les six cles du contrat, la preuve comprise",
                    ancre.get("titre"))
                .containsExactlyInAnyOrderElementsOf(CLES_V4);
            assertThat(STATUTS).contains(String.valueOf(attendu.get("status")));
            assertThat(motsDe(attendu.get("strength_tag"))).isLessThanOrEqualTo(3);
            assertThat(motsDe(attendu.get("focus_tag"))).isLessThanOrEqualTo(3);
            String niveau = String.valueOf(attendu.get("level_reached"));
            assertThat(NIVEAUX).contains(niveau);
            paliersCouverts.add(niveau);
            verdictsCouverts.add(String.valueOf(attendu.get("status")));

            Object preuve = attendu.get("level_evidence");
            assertThat(preuve)
                .as("ancre « %s » : un ENTIER, jamais une citation", ancre.get("titre"))
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
        assertThat(paliersCouverts)
            .as("les cinq paliers restent ancres, preuve comprise")
            .containsExactlyInAnyOrderElementsOf(NIVEAUX);
        assertThat(verdictsCouverts).containsExactlyInAnyOrderElementsOf(STATUTS);
    }

    /**
     * LE CONTRAT DE SORTIE v5 : celui de v4, {@code level_evidence} passe dans
     * {@code required}, et <b>rien d'autre</b>. C'est la contrainte dure qui rend
     * le cout symetrique — le fournisseur refusera une sortie sans preuve, quel
     * que soit le palier. Verrou : egalite STRICTE de tout le reste.
     */
    @Test
    void leToolSchemaV5EstCeluiDeV4AvecLaPreuveRENDUEOBLIGATOIRE() {
        Map<String, Object> v4 = resource("prompts/competence-analysis-tool-schema-v4.json");
        Map<String, Object> v5 = resource("prompts/competence-analysis-tool-schema-v5.json");

        assertThat(v5.get("type")).isEqualTo(v4.get("type"));
        assertThat(v5.get("additionalProperties")).isEqualTo(false);
        assertThat(strings(v5.get("required")))
            .as("les six cles, dans l'ordre des proprietes")
            .containsExactlyElementsOf(CLES_V4);
        assertThat(strings(v4.get("required")))
            .as("temoin : v4 ne l'exigeait pas, c'est bien LA difference")
            .doesNotContain("level_evidence");
        assertThat(v5.keySet())
            .as("aucune cle racine ajoutee ni retiree")
            .containsExactlyInAnyOrderElementsOf(v4.keySet());

        Map<String, Object> propsV4 = map(v4.get("properties"));
        Map<String, Object> propsV5 = map(v5.get("properties"));
        assertThat(propsV5.keySet()).containsExactlyElementsOf(
            propsV4.keySet().stream().toList());
        for (String cle : CLES_V4) {
            if ("level_evidence".equals(cle)) continue;
            assertThat(propsV5.get(cle))
                .as("%s : le contrat de v4 ne bouge pas d'un caractere", cle)
                .isEqualTo(propsV4.get(cle));
        }

        Map<String, Object> preuveV4 = map(propsV4.get("level_evidence"));
        Map<String, Object> preuveV5 = map(propsV5.get("level_evidence"));
        assertThat(preuveV5.keySet()).containsExactlyElementsOf(preuveV4.keySet().stream().toList());
        for (String contrainte : List.of("type", "minimum")) {
            assertThat(preuveV5.get(contrainte))
                .as("level_evidence.%s : un ENTIER >= 1, inchange", contrainte)
                .isEqualTo(preuveV4.get(contrainte));
        }
        assertThat(v5.get("title")).isEqualTo("Analyse de compétence TCF IRN v5");
    }

    /**
     * Les DEUX descriptions editees se reconstruisent exactement en v4, par la
     * liste enumeree ci-dessous.
     *
     * <p>⚠️ On ne peut pas se contenter d'un {@code startsWith} : les deux textes
     * de v4 contiennent la phrase « dès qu'il vaut B1 ou B2 », qui devient
     * <b>fausse</b> sous v5. Conserver le prefixe intact reviendrait a livrer une
     * description qui se contredit — pire qu'une reformulation. La reconstruction
     * enumeree est de toute facon plus forte : elle prouve que RIEN d'autre n'a
     * ete reecrit.
     */
    @Test
    void lesDeuxDescriptionsEditeesParLeToolSchemaV5SeReconstruisentEnV4() {
        Map<String, Object> v4 = resource("prompts/competence-analysis-tool-schema-v4.json");
        Map<String, Object> v5 = resource("prompts/competence-analysis-tool-schema-v5.json");

        String champ = String.valueOf(map(map(v5.get("properties"))
            .get("level_evidence")).get("description"));
        assertThat(champ)
            .contains("OBLIGATOIRE À CHAQUE ANALYSE")
            .doesNotContain("à OMETTRE pour A2");
        for (String[] edition : EDITIONS_DESCRIPTION_PREUVE_V5) {
            assertThat(champ).contains(edition[0]);
            champ = champ.replace(edition[0], edition[1]);
        }
        assertThat(champ).isEqualTo(String.valueOf(
            map(map(v4.get("properties")).get("level_evidence")).get("description")));

        String racine = String.valueOf(v5.get("description"));
        assertThat(racine)
            .as("la symetrie du cout est ecrite la ou le fournisseur la lit")
            .contains("annoncer un A2 n'est pas plus confortable qu'annoncer un B2")
            .contains("il ne sanctionne rien en dessous du B1");
        for (String[] edition : EDITIONS_DESCRIPTION_RACINE_V5) {
            assertThat(racine).contains(edition[0]);
            racine = racine.replace(edition[0], edition[1]);
        }
        assertThat(racine).isEqualTo(String.valueOf(v4.get("description")));
    }

    /** L'interdiction de la NOTE survit a v5 du contrat, comme a toutes les autres. */
    @Test
    void leToolSchemaV5NePrevoitToujoursAucunChampDeNote() {
        String brut = resourceText("prompts/competence-analysis-tool-schema-v5.json")
            .toLowerCase(Locale.ROOT);
        assertThat(brut).doesNotContain("note_globale", "niveau_cecrl", "scores_criteres", "/20");

        Map<String, Object> properties = map(resource(
            "prompts/competence-analysis-tool-schema-v5.json").get("properties"));
        assertThat(properties.keySet().stream().filter(k -> k.contains("note")))
            .as("aucun champ de note : un micro-exercice n'en porte pas")
            .isEmpty();
        assertThat(strings(map(properties.get("level_reached")).get("enum")))
            .as("profil TCF IRN : cinq valeurs, jamais C1 ni C2")
            .containsExactlyElementsOf(NIVEAUX);
    }

    /** L'invariant du montage a deux appels survit a v6. */
    @Test
    void lesConsignesV6NeParlentJamaisDuNiveauViseParLeCandidat() {
        String consignes = resourceText("prompts/competence-analysis-rubrics-v6.json");

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

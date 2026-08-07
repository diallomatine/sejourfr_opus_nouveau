package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Verifie que le system prompt et le user message sont RENDUS depuis
 * production-rubrics-v3.json (commun + bloc tache), sans aucun gabarit .md.
 */
class EvaluationPromptBuilderTest {

    private EvaluationPromptBuilder builder;

    @BeforeEach
    void setUp() {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.setRubricsVersion("v3");
        ObjectMapper om = new ObjectMapper();
        ProductionRubricsProvider provider = new ProductionRubricsProvider(props, om);
        provider.load(); // charge le fichier v3 du classpath
        builder = new EvaluationPromptBuilder(om, provider);
    }

    @Test
    void systemPrompt_rendu_depuis_commun() {
        String system = builder.buildSystemPrompt();
        // Sections (titres rendus en "# titre")
        assertThat(system).contains("# Role");
        assertThat(system).contains("# Production hors-sujet (regle stricte)");
        assertThat(system).contains("examinateur officiel du TCF IRN");
        // Few-shot rendus
        assertThat(system).contains("# Exemples d'ancrage");
        assertThat(system).contains("niveau_cecrl : B2");
        // Aucune fuite de placeholder de gabarit
        assertThat(system).doesNotContain("{MODALITE}").doesNotContain("{CRITERES}");
    }

    @Test
    void userPrompt_EE_contient_donnees_et_bloc_tache() {
        ProductionTask task = new ProductionTask();
        task.setEpreuve(EpreuveType.TCF_EE);
        task.setTacheNumero((short) 1);
        task.setNiveauCible("A2");
        task.setConsigne("Annoncez votre demenagement a un ami et invitez-le.");
        task.setMotsMin(30);
        task.setMotsMax(60);

        String user = builder.buildUserPrompt(task, "Salut Marie, j'ai demenage. Viens samedi !", false, null);

        assertThat(user).contains("ÉPREUVE : Expression ecrite, tâche 1");
        assertThat(user).contains("NIVEAU CIBLE DE LA TÂCHE : A2");
        assertThat(user).contains("LONGUEUR ATTENDUE : 30 à 60 mots");
        assertThat(user).contains("Annoncez votre demenagement");
        assertThat(user).contains("\"pertinence\""); // criteres JSON du bloc tache
        assertThat(user).contains("BARÈME DE LA NOTE /20");
        assertThat(user).contains("- A2 :"); // descripteurs formates
        assertThat(user).contains("submit_evaluation");
        // EE : pas de bloc duree
        assertThat(user).doesNotContain("DURÉE");
    }

    @Test
    void systemPrompt_interaction_utilise_examinateur_comme_preuve_de_comprehension() {
        String system = builder.buildSystemPrompt();
        assertThat(system).contains("# Production orale en INTERACTION");
        // Point 2/4b : tolerance STT temps reel + examinateur temoin de comprehension.
        assertThat(system).contains("TRANSCRIPTION TEMPS REEL");
        assertThat(system).contains("TEMOIN DE COMPREHENSION");
        assertThat(system).contains("s'est FAIT COMPRENDRE");
    }

    @Test
    void userPrompt_EO_T2_ne_exige_pas_toutes_les_questions() {
        ProductionTask task = new ProductionTask();
        task.setEpreuve(EpreuveType.TCF_EO);
        task.setTacheNumero((short) 2);
        task.setNiveauCible("B1");
        task.setConsigne("Reservez une chambre d'hotel.");
        task.setDureeMaxSec(300);

        String user = builder.buildUserPrompt(task, "Candidat : bonjour je voudrais une chambre", true, 200);

        assertThat(user).contains("ÉPREUVE : Expression orale, tâche 2");
        // Point 6 : les questions du sujet sont des pistes, pas une check-list.
        assertThat(user).contains("ne penalise JAMAIS le fait qu'il n'ait pas pose toutes ces questions");
    }

    @Test
    void userPrompt_EO_n_injecte_jamais_la_duree_dans_le_materiau_de_notation() {
        ProductionTask task = new ProductionTask();
        task.setEpreuve(EpreuveType.TCF_EO);
        task.setTacheNumero((short) 1);
        task.setNiveauCible("A2");
        task.setConsigne("Presentez-vous.");
        task.setDureeMaxSec(180);

        String user = builder.buildUserPrompt(task, "bonjour je m'appelle samuel", true, 90);

        assertThat(user).contains("ÉPREUVE : Expression orale, tâche 1");
        assertThat(user).doesNotContain("DURÉE", "90 s", "objectif 180 s");
        // EO : pas de bloc longueur (specifique EE)
        assertThat(user).doesNotContain("LONGUEUR ATTENDUE");
    }

    // ------------------------------------------------------------------- v5

    private EvaluationPromptBuilder builderV5() {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.setRubricsVersion("v5");
        ObjectMapper om = new ObjectMapper();
        ProductionRubricsProvider provider = new ProductionRubricsProvider(props, om);
        provider.load();
        return new EvaluationPromptBuilder(om, provider);
    }

    /**
     * La grille envoyee au modele est bien celle du TCF : 4 criteres, poids
     * 0,25, libelles ACCENTUES (ce sont eux qui remontent ensuite jusqu'a
     * l'ecran du candidat).
     */
    @Test
    void userPrompt_v5_envoie_les_quatre_criteres_du_tcf() {
        ProductionTask task = new ProductionTask();
        task.setEpreuve(EpreuveType.TCF_EE);
        task.setTacheNumero((short) 1);
        task.setNiveauCible("A2");
        task.setConsigne("Annoncez votre demenagement a un ami et invitez-le.");
        task.setMotsMin(30);
        task.setMotsMax(60);

        String user = builderV5().buildUserPrompt(task, "Salut Marie, j'ai demenage. Viens samedi !",
                false, null);

        assertThat(user)
                .contains("\"communiquer\"").contains("\"interagir\"")
                .contains("\"lexique\"").contains("\"morphosyntaxe\"")
                .contains("0.25")
                .as("libelles accentues, tels qu'affiches au candidat")
                .contains("Communiquer : accomplir la tâche et enchaîner les idées")
                .as("les criteres abandonnes ne doivent plus apparaitre")
                .doesNotContain("realisation_consigne").doesNotContain("coherence\"");
    }

    // ------------------------------------------------------------------- v8

    private EvaluationPromptBuilder builderV8() {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.setRubricsVersion("v8");
        ObjectMapper om = new ObjectMapper();
        ProductionRubricsProvider provider = new ProductionRubricsProvider(props, om);
        provider.load();
        return new EvaluationPromptBuilder(om, provider);
    }

    /**
     * Le system prompt v8 porte les consignes de RESTITUTION — et garde
     * intactes celles de notation : c'est tout le contrat de cette version.
     */
    @Test
    void systemPrompt_v8_porte_la_restitution_sans_toucher_a_la_notation() {
        String system = builderV8().buildSystemPrompt();

        assertThat(system)
                .as("notation inchangee")
                .contains("# Du score au niveau : la note EST le niveau (obligatoire)")
                .contains("10 et plus -> B2 ; 6 a 9 -> B1 ; 2 a 5 -> A2")
                .contains("GARDE-FOU DE COUPLAGE")
                .contains("TEST DECISIF A1 vs A2")
                .contains("TEST DECISIF B1 vs B2")
                .contains("# Exemples d'ancrage")
                .as("restitution ajoutee")
                .contains("# Une erreur, un seul endroit (regle anti-repetition, regle capitale)")
                .contains("# Ne reproche jamais un moyen que la consigne n'exigeait pas (regle capitale)")
                .contains("# Version amelioree de la production (taches ECRITES uniquement)")
                .contains("# Confiance : TA certitude de correcteur, jamais la qualite du candidat")
                .contains("# Accomplissement de la tache et VERDICT (bloc obligatoire)");
        assertThat(system).doesNotContain("{MODALITE}").doesNotContain("{CRITERES}");
    }

    /** Chaque tache ECRITE demande la reecriture, chaque tache orale l'interdit. */
    @Test
    void userPrompt_v8_demande_la_version_amelioree_a_l_ecrit_et_l_interdit_a_l_oral() {
        EvaluationPromptBuilder builder = builderV8();

        ProductionTask ee = new ProductionTask();
        ee.setEpreuve(EpreuveType.TCF_EE);
        ee.setTacheNumero((short) 2);
        ee.setNiveauCible("B1");
        ee.setConsigne("Racontez un voyage marquant a un ami.");
        ee.setMotsMin(60);
        ee.setMotsMax(90);
        assertThat(builder.buildUserPrompt(ee, "Je suis alle a Lyon avec ma soeur.", false, null))
                .contains("VERSION AMELIOREE obligatoire")
                .contains("60 a 90 mots")
                .contains("accomplissement.objectif");

        ProductionTask eo = new ProductionTask();
        eo.setEpreuve(EpreuveType.TCF_EO);
        eo.setTacheNumero((short) 2);
        eo.setNiveauCible("B1");
        eo.setConsigne("Reservez une chambre d'hotel.");
        assertThat(builder.buildUserPrompt(eo, "Candidat : bonjour je voudrais une chambre", true, 200))
                .contains("AUCUNE version_amelioree sur une tache orale")
                .doesNotContain("VERSION AMELIOREE obligatoire");
    }

    // ------------------------------------------------------------------ v12

    private EvaluationPromptBuilder builderV12() {
        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.setRubricsVersion("v12");
        ObjectMapper om = new ObjectMapper();
        ProductionRubricsProvider provider = new ProductionRubricsProvider(props, om);
        provider.load();
        return new EvaluationPromptBuilder(om, provider);
    }

    /**
     * Sous v12 la production part DECOUPEE ET NUMEROTEE, et les bornes servies
     * sont une DONNEE (elles dependent de la production), pas une consigne de
     * notation — celle-ci vit dans le fichier de rubriques, comme tout le reste.
     */
    @Test
    void userPrompt_v12_envoie_la_production_decoupee_en_segments_numerotes() {
        ProductionTask task = new ProductionTask();
        task.setEpreuve(EpreuveType.TCF_EE);
        task.setTacheNumero((short) 1);
        task.setNiveauCible("A2");
        task.setConsigne("Annoncez votre demenagement a un ami et invitez-le.");
        task.setMotsMin(30);
        task.setMotsMax(60);
        String production = "Salut Marie ! J'ai déménagé samedi. Viens le voir ?";

        EvaluationProductionSegments segments =
            EvaluationProductionSegments.of(production, EpreuveType.TCF_EE);
        String user = builderV12().buildUserPrompt(task, production, false, null, segments);

        assertThat(user)
            .contains("PRODUCTION DU CANDIDAT, DÉCOUPÉE EN SEGMENTS NUMÉROTÉS")
            .contains("[1] Salut Marie !")
            .contains("[2] J'ai déménagé samedi.")
            .contains("[3] Viens le voir ?")
            .contains("SEGMENTS DISPONIBLES POUR `preuve_segment` : 1 à 3.")
            .contains("submit_evaluation");
    }

    /** Sans decoupe (contrats v5 et anterieurs), le rendu ne change pas d'un caractere. */
    @Test
    void userPrompt_sans_decoupe_reste_celui_des_contrats_anterieurs() {
        ProductionTask task = new ProductionTask();
        task.setEpreuve(EpreuveType.TCF_EE);
        task.setTacheNumero((short) 1);
        task.setNiveauCible("A2");
        task.setConsigne("Annoncez votre demenagement a un ami et invitez-le.");

        assertThat(builderV12().buildUserPrompt(task, "Salut Marie !", false, null, null))
            .contains("PRODUCTION DU CANDIDAT :")
            .doesNotContain("SEGMENTS DISPONIBLES");
    }

    /** Le system prompt v12 dit au correcteur de DESIGNER un numero, plus de recopier. */
    @Test
    void systemPrompt_v12_demande_un_numero_de_segment_et_plus_une_recopie() {
        String system = builderV12().buildSystemPrompt();

        assertThat(system)
            .contains("preuve_segment")
            .contains("SEGMENTS NUMEROTES")
            .as("notation strictement inchangee par rapport a v9")
            .contains("# Du score au niveau : la note EST le niveau (obligatoire)")
            .contains("10 et plus -> B2 ; 6 a 9 -> B1 ; 2 a 5 -> A2")
            .contains("TEST DECISIF A1 vs A2")
            .contains("TEST DECISIF B1 vs B2")
            .contains("GARDE-FOU DE COUPLAGE")
            .contains("# Exemples d'ancrage")
            .as("la consigne de recopie litterale a disparu")
            .doesNotContain("recopiee EXACTEMENT telle qu'elle apparait")
            .doesNotContain("caractere par caractere");
    }

    /** Le system prompt v5 porte le passage note -> niveau et l'exigence pedagogique. */
    @Test
    void systemPrompt_v5_porte_le_passage_note_niveau_et_le_comment() {
        String system = builderV5().buildSystemPrompt();

        assertThat(system)
                .contains("# Du score au niveau : la note EST le niveau (obligatoire)")
                .contains("16 et plus -> B2 ; 13 a 15 -> B1 ; 9 a 12 -> A2 ; 1 a 8 -> A1")
                .contains("# Preuves litterales et priorites : ENSEIGNER, PAS CONSTATER")
                .contains("GARDE-FOU DE COUPLAGE")
                .contains("# Exemples d'ancrage");
        assertThat(system).doesNotContain("{MODALITE}").doesNotContain("{CRITERES}");
    }
}

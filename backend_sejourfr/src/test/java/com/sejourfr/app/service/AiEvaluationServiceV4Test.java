package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ProductionSubmissionSource;
import com.sejourfr.app.enums.SubmissionStatut;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Moteur d'evaluation v4 vu de bout en bout ({@code evaluate}) avec un LLM
 * mocke : verdict de validite pre-LLM, confiance plafonnee serveur, filtrage
 * des preuves inventees, bandes qualitatives par critere, plafonds de niveau et
 * avertissement « fonde sur la transcription ».
 *
 * <p>Les rubriques chargees sont les VRAIES (v4) : les poids et les codes de
 * criteres testes ici sont ceux qui tourneront en production.
 */
class AiEvaluationServiceV4Test {

    private static final String TEXTE_EE =
        "Salut Paul ! J'ai une bonne nouvelle : j'ai enfin déménagé la semaine dernière. "
            + "Mon logement se trouve près de la gare, il est lumineux et il y a un petit "
            + "jardin derrière. Viens passer le week-end quand tu veux, il y a de la place.";

    private com.sejourfr.app.manager.ProductionSubmissionManager submissionManager;
    private com.sejourfr.app.manager.TranscriptionManager transcriptionManager;
    private com.sejourfr.app.manager.AiEvaluationManager aiEvaluationManager;
    private EvaluationLlmClient llmClient;
    private EvaluationLlmClient secondPassClient;
    private ProductionSecondePasseService secondePasse;
    private ProductionEvaluationProperties props;
    private AiEvaluationService service;

    private static Map<String, Object> score(String code, Number note, String preuve) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", code);
        m.put("note_sur_20", note);
        m.put("commentaire", "commentaire " + code);
        m.put("preuve", preuve);
        return m;
    }

    /** Feedback LLM plausible pour EE_T1 (codes de la rubrique v4). */
    private static Map<String, Object> feedbackEeT1(Number note) {
        Map<String, Object> f = new LinkedHashMap<>();
        f.put("note_globale", note);
        f.put("niveau_cecrl", "B1");
        f.put("justification_niveau", "Emploi du passé composé et lexique du logement.");
        f.put("confiance", "HAUTE");
        f.put("confiance_raisons", new ArrayList<>(List.of("production complète et lisible")));
        f.put("accomplissement", Map.of(
            "points_traites", List.of(Map.of("libelle", "Nouvelle annoncée", "obligatoire", true)),
            "points_oublies", List.of(Map.of("libelle", "Météo évoquée", "obligatoire", false))));
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("realisation_consigne", note, "j'ai enfin déménagé"),
            score("adequation_destinataire", note, "Salut Paul"),
            score("lexique", note, "il est lumineux"),
            score("morphosyntaxe", note, "Viens passer le week-end"),
            score("coherence", note, "il y a un petit jardin"))));
        f.put("points_forts", new ArrayList<>(List.of("Message clair")));
        f.put("points_a_ameliorer", new ArrayList<>(List.of("Varier les connecteurs")));
        return f;
    }

    /** Feedback conforme aux quatre critères universels de la rubrique v3. */
    private static Map<String, Object> feedbackV3(Number note) {
        Map<String, Object> f = feedbackEeT1(note);
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("pertinence", note, "j'ai enfin déménagé"),
            score("lexique", note, "il est lumineux"),
            score("morphosyntaxe", note, "Viens passer le week-end"),
            score("coherence", note, "il y a un petit jardin"))));
        return f;
    }

    private ProductionTask task(EpreuveType epreuve, int tache) {
        ProductionTask t = new ProductionTask();
        t.setId(UUID.randomUUID());
        t.setEpreuve(epreuve);
        t.setTacheNumero((short) tache);
        t.setConsigne("Vous venez d'emménager. Écrivez à un ami pour annoncer la nouvelle, "
            + "décrire votre logement et l'inviter.");
        t.setNiveauCible("B1");
        return t;
    }

    private ProductionSubmission submission(ProductionTask task, String texte) {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(UUID.randomUUID());
        s.setProductionTask(task);
        s.setStatut(SubmissionStatut.SUBMITTED);
        s.setTexteSoumis(texte);
        when(submissionManager.findById(s.getId())).thenReturn(Optional.of(s));
        return s;
    }

    private ProductionSubmission submissionOrale(ProductionTask task, String transcript,
                                                 ProductionSubmissionSource source) {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(UUID.randomUUID());
        s.setProductionTask(task);
        s.setStatut(SubmissionStatut.SUBMITTED);
        s.setSource(source);
        s.setMediaDurationSec(210);
        when(submissionManager.findById(s.getId())).thenReturn(Optional.of(s));
        when(transcriptionManager.findLatestTexteBySubmissionId(s.getId()))
                .thenReturn(Optional.of(transcript));
        return s;
    }

    private void stubLlm(Map<String, Object> feedback) {
        when(llmClient.evaluate(anyString(), anyString()))
            .thenReturn(new EvaluationLlmClient.Outcome(feedback, 100, 200, 3));
    }

    @SuppressWarnings("unchecked")
    private static List<Map<String, Object>> scores(AiEvaluation eval) {
        return (List<Map<String, Object>>) eval.getFeedbackJson().get("scores_criteres");
    }

    @SuppressWarnings("unchecked")
    private static List<String> avertissements(AiEvaluation eval) {
        Object o = eval.getFeedbackJson().get("avertissements");
        return o instanceof List<?> l ? (List<String>) l : List.of();
    }

    @BeforeEach
    void setUp() {
        submissionManager = mock(com.sejourfr.app.manager.ProductionSubmissionManager.class);
        transcriptionManager = mock(com.sejourfr.app.manager.TranscriptionManager.class);
        aiEvaluationManager = mock(com.sejourfr.app.manager.AiEvaluationManager.class);
        llmClient = mock(EvaluationLlmClient.class);
        when(llmClient.getModelName()).thenReturn("modele-test");
        when(llmClient.getPromptVersion()).thenReturn("v2");
        secondPassClient = mock(EvaluationLlmClient.class);
        when(secondPassClient.getModelName()).thenReturn("modele-test-2");
        when(secondPassClient.getPromptVersion()).thenReturn("v2");
        when(aiEvaluationManager.save(any())).thenAnswer(inv -> inv.getArgument(0));

        props = new ProductionEvaluationProperties();
        buildService("v4");
    }

    /** Recable le service sur une version de rubriques donnee (bascule v3 ↔ v4). */
    private void buildService(String rubricsVersion) {
        props.setRubricsVersion(rubricsVersion);
        ProductionRubricsProvider rubrics = new ProductionRubricsProvider(props, new ObjectMapper());
        rubrics.load();
        EvaluationPromptBuilder promptBuilder = new EvaluationPromptBuilder(new ObjectMapper(), rubrics);
        ProductionValidityService validity = new ProductionValidityService(props);

        secondePasse = new ProductionSecondePasseService(props, secondPassClient, rubrics);
        service = new AiEvaluationService(submissionManager, transcriptionManager, aiEvaluationManager,
            llmClient, promptBuilder, rubrics, validity, secondePasse,
            new ProductionFluiditeService(props), new EvaluationRefusalMetrics(), new EvaluationPurgeMetrics(), props);
    }

    // -------------------------------------------------- verdict INVALIDE (T1)

    @Test
    void productionInvalide_ne_declenche_aucun_appel_llm_et_note_zero() {
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task,
            "Hello Mary, I am writing to tell you that I finally found a new apartment "
                + "in the city center, it is very nice and it has two bedrooms.");

        AiEvaluation eval = service.evaluate(sub.getId());

        verify(llmClient, never()).evaluate(anyString(), anyString());
        assertThat(eval.getNoteSur20()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
        assertThat(eval.getModeleUtilise()).isEqualTo(AiEvaluationService.MODELE_VALIDATION_SERVEUR);
        assertThat(eval.getFeedbackJson().get("confiance")).isEqualTo("FAIBLE");
        assertThat(avertissements(eval)).anyMatch(a -> a.contains("n'est pas rédigé en français"));
        // Tous les criteres de la rubrique sont presents, a 0 / NON_EVALUABLE.
        assertThat(scores(eval)).hasSize(5)
            .allSatisfy(s -> assertThat(s.get("bande")).isEqualTo("NON_EVALUABLE"));
        // La submission passe quand meme a EVALUATED : l'utilisateur voit un resultat.
        assertThat(sub.getStatut()).isEqualTo(SubmissionStatut.EVALUATED);
        verify(submissionManager).save(sub);
    }

    // ---------------------------------------------------------- Tache 3 bandes

    @Test
    void bande_qualitative_ajoutee_a_chaque_critere() {
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task, TEXTE_EE);
        Map<String, Object> feedback = feedbackEeT1(13);
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> s = (List<Map<String, Object>>) feedback.get("scores_criteres");
        s.get(0).put("note_sur_20", 18);
        s.get(1).put("note_sur_20", 13);
        s.get(2).put("note_sur_20", 8);
        s.get(3).put("note_sur_20", 3);
        s.get(4).put("note_sur_20", 0);
        stubLlm(feedback);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(scores(eval)).extracting(m -> m.get("bande"))
            .containsExactly("TRES_BONNE_MAITRISE", "SATISFAISANT", "EN_COURS_ACQUISITION",
                "FRAGILE", "NON_EVALUABLE");
        // note_sur_20 reste dans le JSON (banc de mesure + admin).
        assertThat(scores(eval)).allSatisfy(m -> assertThat(m).containsKey("note_sur_20"));
    }

    // ------------------------------------------------------------- confiance

    @Test
    void confiance_conservee_quand_rien_ne_la_degrade() {
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task, TEXTE_EE);
        stubLlm(feedbackEeT1(13));

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getFeedbackJson().get("confiance")).isEqualTo("HAUTE");
    }

    @Test
    void confiance_absente_vaut_moyenne() {
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task, TEXTE_EE);
        Map<String, Object> feedback = feedbackEeT1(13);
        feedback.remove("confiance");
        stubLlm(feedback);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getFeedbackJson().get("confiance")).isEqualTo("MOYENNE");
    }

    @Test
    void confiance_hors_enum_vaut_moyenne() {
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task, TEXTE_EE);
        Map<String, Object> feedback = feedbackEeT1(13);
        feedback.put("confiance", "TOTALE");
        stubLlm(feedback);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getFeedbackJson().get("confiance")).isEqualTo("MOYENNE");
    }

    /**
     * Seul un obstacle a l'OBSERVATION plafonne la confiance : ici une langue
     * a moitie etrangere, qu'on ne lit qu'a moitie.
     */
    @Test
    @SuppressWarnings("unchecked")
    void confiance_degradee_par_un_doute_sur_la_langue() {
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task,
            "Hello Paul, I write you today about mon new apartment. Very nice place, big kitchen, "
                + "two bedrooms, small garden behind. Come visit next Saturday, we eat together, "
                + "je suis très content de la nouvelle.");
        stubLlm(feedbackEeT1(13));

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getFeedbackJson().get("confiance")).isEqualTo("MOYENNE");
        assertThat((List<String>) eval.getFeedbackJson().get("confiance_raisons"))
            .anyMatch(r -> r.contains("vérifications automatiques"));
        assertThat(avertissements(eval)).anyMatch(a -> a.contains("ne semble pas être en français"));
    }

    /**
     * Un recopiage partiel de la consigne est un doute d'AUTHENTICITE : le
     * candidat est averti, ses mots recopies sont ecartes, mais ce qui reste
     * s'observe parfaitement — la confiance de la correction n'y touche pas.
     */
    @Test
    void confiance_intacte_sur_un_recopiage_de_consigne() {
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task,
            "Vous venez d'emménager. Écrivez à un ami pour annoncer la nouvelle, décrire votre "
                + "logement et l'inviter. Salut Paul, mon logement est clair et calme, viens me voir.");
        stubLlm(feedbackEeT1(13));

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getFeedbackJson().get("confiance")).isEqualTo("HAUTE");
        assertThat(avertissements(eval)).anyMatch(a -> a.contains("recopie l'énoncé"));
    }

    @Test
    @SuppressWarnings("unchecked")
    void confiance_degradee_sur_un_dialogue_temps_reel() {
        ProductionTask task = task(EpreuveType.TCF_EO, 1);
        String dialogue = """
            Examinateur : Bonjour, pouvez-vous vous présenter ?
            Candidat : Bonjour, je m'appelle Karim et je viens du Maroc. Je travaille comme
            cuisinier dans un restaurant à Lyon depuis deux ans et j'aime beaucoup mon métier.
            """;
        ProductionSubmission sub = submissionOrale(task, dialogue, ProductionSubmissionSource.REALTIME);
        Map<String, Object> feedback = feedbackEeT1(13);
        feedback.put("scores_criteres", new ArrayList<>(List.of(
            score("realisation_consigne", 13, "je m'appelle Karim"),
            score("developpement_reponses", 13, "je travaille comme"),
            score("lexique", 13, "cuisinier dans un restaurant"),
            score("morphosyntaxe", 13, "je viens du Maroc"),
            score("coherence", 13, "depuis deux ans"))));
        stubLlm(feedback);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getFeedbackJson().get("confiance")).isEqualTo("MOYENNE");
        assertThat((List<String>) eval.getFeedbackJson().get("confiance_raisons"))
            .anyMatch(r -> r.contains("en direct"));
    }

    // --------------------------------------------------------------- preuves

    @Test
    void preuve_inventee_est_retiree_preuve_reelle_conservee() {
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task, TEXTE_EE);
        Map<String, Object> feedback = feedbackEeT1(13);
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> s = (List<Map<String, Object>>) feedback.get("scores_criteres");
        s.get(2).put("preuve", "j'ai visité le musée du Louvre hier");
        stubLlm(feedback);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(scores(eval).get(0)).containsEntry("preuve", "j'ai enfin déménagé");
        assertThat(scores(eval).get(2)).doesNotContainKey("preuve");
    }

    @Test
    void preuve_tolere_la_ponctuation_et_les_accents_approximatifs() {
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task, TEXTE_EE);
        Map<String, Object> feedback = feedbackEeT1(13);
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> s = (List<Map<String, Object>>) feedback.get("scores_criteres");
        s.get(0).put("preuve", "j'ai enfin demenage,");
        stubLlm(feedback);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(scores(eval).get(0)).containsKey("preuve");
    }

    // -------------------------------------------------------------- plafonds

    @Test
    void plafond_prise_de_position_ramene_le_niveau_a_A2_sur_T3() {
        ProductionTask task = task(EpreuveType.TCF_EE, 3);
        ProductionSubmission sub = submission(task, TEXTE_EE);
        Map<String, Object> feedback = feedbackEeT1(14);
        feedback.put("scores_criteres", new ArrayList<>(List.of(
            score("prise_position", 4, "il y a un petit jardin"),
            score("argumentation", 14, "il est lumineux"),
            score("coherence", 14, "Viens passer le week-end"),
            score("lexique", 14, "près de la gare"),
            score("morphosyntaxe", 14, "j'ai enfin déménagé"))));
        stubLlm(feedback);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.A2);
        assertThat(eval.getFeedbackJson().get("niveau_cecrl")).isEqualTo("A2");
        // Le plafond est TRACÉ dans le feedback : sans cette clé, le bilan
        // d'épreuve (qui recalcule sa compétence depuis scores_criteres) ne
        // pouvait pas en tenir compte — la tâche ressortait B1/B2 au bilan.
        assertThat(eval.getFeedbackJson().get(AiEvaluationService.PLAFOND_NIVEAU_KEY)).isEqualTo("A2");
        assertThat(avertissements(eval)).anyMatch(a -> a.contains("prise de position"));
    }

    @Test
    void plafond_prise_de_position_ne_s_applique_pas_au_dessus_du_seuil() {
        ProductionTask task = task(EpreuveType.TCF_EE, 3);
        ProductionSubmission sub = submission(task, TEXTE_EE);
        Map<String, Object> feedback = feedbackEeT1(14);
        feedback.put("scores_criteres", new ArrayList<>(List.of(
            score("prise_position", 12, "il y a un petit jardin"),
            score("argumentation", 14, "il est lumineux"),
            score("coherence", 14, "Viens passer le week-end"),
            score("lexique", 14, "près de la gare"),
            score("morphosyntaxe", 14, "j'ai enfin déménagé"))));
        stubLlm(feedback);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.B1);
        assertThat(eval.getFeedbackJson()).doesNotContainKey(AiEvaluationService.PLAFOND_NIVEAU_KEY);
        assertThat(avertissements(eval)).noneMatch(a -> a.contains("prise de position"));
    }

    @Test
    void plafond_conduite_echange_ramene_le_niveau_a_A2_sur_EO_T2() {
        ProductionTask task = task(EpreuveType.TCF_EO, 2);
        String dialogue = """
            Examinateur : Bonjour, que puis-je faire pour vous ?
            Candidat : Bonjour madame, je voudrais avoir des informations sur les horaires
            du train pour Marseille et je cherche aussi le prix du billet aller-retour.
            """;
        ProductionSubmission sub = submissionOrale(task, dialogue, ProductionSubmissionSource.ASYNC);
        Map<String, Object> feedback = feedbackEeT1(14);
        feedback.put("scores_criteres", new ArrayList<>(List.of(
            score("conduite_echange", 5, "je voudrais avoir des informations"),
            score("adequation_destinataire", 14, "Bonjour madame"),
            score("lexique", 14, "le prix du billet"),
            score("morphosyntaxe", 14, "je cherche aussi"),
            score("coherence", 14, "pour Marseille"))));
        stubLlm(feedback);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.A2);
        assertThat(avertissements(eval)).anyMatch(a -> a.contains("L'échange n'a pas vraiment eu lieu"));
    }

    @Test
    void plafonds_desactivables_par_configuration() {
        props.getPlafonds().setEnabled(false);
        ProductionTask task = task(EpreuveType.TCF_EE, 3);
        ProductionSubmission sub = submission(task, TEXTE_EE);
        Map<String, Object> feedback = feedbackEeT1(14);
        feedback.put("scores_criteres", new ArrayList<>(List.of(
            score("prise_position", 0, "il y a un petit jardin"),
            score("argumentation", 14, "il est lumineux"),
            score("coherence", 14, "Viens passer le week-end"),
            score("lexique", 14, "près de la gare"),
            score("morphosyntaxe", 14, "j'ai enfin déménagé"))));
        stubLlm(feedback);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.B1);
    }

    // ---------------------------------------------------- avertissement oral

    @Test
    void production_orale_porte_l_avertissement_transcription() {
        ProductionTask task = task(EpreuveType.TCF_EO, 1);
        ProductionSubmission sub = submissionOrale(task,
            "Bonjour, je m'appelle Karim et je viens du Maroc. Je travaille comme cuisinier "
                + "dans un restaurant à Lyon depuis deux ans et j'aime beaucoup mon métier.",
            ProductionSubmissionSource.ASYNC);
        Map<String, Object> feedback = feedbackEeT1(13);
        feedback.put("scores_criteres", new ArrayList<>(List.of(
            score("realisation_consigne", 13, "je m'appelle Karim"),
            score("developpement_reponses", 13, "je travaille comme cuisinier"),
            score("lexique", 13, "dans un restaurant"),
            score("morphosyntaxe", 13, "je viens du Maroc"),
            score("coherence", 13, "depuis deux ans"))));
        stubLlm(feedback);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(avertissements(eval)).first()
            .isEqualTo(AiEvaluationService.AVERTISSEMENT_TRANSCRIPTION);
    }

    @Test
    void production_ecrite_ne_porte_pas_l_avertissement_transcription() {
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task, TEXTE_EE);
        stubLlm(feedbackEeT1(13));

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(avertissements(eval)).doesNotContain(AiEvaluationService.AVERTISSEMENT_TRANSCRIPTION);
    }

    // ------------------------------------------------------- accomplissement

    @Test
    @SuppressWarnings("unchecked")
    void accomplissement_conserve_tel_quel_et_les_pistes_ne_penalisent_pas() {
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task, TEXTE_EE);
        stubLlm(feedbackEeT1(13));

        AiEvaluation eval = service.evaluate(sub.getId());

        Map<String, Object> acc = (Map<String, Object>) eval.getFeedbackJson().get("accomplissement");
        assertThat((List<Map<String, Object>>) acc.get("points_oublies"))
            .singleElement()
            .satisfies(p -> assertThat(p).containsEntry("obligatoire", false));
        // Σ(13 × poids) = 13 : un point oublie « piste » n'a rien retire.
        assertThat(eval.getNoteSur20()).isEqualByComparingTo(new BigDecimal("13"));
    }

    // ------------------------------------------------------- retour arriere v3

    @Test
    void rubriques_v3_et_reponse_sans_champs_v2_restent_evaluables() {
        // Le banc de mesure compare v3 et v4 en basculant EVAL_RUBRICS_VERSION :
        // le chemin v3 (4 criteres universels, pas de confiance ni de preuve)
        // doit continuer a produire une evaluation complete.
        buildService("v3");
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task, TEXTE_EE);

        Map<String, Object> feedback = new LinkedHashMap<>();
        feedback.put("note_globale", 13);
        feedback.put("niveau_cecrl", "B1");
        // Maps mutables : Jackson en produit de mutables, et le service enrichit
        // chaque score sur place (label, bande).
        List<Map<String, Object>> v3Scores = new ArrayList<>();
        for (String code : List.of("pertinence", "lexique", "morphosyntaxe", "coherence")) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("code", code);
            m.put("note_sur_20", 13);
            m.put("commentaire", "ok");
            v3Scores.add(m);
        }
        feedback.put("scores_criteres", v3Scores);
        stubLlm(feedback);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getNoteSur20()).isEqualByComparingTo(new BigDecimal("13"));
        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.B1);
        // Les enrichissements v4 s'appliquent quand meme (bandes, confiance par defaut).
        assertThat(scores(eval)).allSatisfy(s -> assertThat(s.get("bande")).isEqualTo("SATISFAISANT"));
        assertThat(eval.getFeedbackJson().get("confiance")).isEqualTo("MOYENNE");
        assertThat(eval.getFeedbackJson()).containsKey("accomplissement");
    }

    @Test
    void accomplissement_absent_est_normalise_en_listes_vides() {
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task, TEXTE_EE);
        Map<String, Object> feedback = feedbackEeT1(13);
        feedback.remove("accomplissement");
        stubLlm(feedback);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getFeedbackJson().get("accomplissement"))
            .isEqualTo(Map.of("points_traites", List.of(), "points_oublies", List.of()));
    }

    // ------------------------------------------------------------------------
    // Phase 3 — seconde passe (drapeau seconde-passe.enabled, false par defaut)
    // ------------------------------------------------------------------------

    /** Note 12 = pile sur le seuil B1 par defaut → zone floue garantie. */
    private ProductionSubmission submissionZoneFloue() {
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        return submission(task, TEXTE_EE);
    }

    private void stubSecondePasse(Map<String, Object> feedback) {
        when(secondPassClient.evaluate(anyString(), anyString()))
            .thenReturn(new EvaluationLlmClient.Outcome(feedback, 50, 60, 2));
    }

    @Test
    void secondePasse_desactivee_par_defaut_meme_en_zone_floue() {
        ProductionSubmission sub = submissionZoneFloue();
        stubLlm(feedbackEeT1(12));

        AiEvaluation eval = service.evaluate(sub.getId());

        verify(llmClient, times(1)).evaluate(anyString(), anyString());
        verify(secondPassClient, never()).evaluate(anyString(), anyString());
        assertThat(eval.getNoteSur20()).isEqualByComparingTo(new BigDecimal("12"));
        assertThat(eval.getFeedbackJson()).doesNotContainKey("seconde_passe");
        // Couts : ceux de l'unique appel.
        assertThat(eval.getTokensInput()).isEqualTo(100);
        assertThat(eval.getCoutMicroUsd()).isEqualTo(3);
    }

    @Test
    void secondePasse_activee_mais_zone_sure_ne_declenche_rien() {
        props.getSecondePasse().setEnabled(true);
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task, TEXTE_EE);
        // 17 : loin des seuils 15 / 12 / 7, confiance HAUTE, niveau LLM a 1 palier.
        stubLlm(feedbackEeT1(17));

        AiEvaluation eval = service.evaluate(sub.getId());

        verify(secondPassClient, never()).evaluate(anyString(), anyString());
        assertThat(eval.getFeedbackJson()).doesNotContainKey("seconde_passe");
    }

    @Test
    void secondePasse_zone_floue_retient_la_plus_basse_et_abaisse_la_confiance() {
        props.getSecondePasse().setEnabled(true);
        ProductionSubmission sub = submissionZoneFloue();
        stubLlm(feedbackEeT1(12));
        stubSecondePasse(feedbackEeT1(9));

        AiEvaluation eval = service.evaluate(sub.getId());

        verify(secondPassClient, times(1)).evaluate(anyString(), anyString());
        // La plus basse des deux passes l'emporte (biais mesure vers l'indulgence).
        assertThat(eval.getNoteSur20()).isEqualByComparingTo(new BigDecimal("9"));
        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.A2);
        assertThat(eval.getModeleUtilise()).isEqualTo("modele-test-2");
        // Divergence -> confiance abaissee d'un cran (HAUTE -> MOYENNE).
        assertThat(eval.getFeedbackJson().get("confiance")).isEqualTo("MOYENNE");
        // Couts cumules sur les deux appels.
        assertThat(eval.getTokensInput()).isEqualTo(150);
        assertThat(eval.getCoutMicroUsd()).isEqualTo(5);
        assertThat(eval.getFeedbackJson()).containsKey("seconde_passe");
    }

    @Test
    @SuppressWarnings("unchecked")
    void secondePasse_deux_passes_identiques_ne_touchent_pas_la_confiance() {
        props.getSecondePasse().setEnabled(true);
        ProductionSubmission sub = submissionZoneFloue();
        stubLlm(feedbackEeT1(12));
        stubSecondePasse(feedbackEeT1(12));

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getNoteSur20()).isEqualByComparingTo(new BigDecimal("12"));
        assertThat(eval.getFeedbackJson().get("confiance")).isEqualTo("HAUTE");
        Map<String, Object> trace = (Map<String, Object>) eval.getFeedbackJson().get("seconde_passe");
        assertThat(trace.get("divergente")).isEqualTo(false);
    }

    @Test
    void secondePasse_en_echec_conserve_la_premiere_passe() {
        props.getSecondePasse().setEnabled(true);
        ProductionSubmission sub = submissionZoneFloue();
        stubLlm(feedbackEeT1(12));
        when(secondPassClient.evaluate(anyString(), anyString()))
            .thenThrow(new com.sejourfr.app.exception.AiEvaluationException("LLM 2 injoignable"));

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getNoteSur20()).isEqualByComparingTo(new BigDecimal("12"));
        assertThat(eval.getModeleUtilise()).isEqualTo("modele-test");
        assertThat(eval.getFeedbackJson()).doesNotContainKey("seconde_passe");
    }

    // ------------------------------------------------------------------------
    // Phase 3 — fluidite (drapeau fluidite.enabled, false par defaut)
    // ------------------------------------------------------------------------

    private ProductionSubmission submissionOraleNotee() {
        ProductionTask task = task(EpreuveType.TCF_EO, 1);
        ProductionSubmission sub = submissionOrale(task,
            "Bonjour, je m'appelle Karim et je viens du Maroc. Je travaille comme cuisinier "
                + "dans un restaurant à Lyon depuis deux ans et j'aime beaucoup mon métier.",
            ProductionSubmissionSource.ASYNC);
        Map<String, Object> feedback = feedbackEeT1(13);
        feedback.put("scores_criteres", new ArrayList<>(List.of(
            score("realisation_consigne", 13, "je m'appelle Karim"),
            score("developpement_reponses", 13, "je travaille comme cuisinier"),
            score("lexique", 13, "dans un restaurant"),
            score("morphosyntaxe", 13, "je viens du Maroc"),
            score("coherence", 13, "depuis deux ans"))));
        stubLlm(feedback);
        return sub;
    }

    @Test
    void fluidite_desactivee_par_defaut_aucun_bloc_expose() {
        AiEvaluation eval = service.evaluate(submissionOraleNotee().getId());

        assertThat(eval.getFeedbackJson()).doesNotContainKey("fluidite");
    }

    @Test
    @SuppressWarnings("unchecked")
    void fluidite_activee_expose_le_debit_sans_changer_note_ni_niveau() {
        AiEvaluation sansDrapeau = service.evaluate(submissionOraleNotee().getId());

        props.getFluidite().setEnabled(true);
        AiEvaluation avecDrapeau = service.evaluate(submissionOraleNotee().getId());

        Map<String, Object> fluidite =
            (Map<String, Object>) avecDrapeau.getFeedbackJson().get("fluidite");
        assertThat(fluidite).isNotNull();
        assertThat(fluidite.get("debit_mots_par_minute")).isNotNull();
        assertThat(fluidite.get("informatif")).isEqualTo(true);
        // Le drapeau n'ajoute QUE de l'information : note et niveau inchanges.
        assertThat(avecDrapeau.getNoteSur20()).isEqualByComparingTo(sansDrapeau.getNoteSur20());
        assertThat(avecDrapeau.getNiveauCecrl()).isEqualTo(sansDrapeau.getNiveauCecrl());
    }

    @Test
    void fluidite_ne_s_applique_pas_a_l_ecrit() {
        props.getFluidite().setEnabled(true);
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task, TEXTE_EE);
        stubLlm(feedbackEeT1(13));

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getFeedbackJson()).doesNotContainKey("fluidite");
    }

    // ------------------------------------------- garanties SERVEUR du feedback

    /**
     * « Au plus 2 points à améliorer » est une règle produit : seuls le prompt
     * et le {@code maxItems} du tool-schema la portaient, et le LLM ne la tenait
     * pas (83 évaluations sur 109 dépassaient 2 en base). Le serveur tranche.
     */
    @Test
    @SuppressWarnings("unchecked")
    void points_a_ameliorer_sont_tronques_a_deux() {
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task, TEXTE_EE);
        Map<String, Object> feedback = feedbackEeT1(13);
        feedback.put("points_a_ameliorer", new ArrayList<>(List.of(
            "Varier les connecteurs", "Soigner les accords", "Développer la conclusion",
            "Éviter les répétitions", "Structurer en paragraphes")));
        stubLlm(feedback);

        AiEvaluation eval = service.evaluate(sub.getId());

        // Forme unique pour les fronts : objets {constat, ...}, tronques a 2.
        List<Map<String, Object>> points =
            (List<Map<String, Object>>) eval.getFeedbackJson().get("points_a_ameliorer");
        assertThat(points).extracting(m -> m.get("constat"))
            .containsExactly("Varier les connecteurs", "Soigner les accords");
    }

    @Test
    @SuppressWarnings("unchecked")
    void points_a_ameliorer_conformes_sont_laisses_intacts() {
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task, TEXTE_EE);
        Map<String, Object> feedback = feedbackEeT1(13);
        feedback.put("points_a_ameliorer",
            new ArrayList<>(List.of("Varier les connecteurs", "Soigner les accords")));
        stubLlm(feedback);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat((List<Map<String, Object>>) eval.getFeedbackJson().get("points_a_ameliorer"))
            .extracting(m -> m.get("constat"))
            .containsExactly("Varier les connecteurs", "Soigner les accords");
    }

    /**
     * La note doit rester relisable a posteriori : sans la version de GRILLE,
     * {@code prompt_version} ne disait que la forme de la sortie ("v2"), jamais
     * avec quels critères ni quels poids la note avait été produite.
     */
    @Test
    void version_de_grille_est_persistee_a_cote_du_tool_schema() {
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task, TEXTE_EE);
        stubLlm(feedbackEeT1(13));

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getPromptVersion()).isEqualTo("v2");
        assertThat(eval.getRubricsVersion()).isEqualTo("v4");
    }

    /** Y compris quand aucun LLM n'a été appelé (production jugée inexploitable). */
    @Test
    void version_de_grille_est_persistee_meme_sans_appel_llm() {
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task,
            "Hello Mary, I am writing to tell you that I finally found a new apartment "
                + "in the city center, it is very nice and it has two bedrooms.");

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getRubricsVersion()).isEqualTo("v4");
    }

    @Test
    void version_de_grille_suit_la_configuration() {
        buildService("v3");
        ProductionTask task = task(EpreuveType.TCF_EE, 1);
        ProductionSubmission sub = submission(task, TEXTE_EE);
        stubLlm(feedbackV3(13));

        assertThat(service.evaluate(sub.getId()).getRubricsVersion()).isEqualTo("v3");
    }
}

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
 * Moteur d'evaluation sur les rubriques v8 / tool-schema v5 — la version de la
 * RESTITUTION. Ce que verrouille cette classe :
 * <ul>
 *   <li>le nouveau verdict {@code accomplissement.objectif} + son resume
 *       traversent le pipeline jusqu'au feedback persiste ;</li>
 *   <li>la COHERENCE DEFENSIVE du verdict : un ATTEINT contredit par un point
 *       obligatoire oublie est abaisse par le serveur, jamais releve ;</li>
 *   <li>les plafonds de restitution (2 points forts, 3 exemples corriges) sont
 *       garantis SERVEUR, comme les 2 priorites ;</li>
 *   <li>{@code version_amelioree} vit a l'ECRIT et disparait a l'ORAL ;</li>
 *   <li>NON-REGRESSION : la notation est celle de v7 (memes notes, memes
 *       niveaux), et une sortie « legacy » sans verdict continue de passer.</li>
 * </ul>
 */
class AiEvaluationServiceV8Test {

    private static final String TEXTE_EE =
        "Salut Paul ! J'ai une bonne nouvelle : j'ai enfin déménagé la semaine dernière. "
            + "Mon logement se trouve près de la gare, il est lumineux et il y a un petit "
            + "jardin derrière. Viens passer le week-end quand tu veux, il y a de la place.";

    /** ~34 % de l'énoncé recopié : doute d'AUTHENTICITE, pas d'observation. */
    private static final String TEXTE_RECOPIAGE =
        "Vous venez d'emménager. Écrivez à un ami pour annoncer la nouvelle, décrire votre "
            + "logement et l'inviter. Salut Paul, mon logement est clair et calme, viens me voir.";

    /** Français très minoritaire, rien de recopié : obstacle à l'OBSERVATION. */
    private static final String TEXTE_LANGUE_DOUTEUSE =
        "Hello Paul, I write you today about mon new apartment. Very nice place, big kitchen, "
            + "two bedrooms, small garden behind. Come visit next Saturday, we eat together, "
            + "je suis très content de la nouvelle.";

    /** Énoncé recopié PUIS poursuivi en anglais : les deux doutes à la fois. */
    private static final String TEXTE_RECOPIAGE_ET_LANGUE_DOUTEUSE =
        "Vous venez d'emménager. Écrivez à un ami pour annoncer la nouvelle, décrire votre "
            + "logement et l'inviter. Hello Paul, I moved last week to a new apartment near the "
            + "station, very bright, two bedrooms, big kitchen and a small garden behind the "
            + "building. Come visit soon.";

    private static final String DIALOGUE_EO =
        "Examinateur : Bonjour, bienvenue à la mairie, je vous écoute.\n"
            + "Candidat : bonjour madame je voudrais des renseignements pour une inscription\n"
            + "Examinateur : Très bien, pour qui souhaitez-vous inscrire ?\n"
            + "Candidat : pour ma fille elle a six ans et nous habitons ici depuis un mois";

    private static final String VERSION_AMELIOREE =
        "Salut Paul ! J'ai une bonne nouvelle : j'ai déménagé la semaine dernière parce que "
            + "mon ancien logement était trop petit. Mon nouvel appartement, qui se trouve "
            + "près de la gare, est lumineux et possède un petit jardin. Viens passer le "
            + "week-end quand tu veux : il y a de la place pour toi.";

    private com.sejourfr.app.manager.ProductionSubmissionManager submissionManager;
    private com.sejourfr.app.manager.TranscriptionManager transcriptionManager;
    private com.sejourfr.app.manager.AiEvaluationManager aiEvaluationManager;
    private EvaluationLlmClient llmClient;
    private ProductionEvaluationProperties props;
    private AiEvaluationService service;

    @BeforeEach
    void setUp() {
        submissionManager = mock(com.sejourfr.app.manager.ProductionSubmissionManager.class);
        transcriptionManager = mock(com.sejourfr.app.manager.TranscriptionManager.class);
        aiEvaluationManager = mock(com.sejourfr.app.manager.AiEvaluationManager.class);
        llmClient = mock(EvaluationLlmClient.class);
        when(llmClient.getModelName()).thenReturn("modele-test");
        when(llmClient.getPromptVersion()).thenReturn("v5");
        when(aiEvaluationManager.save(any())).thenAnswer(inv -> inv.getArgument(0));

        props = new ProductionEvaluationProperties();
        props.setRubricsVersion("v8");
        buildService();
    }

    private void buildService() {
        ProductionRubricsProvider rubrics = new ProductionRubricsProvider(props, new ObjectMapper());
        rubrics.load();
        EvaluationPromptBuilder promptBuilder = new EvaluationPromptBuilder(new ObjectMapper(), rubrics);
        service = new AiEvaluationService(submissionManager, transcriptionManager, aiEvaluationManager,
            llmClient, promptBuilder, rubrics, new ProductionValidityService(props),
            new ProductionSecondePasseService(props, mock(EvaluationLlmClient.class), rubrics),
            new ProductionFluiditeService(props), new EvaluationRefusalMetrics(), props);
    }

    // ------------------------------------------------------------- fixtures

    private static Map<String, Object> score(String code, Number note, String preuve) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", code);
        m.put("note_sur_20", note);
        m.put("commentaire", "commentaire " + code);
        m.put("preuve", preuve);
        return m;
    }

    private static Map<String, Object> point(String libelle, boolean obligatoire) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("libelle", libelle);
        m.put("obligatoire", obligatoire);
        return m;
    }

    private static Map<String, Object> accomplissement(String objectif, List<Object> oublies) {
        Map<String, Object> acc = new LinkedHashMap<>();
        acc.put("objectif", objectif);
        acc.put("objectif_resume",
            "Tu annonces ton déménagement, tu décris ton logement et tu invites ton ami.");
        acc.put("points_traites", new ArrayList<>(List.of(point("Nouvelle annoncée", true))));
        acc.put("points_oublies", new ArrayList<>(oublies));
        return acc;
    }

    /** Sortie v5 plausible : notes de la grille du TCF, preuves prises dans le texte. */
    private static Map<String, Object> feedback(Number communiquer, Number interagir,
                                                Number lexique, Number morphosyntaxe) {
        Map<String, Object> f = new LinkedHashMap<>();
        f.put("note_globale", 7);
        f.put("niveau_cecrl", "B1");
        f.put("justification_niveau", "Emploi du passé composé et lexique du logement.");
        f.put("confiance", "HAUTE");
        f.put("confiance_raisons", new ArrayList<>(List.of("production complète et lisible")));
        f.put("accomplissement", accomplissement("ATTEINT", List.of()));
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", communiquer, "j'ai enfin déménagé"),
            score("interagir", interagir, "Salut Paul"),
            score("lexique", lexique, "il est lumineux"),
            score("morphosyntaxe", morphosyntaxe, "Viens passer le week-end"))));
        f.put("points_forts", new ArrayList<>(List.of("Message clair")));
        f.put("points_a_ameliorer", new ArrayList<>(List.of(Map.of(
            "constat", "Vos idées sont juxtaposées.",
            "comment", "Relie tes deux idées avec « parce que » au lieu d'un point.",
            "exemple", Map.of("avant", "il est lumineux", "apres", "il est lumineux parce qu'il")))));
        f.put("suggestions", new ArrayList<>());
        f.put("exemples_corriges", new ArrayList<>());
        f.put("version_amelioree", VERSION_AMELIOREE);
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

    private ProductionSubmission submissionOrale(ProductionTask task, String transcript) {
        return submissionOrale(task, transcript, null);
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
    private static Map<String, Object> accomplissementDe(AiEvaluation eval) {
        return (Map<String, Object>) eval.getFeedbackJson().get("accomplissement");
    }

    @SuppressWarnings("unchecked")
    private static List<String> avertissements(AiEvaluation eval) {
        Object o = eval.getFeedbackJson().get("avertissements");
        return o instanceof List<?> l ? (List<String>) l : List.of();
    }

    // ------------------------------------------------------- verdict de tache

    @Test
    void le_verdict_et_son_resume_traversent_le_pipeline() {
        stubLlm(feedback(7, 7, 7, 7));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(accomplissementDe(eval))
            .containsEntry("objectif", "ATTEINT")
            .containsEntry("objectif_resume",
                "Tu annonces ton déménagement, tu décris ton logement et tu invites ton ami.");
        assertThat(eval.getNoteSur20()).isEqualByComparingTo("7.0");
        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.B1);
    }

    /**
     * LE garde-fou : le rapport ne peut plus se contredire en tete d'ecran. Un
     * ATTEINT annonce alors qu'un point OBLIGATOIRE est liste comme oublie est
     * abaisse cote serveur — dans le sens prudent, comme la confiance.
     */
    @Test
    void un_atteint_contredit_par_un_manque_obligatoire_est_abaisse() {
        Map<String, Object> f = feedback(7, 7, 7, 7);
        f.put("accomplissement", accomplissement("ATTEINT", List.of(point("Invitation absente", true))));
        stubLlm(f);
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        assertThat(accomplissementDe(service.evaluate(sub.getId())))
            .containsEntry("objectif", "PARTIELLEMENT_ATTEINT");
    }

    /** Une PISTE non abordee ne degrade JAMAIS le verdict : regle produit. */
    @Test
    void une_piste_non_abordee_ne_degrade_pas_le_verdict() {
        Map<String, Object> f = feedback(7, 7, 7, 7);
        f.put("accomplissement", accomplissement("ATTEINT", List.of(point("Prix non évoqué", false))));
        stubLlm(f);
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        assertThat(accomplissementDe(service.evaluate(sub.getId())))
            .containsEntry("objectif", "ATTEINT");
    }

    /** Le serveur n'abaisse que : il ne remonte jamais un verdict vers ATTEINT. */
    @Test
    void le_serveur_ne_releve_jamais_un_verdict() {
        Map<String, Object> f = feedback(7, 7, 7, 7);
        f.put("accomplissement", accomplissement("PARTIELLEMENT_ATTEINT", List.of()));
        stubLlm(f);
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        assertThat(accomplissementDe(service.evaluate(sub.getId())))
            .containsEntry("objectif", "PARTIELLEMENT_ATTEINT");
    }

    /**
     * Le verdict est INDEPENDANT de la note : une consigne entierement traitee
     * avec des moyens A1 reste ATTEINTE et se note quand meme A1.
     */
    @Test
    void un_verdict_atteint_ne_remonte_pas_la_note() {
        Map<String, Object> f = feedback(1, 1, 1, 1);
        f.put("accomplissement", accomplissement("ATTEINT", List.of()));
        stubLlm(f);
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(accomplissementDe(eval)).containsEntry("objectif", "ATTEINT");
        assertThat(eval.getNoteSur20()).isEqualByComparingTo("1.0");
        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.A1);
    }

    /** Production jugee inexploitable : verdict explicite, sans appel LLM. */
    @Test
    void une_production_invalide_sort_avec_un_verdict_non_atteint() {
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), "ok");

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(accomplissementDe(eval))
            .containsEntry("objectif", "NON_ATTEINT")
            .containsEntry("objectif_resume",
                AiEvaluationService.RESUME_OBJECTIF_PRODUCTION_INVALIDE);
        assertThat(eval.getNoteSur20()).isEqualByComparingTo(BigDecimal.ZERO);
        verify(llmClient, never()).evaluate(anyString(), anyString());
    }

    // --------------------------------------------- plafonds de restitution

    /** Le contrat v5 REFUSE une sortie trop bavarde, et le retry unique la corrige. */
    @Test
    @SuppressWarnings("unchecked")
    void une_sortie_trop_bavarde_est_refusee_puis_rejouee() {
        Map<String, Object> f = feedback(7, 7, 7, 7);
        f.put("points_forts", new ArrayList<>(List.of(
            "Message clair", "Registre adapté", "Bonne ouverture", "Invitation explicite")));
        f.put("exemples_corriges", new ArrayList<>(List.of(
            exemple("un"), exemple("deux"), exemple("trois"), exemple("quatre"))));
        when(llmClient.evaluate(anyString(), anyString()))
            .thenReturn(new EvaluationLlmClient.Outcome(f, 100, 20, 1))
            .thenReturn(new EvaluationLlmClient.Outcome(conforme(f), 110, 30, 2));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat((List<Object>) eval.getFeedbackJson().get("points_forts")).hasSize(2);
        assertThat((List<Object>) eval.getFeedbackJson().get("exemples_corriges")).hasSize(3);
        verify(llmClient, times(2)).evaluate(anyString(), anyString());
    }

    /**
     * LA garantie : les plafonds de restitution sont tenus par le SERVEUR, pas
     * seulement par le contrat. Meme sur un schema tolerant — donc sans aucun
     * retry — une sortie trop bavarde ressort coupee, exactement comme les deux
     * priorites (le prompt et le tool-schema demandent la regle, ils ne la
     * tiennent pas : 83 evaluations sur 109 depassaient 2 priorites en base).
     */
    @Test
    @SuppressWarnings("unchecked")
    void les_plafonds_de_restitution_sont_tenus_serveur_sans_retry() {
        when(llmClient.getPromptVersion()).thenReturn("v3"); // contrat non strict
        Map<String, Object> f = feedback(7, 7, 7, 7);
        f.put("points_forts", new ArrayList<>(List.of("un", "deux", "trois")));
        f.put("exemples_corriges", new ArrayList<>(List.of(
            exemple("un"), exemple("deux"), exemple("trois"), exemple("quatre"))));
        stubLlm(f);
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat((List<Object>) eval.getFeedbackJson().get("points_forts"))
            .containsExactly("un", "deux");
        assertThat((List<Object>) eval.getFeedbackJson().get("exemples_corriges")).hasSize(3);
        verify(llmClient, times(1)).evaluate(anyString(), anyString());
    }

    private static Map<String, Object> exemple(String marqueur) {
        return Map.of(
            "original", "il est lumineux " + marqueur,
            "corrige", "il est lumineux et calme " + marqueur,
            "explication", "La coordination enrichit la description.",
            "gain", "Deux qualités reliées, marqueur attendu au palier suivant.");
    }

    /** Copie conforme au contrat v5 (plafonds respectes) d'un feedback trop bavard. */
    private static Map<String, Object> conforme(Map<String, Object> f) {
        Map<String, Object> out = new LinkedHashMap<>(f);
        out.put("points_forts", new ArrayList<>(List.of("Message clair", "Registre adapté")));
        out.put("exemples_corriges",
            new ArrayList<>(List.of(exemple("un"), exemple("deux"), exemple("trois"))));
        return out;
    }

    // ------------------------------------------------- version amelioree

    @Test
    void la_version_amelioree_est_rendue_a_l_ecrit() {
        stubLlm(feedback(7, 7, 7, 7));
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        assertThat(service.evaluate(sub.getId()).getFeedbackJson())
            .containsEntry("version_amelioree", VERSION_AMELIOREE);
    }

    /** A l'oral, on ne rend jamais un dialogue modele : le serveur le retire. */
    @Test
    void la_version_amelioree_est_retiree_a_l_oral() {
        Map<String, Object> f = feedback(7, 7, 7, 7);
        f.put("version_amelioree", "Bonjour madame, je souhaiterais des renseignements.");
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", 7, "je voudrais des renseignements"),
            score("interagir", 7, "bonjour madame"),
            score("lexique", 7, "des renseignements"),
            score("morphosyntaxe", 7, "je voudrais des renseignements"))));
        stubLlm(f);
        ProductionSubmission sub = submissionOrale(task(EpreuveType.TCF_EO, 2), DIALOGUE_EO);

        assertThat(service.evaluate(sub.getId()).getFeedbackJson())
            .doesNotContainKey("version_amelioree");
    }

    // ------------------------------------------------------------- confiance

    /**
     * LE changement : recopier l'énoncé ne rend pas la correction moins sûre.
     * On écarte les mots recopiés — c'est écrit au candidat — et ce qui reste
     * s'observe parfaitement. Convertir ce soupçon d'authenticité en
     * incertitude de correction est exactement ce que la grille v8 interdit au
     * correcteur ; le serveur ne se l'autorise plus non plus.
     */
    @Test
    void un_recopiage_de_consigne_ne_plafonne_plus_la_confiance() {
        Map<String, Object> f = feedback(7, 7, 7, 7);
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", 7, "mon logement est clair"),
            score("interagir", 7, "Salut Paul"),
            score("lexique", 7, "clair et calme"),
            score("morphosyntaxe", 7, "viens me voir"))));
        stubLlm(f);
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_RECOPIAGE);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getFeedbackJson().get("confiance")).isEqualTo("HAUTE");
        // L'avertissement destiné au candidat, lui, est toujours rendu.
        assertThat(avertissements(eval)).anyMatch(a -> a.contains("recopie l'énoncé"));
    }

    /** Une langue à moitié étrangère reste un obstacle RÉEL à l'observation. */
    @Test
    @SuppressWarnings("unchecked")
    void une_langue_douteuse_plafonne_toujours_la_confiance() {
        Map<String, Object> f = feedback(7, 7, 7, 7);
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", 7, "je suis très content"),
            score("interagir", 7, "Hello Paul"),
            score("lexique", 7, "big kitchen"),
            score("morphosyntaxe", 7, "de la nouvelle"))));
        stubLlm(f);
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_LANGUE_DOUTEUSE);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getFeedbackJson().get("confiance")).isEqualTo("MOYENNE");
        assertThat((List<String>) eval.getFeedbackJson().get("confiance_raisons"))
            .anyMatch(r -> r.contains("vérifications automatiques"));
    }

    /** Les deux doutes ensemble : l'obstacle à l'observation l'emporte. */
    @Test
    void les_deux_doutes_cumules_plafonnent_la_confiance() {
        Map<String, Object> f = feedback(7, 7, 7, 7);
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", 7, "Come visit soon"),
            score("interagir", 7, "Hello Paul"),
            score("lexique", 7, "big kitchen"),
            score("morphosyntaxe", 7, "near the station"))));
        stubLlm(f);
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1),
            TEXTE_RECOPIAGE_ET_LANGUE_DOUTEUSE);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getFeedbackJson().get("confiance")).isEqualTo("MOYENNE");
        assertThat(avertissements(eval)).anyMatch(a -> a.contains("recopie l'énoncé"));
    }

    /** La transcription au fil de l'eau reste, elle aussi, un plafond serveur. */
    @Test
    @SuppressWarnings("unchecked")
    void un_dialogue_temps_reel_plafonne_toujours_la_confiance() {
        Map<String, Object> f = feedback(7, 7, 7, 7);
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", 7, "je voudrais des renseignements"),
            score("interagir", 7, "bonjour madame"),
            score("lexique", 7, "des renseignements"),
            score("morphosyntaxe", 7, "nous habitons ici depuis un mois"))));
        stubLlm(f);
        ProductionSubmission sub = submissionOrale(task(EpreuveType.TCF_EO, 2), DIALOGUE_EO,
            ProductionSubmissionSource.REALTIME);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(eval.getFeedbackJson().get("confiance")).isEqualTo("MOYENNE");
        assertThat((List<String>) eval.getFeedbackJson().get("confiance_raisons"))
            .anyMatch(r -> r.contains("en direct"));
    }

    // ------------------------------------------------------ non-regression

    /**
     * v8 ne touche a AUCUN bareme : le meme jeu de notes donne exactement la
     * meme note et le meme niveau que sous v7, garde-fou de couplage compris.
     */
    @Test
    void la_notation_est_identique_a_celle_de_v7() {
        Map<String, Object> f = feedback(12, 11, 1, 1);
        stubLlm(f);
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);
        AiEvaluation v8 = service.evaluate(sub.getId());

        // Meme production, meme sortie brute, sur la paire precedente.
        props.setRubricsVersion("v7");
        buildService();
        when(llmClient.getPromptVersion()).thenReturn("v4");
        Map<String, Object> sansRestitution = feedback(12, 11, 1, 1);
        sansRestitution.remove("version_amelioree");
        sansRestitution.put("accomplissement", Map.of(
            "points_traites", List.of(point("Nouvelle annoncée", true)),
            "points_oublies", List.of()));
        stubLlm(sansRestitution);
        ProductionSubmission subV7 = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);
        AiEvaluation v7 = service.evaluate(subV7.getId());

        assertThat(v8.getNoteSur20()).isEqualByComparingTo(v7.getNoteSur20());
        assertThat(v8.getNiveauCecrl()).isEqualTo(v7.getNiveauCecrl());
        assertThat(v8.getNoteSur20()).isEqualByComparingTo("1.5");
        assertThat(v8.getNiveauCecrl()).isEqualTo(NiveauCecrl.A1);
    }

    /**
     * Les ~100 evaluations deja en base n'ont pas de verdict : rien n'est
     * migre, rien ne casse. Une sortie sans {@code objectif} passe le pipeline,
     * le champ reste simplement absent et les fronts n'affichent pas le bloc.
     */
    @Test
    void une_sortie_legacy_sans_verdict_reste_lisible() {
        when(llmClient.getPromptVersion()).thenReturn("v3"); // contrat non strict
        Map<String, Object> f = feedback(7, 7, 7, 7);
        f.put("accomplissement", Map.of(
            "points_traites", List.of(point("Nouvelle annoncée", true)),
            "points_oublies", List.of(point("Invitation absente", true))));
        f.remove("version_amelioree");
        stubLlm(f);
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        AiEvaluation eval = service.evaluate(sub.getId());

        assertThat(accomplissementDe(eval))
            .doesNotContainKey("objectif")
            .doesNotContainKey("objectif_resume")
            .containsKeys("points_traites", "points_oublies");
        assertThat(eval.getNoteSur20()).isEqualByComparingTo("7.0");
    }

    /** Un bloc accomplissement totalement absent reste normalise, sans verdict invente. */
    @Test
    void un_accomplissement_absent_ne_fabrique_pas_de_verdict() {
        when(llmClient.getPromptVersion()).thenReturn("v3");
        Map<String, Object> f = feedback(7, 7, 7, 7);
        f.remove("accomplissement");
        f.remove("version_amelioree");
        stubLlm(f);
        ProductionSubmission sub = submission(task(EpreuveType.TCF_EE, 1), TEXTE_EE);

        assertThat(accomplissementDe(service.evaluate(sub.getId())))
            .doesNotContainKey("objectif")
            .containsEntry("points_traites", List.of())
            .containsEntry("points_oublies", List.of());
    }
}

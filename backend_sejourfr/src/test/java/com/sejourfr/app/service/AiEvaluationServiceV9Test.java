package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

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
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Rubriques v9 / tool-schema v5, et le FILET SERVEUR qui les accompagne. Ce que
 * verrouille cette classe :
 * <ul>
 *   <li>v9 se charge sur le contrat v5 — aucun champ de sortie n'a change ;</li>
 *   <li>la NOTATION est celle de v8 au point pres : le meme jeu de scores donne
 *       la meme note et le meme niveau ;</li>
 *   <li>a l'ORAL, un reproche qui ne tient que par un mot de la transcription est
 *       purge du rapport, et le candidat en est averti ;</li>
 *   <li>a l'ECRIT, rien n'est purge : l'orthographe compte ;</li>
 *   <li>un {@code exemples_corriges} fonde sur une notion orale interdite ne
 *       detruit plus l'evaluation — l'entree est retiree, sans reessai.</li>
 * </ul>
 */
class AiEvaluationServiceV9Test {

    private static final String TEXTE_EE =
        "Salut Paul ! J'ai une bonne nouvelle : j'ai enfin déménagé la semaine dernière. "
            + "Mon logement se trouve près de la gare, il est lumineux et il y a un petit "
            + "jardin derrière. Viens passer le week-end quand tu veux, il y a de la place.";

    /** Transcription portant les artefacts reels de l'incident du 2026-08-06. */
    private static final String DIALOGUE_EO =
        "Examinateur : Bonjour, pourquoi souhaitez-vous déménager ?\n"
            + "Candidat : je veux aller habiter à l'île parce que le loyer est moins cher "
            + "pour ma famille\n"
            + "Examinateur : Et les transports, cela vous inquiète ?\n"
            + "Candidat : non il y a le tramway et je prends le pont par travers la ville "
            + "donc je mets vingt minutes";

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
        props.setRubricsVersion("v9");
        buildService();
    }

    private void buildService() {
        ProductionRubricsProvider rubrics = new ProductionRubricsProvider(props, new ObjectMapper());
        rubrics.load();
        service = new AiEvaluationService(submissionManager, transcriptionManager, aiEvaluationManager,
            llmClient, new EvaluationPromptBuilder(new ObjectMapper(), rubrics), rubrics,
            new ProductionValidityService(props),
            new ProductionSecondePasseService(props, mock(EvaluationLlmClient.class), rubrics),
            new ProductionFluiditeService(props), new EvaluationRefusalMetrics(), new EvaluationPurgeMetrics(), props);
    }

    // ------------------------------------------------------- non-regression

    /** v9 ne touche a aucun bareme : meme sortie brute, meme note, meme niveau. */
    @Test
    void la_notation_est_identique_a_celle_de_v8() {
        stubLlm(feedbackEcrit(12, 11, 1, 1));
        AiEvaluation v9 = service.evaluate(submissionEcrite().getId());

        props.setRubricsVersion("v8");
        buildService();
        stubLlm(feedbackEcrit(12, 11, 1, 1));
        AiEvaluation v8 = service.evaluate(submissionEcrite().getId());

        assertThat(v9.getNoteSur20()).isEqualByComparingTo(v8.getNoteSur20());
        assertThat(v9.getNiveauCecrl()).isEqualTo(v8.getNiveauCecrl());
        assertThat(v9.getNoteSur20()).isEqualByComparingTo("1.5");
        assertThat(v9.getNiveauCecrl()).isEqualTo(NiveauCecrl.A1);
    }

    // --------------------------------------------------- filet oral (volet 1)

    @Test
    @SuppressWarnings("unchecked")
    void un_reproche_bati_sur_un_mot_de_la_transcription_est_purge_a_l_oral() {
        Map<String, Object> f = feedbackOral();
        score(f, "lexique").put("commentaire",
            "Le lexique du quotidien est employé correctement. "
                + "En revanche « l'île » est impropre pour désigner une ville.");
        f.put("suggestions", new ArrayList<>(List.of(
            "Révisez les prépositions : on ne dit pas « par travers ».")));
        stubLlm(f);

        AiEvaluation eval = service.evaluate(submissionOrale().getId());
        Map<String, Object> feedback = eval.getFeedbackJson();

        assertThat(score(feedback, "lexique").get("commentaire"))
            .isEqualTo("Le lexique du quotidien est employé correctement.");
        assertThat((List<Object>) feedback.get("suggestions")).isEmpty();
        assertThat((List<String>) feedback.get("avertissements"))
            .contains(EvaluationOralArtifactFilter.AVERTISSEMENT_ARTEFACT);
        // La restitution seule est touchee : la note ne bouge pas.
        assertThat(eval.getNoteSur20()).isEqualByComparingTo("7.0");
        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.B1);
    }

    /** A l'ECRIT, l'orthographe compte : rien n'est purge, aucun avertissement. */
    @Test
    @SuppressWarnings("unchecked")
    void le_meme_reproche_est_conserve_a_l_ecrit() {
        Map<String, Object> f = feedbackEcrit(7, 7, 7, 7);
        String commentaire = "Le mot « jardin » est mal orthographié.";
        score(f, "lexique").put("commentaire", commentaire);
        stubLlm(f);

        Map<String, Object> feedback = service.evaluate(submissionEcrite().getId()).getFeedbackJson();

        assertThat(score(feedback, "lexique").get("commentaire")).isEqualTo(commentaire);
        assertThat((List<String>) feedback.getOrDefault("avertissements", List.of()))
            .doesNotContain(EvaluationOralArtifactFilter.AVERTISSEMENT_ARTEFACT);
    }

    // ------------------------------------------------- filet oral (volet LANGUE)

    /**
     * Bout en bout : le reproche de langue etrangere disparait de la restitution
     * ORALE, l'avertissement DEDIE est pose, et la note ne bouge pas d'un iota —
     * ce filet n'agit que sur du texte.
     */
    @Test
    @SuppressWarnings("unchecked")
    void un_reproche_de_langue_etrangere_est_purge_a_l_oral() {
        Map<String, Object> f = feedbackOral();
        score(f, "communiquer").put("commentaire",
            "Le propos suit un fil clair. "
                + "Plusieurs passages sont inaudibles ou en langue étrangère, ce qui bloque "
                + "la communication.");
        f.put("suggestions", new ArrayList<>(List.of(
            "Éviter de passer à une autre langue pendant l'épreuve : rester en français.")));
        stubLlm(f);

        AiEvaluation eval = service.evaluate(submissionOraleLongue().getId());
        Map<String, Object> feedback = eval.getFeedbackJson();

        assertThat(score(feedback, "communiquer").get("commentaire"))
            .isEqualTo("Le propos suit un fil clair.");
        assertThat((List<Object>) feedback.get("suggestions")).isEmpty();
        assertThat((List<String>) feedback.get("avertissements"))
            .contains(EvaluationOralArtifactFilter.AVERTISSEMENT_LANGUE);
        assertThat(eval.getNoteSur20()).isEqualByComparingTo("7.0");
        assertThat(eval.getNiveauCecrl()).isEqualTo(NiveauCecrl.B1);
    }

    /**
     * ASYMETRIE EE / EO — a l'ECRIT, le candidat a tape chaque mot : une langue
     * etrangere est une VRAIE non-realisation et doit remonter. Rien n'est purge,
     * aucun avertissement.
     */
    @Test
    @SuppressWarnings("unchecked")
    void le_meme_reproche_de_langue_est_conserve_a_l_ecrit() {
        Map<String, Object> f = feedbackEcrit(7, 7, 7, 7);
        String commentaire = "Plusieurs phrases sont rédigées en anglais : la consigne "
            + "demandait un message en français.";
        score(f, "communiquer").put("commentaire", commentaire);
        stubLlm(f);

        Map<String, Object> feedback = service.evaluate(submissionEcrite().getId()).getFeedbackJson();

        assertThat(score(feedback, "communiquer").get("commentaire")).isEqualTo(commentaire);
        assertThat((List<String>) feedback.getOrDefault("avertissements", List.of()))
            .doesNotContain(EvaluationOralArtifactFilter.AVERTISSEMENT_LANGUE);
    }

    // ------------------------------------------- exemples corriges (volet 3)

    /**
     * L'INCIDENT : deux {@code explication} fondees sur une notion orale
     * interdite faisaient echouer toute l'evaluation apres le reessai, et la
     * tache etait perdue. Desormais l'entree est retiree, sans reessai et sans
     * perte.
     */
    @Test
    @SuppressWarnings("unchecked")
    void un_exemple_corrige_fonde_sur_une_notion_orale_interdite_ne_perd_plus_la_tache() {
        Map<String, Object> f = feedbackOral();
        f.put("exemples_corriges", new ArrayList<>(List.of(
            Map.of("original", "je veux aller habiter",
                "corrige", "je voudrais aller habiter",
                "explication", "Cette version évite les répétitions du début.",
                "gain", "un propos plus direct"),
            Map.of("original", "le loyer est moins cher",
                "corrige", "le loyer est moins cher qu'ici",
                "explication", "La comparaison précise le propos.",
                "gain", "une comparaison construite, marqueur attendu au B1"))));
        stubLlm(f);

        AiEvaluation eval = service.evaluate(submissionOrale().getId());

        assertThat((List<Object>) eval.getFeedbackJson().get("exemples_corriges")).hasSize(1);
        assertThat(eval.getNoteSur20()).isEqualByComparingTo("7.0");
        verify(llmClient, times(1)).evaluate(anyString(), anyString());
    }

    // -------------------------------------------------------------- fixtures

    private void stubLlm(Map<String, Object> feedback) {
        when(llmClient.evaluate(anyString(), anyString()))
            .thenReturn(new EvaluationLlmClient.Outcome(feedback, 100, 200, 3));
    }

    private ProductionTask task(EpreuveType epreuve, int tache) {
        ProductionTask t = new ProductionTask();
        t.setId(UUID.randomUUID());
        t.setEpreuve(epreuve);
        t.setTacheNumero((short) tache);
        t.setNiveauCible("B1");
        t.setConsigne("Vous venez d'emménager. Écrivez à un ami pour annoncer la nouvelle, "
            + "décrire votre logement et l'inviter.");
        return t;
    }

    private ProductionSubmission submissionEcrite() {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(UUID.randomUUID());
        s.setProductionTask(task(EpreuveType.TCF_EE, 1));
        s.setStatut(SubmissionStatut.SUBMITTED);
        s.setTexteSoumis(TEXTE_EE);
        when(submissionManager.findById(s.getId())).thenReturn(Optional.of(s));
        return s;
    }

    private ProductionSubmission submissionOrale() {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(UUID.randomUUID());
        s.setProductionTask(task(EpreuveType.TCF_EO, 2));
        s.setStatut(SubmissionStatut.SUBMITTED);
        s.setMediaDurationSec(210);
        when(submissionManager.findById(s.getId())).thenReturn(Optional.of(s));
        when(transcriptionManager.findLatestTexteBySubmissionId(s.getId()))
            .thenReturn(Optional.of(DIALOGUE_EO));
        return s;
    }

    /**
     * Transcription francaise ASSEZ LONGUE pour que le volet langue soit
     * mesurable (>= 40 mots exploitables), portant l'artefact neerlandais reel.
     */
    private ProductionSubmission submissionOraleLongue() {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(UUID.randomUUID());
        s.setProductionTask(task(EpreuveType.TCF_EO, 2));
        s.setStatut(SubmissionStatut.SUBMITTED);
        s.setMediaDurationSec(210);
        when(submissionManager.findById(s.getId())).thenReturn(Optional.of(s));
        when(transcriptionManager.findLatestTexteBySubmissionId(s.getId()))
            .thenReturn(Optional.of(
                "Examinateur : Bonjour, pourquoi souhaitez-vous déménager ?\n"
                    + "Candidat : je veux aller habiter dans une autre ville parce que le loyer "
                    + "est moins cher pour ma famille et il y a un grand parc juste à côté de "
                    + "chez nous\n"
                    + "Candidat : Ja. Dus kan nog sorteer de weekenden\n"
                    + "Examinateur : Et les transports, cela vous inquiète ?\n"
                    + "Candidat : non il y a le tramway et je mets vingt minutes pour aller au "
                    + "travail chaque matin avec mes collègues"));
        return s;
    }

    private static Map<String, Object> feedbackEcrit(Number communiquer, Number interagir,
                                                     Number lexique, Number morphosyntaxe) {
        Map<String, Object> f = base();
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", communiquer, "j'ai enfin déménagé"),
            score("interagir", interagir, "Salut Paul"),
            score("lexique", lexique, "il est lumineux"),
            score("morphosyntaxe", morphosyntaxe, "Viens passer le week-end"))));
        f.put("version_amelioree", "Salut Paul ! J'ai déménagé la semaine dernière parce que "
            + "mon ancien logement était trop petit. Viens quand tu veux.");
        return f;
    }

    private static Map<String, Object> feedbackOral() {
        Map<String, Object> f = base();
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", 7, "le loyer est moins cher"),
            score("interagir", 7, "il y a le tramway"),
            score("lexique", 7, "pour ma famille"),
            score("morphosyntaxe", 7, "je mets vingt minutes"))));
        return f;
    }

    private static Map<String, Object> base() {
        Map<String, Object> f = new LinkedHashMap<>();
        f.put("note_globale", 7);
        f.put("niveau_cecrl", "B1");
        f.put("justification_niveau", "Emploi du passé composé et lexique du logement.");
        f.put("confiance", "HAUTE");
        f.put("confiance_raisons", new ArrayList<>(List.of("production complète et lisible")));
        Map<String, Object> acc = new LinkedHashMap<>();
        acc.put("objectif", "ATTEINT");
        acc.put("objectif_resume", "Tu expliques ton projet et tu réponds aux questions.");
        acc.put("points_traites", new ArrayList<>(List.of(
            Map.of("libelle", "Projet expliqué", "obligatoire", true))));
        acc.put("points_oublies", new ArrayList<>());
        f.put("accomplissement", acc);
        f.put("points_forts", new ArrayList<>(List.of("Message clair")));
        f.put("points_a_ameliorer", new ArrayList<>(List.of(new LinkedHashMap<>(Map.of(
            "constat", "Vos idées sont juxtaposées.",
            "comment", "Reliez-les avec « parce que ».")))));
        f.put("suggestions", new ArrayList<>());
        f.put("exemples_corriges", new ArrayList<>());
        return f;
    }

    private static Map<String, Object> score(String code, Number note, String preuve) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", code);
        m.put("note_sur_20", note);
        m.put("commentaire", "Commentaire neutre sur " + code + ".");
        m.put("preuve", preuve);
        return m;
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> score(Map<String, Object> feedback, String code) {
        for (Object raw : (List<Object>) feedback.get("scores_criteres")) {
            Map<String, Object> s = (Map<String, Object>) raw;
            if (code.equals(s.get("code"))) return s;
        }
        throw new IllegalArgumentException("critere absent : " + code);
    }
}

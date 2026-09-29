package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.AiEvaluationException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import tools.jackson.databind.ObjectMapper;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * RUBRIQUES v12 / TOOL-SCHEMA v6 : la preuve se DESIGNE par un numero de
 * segment, elle ne se recopie plus. Ce que verrouille cette classe :
 * <ul>
 *   <li>le correcteur recoit une production NUMEROTEE et ne renvoie qu'un
 *       entier ;</li>
 *   <li>le serveur resout ce numero en TEXTE avant persistance : le contrat
 *       servi aux trois fronts ({@code feedback_json.preuve}, une chaine) ne
 *       change pas d'un caractere — aucun miroir de DTO a propager ;</li>
 *   <li>la NOTATION est celle de v9 au point pres : memes scores, meme note,
 *       meme niveau ;</li>
 *   <li>un numero inexistant est la SEULE erreur de preuve possible, et elle se
 *       repare par le reessai unique ;</li>
 *   <li>a l'oral, seuls les tours du candidat portent un numero : le correcteur
 *       ne PEUT PAS designer l'examinateur.</li>
 * </ul>
 */
class AiEvaluationServiceV12Test {

    private static final String TEXTE_EE =
        "Salut Paul ! J'ai une bonne nouvelle : j'ai enfin déménagé la semaine dernière. "
            + "Mon logement se trouve près de la gare, il est lumineux et il y a un petit "
            + "jardin derrière. Viens passer le week-end quand tu veux, il y a de la place.";

    private static final String DIALOGUE_EO =
        "Examinateur : Bonjour, pourquoi souhaitez-vous déménager ?\n"
            + "Candidat : je veux aller habiter plus près de mon travail parce que le loyer "
            + "est moins cher pour ma famille\n"
            + "Examinateur : Et les transports, cela vous inquiète ?\n"
            + "Candidat : non il y a le tramway et je mets vingt minutes";

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
        when(llmClient.getPromptVersion()).thenReturn("v6");
        when(aiEvaluationManager.save(any())).thenAnswer(inv -> inv.getArgument(0));

        props = new ProductionEvaluationProperties();
        props.setRubricsVersion("v12");
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

    // ------------------------------------------------------- le materiau envoye

    @Test
    void la_production_part_decoupee_en_segments_numerotes() {
        stubLlm(feedbackEcrit(7, 7, 7, 7));
        service.evaluate(submissionEcrite().getId());

        assertThat(userPromptEnvoye())
            .contains("PRODUCTION DU CANDIDAT, DÉCOUPÉE EN SEGMENTS NUMÉROTÉS")
            .contains("[1] Salut Paul !")
            .contains("SEGMENTS DISPONIBLES POUR `preuve_segment` : 1 à 4.")
            .as("plus aucune consigne de recopie litterale")
            .doesNotContain("recopiee EXACTEMENT telle qu'elle apparait");
    }

    @Test
    void a_l_oral_l_examinateur_ne_porte_aucun_numero() {
        stubLlm(feedbackOral(7, 7, 7, 7));
        service.evaluate(submissionOrale().getId());

        String prompt = userPromptEnvoye();
        assertThat(prompt)
            .contains("[1] Candidat :")
            .contains("[2] Candidat :")
            .contains("Examinateur : Et les transports, cela vous inquiète ?")
            .doesNotContain("] Examinateur");
    }

    // ------------------------------------------ le contrat servi aux 3 fronts

    /**
     * LE POINT CAPITAL DE LA BASCULE : ce que lisent le web, le mobile et
     * l'admin est INCHANGE — un champ {@code preuve} textuel, portant un extrait
     * litteral de la production. {@code preuve_segment} ne sort jamais du
     * serveur.
     */
    @Test
    @SuppressWarnings("unchecked")
    void le_numero_est_resolu_en_texte_avant_persistance() {
        stubLlm(feedbackEcrit(7, 7, 7, 7));

        Map<String, Object> feedback = service.evaluate(submissionEcrite().getId()).getFeedbackJson();

        for (Object raw : (List<Object>) feedback.get("scores_criteres")) {
            Map<String, Object> score = (Map<String, Object>) raw;
            assertThat(score).containsKey("preuve").doesNotContainKey("preuve_segment");
            assertThat(score.get("preuve")).asString().isNotBlank();
            assertThat(TEXTE_EE).contains(score.get("preuve").toString());
        }
        assertThat(score(feedback, "communiquer").get("preuve")).isEqualTo("Salut Paul !");
        assertThat(score(feedback, "lexique").get("preuve"))
            .isEqualTo("Mon logement se trouve près de la gare, il est lumineux et il y a un "
                + "petit jardin derrière.");
    }

    @Test
    void a_l_oral_la_preuve_resolue_est_le_tour_du_candidat_sans_son_marqueur() {
        stubLlm(feedbackOral(7, 7, 7, 7));

        Map<String, Object> feedback = service.evaluate(submissionOrale().getId()).getFeedbackJson();

        assertThat(score(feedback, "communiquer").get("preuve"))
            .isEqualTo("je veux aller habiter plus près de mon travail parce que le loyer "
                + "est moins cher pour ma famille");
        assertThat(score(feedback, "morphosyntaxe").get("preuve"))
            .isEqualTo("non il y a le tramway et je mets vingt minutes");
    }

    // ----------------------------------------------------------- non-regression

    /** v12 ne touche a aucun bareme : memes scores, meme note, meme niveau qu'en v9. */
    @Test
    void la_notation_est_identique_a_celle_de_v9() {
        stubLlm(feedbackEcrit(12, 11, 1, 1));
        AiEvaluation v12 = service.evaluate(submissionEcrite().getId());

        props.setRubricsVersion("v9");
        when(llmClient.getPromptVersion()).thenReturn("v5");
        buildService();
        stubLlm(feedbackEcritV9(12, 11, 1, 1));
        AiEvaluation v9 = service.evaluate(submissionEcrite().getId());

        assertThat(v12.getNoteSur20()).isEqualByComparingTo(v9.getNoteSur20());
        assertThat(v12.getNiveauCecrl()).isEqualTo(v9.getNiveauCecrl());
        assertThat(v12.getNoteSur20()).isEqualByComparingTo("1.5");
        assertThat(v12.getNiveauCecrl()).isEqualTo(NiveauCecrl.A1);
    }

    // -------------------------------------------------- la seule erreur possible

    /**
     * Un numero hors bornes est desormais la SEULE facon de rater une preuve —
     * et le reessai unique la repare, parce qu'il n'y a rien a recopier.
     */
    @Test
    void un_numero_hors_bornes_est_repare_par_le_reessai() {
        Map<String, Object> faux = feedbackEcrit(7, 7, 7, 7);
        score(faux, "lexique").put("preuve_segment", 99);
        when(llmClient.evaluate(anyString(), anyString()))
            .thenReturn(new EvaluationLlmClient.Outcome(faux, 100, 200, 3))
            .thenReturn(new EvaluationLlmClient.Outcome(feedbackEcrit(7, 7, 7, 7), 90, 180, 2));

        Map<String, Object> feedback = service.evaluate(submissionEcrite().getId()).getFeedbackJson();

        verify(llmClient, times(2)).evaluate(anyString(), anyString());
        assertThat(score(feedback, "lexique").get("preuve")).asString().isNotBlank();
    }

    /** Le message de reessai parle de NUMERO, plus jamais de recopie de citation. */
    @Test
    void le_reessai_rappelle_la_regle_du_numero() {
        Map<String, Object> faux = feedbackEcrit(7, 7, 7, 7);
        score(faux, "lexique").put("preuve_segment", 99);
        when(llmClient.evaluate(anyString(), anyString()))
            .thenReturn(new EvaluationLlmClient.Outcome(faux, 100, 200, 3))
            .thenReturn(new EvaluationLlmClient.Outcome(feedbackEcrit(7, 7, 7, 7), 90, 180, 2));

        service.evaluate(submissionEcrite().getId());

        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(llmClient, times(2)).evaluate(anyString(), user.capture());
        assertThat(user.getAllValues().get(1))
            .contains("NUMERO DE SEGMENT INVALIDE")
            .contains("n'est PAS une citation")
            .doesNotContain("RE-CITE PLUS COURT");
    }

    /**
     * Un numero toujours faux apres le reessai degrade la sortie comme le faisait
     * une citation introuvable : la preuve est retiree, la confiance plafonnee,
     * et le candidat est averti — jamais une correction perdue.
     */
    @Test
    @SuppressWarnings("unchecked")
    void un_numero_toujours_faux_apres_le_reessai_degrade_au_lieu_de_perdre_la_correction() {
        Map<String, Object> faux = feedbackEcrit(7, 7, 7, 7);
        score(faux, "lexique").put("preuve_segment", 42);
        stubLlm(faux);

        Map<String, Object> feedback = service.evaluate(submissionEcrite().getId()).getFeedbackJson();

        assertThat(score(feedback, "lexique")).doesNotContainKey("preuve")
            .doesNotContainKey("preuve_segment");
        assertThat(feedback.get("confiance")).isEqualTo("MOYENNE");
        assertThat((List<String>) feedback.get("avertissements"))
            .contains(AiEvaluationService.AVERTISSEMENT_PREUVE_RETIREE);
    }

    /** Un {@code preuve_segment} absent ou non entier reste BLOQUANT, comme une preuve vide. */
    @Test
    void une_preuve_non_entiere_reste_bloquante() {
        Map<String, Object> faux = feedbackEcrit(7, 7, 7, 7);
        score(faux, "lexique").put("preuve_segment", "la deuxième phrase");
        stubLlm(faux);

        UUID id = submissionEcrite().getId();
        assertThatThrownBy(() -> service.evaluate(id))
            .isInstanceOf(AiEvaluationException.class)
            .hasMessageContaining("numero de segment entier");
    }

    // -------------------------------------------------------------- fixtures

    private String userPromptEnvoye() {
        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(llmClient).evaluate(anyString(), user.capture());
        return user.getValue();
    }

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

    // ------------------------------------------- rubriques v14 / tool-schema v8

    /**
     * SOUS v14/v8 LE CHAMP NE PART PLUS AU CORRECTEUR ET NE REVIENT PLUS. Le
     * prompt n'en parle plus (aucune consigne a suivre), et si une sortie en
     * portait une malgre tout, le serveur la retire — a l'ECRIT comme a l'oral.
     * Tout le reste de la correction est inchange : meme note, meme niveau,
     * meme preuve resolue en texte.
     */
    @Test
    void v14_ne_demande_plus_et_ne_persiste_plus_la_version_amelioree_a_l_ecrit() {
        props.setRubricsVersion("v14");
        when(llmClient.getPromptVersion()).thenReturn("v8");
        buildService();

        stubLlm(feedbackEcrit(7, 7, 7, 7));
        AiEvaluation evaluation = service.evaluate(submissionEcrite().getId());

        assertThat(userPromptEnvoye())
            .as("le correcteur n'entend plus parler du champ retire")
            .doesNotContain("version_amelioree", "VERSION AMELIOREE");
        assertThat(evaluation.getFeedbackJson())
            .doesNotContainKey("version_amelioree")
            .containsEntry("niveau_cecrl", "B1");
        assertThat(evaluation.getNoteSur20()).isEqualByComparingTo("7.0");
        assertThat(score(evaluation.getFeedbackJson(), "communiquer").get("preuve"))
            .isEqualTo("Salut Paul !");
    }

    private static Map<String, Object> feedbackEcrit(Number communiquer, Number interagir,
                                                     Number lexique, Number morphosyntaxe) {
        Map<String, Object> f = base();
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", communiquer, 1),
            score("interagir", interagir, 4),
            score("lexique", lexique, 3),
            score("morphosyntaxe", morphosyntaxe, 2))));
        f.put("version_amelioree", "Salut Paul ! J'ai déménagé la semaine dernière parce que "
            + "mon ancien logement était trop petit. Viens quand tu veux.");
        return f;
    }

    /** Meme sortie, contrat v5 : la preuve y est une citation recopiee. */
    private static Map<String, Object> feedbackEcritV9(Number communiquer, Number interagir,
                                                       Number lexique, Number morphosyntaxe) {
        Map<String, Object> f = base();
        f.put("scores_criteres", new ArrayList<>(List.of(
            scoreCitation("communiquer", communiquer, "j'ai enfin déménagé"),
            scoreCitation("interagir", interagir, "Salut Paul"),
            scoreCitation("lexique", lexique, "il est lumineux"),
            scoreCitation("morphosyntaxe", morphosyntaxe, "Viens passer le week-end"))));
        f.put("version_amelioree", "Salut Paul ! J'ai déménagé la semaine dernière parce que "
            + "mon ancien logement était trop petit. Viens quand tu veux.");
        return f;
    }

    private static Map<String, Object> feedbackOral(Number communiquer, Number interagir,
                                                    Number lexique, Number morphosyntaxe) {
        Map<String, Object> f = base();
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", communiquer, 1),
            score("interagir", interagir, 1),
            score("lexique", lexique, 2),
            score("morphosyntaxe", morphosyntaxe, 2))));
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
        acc.put("objectif_resume", "Tu annonces la nouvelle, tu décris le logement et tu invites.");
        acc.put("points_traites", new ArrayList<>(List.of(
            Map.of("libelle", "Nouvelle annoncée", "obligatoire", true))));
        acc.put("points_oublies", new ArrayList<>());
        f.put("accomplissement", acc);
        f.put("points_forts", new ArrayList<>(List.of("Message clair")));
        f.put("points_a_ameliorer", new ArrayList<>(List.of(new LinkedHashMap<>(Map.of(
            "constat", "Vos idées sont juxtaposées.",
            "comment", "Reliez-les avec « parce que » au lieu de les poser côte à côte.")))));
        f.put("suggestions", new ArrayList<>());
        f.put("exemples_corriges", new ArrayList<>());
        return f;
    }

    private static Map<String, Object> score(String code, Number note, int segment) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", code);
        m.put("note_sur_20", note);
        m.put("commentaire", "Commentaire neutre sur " + code + ".");
        m.put("preuve_segment", segment);
        return m;
    }

    private static Map<String, Object> scoreCitation(String code, Number note, String preuve) {
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

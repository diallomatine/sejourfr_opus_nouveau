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
import org.mockito.ArgumentCaptor;
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
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * RUBRIQUES v15 / TOOL-SCHEMA v9 : {@code exemples_corriges} et
 * {@code suggestions} quittent le contrat. Ce que verrouille cette classe :
 * <ul>
 *   <li>le correcteur n'entend plus parler des deux champs ;</li>
 *   <li>RETRAIT DEFENSIF : une sortie qui les porterait quand meme n'echoue pas,
 *       le serveur les jette — une evaluation perdue coute plus cher que deux
 *       champs ignores ;</li>
 *   <li>ce qui RESTE est intact : note, niveau, preuve resolue en texte,
 *       {@code accomplissement} (verdict, resume, points traites/oublies) et
 *       {@code avertissements}, que le SERVEUR ecrit et qui n'a jamais ete au
 *       tool-schema ;</li>
 *   <li>le chemin « production invalide » (aucun appel LLM) ne fabrique plus les
 *       deux cles ;</li>
 *   <li>REVERSIBILITE : sous la paire precedente v14/v8, les deux champs sont
 *       de nouveau exiges et servis.</li>
 * </ul>
 */
class AiEvaluationServiceV15Test {

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
        when(llmClient.getPromptVersion()).thenReturn("v9");
        when(aiEvaluationManager.save(any())).thenAnswer(inv -> inv.getArgument(0));

        props = new ProductionEvaluationProperties();
        props.setRubricsVersion("v15");
        buildService();
    }

    private void buildService() {
        ProductionRubricsProvider rubrics = new ProductionRubricsProvider(props, new ObjectMapper());
        rubrics.load();
        service = new AiEvaluationService(submissionManager, transcriptionManager, aiEvaluationManager,
            llmClient, new EvaluationPromptBuilder(new ObjectMapper(), rubrics), rubrics,
            new ProductionValidityService(props),
            new ProductionSecondePasseService(props, mock(EvaluationLlmClient.class), rubrics),
            new ProductionFluiditeService(props), new EvaluationRefusalMetrics(),
            new EvaluationPurgeMetrics(), props);
    }

    // ------------------------------------------------ ce que recoit le modele

    @Test
    void le_correcteur_n_entend_plus_parler_des_deux_champs_retires() {
        stubLlm(feedbackEcrit(7, 7, 7, 7));
        service.evaluate(submissionEcrite().getId());

        assertThat(userPromptEnvoye())
            .doesNotContain("exemples_corriges", "suggestion", "exemple corrige", "EXEMPLES CORRIGES")
            .as("ce qui reste, lui, est toujours demande")
            .contains("preuve_segment", "points_a_ameliorer", "accomplissement");
    }

    // -------------------------------------------------- le retrait defensif

    /**
     * Le schema ferme suffit en theorie ; ce filet garantit qu'une sortie
     * recalcitrante n'en persiste pas — exactement comme pour
     * {@code version_amelioree} sous v8. Et surtout : la sortie n'est PAS
     * refusee, elle est nettoyee.
     */
    @Test
    void une_sortie_qui_les_porte_encore_est_nettoyee_jamais_refusee() {
        Map<String, Object> f = feedbackEcrit(7, 7, 7, 7);
        f.put("suggestions", new ArrayList<>(List.of("Entraînez-vous à relier deux idées.")));
        f.put("exemples_corriges", new ArrayList<>(List.of(exemple(), exemple(), exemple(), exemple())));
        stubLlm(f);

        AiEvaluation evaluation = service.evaluate(submissionEcrite().getId());

        assertThat(evaluation.getFeedbackJson())
            .doesNotContainKey("suggestions")
            .doesNotContainKey("exemples_corriges");
        verify(llmClient, times(1)).evaluate(anyString(), anyString());
        assertThat(evaluation.getNoteSur20()).isEqualByComparingTo("7.0");
        assertThat(evaluation.getNiveauCecrl()).isEqualTo(NiveauCecrl.B1);
    }

    /** Sans eux non plus, rien ne casse : c'est le cas NOMINAL sous v15. */
    @Test
    @SuppressWarnings("unchecked")
    void une_sortie_sans_les_deux_champs_traverse_le_pipeline() {
        stubLlm(feedbackEcrit(7, 7, 7, 7));

        Map<String, Object> feedback = service.evaluate(submissionEcrite().getId()).getFeedbackJson();

        assertThat(feedback)
            .doesNotContainKey("suggestions")
            .doesNotContainKey("exemples_corriges");
        // Ce qui reste sert toujours a quelque chose : le bandeau du haut, le
        // compteur « Ce qui marche », et les deux priorites.
        Map<String, Object> accomplissement = (Map<String, Object>) feedback.get("accomplissement");
        assertThat(accomplissement)
            .containsEntry("objectif", "ATTEINT")
            .containsKey("objectif_resume")
            .containsKey("points_traites");
        assertThat((List<Object>) feedback.get("points_a_ameliorer")).hasSize(1);
        assertThat((List<Object>) feedback.get("points_forts")).hasSize(1);
        assertThat(score(feedback, "communiquer").get("preuve")).isEqualTo("Salut Paul !");
    }

    /**
     * {@code avertissements} n'est PAS dans le tool-schema : c'est le serveur qui
     * l'ecrit. Il porte la limite assumee de l'oral et le signalement des purges,
     * et la bascule ne doit pas l'emporter au passage.
     */
    @Test
    @SuppressWarnings("unchecked")
    void les_avertissements_serveur_restent_produits_a_l_oral() {
        stubLlm(feedbackOral(7, 7, 7, 7));

        Map<String, Object> feedback = service.evaluate(submissionOrale().getId()).getFeedbackJson();

        assertThat((List<String>) feedback.get("avertissements"))
            .contains(AiEvaluationService.AVERTISSEMENT_TRANSCRIPTION);
        assertThat(feedback).doesNotContainKey("suggestions").doesNotContainKey("exemples_corriges");
        assertThat(score(feedback, "morphosyntaxe").get("preuve"))
            .isEqualTo("non il y a le tramway et je mets vingt minutes");
    }

    /**
     * Chemin « production inexploitable » : aucun appel LLM, et plus aucune des
     * deux cles fabriquee cote serveur. Le verdict, lui, reste explicite.
     */
    @Test
    void une_production_invalide_ne_fabrique_plus_les_deux_cles() {
        ProductionSubmission sub = new ProductionSubmission();
        sub.setId(UUID.randomUUID());
        sub.setProductionTask(task(EpreuveType.TCF_EE, 1));
        sub.setStatut(SubmissionStatut.SUBMITTED);
        sub.setTexteSoumis("ok");
        when(submissionManager.findById(sub.getId())).thenReturn(Optional.of(sub));

        AiEvaluation evaluation = service.evaluate(sub.getId());

        assertThat(evaluation.getFeedbackJson())
            .doesNotContainKey("suggestions")
            .doesNotContainKey("exemples_corriges");
        assertThat(evaluation.getNoteSur20()).isEqualByComparingTo(BigDecimal.ZERO);
    }

    // ---------------------------------------------------------- non-regression

    /** v15 ne touche a aucun bareme : memes scores, meme note, meme niveau qu'en v14. */
    @Test
    void la_notation_est_identique_a_celle_de_v14() {
        stubLlm(feedbackEcrit(12, 11, 1, 1));
        AiEvaluation v15 = service.evaluate(submissionEcrite().getId());

        props.setRubricsVersion("v14");
        when(llmClient.getPromptVersion()).thenReturn("v8");
        buildService();
        Map<String, Object> f = feedbackEcrit(12, 11, 1, 1);
        f.put("suggestions", new ArrayList<>());
        f.put("exemples_corriges", new ArrayList<>());
        stubLlm(f);
        AiEvaluation v14 = service.evaluate(submissionEcrite().getId());

        assertThat(v15.getNoteSur20()).isEqualByComparingTo(v14.getNoteSur20());
        assertThat(v15.getNiveauCecrl()).isEqualTo(v14.getNiveauCecrl());
        assertThat(v15.getNoteSur20()).isEqualByComparingTo("1.5");
        assertThat(v15.getNiveauCecrl()).isEqualTo(NiveauCecrl.A1);
    }

    /**
     * REVERSIBILITE : le retour arriere v15/v9 -> v14/v8 se fait par deux
     * variables d'environnement, et il doit rendre les deux champs au candidat.
     */
    @Test
    @SuppressWarnings("unchecked")
    void le_retour_arriere_v14_v8_ressert_les_deux_champs() {
        props.setRubricsVersion("v14");
        when(llmClient.getPromptVersion()).thenReturn("v8");
        buildService();

        Map<String, Object> f = feedbackEcrit(7, 7, 7, 7);
        f.put("suggestions", new ArrayList<>(List.of("Entraînez-vous à relier deux idées.")));
        f.put("exemples_corriges", new ArrayList<>(List.of(exemple())));
        stubLlm(f);

        Map<String, Object> feedback = service.evaluate(submissionEcrite().getId()).getFeedbackJson();

        assertThat((List<Object>) feedback.get("suggestions")).hasSize(1);
        assertThat((List<Object>) feedback.get("exemples_corriges")).hasSize(1);
        assertThat(userPromptEnvoye()).contains("exemples_corriges");
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

    private static Map<String, Object> feedbackEcrit(Number communiquer, Number interagir,
                                                     Number lexique, Number morphosyntaxe) {
        Map<String, Object> f = base();
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", communiquer, 1),
            score("interagir", interagir, 4),
            score("lexique", lexique, 3),
            score("morphosyntaxe", morphosyntaxe, 2))));
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

    /** Sortie v9 : plus de {@code suggestions}, plus d'{@code exemples_corriges}. */
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
        return f;
    }

    private static Map<String, Object> exemple() {
        return Map.of(
            "original", "il est lumineux",
            "corrige", "il est lumineux et calme",
            "explication", "La coordination enrichit la description.",
            "gain", "Deux qualités reliées.");
    }

    private static Map<String, Object> score(String code, Number note, int segment) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", code);
        m.put("note_sur_20", note);
        m.put("commentaire", "Commentaire neutre sur " + code + ".");
        m.put("preuve_segment", segment);
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

package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
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
import static org.mockito.Mockito.when;

/**
 * BRANCHEMENT du filet « marqueur A2 vendu comme levier d'un palier supérieur »
 * dans le pipeline de notation : un filet qui n'est pas appelé ne sert à rien.
 *
 * <p>Vérifie aussi les deux garanties qui permettent de le livrer sans campagne
 * de banc : <b>la note et le niveau ne bougent pas</b>, et le candidat est
 * prévenu qu'une remarque a été retirée.
 */
class AiEvaluationServicePalierMarqueurTest {

    private static final String TEXTE_EE =
        "Salut Lucia ! Ma nouvelle collègue s'appelle Fatima. Elle est très jeune, elle a "
            + "moins de 25 ans. Elle est belle et elle est agréable. J'aime bien discuter "
            + "avec elle pendant la pause. J'aime bien prendre un café avec elle.";

    private com.sejourfr.app.manager.ProductionSubmissionManager submissionManager;
    private com.sejourfr.app.manager.TranscriptionManager transcriptionManager;
    private com.sejourfr.app.manager.AiEvaluationManager aiEvaluationManager;
    private EvaluationLlmClient llmClient;
    private EvaluationPurgeMetrics purgeMetrics;
    private AiEvaluationService service;

    @BeforeEach
    void setUp() {
        submissionManager = mock(com.sejourfr.app.manager.ProductionSubmissionManager.class);
        transcriptionManager = mock(com.sejourfr.app.manager.TranscriptionManager.class);
        aiEvaluationManager = mock(com.sejourfr.app.manager.AiEvaluationManager.class);
        llmClient = mock(EvaluationLlmClient.class);
        when(llmClient.getModelName()).thenReturn("modele-test");
        when(llmClient.getPromptVersion()).thenReturn("v7");
        when(aiEvaluationManager.save(any())).thenAnswer(inv -> inv.getArgument(0));

        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        props.setRubricsVersion("v13");
        ProductionRubricsProvider rubrics = new ProductionRubricsProvider(props, new ObjectMapper());
        rubrics.load();
        purgeMetrics = new EvaluationPurgeMetrics();
        service = new AiEvaluationService(submissionManager, transcriptionManager,
            aiEvaluationManager, llmClient, new EvaluationPromptBuilder(new ObjectMapper(), rubrics),
            rubrics, new ProductionValidityService(props),
            new ProductionSecondePasseService(props, mock(EvaluationLlmClient.class), rubrics),
            new ProductionFluiditeService(props), new EvaluationRefusalMetrics(), purgeMetrics,
            props);
    }

    /**
     * LES DEUX VERBATIMS RÉELS du défaut, dans la même évaluation : ils ne
     * doivent plus parvenir au candidat.
     */
    @Test
    @SuppressWarnings("unchecked")
    void lesDeuxVerbatimsDuDefaut_neParviennentPlusAuCandidat() {
        stubLlm(feedbackAvecLeDefaut());

        Map<String, Object> feedback = service.evaluate(submission().getId()).getFeedbackJson();

        assertThat(feedback.toString())
            .doesNotContain("marqueur attendu au B1")
            .doesNotContain("Pour viser le palier B1");
        assertThat((List<Object>) feedback.get("suggestions"))
            .containsExactly("Relis ton message avant de l'envoyer.");
        assertThat((List<Object>) feedback.get("exemples_corriges")).isEmpty();
    }

    /** Le candidat est prévenu : on ne retire pas une remarque en silence. */
    @Test
    @SuppressWarnings("unchecked")
    void unAvertissementExpliqueLaRemarqueRetiree() {
        stubLlm(feedbackAvecLeDefaut());

        Map<String, Object> feedback = service.evaluate(submission().getId()).getFeedbackJson();

        assertThat((List<Object>) feedback.get("avertissements"))
            .contains(EvaluationPalierMarqueurFilter.AVERTISSEMENT_MARQUEUR_PALIER);
    }

    /**
     * LA GARANTIE QUI DISPENSE DE CAMPAGNE : le même jeu de
     * {@code scores_criteres} donne exactement la même note et le même niveau,
     * avec ou sans purge.
     */
    @Test
    void niLaNoteNiLeNiveauNeBougent() {
        stubLlm(feedbackAvecLeDefaut());
        AiEvaluation avecDefaut = service.evaluate(submission().getId());

        stubLlm(feedbackSain());
        AiEvaluation sain = service.evaluate(submission().getId());

        assertThat(avecDefaut.getNoteSur20()).isEqualByComparingTo(sain.getNoteSur20());
        assertThat(avecDefaut.getNiveauCecrl()).isEqualTo(sain.getNiveauCecrl());
    }

    /** Ce que le filet retire est COMPTÉ : un contrôle muet ne se pilote pas. */
    @Test
    void cequiEstPurgeEstCompte() {
        stubLlm(feedbackAvecLeDefaut());

        service.evaluate(submission().getId());

        assertThat(purgeMetrics.compteurs())
            // 2 phrases fautives, et 2 entrees emportees : la suggestion et
            // l'exemple corrige ne tenaient chacun que par cette phrase.
            .containsEntry("MARQUEUR_PALIER/remarques", 2L)
            .containsEntry("MARQUEUR_PALIER/entrees", 2L);
    }

    /** Une évaluation saine ne déclenche rien : pas d'avertissement, pas de compteur. */
    @Test
    void evaluationSaine_aucunePurgeAucunAvertissement() {
        stubLlm(feedbackSain());

        Map<String, Object> feedback = service.evaluate(submission().getId()).getFeedbackJson();

        assertThat(purgeMetrics.compteurs()).isEmpty();
        assertThat(String.valueOf(feedback.get("avertissements")))
            .doesNotContain(EvaluationPalierMarqueurFilter.AVERTISSEMENT_MARQUEUR_PALIER);
    }

    // ------------------------------------------------------------- fixtures

    private void stubLlm(Map<String, Object> feedback) {
        when(llmClient.evaluate(anyString(), anyString()))
            .thenReturn(new EvaluationLlmClient.Outcome(feedback, 100, 200, 3));
    }

    private ProductionSubmission submission() {
        ProductionTask t = new ProductionTask();
        t.setId(UUID.randomUUID());
        t.setEpreuve(EpreuveType.TCF_EE);
        t.setTacheNumero((short) 1);
        t.setNiveauCible("B1");
        t.setConsigne("Décrivez une nouvelle collègue à une amie.");
        t.setMotsMin(30);
        t.setMotsMax(60);

        ProductionSubmission s = new ProductionSubmission();
        s.setId(UUID.randomUUID());
        s.setProductionTask(t);
        s.setStatut(SubmissionStatut.SUBMITTED);
        s.setTexteSoumis(TEXTE_EE);
        when(submissionManager.findById(s.getId())).thenReturn(Optional.of(s));
        return s;
    }

    /** Sortie du correcteur portant les deux verbatims réellement observés. */
    private static Map<String, Object> feedbackAvecLeDefaut() {
        Map<String, Object> f = base();
        f.put("suggestions", new ArrayList<>(List.of(
            "Pour viser le palier B1, essaie d'ajouter une justification : par exemple "
                + "« j'aime discuter avec elle parce qu'elle est très agréable ».",
            "Relis ton message avant de l'envoyer.")));
        Map<String, Object> exemple = new LinkedHashMap<>();
        exemple.put("original", "Elle est belle et elle est agréable.");
        exemple.put("corrige", "Elle est jolie et vraiment facile à vivre.");
        exemple.put("explication", "Un adjectif plus précis remplace « belle ».");
        exemple.put("gain", "cette version emploie une subordonnée causale avec « parce que », "
            + "marqueur attendu au B1.");
        f.put("exemples_corriges", new ArrayList<>(List.of(exemple)));
        return f;
    }

    /** Même notation, conseils justes : aucun marqueur A2 vendu comme un palier. */
    private static Map<String, Object> feedbackSain() {
        Map<String, Object> f = base();
        f.put("suggestions", new ArrayList<>(List.of(
            "Pour viser le palier B1, emploie un connecteur qui organise ton propos : "
                + "« d'abord », « en revanche ».",
            "Relis ton message avant de l'envoyer.")));
        f.put("exemples_corriges", new ArrayList<>());
        return f;
    }

    private static Map<String, Object> base() {
        Map<String, Object> f = new LinkedHashMap<>();
        f.put("note_globale", 4);
        f.put("niveau_cecrl", "A2");
        f.put("justification_niveau", "Phrases simples coordonnées, lexique courant.");
        f.put("confiance", "HAUTE");
        f.put("confiance_raisons", new ArrayList<>(List.of("production complète et lisible")));
        Map<String, Object> acc = new LinkedHashMap<>();
        acc.put("objectif", "ATTEINT");
        acc.put("objectif_resume", "Tu décris ta collègue et tu dis ce que tu apprécies.");
        acc.put("points_traites", new ArrayList<>(List.of(
            Map.of("libelle", "Description faite", "obligatoire", true))));
        acc.put("points_oublies", new ArrayList<>());
        f.put("accomplissement", acc);
        f.put("points_forts", new ArrayList<>(List.of("Message clair")));
        f.put("points_a_ameliorer", new ArrayList<>(List.of(new LinkedHashMap<>(Map.of(
            "constat", "Les phrases sont juxtaposées.",
            "comment", "Relie tes idées au lieu de les séparer par un point.")))));
        f.put("version_amelioree", "Salut Lucia ! Ma nouvelle collègue Fatima a moins de "
            + "25 ans. Elle est jolie et facile à vivre. J'adore discuter avec elle.");
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", 5, 1),
            score("interagir", 5, 2),
            score("lexique", 4, 3),
            score("morphosyntaxe", 4, 4))));
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
}

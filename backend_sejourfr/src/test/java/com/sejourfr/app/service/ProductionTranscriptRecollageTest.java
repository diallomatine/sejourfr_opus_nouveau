package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.dto.ProductionSubmissionDto;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.Transcription;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.ProductionSubmissionSource;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.mapper.ProductionSubmissionMapper;
import com.sejourfr.app.repository.TranscriptionRepository;
import com.sejourfr.app.util.TranscriptTurnStitcher;
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
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * INVARIANT CENTRAL du recollage des tours : le texte sur lequel les preuves
 * sont citees est EXACTEMENT celui que le candidat relit.
 *
 * <p>La garantie est structurelle — correcteur, controle de preuve et DTO servi
 * aux fronts passent tous par
 * {@code TranscriptionManager#findLatestTexteBySubmissionId} — mais elle se
 * verifie de bout en bout ici, sur un transcript temps reel FRAGMENTE : le vrai
 * {@link AiEvaluationService} note, le vrai {@link ProductionSubmissionMapper}
 * sert, et chaque citation persistee doit se relire mot pour mot dans le champ
 * servi aux fronts.
 */
class ProductionTranscriptRecollageTest {

    /**
     * Cas reel : l'enonce du candidat est scinde a une frontiere arbitraire, ici
     * DEUX fois (le signal de fin de tour vient du modele, pas du candidat).
     */
    private static final String DIALOGUE_FRAGMENTE = """
        Examinateur : Bonjour, bienvenue à l'agence, je vous écoute.
        Candidat : Bonjour madame, j'aimerais louer une voiture
        Candidat : si vous en avez s'il vous plaît.
        Examinateur : Bien sûr, pour quelles dates ?
        Candidat : Je voudrais la voiture du douze au quinze mai
        Candidat : parce que je pars en vacances avec ma famille.""";

    /** Citation a cheval sur la premiere frontiere fusionnee. */
    private static final String PREUVE_A_CHEVAL_1 =
        "j'aimerais louer une voiture si vous en avez s'il vous plaît";

    /** Citation a cheval sur la seconde frontiere fusionnee. */
    private static final String PREUVE_A_CHEVAL_2 =
        "Je voudrais la voiture du douze au quinze mai parce que je pars en vacances";

    private ProductionSubmissionManager submissionManager;
    private TranscriptionRepository transcriptionRepository;
    private AiEvaluationManager aiEvaluationManager;
    private EvaluationLlmClient llmClient;
    private ProductionEvaluationProperties props;

    @BeforeEach
    void setUp() {
        submissionManager = mock(ProductionSubmissionManager.class);
        transcriptionRepository = mock(TranscriptionRepository.class);
        aiEvaluationManager = mock(AiEvaluationManager.class);
        llmClient = mock(EvaluationLlmClient.class);
        when(llmClient.getModelName()).thenReturn("modele-test");
        when(llmClient.getPromptVersion()).thenReturn("v5");
        when(aiEvaluationManager.save(any())).thenAnswer(inv -> inv.getArgument(0));

        props = new ProductionEvaluationProperties();
        props.setRubricsVersion("v8");
    }

    /**
     * Le manager REEL (repository mocke + recolleur reel) : c'est le point de
     * passage unique que le test doit exercer, pas un mock qui le contournerait.
     */
    private TranscriptionManager transcriptionManager(UUID submissionId) {
        Transcription t = new Transcription();
        t.setTexte(DIALOGUE_FRAGMENTE);
        when(transcriptionRepository.findFirstBySubmissionIdOrderByCreatedAtDesc(submissionId))
            .thenReturn(Optional.of(t));
        return new TranscriptionManager(transcriptionRepository, new TranscriptTurnStitcher(props));
    }

    private AiEvaluationService service(TranscriptionManager transcriptionManager) {
        ProductionRubricsProvider rubrics = new ProductionRubricsProvider(props, new ObjectMapper());
        rubrics.load();
        return new AiEvaluationService(submissionManager, transcriptionManager, aiEvaluationManager,
            llmClient, new EvaluationPromptBuilder(new ObjectMapper(), rubrics), rubrics,
            new ProductionValidityService(props),
            new ProductionSecondePasseService(props, mock(EvaluationLlmClient.class), rubrics),
            new ProductionFluiditeService(props), new EvaluationRefusalMetrics(), props);
    }

    private ProductionSubmission submissionOrale() {
        ProductionTask task = new ProductionTask();
        task.setId(UUID.randomUUID());
        task.setEpreuve(EpreuveType.TCF_EO);
        task.setTacheNumero((short) 2);
        task.setConsigne("Vous êtes dans une agence de location. Louez une voiture.");
        task.setNiveauCible("B1");

        ProductionSubmission s = new ProductionSubmission();
        s.setId(UUID.randomUUID());
        s.setProductionTask(task);
        s.setStatut(SubmissionStatut.SUBMITTED);
        s.setSource(ProductionSubmissionSource.REALTIME);
        s.setMediaDurationSec(210);
        when(submissionManager.findById(s.getId())).thenReturn(Optional.of(s));
        return s;
    }

    private static Map<String, Object> score(String code, Number note, String preuve) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", code);
        m.put("note_sur_20", note);
        m.put("commentaire", "commentaire " + code);
        m.put("preuve", preuve);
        return m;
    }

    /** Sortie plausible dont DEUX preuves enjambent une frontiere de tour. */
    private void stubLlm() {
        Map<String, Object> acc = new LinkedHashMap<>();
        acc.put("objectif", "ATTEINT");
        acc.put("objectif_resume", "Tu demandes une voiture et tu précises tes dates.");
        acc.put("points_traites", new ArrayList<>(List.of(
            Map.of("libelle", "Demande formulée", "obligatoire", true))));
        acc.put("points_oublies", new ArrayList<>());

        Map<String, Object> f = new LinkedHashMap<>();
        f.put("note_globale", 7);
        f.put("niveau_cecrl", "B1");
        f.put("justification_niveau", "Demande claire et dates précisées.");
        f.put("confiance", "HAUTE");
        f.put("confiance_raisons", new ArrayList<>(List.of("échange complet et lisible")));
        f.put("accomplissement", acc);
        f.put("scores_criteres", new ArrayList<>(List.of(
            score("communiquer", 7, PREUVE_A_CHEVAL_1),
            score("interagir", 7, "Bonjour madame"),
            score("lexique", 7, "je pars en vacances avec ma famille"),
            score("morphosyntaxe", 7, PREUVE_A_CHEVAL_2))));
        f.put("points_forts", new ArrayList<>(List.of("Demande directe et polie")));
        f.put("points_a_ameliorer", new ArrayList<>(List.of(Map.of(
            "constat", "Tes idées restent juxtaposées.",
            "comment", "Relie tes deux phrases.",
            "exemple", Map.of("avant", "Bonjour madame", "apres", "Bonjour madame, excusez-moi")))));
        f.put("suggestions", new ArrayList<>());
        f.put("exemples_corriges", new ArrayList<>());

        when(llmClient.evaluate(anyString(), anyString()))
            .thenReturn(new EvaluationLlmClient.Outcome(f, 100, 200, 3));
    }

    @SuppressWarnings("unchecked")
    private static List<String> preuves(AiEvaluation eval) {
        List<String> out = new ArrayList<>();
        for (Object s : (List<Object>) eval.getFeedbackJson().get("scores_criteres")) {
            Object preuve = ((Map<String, Object>) s).get("preuve");
            if (preuve != null) out.add(preuve.toString());
        }
        return out;
    }

    @Test
    void le_texte_cite_par_le_correcteur_est_exactement_celui_servi_aux_fronts() {
        stubLlm();
        ProductionSubmission sub = submissionOrale();
        TranscriptionManager manager = transcriptionManager(sub.getId());

        AiEvaluation eval = service(manager).evaluate(sub.getId());
        when(aiEvaluationManager.findLatestBySubmissionId(sub.getId())).thenReturn(Optional.of(eval));

        ProductionSubmissionDto dto = new ProductionSubmissionMapper(
            aiEvaluationManager, manager, mock(ProductionAudioStorageService.class)).toDto(sub);

        // Les quatre citations survivent : les deux qui enjambaient une
        // frontiere sont desormais rattachables.
        assertThat(preuves(eval)).hasSize(4);
        // ET chacune se relit mot pour mot dans le champ servi aux fronts.
        assertThat(dto.transcription()).isNotNull();
        for (String preuve : preuves(eval)) {
            assertThat(dto.transcription()).contains(preuve);
        }
        assertThat(dto.transcription())
            .isEqualTo(manager.findLatestTexteBySubmissionId(sub.getId()).orElseThrow());
    }

    /**
     * Sans recollage, ces memes citations ne sont rattachables a aucun segment
     * (un segment par tour) : la correction echoue, le candidat ne voit pas sa
     * note. C'est le defaut que corrige le recollage.
     */
    @Test
    void drapeau_eteint_les_memes_citations_ne_sont_plus_rattachables() {
        props.getRecollageTours().setEnabled(false);
        stubLlm();
        ProductionSubmission sub = submissionOrale();
        AiEvaluationService service = service(transcriptionManager(sub.getId()));

        assertThatThrownBy(() -> service.evaluate(sub.getId()))
            .isInstanceOf(AiEvaluationException.class);
    }

    @Test
    void le_correcteur_recoit_le_transcript_recolle_et_non_le_transcript_brut() {
        ProductionSubmission sub = submissionOrale();
        String servi = transcriptionManager(sub.getId())
            .findLatestTexteBySubmissionId(sub.getId()).orElseThrow();

        assertThat(servi).contains(PREUVE_A_CHEVAL_1);
        assertThat(DIALOGUE_FRAGMENTE).doesNotContain(PREUVE_A_CHEVAL_1);
        // Le tour de l'examinateur reste une frontiere : rien n'est fusionne
        // a travers lui.
        assertThat(servi).contains("Examinateur : Bien sûr, pour quelles dates ?");
    }
}

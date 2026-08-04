package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.manager.UserManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.access.AccessDeniedException;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Orchestration d'une soumission EO/EE (cf. {@link ProductionEvaluationService}) :
 * gardes d'appartenance (IDOR), epreuve terminee / chrono ecoule, validation du
 * payload et du nombre de mots, transitions de statut, plafond de retries.
 * Unitaire pur (managers + storage + runner mockes).
 */
class ProductionEvaluationServiceTest {

    private ProductionTaskManager taskManager;
    private ProductionSubmissionManager submissionManager;
    private TranscriptionManager transcriptionManager;
    private AttemptManager attemptManager;
    private UserManager userManager;
    private ProductionAudioStorageService audioStorage;
    private ProductionPipelineAsyncRunner pipelineRunner;
    private ProductionEvaluationProperties props;
    private SubscriptionService subscriptionService;
    private ProductionEvaluationService service;

    private final UUID userId = UUID.randomUUID();
    private final UUID taskId = UUID.randomUUID();
    private final UUID attemptId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        taskManager = mock(ProductionTaskManager.class);
        submissionManager = mock(ProductionSubmissionManager.class);
        transcriptionManager = mock(TranscriptionManager.class);
        attemptManager = mock(AttemptManager.class);
        userManager = mock(UserManager.class);
        audioStorage = mock(ProductionAudioStorageService.class);
        pipelineRunner = mock(ProductionPipelineAsyncRunner.class);
        props = mock(ProductionEvaluationProperties.class);
        subscriptionService = mock(SubscriptionService.class);
        // Gardes de session + quota : collaborateur REEL (pur), pour que les
        // regles verifiees ici soient celles qui tournent en production.
        ProductionAccessService accessService = new ProductionAccessService(
                subscriptionService, attemptManager, submissionManager);
        service = new ProductionEvaluationService(
                taskManager, submissionManager, transcriptionManager, attemptManager,
                userManager, audioStorage, pipelineRunner, accessService, props);

        when(props.getMinTextWords()).thenReturn(10);
        when(props.getMaxTextWords()).thenReturn(300);
        when(props.getMaxAudioSizeBytes()).thenReturn(25L * 1024 * 1024);
        when(props.getMaxRetriesPerSubmission()).thenReturn(3);
        when(submissionManager.save(any())).thenAnswer(inv -> inv.getArgument(0));
        // finishSubAttemptIfFullExam : pas d'examen complet par defaut.
        when(attemptManager.findByIdWithParent(any())).thenReturn(Optional.empty());
    }

    private User user() {
        User u = new User();
        u.setId(userId);
        return u;
    }

    private Attempt ownedAttempt(EpreuveType epreuve) {
        Attempt a = new Attempt();
        a.setId(attemptId);
        a.setUser(user());
        a.setEpreuve(epreuve);
        a.setStartedAt(Instant.now());
        return a;
    }

    private Attempt ownedAttempt() {
        return ownedAttempt(EpreuveType.TCF_EE);
    }

    private ProductionTask task(EpreuveType epreuve) {
        ProductionTask t = new ProductionTask();
        t.setId(taskId);
        t.setEpreuve(epreuve);
        t.setActive(true);
        return t;
    }

    private static String words(int n) {
        return ("mot ".repeat(n)).trim();
    }

    private void stubCommon(ProductionTask task, Attempt attempt) {
        when(userManager.findById(userId)).thenReturn(Optional.of(user()));
        when(taskManager.findById(taskId)).thenReturn(Optional.of(task));
        when(attemptManager.findById(attemptId)).thenReturn(Optional.of(attempt));
    }

    // ------------------------------------------------------------------------
    // Gardes communes
    // ------------------------------------------------------------------------

    @Test
    void submit_user_introuvable_renvoie_404() {
        when(userManager.findById(userId)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.submitAndEvaluate(userId, taskId, attemptId, null, "x"))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void submit_attempt_d_autrui_refuse_IDOR() {
        Attempt foreign = new Attempt();
        foreign.setId(attemptId);
        User other = new User();
        other.setId(UUID.randomUUID());
        foreign.setUser(other);
        stubCommon(task(EpreuveType.TCF_EE), foreign);

        assertThatThrownBy(() -> service.submitAndEvaluate(userId, taskId, attemptId, null, words(20)))
                .isInstanceOf(AccessDeniedException.class);
        verify(pipelineRunner, never()).runPipelineAsync(any(), anyBoolean());
    }

    @Test
    void submit_epreuve_terminee_refuse() {
        Attempt finished = ownedAttempt();
        finished.setFinishedAt(Instant.now());
        stubCommon(task(EpreuveType.TCF_EE), finished);

        assertThatThrownBy(() -> service.submitAndEvaluate(userId, taskId, attemptId, null, words(20)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void submit_chrono_ecoule_refuse() {
        Attempt expired = ownedAttempt();
        expired.setTimeLimitSeconds(1800);
        expired.setStartedAt(Instant.now().minusSeconds(1800 + 120)); // au-dela des 60s de grace
        stubCommon(task(EpreuveType.TCF_EE), expired);

        assertThatThrownBy(() -> service.submitAndEvaluate(userId, taskId, attemptId, null, words(20)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void submit_tache_inactive_refuse() {
        ProductionTask inactive = task(EpreuveType.TCF_EE);
        inactive.setActive(false);
        stubCommon(inactive, ownedAttempt());

        assertThatThrownBy(() -> service.submitAndEvaluate(userId, taskId, attemptId, null, words(20)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void submit_tache_orale_dans_une_session_ecrite_refuse() {
        // Une production ORALE etait acceptee, evaluee et comptee dans une
        // session d'examen ECRITE (et, en examen complet, auto-finalisait la
        // mauvaise sous-epreuve avec un niveau CECRL faux).
        stubCommon(task(EpreuveType.TCF_EO), ownedAttempt(EpreuveType.TCF_EE));
        MockMultipartFile audio = new MockMultipartFile("audio", "a.mp3", "audio/mpeg", new byte[]{1, 2, 3});

        assertThatThrownBy(() -> service.submitAndEvaluate(userId, taskId, attemptId, audio, null))
                .isInstanceOf(BusinessException.class);
        verify(pipelineRunner, never()).runPipelineAsync(any(), anyBoolean());
        verify(audioStorage, never()).upload(any(), any(), any(), any());
    }

    @Test
    void submit_tache_ecrite_dans_une_session_orale_refuse() {
        stubCommon(task(EpreuveType.TCF_EE), ownedAttempt(EpreuveType.TCF_EO));

        assertThatThrownBy(() -> service.submitAndEvaluate(userId, taskId, attemptId, null, words(20)))
                .isInstanceOf(BusinessException.class);
        verify(submissionManager, never()).save(any());
    }

    @Test
    void submit_examen_refuse_une_seconde_production_sur_la_meme_tache() {
        // Un examen, c'est 3 taches, une fois chacune : sans ce plafond, une
        // session d'examen gratuite acceptait autant d'evaluations IA que le
        // client en envoyait.
        Attempt exam = ownedAttempt(EpreuveType.TCF_EE);
        exam.setSlotNumber(1);
        ProductionTask t = task(EpreuveType.TCF_EE);
        t.setTacheNumero((short) 1);
        stubCommon(t, exam);
        when(submissionManager.countByAttemptAndTache(attemptId, (short) 1)).thenReturn(1L);

        assertThatThrownBy(() -> service.submitAndEvaluate(userId, taskId, attemptId, null, words(20)))
                .isInstanceOf(BusinessException.class);
        verify(pipelineRunner, never()).runPipelineAsync(any(), anyBoolean());
    }

    // ------------------------------------------------------------------------
    // Payload EE / EO
    // ------------------------------------------------------------------------

    @Test
    void submit_EE_sans_texte_refuse() {
        stubCommon(task(EpreuveType.TCF_EE), ownedAttempt());
        assertThatThrownBy(() -> service.submitAndEvaluate(userId, taskId, attemptId, null, "  "))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void submit_EO_sans_audio_refuse() {
        stubCommon(task(EpreuveType.TCF_EO), ownedAttempt(EpreuveType.TCF_EO));
        assertThatThrownBy(() -> service.submitAndEvaluate(userId, taskId, attemptId, null, null))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void submit_EE_avec_audio_en_plus_refuse() {
        stubCommon(task(EpreuveType.TCF_EE), ownedAttempt());
        MockMultipartFile audio = new MockMultipartFile("audio", "a.mp3", "audio/mpeg", new byte[]{1, 2, 3});
        assertThatThrownBy(() -> service.submitAndEvaluate(userId, taskId, attemptId, audio, words(20)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void submit_EO_content_type_non_audio_refuse() {
        stubCommon(task(EpreuveType.TCF_EO), ownedAttempt(EpreuveType.TCF_EO));
        MockMultipartFile bad = new MockMultipartFile("audio", "x.html", "text/html", new byte[]{1, 2, 3});
        assertThatThrownBy(() -> service.submitAndEvaluate(userId, taskId, attemptId, bad, null))
                .isInstanceOf(BusinessException.class);
    }

    // ------------------------------------------------------------------------
    // Nombre de mots EE
    // ------------------------------------------------------------------------

    @Test
    void submit_EE_trop_court_refuse() {
        ProductionTask t = task(EpreuveType.TCF_EE);
        t.setMotsMin(50);
        stubCommon(t, ownedAttempt());
        assertThatThrownBy(() -> service.submitAndEvaluate(userId, taskId, attemptId, null, words(5)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void submit_EE_trop_long_au_dela_de_la_tolerance_refuse() {
        ProductionTask t = task(EpreuveType.TCF_EE);
        t.setMotsMax(10); // plafond tolere = floor(10*1.2) = 12
        stubCommon(t, ownedAttempt());
        assertThatThrownBy(() -> service.submitAndEvaluate(userId, taskId, attemptId, null, words(20)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void submit_EE_valide_cree_la_submission_en_SUBMITTED_et_lance_le_pipeline() {
        ProductionTask t = task(EpreuveType.TCF_EE); // motsMin/Max null → plancher = minTextWords (10)
        stubCommon(t, ownedAttempt());

        ProductionSubmission saved = service.submitAndEvaluate(userId, taskId, attemptId, null, words(20));

        ArgumentCaptor<ProductionSubmission> captor = ArgumentCaptor.forClass(ProductionSubmission.class);
        verify(submissionManager).save(captor.capture());
        assertThat(captor.getValue().getStatut()).isEqualTo(SubmissionStatut.SUBMITTED);
        assertThat(saved.getMotsCount()).isEqualTo(20);
        verify(pipelineRunner).runPipelineAsync(any(), eq(false));
        verify(audioStorage, never()).upload(any(), any(), any(), any());
    }

    @Test
    void submit_EO_valide_uploade_l_audio_avant_de_persister() {
        stubCommon(task(EpreuveType.TCF_EO), ownedAttempt(EpreuveType.TCF_EO));
        when(audioStorage.upload(any(), any(), any(), any()))
                .thenReturn(new ProductionAudioStorageService.StoredAudio("submissions/k.mp3", "audio/mpeg"));
        MockMultipartFile audio = new MockMultipartFile("audio", "rec.mp3", "audio/mpeg", new byte[]{1, 2, 3, 4});

        ProductionSubmission saved = service.submitAndEvaluate(userId, taskId, attemptId, audio, null);

        assertThat(saved.getMediaUrl()).isEqualTo("submissions/k.mp3");
        verify(audioStorage).upload(any(), any(), eq("audio/mpeg"), eq("mp3"));
        verify(pipelineRunner).runPipelineAsync(any(), eq(true));
    }

    // ------------------------------------------------------------------------
    // evaluateRealtimeTranscript
    // ------------------------------------------------------------------------

    @Test
    void realtime_tache_non_orale_refuse() {
        stubCommon(task(EpreuveType.TCF_EE), ownedAttempt());
        assertThatThrownBy(() -> service.evaluateRealtimeTranscript(userId, taskId, attemptId, "Examinateur: ...", 90))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void realtime_transcript_vide_refuse() {
        stubCommon(task(EpreuveType.TCF_EO), ownedAttempt(EpreuveType.TCF_EO));
        assertThatThrownBy(() -> service.evaluateRealtimeTranscript(userId, taskId, attemptId, "   ", 90))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void realtime_valide_persiste_submission_transcription_et_lance_le_pipeline() {
        stubCommon(task(EpreuveType.TCF_EO), ownedAttempt(EpreuveType.TCF_EO));

        service.evaluateRealtimeTranscript(userId, taskId, attemptId, "Examinateur: Bonjour\nCandidat: Bonjour", 90);

        verify(transcriptionManager).save(any());
        verify(pipelineRunner).runPipelineAsync(any(), eq(true));
    }

    // La voie temps réel ne vérifiait NI finishedAt, NI le chrono, NI l'épreuve,
    // NI le quota — alors que la voie asynchrone vérifie les quatre. Elle était
    // donc un contournement complet du verrou freemium (une sous-épreuve
    // pré-terminée acceptait encore des notations).

    @Test
    void realtime_epreuve_terminee_refuse() {
        Attempt finished = ownedAttempt(EpreuveType.TCF_EO);
        finished.setFinishedAt(Instant.now());
        stubCommon(task(EpreuveType.TCF_EO), finished);

        assertThatThrownBy(() -> service.evaluateRealtimeTranscript(
                userId, taskId, attemptId, "Candidat : bonjour", 60))
                .isInstanceOf(BusinessException.class);
        verify(submissionManager, never()).save(any());
        verify(pipelineRunner, never()).runPipelineAsync(any(), anyBoolean());
    }

    @Test
    void realtime_chrono_ecoule_refuse() {
        Attempt expired = ownedAttempt(EpreuveType.TCF_EO);
        expired.setTimeLimitSeconds(900);
        expired.setStartedAt(Instant.now().minusSeconds(900 + 120));
        stubCommon(task(EpreuveType.TCF_EO), expired);

        assertThatThrownBy(() -> service.evaluateRealtimeTranscript(
                userId, taskId, attemptId, "Candidat : bonjour", 60))
                .isInstanceOf(BusinessException.class);
        verify(pipelineRunner, never()).runPipelineAsync(any(), anyBoolean());
    }

    @Test
    void realtime_attempt_d_une_autre_epreuve_refuse() {
        stubCommon(task(EpreuveType.TCF_EO), ownedAttempt(EpreuveType.TCF_EE));

        assertThatThrownBy(() -> service.evaluateRealtimeTranscript(
                userId, taskId, attemptId, "Candidat : bonjour", 60))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void realtime_attempt_d_autrui_refuse() {
        Attempt foreign = ownedAttempt(EpreuveType.TCF_EO);
        User other = new User();
        other.setId(UUID.randomUUID());
        foreign.setUser(other);
        stubCommon(task(EpreuveType.TCF_EO), foreign);

        assertThatThrownBy(() -> service.evaluateRealtimeTranscript(
                userId, taskId, attemptId, "Candidat : bonjour", 60))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void realtime_quota_gratuit_epuise_refuse() {
        stubCommon(task(EpreuveType.TCF_EO), ownedAttempt(EpreuveType.TCF_EO));
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(attemptManager.countProductionExamSessions(userId)).thenReturn(0L);
        when(submissionManager.countTrainingByUserAndEpreuve(userId, EpreuveType.TCF_EO)).thenReturn(1L);

        assertThatThrownBy(() -> service.evaluateRealtimeTranscript(
                userId, taskId, attemptId, "Candidat : bonjour", 60))
                .isInstanceOf(AccessDeniedException.class);
        verify(pipelineRunner, never()).runPipelineAsync(any(), anyBoolean());
    }

    // ------------------------------------------------------------------------
    // Auto-finalisation d'une sous-épreuve d'examen complet
    // ------------------------------------------------------------------------

    @Test
    void autofinish_compte_les_taches_distinctes_de_l_epreuve_pas_les_lignes() {
        Attempt parent = new Attempt();
        parent.setId(UUID.randomUUID());
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        Attempt sub = ownedAttempt(EpreuveType.TCF_EE);
        sub.setParentAttempt(parent);
        ProductionTask t = task(EpreuveType.TCF_EE);
        t.setTacheNumero((short) 2);
        stubCommon(t, sub);
        when(attemptManager.findByIdWithParent(attemptId)).thenReturn(Optional.of(sub));
        // 2 tâches distinctes rendues sur 3 → l'épreuve reste ouverte, même si
        // l'attempt porte davantage de lignes (rejeu, ou soumissions mal aiguillées).
        when(submissionManager.countDistinctTachesByAttemptAndEpreuve(attemptId, EpreuveType.TCF_EE))
                .thenReturn(2L);

        service.submitAndEvaluate(userId, taskId, attemptId, null, words(20));

        assertThat(sub.getFinishedAt()).isNull();
    }

    @Test
    void autofinish_ferme_la_sous_epreuve_a_3_taches_distinctes() {
        Attempt parent = new Attempt();
        parent.setId(UUID.randomUUID());
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        Attempt sub = ownedAttempt(EpreuveType.TCF_EE);
        sub.setParentAttempt(parent);
        ProductionTask t = task(EpreuveType.TCF_EE);
        t.setTacheNumero((short) 3);
        stubCommon(t, sub);
        when(attemptManager.findByIdWithParent(attemptId)).thenReturn(Optional.of(sub));
        when(submissionManager.countDistinctTachesByAttemptAndEpreuve(attemptId, EpreuveType.TCF_EE))
                .thenReturn(3L);

        service.submitAndEvaluate(userId, taskId, attemptId, null, words(20));

        assertThat(sub.getFinishedAt()).isNotNull();
    }

    // ------------------------------------------------------------------------
    // retry
    // ------------------------------------------------------------------------

    private ProductionSubmission failedSubmission(short retryCount) {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(UUID.randomUUID());
        s.setUser(user());
        s.setStatut(SubmissionStatut.FAILED);
        s.setRetryCount(retryCount);
        s.setProductionTask(task(EpreuveType.TCF_EE));
        return s;
    }

    @Test
    void retry_submission_d_autrui_refuse() {
        ProductionSubmission s = failedSubmission((short) 0);
        User other = new User();
        other.setId(UUID.randomUUID());
        s.setUser(other);
        when(submissionManager.findByIdWithTask(s.getId())).thenReturn(Optional.of(s));

        assertThatThrownBy(() -> service.retry(s.getId(), userId)).isInstanceOf(BusinessException.class);
    }

    @Test
    void retry_submission_non_failed_refuse() {
        ProductionSubmission s = failedSubmission((short) 0);
        s.setStatut(SubmissionStatut.EVALUATED);
        when(submissionManager.findByIdWithTask(s.getId())).thenReturn(Optional.of(s));

        assertThatThrownBy(() -> service.retry(s.getId(), userId)).isInstanceOf(BusinessException.class);
    }

    @Test
    void retry_plafond_atteint_refuse() {
        ProductionSubmission s = failedSubmission((short) 3); // max = 3
        when(submissionManager.findByIdWithTask(s.getId())).thenReturn(Optional.of(s));

        assertThatThrownBy(() -> service.retry(s.getId(), userId)).isInstanceOf(BusinessException.class);
        verify(pipelineRunner, never()).runPipelineAsync(any(), anyBoolean());
    }

    @Test
    void retry_valide_incremente_repasse_en_SUBMITTED_et_relance() {
        ProductionSubmission s = failedSubmission((short) 1);
        when(submissionManager.findByIdWithTask(s.getId())).thenReturn(Optional.of(s));

        ProductionSubmission result = service.retry(s.getId(), userId);

        assertThat(result.getStatut()).isEqualTo(SubmissionStatut.SUBMITTED);
        assertThat(result.getRetryCount()).isEqualTo((short) 2);
        verify(pipelineRunner).runPipelineAsync(eq(s.getId()), eq(false));
    }
}

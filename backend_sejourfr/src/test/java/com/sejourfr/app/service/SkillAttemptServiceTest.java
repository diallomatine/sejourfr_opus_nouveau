package com.sejourfr.app.service;

import com.sejourfr.app.config.CompetenceProperties;
import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.dto.SkillAttemptDto;
import com.sejourfr.app.dto.SubmitSkillTextRequest;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillSelfEvaluation;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.SkillPromptManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.mapper.SkillAttemptMapper;
import com.sejourfr.app.ratelimit.RateLimitGuard;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.competence.SkillAnalysisAsyncRunner;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.access.AccessDeniedException;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Regles serveur de la soumission d'une production de competence : coherence
 * section - media, garde-fou anti-abus, consommation du quota, et retry.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SkillAttemptServiceTest {

    @Mock private SkillPromptManager promptManager;
    @Mock private UserSkillAttemptManager attemptManager;
    @Mock private UserManager userManager;
    @Mock private SkillAnalysisAccessService analysisAccessService;
    @Mock private SkillAnalysisAsyncRunner analysisRunner;
    @Mock private ProductionAudioStorageService audioStorage;
    @Mock private SkillAttemptMapper mapper;
    @Mock private RateLimitGuard rateLimitGuard;
    @Mock private CurrentUser currentUser;

    private final CompetenceProperties props = new CompetenceProperties();
    private final ProductionEvaluationProperties productionProps = new ProductionEvaluationProperties();

    private SkillAttemptService service;

    private final UUID userId = UUID.randomUUID();
    private final User user = new User();

    @BeforeEach
    void setUp() {
        service = new SkillAttemptService(promptManager, attemptManager, userManager,
                analysisAccessService, analysisRunner, audioStorage, mapper,
                rateLimitGuard, currentUser, props, productionProps);
        user.setId(userId);
        when(currentUser.getId()).thenReturn(userId);
        when(userManager.findById(userId)).thenReturn(Optional.of(user));
        when(attemptManager.save(any())).thenAnswer(inv -> {
            UserSkillAttempt saved = inv.getArgument(0);
            if (saved.getId() == null) saved.setId(UUID.randomUUID());
            return saved;
        });
        when(mapper.toDto(any())).thenReturn(dummyDto());
        when(mapper.toDtoWithSignedAudio(any())).thenReturn(dummyDto());
    }

    // ------------------------------------------------------------------------
    // Coherence section - media
    // ------------------------------------------------------------------------

    @Test
    void writtenSubmissionOnAnOralPromptIsRejected() {
        SkillPrompt prompt = prompt(SkillSection.EO);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        assertThatThrownBy(() -> service.submitText(
                new SubmitSkillTextRequest(prompt.getId(), "Bonjour Madame.", null, false)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("expression orale");
        verify(attemptManager, never()).save(any());
    }

    @Test
    void audioSubmissionOnAWrittenPromptIsRejected() {
        SkillPrompt prompt = prompt(SkillSection.EE);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        assertThatThrownBy(() -> service.submitAudio(
                prompt.getId(), audioFile(), 30, null, false))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("expression écrite");
        verify(audioStorage, never()).upload(any(), any(), any(), any());
    }

    @Test
    void unknownOrInactivePromptIsNotFound() {
        UUID promptId = UUID.randomUUID();
        when(promptManager.findActiveByIdWithSkill(promptId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.submitText(
                new SubmitSkillTextRequest(promptId, "Bonjour.", null, false)))
                .isInstanceOf(NotFoundException.class);
    }

    // ------------------------------------------------------------------------
    // Bornes anti-abus
    // ------------------------------------------------------------------------

    @Test
    void writtenProductionBeyondTheAbuseCapIsRejected() {
        SkillPrompt prompt = prompt(SkillSection.EE);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));
        String tooLong = "mot ".repeat(props.getAnalysis().getMaxTextWords() + 1);

        assertThatThrownBy(() -> service.submitText(
                new SubmitSkillTextRequest(prompt.getId(), tooLong, null, false)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("400 mots");
    }

    @Test
    void recommendedBoundsNeverBlockASubmission() {
        // Le sujet conseille 15 a 50 mots : une reponse de 3 mots passe quand
        // meme. Ces bornes sont indicatives, jamais bloquantes.
        SkillPrompt prompt = prompt(SkillSection.EE);
        prompt.setRecommendedMinWords(15);
        prompt.setRecommendedMaxWords(50);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        service.submitText(new SubmitSkillTextRequest(prompt.getId(), "Bonjour cher voisin", null, false));

        assertThat(captureSaved().getWordsCount()).isEqualTo(3);
    }

    @Test
    void blankWrittenProductionIsRejected() {
        SkillPrompt prompt = prompt(SkillSection.EE);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        assertThatThrownBy(() -> service.submitText(
                new SubmitSkillTextRequest(prompt.getId(), "   ", null, false)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void recordingBeyondTheDurationCapIsRejected() {
        SkillPrompt prompt = prompt(SkillSection.EO);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        assertThatThrownBy(() -> service.submitAudio(
                prompt.getId(), audioFile(), props.getAnalysis().getMaxAudioDurationSeconds() + 1,
                null, false))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("180 secondes");
    }

    @Test
    void missingRecordingIsRejected() {
        SkillPrompt prompt = prompt(SkillSection.EO);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        assertThatThrownBy(() -> service.submitAudio(prompt.getId(), null, 30, null, false))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Aucun enregistrement");
    }

    // ------------------------------------------------------------------------
    // Analyse et quota
    // ------------------------------------------------------------------------

    @Test
    void productionWithoutAnalysisIsFinalAndCostsNothing() {
        SkillPrompt prompt = prompt(SkillSection.EE);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        service.submitText(new SubmitSkillTextRequest(
                prompt.getId(), "Bonjour, je vous préviens du changement.",
                SkillSelfEvaluation.INCERTAIN, false));

        UserSkillAttempt saved = captureSaved();
        assertThat(saved.getStatut()).isEqualTo(SkillAttemptStatut.RECORDED);
        assertThat(saved.isAnalysisRequested()).isFalse();
        assertThat(saved.getSelfEvaluation()).isEqualTo(SkillSelfEvaluation.INCERTAIN);
        // Ni verification de quota, ni appel au correcteur.
        verify(analysisAccessService, never()).assertCanAnalyse(any());
        verify(analysisRunner, never()).runAsync(any(), anyBoolean());
    }

    @Test
    void requestedAnalysisChecksTheQuotaMarksTheAttemptAndStartsThePipeline() {
        SkillPrompt prompt = prompt(SkillSection.EE);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        service.submitText(new SubmitSkillTextRequest(
                prompt.getId(), "Bonjour, je vous préviens du changement.", null, true));

        UserSkillAttempt saved = captureSaved();
        assertThat(saved.getStatut()).isEqualTo(SkillAttemptStatut.SUBMITTED);
        // Consomme a l'ACCEPTATION, pas au succes : sinon un retry gratuit apres
        // echec offrirait des analyses supplementaires.
        assertThat(saved.isAnalysisRequested()).isTrue();
        verify(analysisAccessService).assertCanAnalyse(userId);
        verify(analysisRunner).runAsync(saved.getId(), false);
    }

    @Test
    void anExhaustedQuotaBlocksBeforeAnythingIsPersisted() {
        SkillPrompt prompt = prompt(SkillSection.EE);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));
        doThrow(new AccessDeniedException("épuisé")).when(analysisAccessService).assertCanAnalyse(userId);

        assertThatThrownBy(() -> service.submitText(new SubmitSkillTextRequest(
                prompt.getId(), "Bonjour.", null, true)))
                .isInstanceOf(AccessDeniedException.class);

        verify(attemptManager, never()).save(any());
        verify(analysisRunner, never()).runAsync(any(), anyBoolean());
    }

    @Test
    void audioIsUploadedBeforeTheRowIsInsertedAndTheKeyIsStoredNotAnUrl() {
        SkillPrompt prompt = prompt(SkillSection.EO);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));
        when(audioStorage.upload(any(), any(), any(), anyString()))
                .thenReturn(new ProductionAudioStorageService.StoredAudio(
                        "submissions/abc.webm", "audio/webm"));

        service.submitAudio(prompt.getId(), audioFile(), 40, null, true);

        UserSkillAttempt saved = captureSaved();
        assertThat(saved.getAudioObjectKey()).isEqualTo("submissions/abc.webm");
        assertThat(saved.getAudioDurationSec()).isEqualTo(40);
        assertThat(saved.getWrittenProduction()).isNull();
        // estOral = true : la transcription Whisper precede l'analyse.
        verify(analysisRunner).runAsync(saved.getId(), true);
    }

    @Test
    void everySubmissionGoesThroughTheRateLimit() {
        SkillPrompt prompt = prompt(SkillSection.EE);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        service.submitText(new SubmitSkillTextRequest(prompt.getId(), "Bonjour.", null, false));

        verify(rateLimitGuard).checkSkillAttempt(userId);
    }

    // ------------------------------------------------------------------------
    // Retry
    // ------------------------------------------------------------------------

    @Test
    void retryOfAFailedAnalysisRestartsWithoutConsumingTheQuotaAgain() {
        UserSkillAttempt attempt = ownedAttempt(SkillAttemptStatut.FAILED, true);
        attempt.setErrorMessage("Fournisseur indisponible");
        when(attemptManager.findByIdWithPrompt(attempt.getId())).thenReturn(Optional.of(attempt));

        service.retry(attempt.getId());

        assertThat(attempt.getStatut()).isEqualTo(SkillAttemptStatut.SUBMITTED);
        assertThat(attempt.getErrorMessage()).isNull();
        verify(analysisRunner).runAsync(attempt.getId(), false);
        // Le quota a deja ete decompte a l'acceptation : on ne le reconsomme pas.
        verify(analysisAccessService, never()).assertCanAnalyse(any());
    }

    @Test
    void retryOfAnAttemptThatIsNotFailedIsAConflict() {
        UserSkillAttempt attempt = ownedAttempt(SkillAttemptStatut.EVALUATED, true);
        when(attemptManager.findByIdWithPrompt(attempt.getId())).thenReturn(Optional.of(attempt));

        assertThatThrownBy(() -> service.retry(attempt.getId()))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void retryOfAProductionRecordedWithoutAnalysisIsAConflict() {
        UserSkillAttempt attempt = ownedAttempt(SkillAttemptStatut.FAILED, false);
        when(attemptManager.findByIdWithPrompt(attempt.getId())).thenReturn(Optional.of(attempt));

        assertThatThrownBy(() -> service.retry(attempt.getId()))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("sans analyse");
    }

    @Test
    void retryIsCappedAndEachRelaunchIsCounted() {
        // Le retry ne reconsomme pas le quota : sans plafond PERSISTE, une panne
        // fournisseur se traduirait par une boucle d'appels payants offerts.
        UserSkillAttempt attempt = ownedAttempt(SkillAttemptStatut.FAILED, true);
        when(attemptManager.findByIdWithPrompt(attempt.getId())).thenReturn(Optional.of(attempt));

        for (short essai = 1; essai <= SkillAttemptService.MAX_RETRIES; essai++) {
            attempt.setStatut(SkillAttemptStatut.FAILED);
            service.retry(attempt.getId());
            assertThat(attempt.getRetryCount()).isEqualTo(essai);
        }

        attempt.setStatut(SkillAttemptStatut.FAILED);
        assertThatThrownBy(() -> service.retry(attempt.getId()))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("3 fois");
        assertThat(attempt.getRetryCount()).isEqualTo(SkillAttemptService.MAX_RETRIES);
    }

    // ------------------------------------------------------------------------
    // Analyse a posteriori (POST /api/skill-attempts/{id}/analyse)
    // ------------------------------------------------------------------------

    @Test
    void analysingARecordedProductionConsumesTheQuotaAndStartsThePipeline() {
        // Le cas metier : produire gratuitement sans IA, puis s'abonner. Sans
        // cette route, la seule issue etait de refaire le sujet — donc de perdre
        // sa production.
        UserSkillAttempt attempt = ownedAttempt(SkillAttemptStatut.RECORDED, false);
        when(attemptManager.findByIdWithPrompt(attempt.getId())).thenReturn(Optional.of(attempt));

        service.analyse(attempt.getId());

        assertThat(attempt.getStatut()).isEqualTo(SkillAttemptStatut.SUBMITTED);
        assertThat(attempt.isAnalysisRequested()).isTrue();
        verify(analysisAccessService).assertCanAnalyse(userId);
        verify(analysisRunner).runAsync(attempt.getId(), false);
        verify(rateLimitGuard).checkSkillAttempt(userId);
    }

    @Test
    void analysingAnOralProductionTranscribesFirst() {
        // La transcription Whisper n'a jamais eu lieu (production rendue sans
        // analyse) : le pipeline doit la declencher, comme sur la voie normale.
        UserSkillAttempt attempt = ownedAttempt(SkillAttemptStatut.RECORDED, false);
        attempt.setWrittenProduction(null);
        attempt.setAudioObjectKey("submissions/abc.webm");
        when(attemptManager.findByIdWithPrompt(attempt.getId())).thenReturn(Optional.of(attempt));

        service.analyse(attempt.getId());

        verify(analysisRunner).runAsync(attempt.getId(), true);
    }

    @Test
    void analysingAnAlreadyAnalysedProductionIsRejected() {
        // Tout statut autre que RECORDED signifie qu'une analyse a deja ete
        // acceptee : repasser par ici contournerait le quota.
        UserSkillAttempt attempt = ownedAttempt(SkillAttemptStatut.EVALUATED, true);
        when(attemptManager.findByIdWithPrompt(attempt.getId())).thenReturn(Optional.of(attempt));

        assertThatThrownBy(() -> service.analyse(attempt.getId()))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("déjà fait l'objet");
        verify(analysisAccessService, never()).assertCanAnalyse(any());
        verify(analysisRunner, never()).runAsync(any(), anyBoolean());
    }

    @Test
    void analysingWithAnExhaustedQuotaChangesNothing() {
        UserSkillAttempt attempt = ownedAttempt(SkillAttemptStatut.RECORDED, false);
        when(attemptManager.findByIdWithPrompt(attempt.getId())).thenReturn(Optional.of(attempt));
        doThrow(new AccessDeniedException("épuisé")).when(analysisAccessService).assertCanAnalyse(userId);

        assertThatThrownBy(() -> service.analyse(attempt.getId()))
                .isInstanceOf(AccessDeniedException.class);

        assertThat(attempt.getStatut()).isEqualTo(SkillAttemptStatut.RECORDED);
        assertThat(attempt.isAnalysisRequested()).isFalse();
        verify(attemptManager, never()).save(any());
        verify(analysisRunner, never()).runAsync(any(), anyBoolean());
    }

    @Test
    void analysingSomeoneElsesAttemptIsNotFound() {
        UserSkillAttempt attempt = ownedAttempt(SkillAttemptStatut.RECORDED, false);
        User someoneElse = new User();
        someoneElse.setId(UUID.randomUUID());
        attempt.setUser(someoneElse);
        when(attemptManager.findByIdWithPrompt(attempt.getId())).thenReturn(Optional.of(attempt));

        assertThatThrownBy(() -> service.analyse(attempt.getId()))
                .isInstanceOf(NotFoundException.class);
        verify(analysisAccessService, never()).assertCanAnalyse(any());
    }

    // ------------------------------------------------------------------------
    // Lecture
    // ------------------------------------------------------------------------

    @Test
    void anotherUsersAttemptIsNotFoundNotForbidden() {
        // 403 confirmerait son existence : on repond 404, comme pour les
        // productions completes.
        UserSkillAttempt attempt = ownedAttempt(SkillAttemptStatut.EVALUATED, true);
        User someoneElse = new User();
        someoneElse.setId(UUID.randomUUID());
        attempt.setUser(someoneElse);
        when(attemptManager.findByIdWithPrompt(attempt.getId())).thenReturn(Optional.of(attempt));

        assertThatThrownBy(() -> service.detail(attempt.getId()))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void historyLimitIsClamped() {
        SkillPrompt prompt = prompt(SkillSection.EE);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));
        when(attemptManager.findByUserAndPrompt(eq(userId), eq(prompt.getId()), any(Integer.class)))
                .thenReturn(java.util.List.of());

        service.history(prompt.getId(), 999);
        verify(attemptManager).findByUserAndPrompt(userId, prompt.getId(), 20);

        service.history(prompt.getId(), 0);
        verify(attemptManager).findByUserAndPrompt(userId, prompt.getId(), 1);
    }

    // ------------------------------------------------------------------------
    // Fixtures
    // ------------------------------------------------------------------------

    private UserSkillAttempt captureSaved() {
        ArgumentCaptor<UserSkillAttempt> captor = ArgumentCaptor.forClass(UserSkillAttempt.class);
        verify(attemptManager).save(captor.capture());
        return captor.getValue();
    }

    private SkillPrompt prompt(SkillSection section) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setSection(section);
        skill.setTaskCode(section == SkillSection.EE ? SkillTaskCode.EE1 : SkillTaskCode.EO1);
        skill.setCode("EE1-C1");
        skill.setTitle("Adapter le message au destinataire");
        skill.setActive(true);

        SkillPrompt prompt = new SkillPrompt();
        prompt.setId(UUID.randomUUID());
        prompt.setSkill(skill);
        prompt.setSection(section);
        prompt.setCode("EE1-C1-S1");
        prompt.setActive(true);
        return prompt;
    }

    private UserSkillAttempt ownedAttempt(SkillAttemptStatut statut, boolean analysisRequested) {
        UserSkillAttempt attempt = new UserSkillAttempt();
        attempt.setId(UUID.randomUUID());
        attempt.setUser(user);
        attempt.setSkillPrompt(prompt(SkillSection.EE));
        attempt.setStatut(statut);
        attempt.setAnalysisRequested(analysisRequested);
        attempt.setWrittenProduction("Bonjour.");
        return attempt;
    }

    private static MockMultipartFile audioFile() {
        return new MockMultipartFile("audio", "reponse.webm", "audio/webm", new byte[]{1, 2, 3});
    }

    private static SkillAttemptDto dummyDto() {
        return new SkillAttemptDto(UUID.randomUUID(), UUID.randomUUID(), "EE1-C1-S1",
                SkillAttemptStatut.RECORDED, false, null, null, null, null, null, null, null,
                null, null, null);
    }
}

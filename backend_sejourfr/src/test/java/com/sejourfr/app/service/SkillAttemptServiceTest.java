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
    @Mock private SkillAccessService accessService;
    @Mock private SkillAnalysisAccessService analysisAccessService;
    @Mock private SkillAnalysisAsyncRunner analysisRunner;
    @Mock private WhisperTranscriptionService whisperService;
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
                accessService, analysisAccessService, analysisRunner, whisperService, mapper,
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
    }

    // ------------------------------------------------------------------------
    // Coherence section - media
    // ------------------------------------------------------------------------

    @Test
    void writtenSubmissionOnAnOralPromptIsRejected() {
        SkillPrompt prompt = prompt(SkillSection.EO);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        assertThatThrownBy(() -> service.submitText(
                new SubmitSkillTextRequest(prompt.getId(), "Bonjour Madame.", null, false, null)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("expression orale");
        verify(attemptManager, never()).save(any());
    }

    @Test
    void audioSubmissionOnAWrittenPromptIsRejected() {
        SkillPrompt prompt = prompt(SkillSection.EE);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        assertThatThrownBy(() -> service.submitAudio(
                prompt.getId(), audioFile(), 30, null, false, null))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("expression écrite");
        verify(whisperService, never()).transcribe(any(), any());
    }

    @Test
    void unknownOrInactivePromptIsNotFound() {
        UUID promptId = UUID.randomUUID();
        when(promptManager.findActiveByIdWithSkill(promptId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.submitText(
                new SubmitSkillTextRequest(promptId, "Bonjour.", null, false, null)))
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
                new SubmitSkillTextRequest(prompt.getId(), tooLong, null, false, null)))
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

        service.submitText(new SubmitSkillTextRequest(prompt.getId(), "Bonjour cher voisin", null, false, null));

        assertThat(captureSaved().getWordsCount()).isEqualTo(3);
    }

    @Test
    void blankWrittenProductionIsRejected() {
        SkillPrompt prompt = prompt(SkillSection.EE);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        assertThatThrownBy(() -> service.submitText(
                new SubmitSkillTextRequest(prompt.getId(), "   ", null, false, null)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void recordingBeyondTheDurationCapIsRejected() {
        SkillPrompt prompt = prompt(SkillSection.EO);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        assertThatThrownBy(() -> service.submitAudio(
                prompt.getId(), audioFile(), props.getAnalysis().getMaxAudioDurationSeconds() + 1,
                null, false, null))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("180 secondes");
    }

    @Test
    void missingRecordingIsRejected() {
        SkillPrompt prompt = prompt(SkillSection.EO);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        assertThatThrownBy(() -> service.submitAudio(prompt.getId(), null, 30, null, false, null))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Aucun enregistrement");
    }

    // ------------------------------------------------------------------------
    // Verrou d'acces (freemium du 2026-08-10) — le client ne decide jamais
    // ------------------------------------------------------------------------

    @Test
    void produireSurUnSujetVerrouilleEstRefuseAvantToutTraitement() {
        SkillPrompt prompt = prompt(SkillSection.EE);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));
        doThrow(new AccessDeniedException(SkillAccessService.LOCKED_MESSAGE))
                .when(accessService).assertCanProduce(userId, prompt);

        assertThatThrownBy(() -> service.submitText(new SubmitSkillTextRequest(
                prompt.getId(), "Bonjour Madame, je vous écris…", null, false, null)))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage(SkillAccessService.LOCKED_MESSAGE);
        // Rien n'est persiste, rien n'est envoye au correcteur.
        verify(attemptManager, never()).save(any());
        verify(analysisRunner, never()).runAsync(any());
    }

    @Test
    void produireSurUnSujetOuvertResteAccepte() {
        SkillPrompt prompt = prompt(SkillSection.EE);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        service.submitText(new SubmitSkillTextRequest(
                prompt.getId(), "Bonjour Madame, je vous écris…", null, false, null));

        verify(accessService).assertCanProduce(userId, prompt);
        assertThat(captureSaved().getStatut()).isEqualTo(SkillAttemptStatut.RECORDED);
    }

    @Test
    void unEnregistrementOralSurUnSujetVerrouilleNEstMemePasUploade() {
        SkillPrompt prompt = prompt(SkillSection.EO);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));
        doThrow(new AccessDeniedException(SkillAccessService.LOCKED_MESSAGE))
                .when(accessService).assertCanProduce(userId, prompt);

        assertThatThrownBy(() -> service.submitAudio(prompt.getId(), audioFile(), 30, null, false, null))
                .isInstanceOf(AccessDeniedException.class);
        verify(whisperService, never()).transcribe(any(), any());
    }

    @Test
    void demanderLAnalyseDUneProductionDevenueVerrouilleeEstRefuse() {
        SkillPrompt prompt = prompt(SkillSection.EE);
        UserSkillAttempt attempt = new UserSkillAttempt();
        attempt.setId(UUID.randomUUID());
        attempt.setUser(user);
        attempt.setSkillPrompt(prompt);
        attempt.setStatut(SkillAttemptStatut.RECORDED);
        when(attemptManager.findByIdWithPrompt(attempt.getId())).thenReturn(Optional.of(attempt));
        doThrow(new AccessDeniedException(SkillAccessService.LOCKED_MESSAGE))
                .when(accessService).assertCanProduce(userId, prompt);

        assertThatThrownBy(() -> service.analyse(attempt.getId()))
                .isInstanceOf(AccessDeniedException.class);
        verify(analysisAccessService, never()).assertCanAnalyse(any());
        verify(analysisRunner, never()).runAsync(any());
    }

    @Test
    void relancerUneAnalyseSurUnSujetVerrouilleEstRefuse() {
        SkillPrompt prompt = prompt(SkillSection.EE);
        UserSkillAttempt attempt = new UserSkillAttempt();
        attempt.setId(UUID.randomUUID());
        attempt.setUser(user);
        attempt.setSkillPrompt(prompt);
        attempt.setStatut(SkillAttemptStatut.FAILED);
        attempt.setAnalysisRequested(true);
        when(attemptManager.findByIdWithPrompt(attempt.getId())).thenReturn(Optional.of(attempt));
        doThrow(new AccessDeniedException(SkillAccessService.LOCKED_MESSAGE))
                .when(accessService).assertCanProduce(userId, prompt);

        assertThatThrownBy(() -> service.retry(attempt.getId()))
                .isInstanceOf(AccessDeniedException.class);
        assertThat(attempt.getRetryCount()).isZero();
        verify(analysisRunner, never()).runAsync(any());
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
                SkillSelfEvaluation.INCERTAIN, false, null));

        UserSkillAttempt saved = captureSaved();
        assertThat(saved.getStatut()).isEqualTo(SkillAttemptStatut.RECORDED);
        assertThat(saved.isAnalysisRequested()).isFalse();
        assertThat(saved.getSelfEvaluation()).isEqualTo(SkillSelfEvaluation.INCERTAIN);
        // Ni verification de quota, ni appel au correcteur.
        verify(analysisAccessService, never()).assertCanAnalyse(any());
        verify(analysisRunner, never()).runAsync(any());
    }

    @Test
    void requestedAnalysisChecksTheQuotaMarksTheAttemptAndStartsThePipeline() {
        SkillPrompt prompt = prompt(SkillSection.EE);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        service.submitText(new SubmitSkillTextRequest(
                prompt.getId(), "Bonjour, je vous préviens du changement.", null, true, null));

        UserSkillAttempt saved = captureSaved();
        assertThat(saved.getStatut()).isEqualTo(SkillAttemptStatut.SUBMITTED);
        // Consomme a l'ACCEPTATION, pas au succes : sinon un retry gratuit apres
        // echec offrirait des analyses supplementaires.
        assertThat(saved.isAnalysisRequested()).isTrue();
        verify(analysisAccessService).assertCanAnalyse(userId);
        verify(analysisRunner).runAsync(saved.getId());
    }

    @Test
    void anExhaustedQuotaBlocksBeforeAnythingIsPersisted() {
        SkillPrompt prompt = prompt(SkillSection.EE);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));
        doThrow(new AccessDeniedException("épuisé")).when(analysisAccessService).assertCanAnalyse(userId);

        assertThatThrownBy(() -> service.submitText(new SubmitSkillTextRequest(
                prompt.getId(), "Bonjour.", null, true, null)))
                .isInstanceOf(AccessDeniedException.class);

        verify(attemptManager, never()).save(any());
        verify(analysisRunner, never()).runAsync(any());
    }

    /**
     * L'AUDIO N'EST JAMAIS STOCKE : il est transcrit PENDANT la requete, puis
     * efface. Ce que la ligne conserve, c'est la transcription — jamais une cle.
     */
    @Test
    void oralAudioIsTranscribedInRequestAndNoObjectKeyIsEverStored() {
        SkillPrompt prompt = prompt(SkillSection.EO);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));
        when(whisperService.transcribe(any(), any())).thenReturn(
                new WhisperTranscriptionClient.WhisperResult("je voudrais reserver", "fr", 37));

        service.submitAudio(prompt.getId(), audioFile(), 40, null, true, null);

        UserSkillAttempt saved = captureSaved();
        assertThat(saved.getAudioObjectKey()).isNull();
        assertThat(saved.getTranscript()).isEqualTo("je voudrais reserver");
        // La duree DETECTEE fait foi sur celle annoncee par le client (40).
        assertThat(saved.getAudioDurationSec()).isEqualTo(37);
        assertThat(saved.getWrittenProduction()).isNull();
        verify(analysisRunner).runAsync(saved.getId());
    }

    /**
     * ⚠️ REGLE REVOQUEE : « on ne paie pas Whisper pour un audio que personne ne
     * corrigera ». Sans audio conserve, ne pas transcrire ne laisserait RIEN de
     * la production — on transcrit donc meme sans analyse demandee.
     */
    @Test
    void oralAudioIsTranscribedEvenWithoutAnAnalysisRequest() {
        SkillPrompt prompt = prompt(SkillSection.EO);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));
        when(whisperService.transcribe(any(), any())).thenReturn(
                new WhisperTranscriptionClient.WhisperResult("quelques phrases", "fr", 20));

        service.submitAudio(prompt.getId(), audioFile(), 40, null, false, null);

        UserSkillAttempt saved = captureSaved();
        assertThat(saved.getStatut()).isEqualTo(SkillAttemptStatut.RECORDED);
        assertThat(saved.getTranscript()).isEqualTo("quelques phrases");
        verify(whisperService).transcribe(any(), any());
        verify(analysisRunner, never()).runAsync(any());
    }

    /** Les octets sont effaces meme quand la transcription echoue, et rien n'est insere. */
    @Test
    void oralBytesAreWipedAndNothingIsInsertedWhenTranscriptionFails() {
        SkillPrompt prompt = prompt(SkillSection.EO);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));
        java.util.concurrent.atomic.AtomicReference<byte[]> vus = new java.util.concurrent.atomic.AtomicReference<>();
        when(whisperService.transcribe(any(), any())).thenAnswer(inv -> {
            vus.set(inv.getArgument(0));
            throw new com.sejourfr.app.exception.TranscriptionException("Whisper indisponible");
        });

        assertThatThrownBy(() -> service.submitAudio(prompt.getId(), audioFile(), 40, null, true, null))
                .isInstanceOf(com.sejourfr.app.exception.TranscriptionException.class);

        assertThat(vus.get()).containsOnly((byte) 0);
        verify(attemptManager, never()).save(any());
        verify(analysisRunner, never()).runAsync(any());
    }

    @Test
    void everySubmissionGoesThroughTheRateLimit() {
        SkillPrompt prompt = prompt(SkillSection.EE);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        service.submitText(new SubmitSkillTextRequest(prompt.getId(), "Bonjour.", null, false, null));

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
        verify(analysisRunner).runAsync(attempt.getId());
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
        verify(analysisRunner).runAsync(attempt.getId());
        verify(rateLimitGuard).checkSkillAttempt(userId);
    }

    /**
     * Une production orale rendue sans analyse est desormais DEJA transcrite :
     * l'analyse part du texte, il n'y a plus rien a transcrire.
     */
    @Test
    void analysingAnOralProductionStartsFromItsTranscript() {
        UserSkillAttempt attempt = ownedAttempt(SkillAttemptStatut.RECORDED, false);
        attempt.setWrittenProduction(null);
        attempt.setTranscript("je voudrais reserver une salle");
        attempt.getSkillPrompt().setSection(SkillSection.EO);
        when(attemptManager.findByIdWithPrompt(attempt.getId())).thenReturn(Optional.of(attempt));

        service.analyse(attempt.getId());

        verify(analysisRunner).runAsync(attempt.getId());
    }

    /**
     * LEGACY : une tentative orale enregistree AVANT le changement n'a ni
     * transcription ni audio relisible. On la refuse AVANT assertCanAnalyse —
     * le candidat ne doit pas y perdre une de ses 3 analyses offertes.
     */
    @Test
    void analysingALegacyOralProductionWithoutTranscriptCostsNoQuota() {
        UserSkillAttempt attempt = ownedAttempt(SkillAttemptStatut.RECORDED, false);
        attempt.setWrittenProduction(null);
        attempt.setAudioObjectKey("submissions/legacy.webm");
        attempt.setTranscript(null);
        attempt.getSkillPrompt().setSection(SkillSection.EO);
        when(attemptManager.findByIdWithPrompt(attempt.getId())).thenReturn(Optional.of(attempt));

        assertThatThrownBy(() -> service.analyse(attempt.getId()))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Refaites le sujet");

        verify(analysisAccessService, never()).assertCanAnalyse(any());
        verify(attemptManager, never()).save(any());
        verify(analysisRunner, never()).runAsync(any());
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
        verify(analysisRunner, never()).runAsync(any());
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
        verify(analysisRunner, never()).runAsync(any());
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

    // ------------------------------------------------------------------------
    // Idempotence (V046) — la cle rendue par le client
    // ------------------------------------------------------------------------

    /**
     * A l'oral, c'est la ou la cle rapporte le plus : le rejeu passe AVANT
     * Whisper, qui est facture a la duree de l'audio.
     */
    @Test
    void uneProductionOraleRejoueeNeRepasseNiParWhisperNiParLeLlm() {
        UUID cle = UUID.randomUUID();
        UserSkillAttempt deja = new UserSkillAttempt();
        deja.setId(UUID.randomUUID());
        when(attemptManager.findByClientKey(userId, cle)).thenReturn(Optional.of(deja));

        service.submitAudio(UUID.randomUUID(), audioFile(), 40, null, true, cle);

        verify(whisperService, never()).transcribe(any(), any());
        verify(attemptManager, never()).save(any());
        verify(analysisRunner, never()).runAsync(any());
        verify(rateLimitGuard, never()).checkSkillAttempt(any());
    }

    /** A l'ecrit, le rejeu ne reconsomme pas non plus le quota d'analyses. */
    @Test
    void uneProductionEcriteRejoueeNeConsommePasDeSecondeAnalyse() {
        UUID cle = UUID.randomUUID();
        UserSkillAttempt deja = new UserSkillAttempt();
        deja.setId(UUID.randomUUID());
        when(attemptManager.findByClientKey(userId, cle)).thenReturn(Optional.of(deja));

        service.submitText(new SubmitSkillTextRequest(
                UUID.randomUUID(), "Bonjour Madame.", null, true, cle));

        verify(attemptManager, never()).save(any());
        verify(analysisRunner, never()).runAsync(any());
        verify(analysisAccessService, never()).assertCanAnalyse(any());
    }

    /** Sans cle, rien ne change : les clients deja installes continuent. */
    @Test
    void sansCleLeComportementEstInchange() {
        SkillPrompt prompt = prompt(SkillSection.EE);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));

        service.submitText(new SubmitSkillTextRequest(prompt.getId(), "Bonjour.", null, false, null));

        // La cle nulle traverse le manager, qui rend vide sans requeter : c'est
        // LUI qui porte cette garde, pour que tout appelant en beneficie.
        verify(attemptManager).save(any());
    }

    /** La cle est ecrite sur la ligne : sans ca le rejeu ne retrouverait rien. */
    @Test
    void laCleEstPerisisteeSurLaProduction() {
        UUID cle = UUID.randomUUID();
        SkillPrompt prompt = prompt(SkillSection.EE);
        when(promptManager.findActiveByIdWithSkill(prompt.getId())).thenReturn(Optional.of(prompt));
        when(attemptManager.findByClientKey(userId, cle)).thenReturn(Optional.empty());

        service.submitText(new SubmitSkillTextRequest(prompt.getId(), "Bonjour.", null, false, cle));

        ArgumentCaptor<UserSkillAttempt> capture = ArgumentCaptor.forClass(UserSkillAttempt.class);
        verify(attemptManager).save(capture.capture());
        assertThat(capture.getValue().getClientSubmissionId()).isEqualTo(cle);
    }

    private static SkillAttemptDto dummyDto() {
        return new SkillAttemptDto(UUID.randomUUID(), UUID.randomUUID(), "EE1-C1-S1",
                SkillAttemptStatut.RECORDED, false, null, null, null, null, null, null,
                null, null, null);
    }
}

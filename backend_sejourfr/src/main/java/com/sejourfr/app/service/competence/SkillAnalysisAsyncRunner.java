package com.sejourfr.app.service.competence;

import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.service.LearningPlanObservationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.UUID;
import java.util.concurrent.CompletableFuture;

/**
 * Execute l'analyse ciblee en arriere-plan, apres la persistance de la
 * tentative. Le caller ({@code SkillAttemptService}) declenche cet appel via le
 * proxy Spring, ce qui est la condition pour que {@code @Async} prenne effet
 * (un appel a soi-meme dans la meme classe serait synchrone sans le dire).
 *
 * <p>Consequence pour les fronts : {@code POST /api/skill-attempts} repond
 * immediatement, et le candidat voit sa production affichee pendant que
 * l'analyse tourne. Il poll ensuite
 * {@code GET /api/skill-attempts/{id}} jusqu'a {@code EVALUATED} ou
 * {@code FAILED}.
 *
 * <p><b>Pas de transaction englobante ici, volontairement.</b> La transcription
 * et l'analyse portent chacune la leur. Une transaction externe serait marquee
 * rollback-only par l'interceptor du service en echec, et le {@code catch}
 * ci-dessous se solderait par un {@code UnexpectedRollbackException} au retour —
 * la tentative resterait alors bloquee en {@code EVALUATING}, sans FAILED
 * durable. C'est pour cette meme raison que
 * {@link SkillAnalysisFailureRecorder} est en {@code REQUIRES_NEW}. Meme
 * invariant que {@code ProductionPipelineAsyncRunner} : ne pas reintroduire de
 * transaction ici.
 *
 * <p>Aucune exception ne remonte au {@code TaskExecutor} : elles seraient
 * loggees sans que personne ne puisse agir, et la tentative resterait en vol.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SkillAnalysisAsyncRunner {

    private final UserSkillAttemptManager attemptManager;
    private final SkillTranscriptionService transcriptionService;
    private final CompetenceAnalysisService analysisService;
    private final SkillAnalysisFailureRecorder failureRecorder;
    private final LearningPlanObservationService learningPlanObservationService;

    /**
     * @param estOral vrai pour une production orale : la transcription Whisper
     *                precede alors l'analyse. Elle n'est declenchee que sur
     *                cette voie — une tentative sans analyse n'arrive jamais
     *                ici, donc on ne paie jamais Whisper pour rien.
     */
    @Async
    public CompletableFuture<Void> runAsync(UUID attemptId, boolean estOral) {
        // JOIN FETCH : la tentative est lue hors de la session Hibernate du
        // thread appelant, deja fermee quand on arrive ici.
        UserSkillAttempt attempt = attemptManager.findByIdWithPrompt(attemptId).orElse(null);
        if (attempt == null) {
            log.warn("Tentative de competence introuvable pour l'analyse async : {}", attemptId);
            return CompletableFuture.completedFuture(null);
        }
        try {
            if (estOral && attempt.getTranscript() == null) {
                transcriptionService.transcribe(attemptId);
            } else {
                attempt.setStatut(SkillAttemptStatut.EVALUATING);
                attemptManager.save(attempt);
            }
            analysisService.analyse(attemptId);
            // L'analyse ciblée est déjà durable et EVALUATED à ce stade. Le
            // Plan est un enrichissement best-effort : une panne de son écriture
            // ne doit jamais rétrograder la tentative en FAILED ni autoriser un
            // retry payant d'une analyse qui a réussi.
            try {
                learningPlanObservationService.recordSkillAttempt(attemptId);
            } catch (Exception observationError) {
                log.warn("Observation Plan ignorée pour la tentative {} : {}",
                        attemptId, observationError.getMessage());
            }
            log.info("Analyse de competence terminee pour la tentative {}", attemptId);
        } catch (Exception e) {
            log.warn("Analyse de competence en echec pour la tentative {} : {}",
                    attemptId, e.getMessage(), e);
            // Toujours une transaction NEUVE : elle isole FAILED d'un eventuel
            // rollback declenche dans un service appele.
            failureRecorder.markFailed(attemptId, e.getMessage());
        }
        return CompletableFuture.completedFuture(null);
    }
}

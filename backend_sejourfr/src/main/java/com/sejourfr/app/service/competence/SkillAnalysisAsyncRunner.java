package com.sejourfr.app.service.competence;

import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.exception.TranscriptionException;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.service.LearningPlanObservationService;
import com.sejourfr.app.service.competence.niveauvise.CompetenceNiveauViseService;
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
    private final CompetenceAnalysisService analysisService;
    private final CompetenceNiveauViseService niveauViseService;
    private final SkillAnalysisFailureRecorder failureRecorder;
    private final LearningPlanObservationService learningPlanObservationService;

    /**
     * <p><b>Aucune transcription ici</b> : depuis que l'audio n'est plus stocke,
     * elle se fait pendant la requete de soumission — c'est le seul moment ou
     * les octets existent. Ce runner part donc toujours d'une production
     * ECRITE : le texte du candidat en EE, sa transcription en EO. Une tentative
     * orale qui arriverait sans transcription est un etat impossible depuis la
     * soumission, sauf sur une ligne anterieure au changement : on echoue
     * clairement plutot que d'analyser du vide.
     */
    @Async
    public CompletableFuture<Void> runAsync(UUID attemptId) {
        // JOIN FETCH : la tentative est lue hors de la session Hibernate du
        // thread appelant, deja fermee quand on arrive ici.
        UserSkillAttempt attempt = attemptManager.findByIdWithPrompt(attemptId).orElse(null);
        if (attempt == null) {
            log.warn("Tentative de competence introuvable pour l'analyse async : {}", attemptId);
            return CompletableFuture.completedFuture(null);
        }
        try {
            if (attempt.getSkillPrompt().getSection() == SkillSection.EO
                    && (attempt.getTranscript() == null || attempt.getTranscript().isBlank())) {
                throw new TranscriptionException(
                        "Cet enregistrement n'a pas pu être retranscrit et n'a pas été conservé : "
                                + "refaites le sujet.");
            }
            attempt.setStatut(SkillAttemptStatut.EVALUATING);
            attemptManager.save(attempt);
            analysisService.analyse(attemptId);
            // SECOND APPEL, séparé de l'analyse : « pour viser X ». Il tourne
            // ICI, après que l'analyse est persistée et hors de sa transaction —
            // c'est ce qui garantit que le correcteur n'a jamais appris quel
            // niveau vise le candidat. Le service n'échoue jamais : au pire le
            // bloc est absent, et l'écran reste utile sans lui.
            niveauViseService.enrichir(attemptId);
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

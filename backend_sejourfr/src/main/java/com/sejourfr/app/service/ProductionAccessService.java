package com.sejourfr.app.service;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

/**
 * Gardes d'accès communes aux DEUX voies de notation d'une production EE/EO :
 * la voie asynchrone (audio / texte déposés puis évalués) et la voie temps réel
 * (dialogue avec l'examinateur vocal). Elles étaient auparavant écrites dans la
 * seule voie asynchrone ; la voie temps réel arrivait donc sans aucun contrôle
 * (épreuve terminée, chrono écoulé, quota freemium) et pouvait noter dans une
 * sous-épreuve pré-terminée par le verrou freemium.
 *
 * <p>Deux familles de règles, volontairement séparées :
 * <ul>
 *   <li>{@link #assertCanSubmit} — cohérence de la SESSION : propriété,
 *       épreuve terminée, chrono, correspondance épreuve tâche ⇄ attempt, et
 *       plafond « une soumission par tâche » en session d'examen ;</li>
 *   <li>{@link #enforceQuota} — budget FREEMIUM (essais gratuits EE/EO).</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
public class ProductionAccessService {

    /** Grâce après expiration du chrono d'épreuve (latence de l'auto-soumission front). */
    static final int SUBMIT_GRACE_SECONDS = 60;

    /** Essais d'entrainement par epreuve pour les comptes non-Premium (a vie). */
    private static final int FREE_TRAINING_PER_EPREUVE = 1;

    private final SubscriptionService subscriptionService;
    private final AttemptManager attemptManager;
    private final ProductionSubmissionManager submissionManager;
    private final DiagnosticSessionManager diagnosticSessionManager;

    /**
     * Toutes les gardes de session à passer avant de créer une soumission EE/EO,
     * quelle que soit la voie (async ou temps réel).
     *
     * @param userId  utilisateur courant
     * @param attempt session visée (déjà chargée)
     * @param task    tâche soumise
     */
    public void assertCanSubmit(UUID userId, Attempt attempt, ProductionTask task) {
        assertOwnership(userId, attempt);
        assertPurposeAndDiagnosticPair(userId, attempt, task);
        assertNotFinished(attempt);
        assertWithinTimeLimit(attempt);
        assertEpreuveMatches(attempt, task);
        assertTacheNotAlreadySubmitted(attempt, task);
    }

    /**
     * Vérif d'appartenance (IDOR) : sans ce check, un attaquant peut deviner un
     * UUID d'attempt actif d'une victime et y poster ses propres productions,
     * polluant son examen blanc (sous-épreuve finalisée prématurément, niveau
     * CECRL calculé sur les productions de l'attaquant).
     */
    private void assertOwnership(UUID userId, Attempt attempt) {
        if (attempt.getUser() == null || !attempt.getUser().getId().equals(userId)) {
            throw new AccessDeniedException("Cette session ne vous appartient pas");
        }
    }

    /**
     * Épreuve déjà finalisée (fin de session, expiration du chrono, ou
     * sous-attempt pré-terminé par le verrou freemium d'un examen complet) :
     * plus aucune soumission.
     */
    private void assertNotFinished(Attempt attempt) {
        if (attempt.getFinishedAt() != null) {
            throw new BusinessException("Cette épreuve est terminée — soumission refusée.");
        }
    }

    /**
     * Chrono d'épreuve (sessions d'examen EE et EO). Grâce de 60 s pour couvrir
     * la latence réseau de l'auto-soumission front à 0:00.
     */
    private void assertWithinTimeLimit(Attempt attempt) {
        if (attempt.getTimeLimitSeconds() == null || attempt.getStartedAt() == null) return;
        Instant deadline = attempt.getStartedAt()
                .plusSeconds(attempt.getTimeLimitSeconds() + SUBMIT_GRACE_SECONDS);
        if (Instant.now().isAfter(deadline)) {
            throw new BusinessException("Le temps de l'épreuve est écoulé — soumission refusée.");
        }
    }

    /**
     * La tâche doit relever de l'épreuve de la session. Sans ce contrôle, une
     * production orale était acceptée, évaluée et comptée dans une session
     * d'expression écrite (et inversement) : dans un examen TCF complet, cela
     * auto-finalisait la mauvaise sous-épreuve et lui posait un niveau CECRL
     * faux — or c'est ce niveau qui fait foi.
     */
    private void assertEpreuveMatches(Attempt attempt, ProductionTask task) {
        EpreuveType attendue = attempt.getEpreuve();
        if (attendue != task.getEpreuve()) {
            throw new BusinessException(
                    "Cette tâche relève de l'épreuve " + task.getEpreuve()
                            + " ; la session ouverte est une épreuve " + attendue
                            + ". Soumission refusée.");
        }
    }

    /**
     * Session d'examen : un examen, c'est 3 tâches, une fois chacune. Sans ce
     * plafond, rien ne borne le nombre de productions (donc d'évaluations IA
     * payantes) rattachées à une même session — la composition renvoyée par
     * {@code /production-exam-tasks} n'étant jamais opposée à ce qui est soumis.
     * L'entraînement libre n'est pas concerné (il a son propre quota freemium).
     */
    private void assertTacheNotAlreadySubmitted(Attempt attempt, ProductionTask task) {
        if (task.isDiagnostic()) {
            if (submissionManager.countByAttempt(attempt.getId()) > 0) {
                throw new BusinessException("Cette étape du diagnostic a déjà été rendue.");
            }
            return;
        }
        if (!isExamSession(attempt)) return;
        Short tache = task.getTacheNumero();
        if (tache == null) return;
        if (submissionManager.countByAttemptAndTache(attempt.getId(), tache) > 0) {
            throw new BusinessException(
                    "La tâche " + tache + " de cet examen a déjà été rendue — une seule "
                            + "production par tâche.");
        }
    }

    /** Session d'examen blanc production : slot posé au start, ou sous-épreuve d'un examen complet. */
    public static boolean isExamSession(Attempt attempt) {
        return attempt.getSlotNumber() != null || attempt.getParentAttempt() != null;
    }

    /**
     * Budget freemium EE/EO (règles validées 2026-06-06) — Premium TCF :
     * illimité. Gratuit : 1 essai d'entraînement par épreuve à vie ; les
     * soumissions d'une session d'examen blanc production ou d'un examen TCF
     * complet ne comptent pas dans ce quota ; refaire l'examen blanc (2ᵉ
     * session) consomme les essais d'entraînement restants.
     */
    public void enforceQuota(UUID userId, EpreuveType epreuve, UUID attemptId) {
        if (subscriptionService.hasTcf(userId)) return;

        if (attemptId != null) {
            Attempt attempt = attemptManager.findById(attemptId).orElse(null);
            if (attempt != null) {
                // Epreuve deja terminee : aucune soumission. Couvre les EE/EO
                // verrouillees d'un examen complet gratuit (pre-terminees au
                // start) — empeche un client de contourner le verrou.
                if (attempt.getFinishedAt() != null) {
                    throw new AccessDeniedException(
                            "Cette epreuve est terminee. L'expression ecrite et orale ne sont "
                                    + "offertes qu'une fois ; passez Premium pour continuer.");
                }
                if (isExamSession(attempt)) {
                    return;
                }
            }
        }

        // Refaire l'examen blanc (2e session) consomme les essais restants.
        if (examSessionsConsumedTraining(userId)) {
            throw new AccessDeniedException(
                    "Vos essais gratuits EE/EO ont ete utilises en refaisant l'examen blanc. "
                            + "Passez Premium pour continuer.");
        }

        if (trainingQuotaExhausted(userId, epreuve)) {
            throw new AccessDeniedException(
                    "Quota gratuit atteint pour " + epreuve.getLabel() + " (" + FREE_TRAINING_PER_EPREUVE
                            + " essai a vie). Passez Premium pour continuer."
            );
        }
    }

    /**
     * Le meme budget freemium, <b>en lecture</b> : « ce candidat peut-il encore
     * produire librement sur cette epreuve ? ».
     *
     * <p>Sert a poser le cadenas sur la verification en situation du Plan
     * ({@code ReassessmentExerciseSelector}) sans rien tenter ni rien consommer.
     * Il partage ses deux conditions avec {@link #enforceQuota} — deux copies
     * auraient fini par afficher un sujet ouvert que le serveur refuse, ou
     * l'inverse. Le sujet reste <b>designe</b> meme verrouille : savoir quoi
     * travailler est ce que le Plan apporte.
     */
    @Transactional(readOnly = true)
    public boolean isTrainingLocked(UUID userId, EpreuveType epreuve) {
        if (subscriptionService.hasTcf(userId)) return false;
        return examSessionsConsumedTraining(userId) || trainingQuotaExhausted(userId, epreuve);
    }

    /**
     * Budget freemium des <b>sessions d'examen blanc production</b> (EE/EO, 3
     * taches), <b>opposable</b> : 1&#x2071;&#x2ba0; session gratuite, une 2&#x1d49;
     * toleree qui consomme les essais d'entrainement restants, au-dela premium.
     *
     * <p>Appele par {@code AttemptService.startProductionAttempt}. Il partage sa
     * condition avec {@link #isProductionExamLocked}, sa jumelle en lecture :
     * deux copies auraient fini par afficher au Plan un jalon ouvert que le
     * serveur refuse — ou l'inverse.
     */
    public void assertCanStartProductionExam(UUID userId) {
        if (isProductionExamLocked(userId)) {
            throw new AccessDeniedException(
                    "Examens blancs production réservés aux abonnés Intégral au-delà des "
                            + "essais gratuits.");
        }
    }

    /**
     * La meme regle <b>en lecture</b> : « ce candidat peut-il encore demarrer un
     * examen blanc d'epreuve ? ».
     *
     * <p>Sert a poser le cadenas du jalon d'epreuve du Plan
     * ({@code PlanMilestoneSelector}) sans rien tenter ni rien consommer. Le
     * jalon reste <b>designe</b> meme verrouille — savoir ou l'on en est fait
     * partie de ce que le Plan apporte.
     */
    @Transactional(readOnly = true)
    public boolean isProductionExamLocked(UUID userId) {
        if (subscriptionService.hasTcf(userId)) return false;
        return examSessionsConsumedTraining(userId);
    }

    /**
     * Les epreuves EE/EO d'un <b>examen blanc TCF complet</b> sont-elles
     * verrouillees pour ce candidat ?
     *
     * <p>Jumelle en lecture du calcul de {@code FullTcfExamService.start}, qui
     * pre-termine les sous-attempts EE/EO d'un compte gratuit ayant deja
     * consomme son freebie. L'examen complet reste demarrable (CO+CE), mais le
     * jalon du Plan porte sur le <b>transfert des productions</b> : c'est cette
     * partie-la qui est fermee, et c'est elle que le cadenas doit annoncer.
     */
    @Transactional(readOnly = true)
    public boolean isFullExamProductionLocked(UUID userId) {
        if (subscriptionService.hasTcf(userId)) return false;
        return submissionManager.hasFullExamProductionSubmission(userId);
    }

    private boolean examSessionsConsumedTraining(UUID userId) {
        return attemptManager.countProductionExamSessions(userId) >= 2;
    }

    private boolean trainingQuotaExhausted(UUID userId, EpreuveType epreuve) {
        return submissionManager.countTrainingByUserAndEpreuve(userId, epreuve)
                >= FREE_TRAINING_PER_EPREUVE;
    }

    /**
     * Bypass gratuit strictement borné au triplet task + attempt + session du
     * même utilisateur. Une task diagnostic seule ne suffit jamais.
     */
    public void enforceQuota(UUID userId, ProductionTask task, UUID attemptId) {
        if (task.isDiagnostic()) {
            Attempt attempt = attemptManager.findById(attemptId)
                    .orElseThrow(() -> new BusinessException("Session de production introuvable."));
            assertOwnership(userId, attempt);
            assertPurposeAndDiagnosticPair(userId, attempt, task);
            return;
        }
        if (attemptId != null && diagnosticSessionManager.existsByAttemptId(attemptId)) {
            throw new BusinessException("Cet attempt est réservé au diagnostic.");
        }
        enforceQuota(userId, task.getEpreuve(), attemptId);
    }

    private void assertPurposeAndDiagnosticPair(
            UUID userId, Attempt attempt, ProductionTask task) {
        var session = diagnosticSessionManager.findByAttemptIdWithContent(attempt.getId()).orElse(null);
        if (!task.isDiagnostic()) {
            if (session != null) {
                throw new BusinessException("Cet attempt est réservé au diagnostic.");
            }
            return;
        }
        if (session == null || session.getUser() == null
                || !userId.equals(session.getUser().getId())) {
            throw new BusinessException("Sujet diagnostic hors de votre session active.");
        }
        boolean written = attempt.getId().equals(session.getWrittenAttempt().getId())
                && task.getId().equals(session.getWrittenTask().getId())
                && attempt.getEpreuve() == EpreuveType.TCF_EE;
        boolean oral = attempt.getId().equals(session.getOralAttempt().getId())
                && task.getId().equals(session.getOralTask().getId())
                && attempt.getEpreuve() == EpreuveType.TCF_EO;
        if (!written && !oral) {
            throw new BusinessException("Le sujet ne correspond pas à cette étape du diagnostic.");
        }
        if (session.getStatus() == com.sejourfr.app.enums.DiagnosticSessionStatus.COMPLETED
                || session.getStatus() == com.sejourfr.app.enums.DiagnosticSessionStatus.ANALYZING) {
            throw new BusinessException("Ce diagnostic n'accepte plus de nouvelle production.");
        }
    }
}

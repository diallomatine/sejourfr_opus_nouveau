package com.sejourfr.app.service;

import com.sejourfr.app.dto.FullTcfExamResponse;
import com.sejourfr.app.dto.FullTcfExamSummaryResponse;
import com.sejourfr.app.dto.ProductionAttemptStartRequest;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.UserManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Orchestration d'un examen blanc TCF complet (les 4 épreuves enchaînées :
 * CO + CE + EE + EO, 90 min total). Un appel à {@link #start} crée un parent
 * portant {@code epreuve = TCF_COMPLET} et les 4 sous-attempts qui en
 * dépendent — atomique, transactionnel.
 *
 * <p>Le niveau CECRL final est le plancher des 4 sous-épreuves (règle
 * officielle TCF IRN). Il est posé à la {@link #finish finalisation}, à
 * condition que toutes les évaluations IA EE/EO soient remontées
 * {@code EVALUATED}.
 *
 * <p>Les sous-attempts vivent indépendamment :
 * <ul>
 *   <li>CO / CE : 25 QCM A2/B1/B2 progressifs, score pondéré X/50.
 *       Composition + chrono via {@link AttemptService#startModuleExamSubAttempt}.</li>
 *   <li>EE / EO : 3 tâches par épreuve, attached au sous-attempt EE/EO via
 *       {@code production_submissions.attempt_id}. Évaluation IA asynchrone.</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FullTcfExamService {

    /** Chrono global affiché côté mobile (parent). */
    private static final int FULL_EXAM_TOTAL_SECONDS = 90 * 60;

    /** Nombre de tâches attendues par épreuve productive (3 comme le vrai TCF). */
    private static final int EXPECTED_PRODUCTION_SUBMISSIONS = 3;

    private static final int HISTORY_LIMIT_DEFAULT = 20;
    private static final int HISTORY_LIMIT_MAX = 100;

    private final AttemptManager attemptManager;
    private final UserManager userManager;
    private final ProductionSubmissionManager productionSubmissionManager;
    private final AiEvaluationManager aiEvaluationManager;
    private final SubscriptionService subscriptionService;
    private final AttemptService attemptService;
    private final TcfLevelEstimatorService levelEstimator;

    // ------------------------------------------------------------------------
    // Création
    // ------------------------------------------------------------------------

    /**
     * Crée un examen blanc TCF complet : parent {@code TCF_COMPLET} + 4
     * sous-attempts (CO, CE, EE, EO) en une seule transaction. Réservé aux
     * comptes premium TCF.
     */
    @Transactional
    public FullTcfExamResponse start(UUID userId, Integer slotNumber) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new NotFoundException("User introuvable : " + userId));
        if (!subscriptionService.hasTcf(userId)) {
            throw new AccessDeniedException("L'examen blanc TCF complet est réservé aux abonnés TCF.");
        }

        Attempt parent = createParent(user, slotNumber);

        // CO + CE : QCM avec questions tirées + chrono propre.
        attemptService.startModuleExamSubAttempt(user, QuestionType.CO, parent);
        attemptService.startModuleExamSubAttempt(user, QuestionType.CE, parent);

        // EE + EO : attempts vides — les 3 tâches seront soumises via
        // /api/production-submissions avec attemptId du sous-attempt + parent.
        attemptService.startProductionAttempt(userId, new ProductionAttemptStartRequest(
                Module.TCF, EpreuveType.TCF_EE, parent.getId()));
        attemptService.startProductionAttempt(userId, new ProductionAttemptStartRequest(
                Module.TCF, EpreuveType.TCF_EO, parent.getId()));

        log.info("Full TCF exam created: parentId={} user={}", parent.getId(), userId);
        return buildResponse(parent);
    }

    private Attempt createParent(User user, Integer slotNumber) {
        Attempt parent = new Attempt();
        parent.setUser(user);
        parent.setType(AttemptType.MOCK_EXAM);
        parent.setModule(Module.TCF);
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        parent.setStatus(AttemptStatus.EN_COURS);
        parent.setTimeLimitSeconds(FULL_EXAM_TOTAL_SECONDS);
        parent.setStartedAt(Instant.now());
        // Slot UI (cf. V110) — propage le slot visé par l'utilisateur dans la
        // grille « 20 slots TCF complets ». Les sous-attempts CO/CE/EE/EO
        // restent à slot_number NULL (ils ne sont pas listés en grille).
        if (slotNumber != null) {
            parent.setSlotNumber(slotNumber);
        }
        // totalQuestions / score / passThreshold restent NULL — le parent
        // n'a pas de questions propres, le résultat est porté par finalCecrlLevel.
        return attemptManager.save(parent);
    }

    // ------------------------------------------------------------------------
    // Lecture
    // ------------------------------------------------------------------------

    /** Détail complet d'un examen blanc (parent + 4 sous-attempts + agrégation CECRL). */
    @Transactional(readOnly = true)
    public FullTcfExamResponse get(UUID userId, UUID parentAttemptId) {
        Attempt parent = loadParentAndCheck(userId, parentAttemptId);
        return buildResponse(parent);
    }

    /** Historique des examens blancs complets d'un user, tri descendant. */
    @Transactional(readOnly = true)
    public List<FullTcfExamSummaryResponse> listMine(UUID userId, int limit) {
        int safeLimit = Math.max(1, Math.min(HISTORY_LIMIT_MAX, limit));
        List<Attempt> parents = attemptManager.findByUserAndEpreuve(
                userId, EpreuveType.TCF_COMPLET, safeLimit);
        return parents.stream().map(this::buildSummary).toList();
    }

    /**
     * Dernier examen blanc complet TCF du user (parent TCF_COMPLET le plus
     * récent) avec son détail intégral — sub-attempts mappés, niveau CECRL
     * par épreuve, statut. Renvoie {@code null} si l'utilisateur n'en a
     * jamais lancé.
     *
     * <p>Utilisé par {@code MeService.progressionSummary} pour alimenter le
     * hero "Progression" mobile sans dupliquer la logique de calcul CECRL.
     */
    @Transactional(readOnly = true)
    public FullTcfExamResponse findLatestForUser(UUID userId) {
        List<Attempt> parents = attemptManager.findByUserAndEpreuve(
                userId, EpreuveType.TCF_COMPLET, 1);
        if (parents.isEmpty()) return null;
        return buildResponse(parents.get(0));
    }

    /**
     * Marque explicitement un sous-attempt EE/EO comme terminé, sans attendre
     * que toutes les submissions soient persistées. Appelé par le mobile
     * après la dernière tâche d'une épreuve productive en mode examen blanc
     * complet — le fire-and-forget de la 3ème submission étant encore en
     * cours côté backend, on ne peut pas se reposer sur le hook automatique
     * de {@code ProductionEvaluationService.finishSubAttemptIfFullExam}.
     *
     * <p>Sans cet appel explicite, le hub de progression mobile resterait
     * bloqué sur EE/EO comme étape courante tant que la 3ème évaluation IA
     * n'aurait pas rendu (~15 s).
     */
    @Transactional
    public FullTcfExamResponse markSubAttemptDone(
            UUID userId, UUID parentAttemptId, EpreuveType epreuve) {
        if (epreuve != EpreuveType.TCF_EE && epreuve != EpreuveType.TCF_EO) {
            throw new BusinessException(
                    "Seuls TCF_EE et TCF_EO peuvent être marqués via cet endpoint.");
        }
        Attempt parent = loadParentAndCheck(userId, parentAttemptId);

        List<Attempt> subs = attemptManager.findSubAttempts(parent.getId());
        Attempt sub = subs.stream()
                .filter(a -> a.getEpreuve() == epreuve)
                .findFirst()
                .orElseThrow(() -> new NotFoundException(
                        "Sous-attempt " + epreuve + " introuvable pour le parent " + parentAttemptId));

        if (sub.getFinishedAt() == null) {
            sub.setFinishedAt(Instant.now());
            sub.setStatus(com.sejourfr.app.enums.AttemptStatus.TERMINE);
            attemptManager.save(sub);
            log.info("Sub-attempt {} marked done explicitly (epreuve={}, parent={})",
                    sub.getId(), epreuve, parent.getId());
        }
        return buildResponse(parent);
    }

    // ------------------------------------------------------------------------
    // Finalisation
    // ------------------------------------------------------------------------

    /**
     * Marque l'examen comme terminé et persiste le niveau CECRL plancher si
     * toutes les évaluations IA EE/EO sont prêtes. Si une eval est encore en
     * cours, on pose seulement {@code finishedAt} — un appel ultérieur à
     * {@link #get} recalculera et persistera le niveau quand prêt.
     *
     * <p>Pré-requis : les 4 sous-attempts QCM/production ont leur
     * {@code finishedAt}. Les 3 submissions par épreuve productive ne sont pas
     * obligatoirement EVALUATED (le mobile attend en polling sur get).
     */
    @Transactional
    public FullTcfExamResponse finish(UUID userId, UUID parentAttemptId) {
        Attempt parent = loadParentAndCheck(userId, parentAttemptId);

        if (parent.getFinishedAt() == null) {
            List<Attempt> subs = attemptManager.findSubAttempts(parent.getId());
            for (Attempt s : subs) {
                if (s.getFinishedAt() == null) {
                    throw new BusinessException(
                            "Sous-attempt " + s.getEpreuve() + " pas encore terminé.");
                }
            }
            parent.setFinishedAt(Instant.now());
            parent.setStatus(AttemptStatus.TERMINE);
            attemptManager.save(parent);
        }

        // Tente de calculer le CECRL plancher dès maintenant (best effort).
        // Si une eval EE/EO n'est pas EVALUATED, finalCecrlLevel restera NULL.
        return buildAndPersistCecrlIfReady(parent);
    }

    // ------------------------------------------------------------------------
    // Internals
    // ------------------------------------------------------------------------

    private Attempt loadParentAndCheck(UUID userId, UUID parentAttemptId) {
        Attempt parent = attemptManager.findById(parentAttemptId)
                .orElseThrow(() -> new NotFoundException("Examen blanc introuvable : " + parentAttemptId));
        if (parent.getUser() == null || !parent.getUser().getId().equals(userId)) {
            throw new AccessDeniedException("Examen blanc n'appartient pas à l'utilisateur courant.");
        }
        if (parent.getEpreuve() != EpreuveType.TCF_COMPLET) {
            throw new BusinessException("Attempt " + parentAttemptId + " n'est pas un examen TCF complet.");
        }
        return parent;
    }

    /**
     * Construit la réponse + persiste {@code finalCecrlLevel} sur le parent
     * si toutes les conditions sont réunies (terminé + toutes les évals IA
     * EVALUATED). Utilisé par get/finish — la persistance n'a lieu qu'une
     * fois (idempotent).
     */
    private FullTcfExamResponse buildAndPersistCecrlIfReady(Attempt parent) {
        FullTcfExamResponse response = buildResponse(parent);
        if (parent.getFinishedAt() != null
                && parent.getFinalCecrlLevel() == null
                && response.status() == FullTcfExamResponse.FullTcfExamStatus.COMPLETED) {
            parent.setFinalCecrlLevel(response.finalCecrlLevel());
            attemptManager.save(parent);
        }
        return response;
    }

    private FullTcfExamResponse buildResponse(Attempt parent) {
        List<Attempt> subs = attemptManager.findSubAttempts(parent.getId());
        Map<EpreuveType, FullTcfExamResponse.SubAttempt> mapped = new EnumMap<>(EpreuveType.class);
        for (Attempt sub : subs) {
            mapped.put(sub.getEpreuve(), mapSubAttempt(sub));
        }

        // Ordre canonique d'affichage : CO → CE → EE → EO.
        List<FullTcfExamResponse.SubAttempt> ordered = new ArrayList<>();
        for (EpreuveType e : List.of(
                EpreuveType.TCF_CO, EpreuveType.TCF_CE,
                EpreuveType.TCF_EE, EpreuveType.TCF_EO)) {
            FullTcfExamResponse.SubAttempt s = mapped.get(e);
            if (s != null) ordered.add(s);
        }

        FullTcfExamResponse.FullTcfExamStatus status = computeStatus(parent, ordered);
        NiveauCecrl finalCecrl = parent.getFinalCecrlLevel();
        if (finalCecrl == null && status == FullTcfExamResponse.FullTcfExamStatus.COMPLETED) {
            finalCecrl = floorOfCecrls(ordered);
        }
        // Plafond IRN B2, y compris pour un finalCecrlLevel persisté avant le
        // cap (données antérieures où EE/EO pouvait remonter C1/C2).
        finalCecrl = levelEstimator.capB2(finalCecrl);
        return new FullTcfExamResponse(
                parent.getId(),
                parent.getStartedAt(),
                parent.getFinishedAt(),
                finalCecrl,
                status,
                ordered);
    }

    private FullTcfExamSummaryResponse buildSummary(Attempt parent) {
        FullTcfExamResponse full = buildResponse(parent);
        return new FullTcfExamSummaryResponse(
                full.id(), full.startedAt(), full.finishedAt(),
                full.finalCecrlLevel(), full.status(),
                parent.getSlotNumber());
    }

    private FullTcfExamResponse.SubAttempt mapSubAttempt(Attempt sub) {
        EpreuveType e = sub.getEpreuve();
        if (e == EpreuveType.TCF_CO || e == EpreuveType.TCF_CE) {
            // Source de vérité : cecrl_level posé à la finalisation par
            // TcfLevelEstimatorService. Fallback weightedScoreToCecrl pour les
            // sous-attempts finis avant V415 (cecrl_level encore NULL).
            NiveauCecrl level = null;
            if (sub.getFinishedAt() != null) {
                level = sub.getCecrlLevel() != null
                        ? sub.getCecrlLevel()
                        : weightedScoreToCecrl(sub.getWeightedScore(), sub.getMaxWeightedScore());
                level = levelEstimator.capB2(level);
            }
            return new FullTcfExamResponse.SubAttempt(
                    sub.getId(), e, sub.getFinishedAt(), level,
                    sub.getWeightedScore(), sub.getMaxWeightedScore(),
                    null, List.of());
        }
        // EE / EO : on compte les submissions EVALUATED pour le niveau CECRL
        // ET on remonte les ids des FAILED — le mobile propose un bouton
        // "Réessayer cette évaluation" qui appelle
        // POST /api/production-submissions/{id}/retry pour chacune. Tant
        // qu'une submission est FAILED, le bilan affiche un état partiel
        // (pas de tolérance silencieuse — l'utilisateur voit le problème).
        List<ProductionSubmission> submissions = productionSubmissionManager.findByAttemptId(sub.getId());
        int evaluatedCount = 0;
        NiveauCecrl floor = null;
        List<UUID> failedIds = new ArrayList<>();
        for (ProductionSubmission s : submissions) {
            if (s.getStatut() == SubmissionStatut.FAILED) {
                failedIds.add(s.getId());
                continue;
            }
            if (s.getStatut() != SubmissionStatut.EVALUATED) continue;
            AiEvaluation eval = aiEvaluationManager.findLatestBySubmissionId(s.getId()).orElse(null);
            if (eval == null || eval.getNiveauCecrl() == null) continue;
            evaluatedCount++;
            floor = levelEstimator.min(floor, eval.getNiveauCecrl());
        }
        // Plancher des 3 tâches, plafonné B2 (l'éval IA peut rendre C1/C2 ;
        // l'IRN ne classe pas au-delà). La note brute reste stockée intacte.
        NiveauCecrl level = evaluatedCount == EXPECTED_PRODUCTION_SUBMISSIONS
                ? levelEstimator.capB2(floor)
                : null;
        return new FullTcfExamResponse.SubAttempt(
                sub.getId(), e, sub.getFinishedAt(), level,
                null, null, evaluatedCount, failedIds);
    }

    private FullTcfExamResponse.FullTcfExamStatus computeStatus(
            Attempt parent, List<FullTcfExamResponse.SubAttempt> subs) {
        // 4 sous-attempts attendus (CO, CE, EE, EO). Si un manque ou n'est
        // pas fini → IN_PROGRESS.
        if (subs.size() < 4) return FullTcfExamResponse.FullTcfExamStatus.IN_PROGRESS;
        for (FullTcfExamResponse.SubAttempt s : subs) {
            if (s.finishedAt() == null) {
                return FullTcfExamResponse.FullTcfExamStatus.IN_PROGRESS;
            }
        }
        // Tous les sous-attempts ont `finishedAt`. Pour chaque épreuve productive,
        // on attend que TOUT soit décidé : soit EVALUATED, soit FAILED (qu'on
        // expose via `failedSubmissionIds` pour permettre un retry mobile).
        // PENDING_EVALUATIONS ne reste que pendant la fenêtre où le pipeline IA
        // tourne encore (statuts SUBMITTED / TRANSCRIBING / EVALUATING).
        for (FullTcfExamResponse.SubAttempt s : subs) {
            if (s.epreuve() == EpreuveType.TCF_EE || s.epreuve() == EpreuveType.TCF_EO) {
                int evaluated = s.submissionsCount() == null ? 0 : s.submissionsCount();
                int failed = s.failedSubmissionIds() == null ? 0 : s.failedSubmissionIds().size();
                if (evaluated + failed < EXPECTED_PRODUCTION_SUBMISSIONS) {
                    // Une ou plusieurs submissions encore en cours de pipeline.
                    return FullTcfExamResponse.FullTcfExamStatus.PENDING_EVALUATIONS;
                }
            } else if (s.cecrlLevel() == null) {
                // CO/CE sans niveau calculé : finishedAt présent mais weightedScore manquant.
                return FullTcfExamResponse.FullTcfExamStatus.PENDING_EVALUATIONS;
            }
        }
        return parent.getFinishedAt() != null
                ? FullTcfExamResponse.FullTcfExamStatus.COMPLETED
                : FullTcfExamResponse.FullTcfExamStatus.PENDING_EVALUATIONS;
    }

    /**
     * Conversion score pondéré CO/CE → niveau CECRL.
     * <ul>
     *   <li>≥ 80 % → B2</li>
     *   <li>≥ 60 % → B1</li>
     *   <li>≥ 40 % → A2</li>
     *   <li>≥ 20 % → A1</li>
     *   <li>&lt; 20 % → A1_NON_ATTEINT</li>
     * </ul>
     * Seuils calibrés sur l'esprit du TCF (60 % = B1 d'usage). Le vrai TCF
     * IRN utilise une grille interne non publique — ces seuils sont
     * volontairement simples pour rester explicables à l'utilisateur.
     */
    private NiveauCecrl weightedScoreToCecrl(Integer score, Integer maxScore) {
        if (score == null || maxScore == null || maxScore <= 0) return null;
        double ratio = (double) score / (double) maxScore;
        if (ratio >= 0.80) return NiveauCecrl.B2;
        if (ratio >= 0.60) return NiveauCecrl.B1;
        if (ratio >= 0.40) return NiveauCecrl.A2;
        if (ratio >= 0.20) return NiveauCecrl.A1;
        return NiveauCecrl.A1_NON_ATTEINT;
    }

    private NiveauCecrl floorOfCecrls(List<FullTcfExamResponse.SubAttempt> subs) {
        NiveauCecrl floor = null;
        for (FullTcfExamResponse.SubAttempt s : subs) {
            floor = levelEstimator.min(floor, s.cecrlLevel());
        }
        return floor;
    }
}

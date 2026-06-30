package com.sejourfr.app.service;

import com.sejourfr.app.dto.FullTcfExamResponse;
import com.sejourfr.app.dto.FullTcfExamSummaryResponse;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import lombok.RequiredArgsConstructor;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.stereotype.Component;

/**
 * Construit le read-model de l'examen blanc TCF complet ({@link FullTcfExamResponse}
 * / {@link FullTcfExamSummaryResponse}) à partir du parent {@code TCF_COMPLET} et
 * de ses 4 sous-attempts : mapping des sous-épreuves, calcul du statut agrégé,
 * scoring CO/CE et plancher CECRL. Sans état ni persistance — la finalisation
 * (pose de {@code finalCecrlLevel}) reste portée par {@link FullTcfExamService}.
 */
@Component
@RequiredArgsConstructor
public class FullTcfExamResponseBuilder {

    /** Nombre de tâches attendues par épreuve productive (3 comme le vrai TCF). */
    private static final int EXPECTED_PRODUCTION_SUBMISSIONS =
            ProductionBilanService.EXPECTED_TASKS_PER_EPREUVE;

    private final AttemptManager attemptManager;
    private final ProductionSubmissionManager productionSubmissionManager;
    private final TcfLevelEstimatorService levelEstimator;
    private final ProductionBilanService productionBilanService;

    public FullTcfExamResponse buildResponse(Attempt parent) {
        List<Attempt> subs = attemptManager.findSubAttempts(parent.getId());
        Map<EpreuveType, FullTcfExamResponse.SubAttempt> mapped = new EnumMap<>(EpreuveType.class);
        for (Attempt sub : subs) {
            mapped.put(sub.getEpreuve(), mapSubAttempt(sub, parent.isProductionLocked()));
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
                parent.getTimerStartedAt(),
                parent.getFinishedAt(),
                finalCecrl,
                status,
                ordered);
    }

    public FullTcfExamSummaryResponse buildSummary(Attempt parent) {
        FullTcfExamResponse full = buildResponse(parent);
        return new FullTcfExamSummaryResponse(
                full.id(), full.startedAt(), full.finishedAt(),
                full.finalCecrlLevel(), full.status(),
                parent.getSlotNumber());
    }

    private FullTcfExamResponse.SubAttempt mapSubAttempt(Attempt sub, boolean parentProductionLocked) {
        EpreuveType e = sub.getEpreuve();
        // Le verrou ne concerne que les épreuves productives EE/EO.
        boolean locked = parentProductionLocked
                && (e == EpreuveType.TCF_EE || e == EpreuveType.TCF_EO);
        if (e == EpreuveType.TCF_CO || e == EpreuveType.TCF_CE) {
            // Source de vérité : cecrl_level posé à la finalisation par
            // TcfLevelEstimatorService. Fallback weightedScoreToCecrl pour les
            // sous-attempts finis avant V416 (cecrl_level encore NULL).
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
                    null, List.of(), locked);
        }
        // EE / EO : on compte les tâches EVALUATED pour le niveau CECRL
        // ET on remonte les ids des FAILED — le mobile propose un bouton
        // "Réessayer cette évaluation" qui appelle
        // POST /api/production-submissions/{id}/retry pour chacune. Tant
        // qu'une submission est FAILED, le bilan affiche un état partiel
        // (pas de tolérance silencieuse — l'utilisateur voit le problème).
        List<ProductionSubmission> submissions = productionSubmissionManager.findByAttemptId(sub.getId());
        List<UUID> failedIds = new ArrayList<>();
        boolean inFlight = false;
        for (ProductionSubmission s : submissions) {
            if (s.getStatut() == SubmissionStatut.FAILED) {
                failedIds.add(s.getId());
            } else if (s.getStatut() != SubmissionStatut.EVALUATED) {
                inFlight = true; // SUBMITTED / TRANSCRIBING / EVALUATING
            }
        }
        Map<Integer, AiEvaluation> evalsByTache = productionBilanService.latestEvalsByTache(submissions);
        int evaluatedCount = evalsByTache.size();
        // Niveau d'épreuve = moyenne pondérée des compétences des 3 tâches
        // (cf. ProductionBilanService), plafonné B2. La note brute reste
        // stockée intacte. Épreuve TERMINÉE incomplète (chrono écoulé, abandon)
        // sans pipeline IA en cours ni FAILED à retenter : les tâches non
        // rendues comptent 0 (« le reste noté 0 ») — y compris zéro soumission
        // → A1_NON_ATTEINT.
        NiveauCecrl level;
        if (evaluatedCount == EXPECTED_PRODUCTION_SUBMISSIONS) {
            level = levelEstimator.capB2(productionBilanService.bilanEpreuve(evalsByTache));
        } else if (sub.getFinishedAt() != null && !inFlight && failedIds.isEmpty()) {
            level = levelEstimator.capB2(productionBilanService.bilanEpreuveTerminee(evalsByTache));
        } else {
            level = null;
        }
        return new FullTcfExamResponse.SubAttempt(
                sub.getId(), e, sub.getFinishedAt(), level,
                null, null, evaluatedCount, failedIds, locked);
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
                // PENDING uniquement s'il reste une submission RÉELLEMENT dans le
                // pipeline IA (SUBMITTED / TRANSCRIBING / EVALUATING). Un examen
                // abandonné avec moins de 3 (voire 0) submissions n'a rien en
                // cours → il est aussi complet qu'il le sera. Les FAILED sont
                // terminales (retry exposé via failedSubmissionIds), pas pending.
                if (hasInFlightProduction(s.attemptId())) {
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

    /** Vrai s'il existe au moins une submission de cet attempt encore dans le
     *  pipeline IA (non terminale). FAILED et EVALUATED sont terminales. */
    private boolean hasInFlightProduction(UUID attemptId) {
        for (ProductionSubmission s : productionSubmissionManager.findByAttemptId(attemptId)) {
            SubmissionStatut st = s.getStatut();
            if (st == SubmissionStatut.SUBMITTED
                    || st == SubmissionStatut.TRANSCRIBING
                    || st == SubmissionStatut.EVALUATING) {
                return true;
            }
        }
        return false;
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

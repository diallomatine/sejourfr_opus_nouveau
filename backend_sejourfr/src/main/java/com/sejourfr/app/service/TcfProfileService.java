package com.sejourfr.app.service;

import com.sejourfr.app.dto.TcfLevelProfileResponse;
import com.sejourfr.app.dto.TcfLevelProfileResponse.EpreuveLevel;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Profil de niveau TCF par épreuve : agrège le DERNIER passage de chaque
 * épreuve indépendamment (dernier examen CO, dernier CE, dernière session EE,
 * dernière EO) et en déduit le niveau global = plancher.
 *
 * <p>Toute la math CECRL (estimation, plancher, plafond B2) est déléguée à
 * {@link TcfLevelEstimatorService} — ce service ne fait que sélectionner les
 * bons attempts et lire les niveaux déjà calculés.
 */
@Service
@RequiredArgsConstructor
public class TcfProfileService {

    /** Nombre d'attempts récents balayés par épreuve pour trouver le dernier exploitable. */
    private static final int SCAN_LIMIT = 50;

    private final AttemptManager attemptManager;
    private final ProductionSubmissionManager productionSubmissionManager;
    private final AiEvaluationManager aiEvaluationManager;
    private final TcfLevelEstimatorService levelEstimator;

    @Transactional(readOnly = true)
    public TcfLevelProfileResponse levelProfile(UUID userId) {
        EpreuveLevel co = latestQcm(userId, QuestionType.CO, EpreuveType.TCF_CO);
        EpreuveLevel ce = latestQcm(userId, QuestionType.CE, EpreuveType.TCF_CE);
        EpreuveLevel ee = latestProduction(userId, EpreuveType.TCF_EE);
        EpreuveLevel eo = latestProduction(userId, EpreuveType.TCF_EO);

        NiveauCecrl global = levelEstimator.floor(
                List.of(co, ce, ee, eo).stream()
                        .map(EpreuveLevel::level)
                        .filter(l -> l != null)
                        .toList());

        return new TcfLevelProfileResponse(co, ce, ee, eo, global);
    }

    /**
     * Dernier examen module fini d'une épreuve QCM (CO/CE), standalone ou
     * sous-attempt d'un examen complet. Niveau lu sur {@code cecrl_level}
     * (fallback score pondéré pour les attempts pré-V415).
     */
    private EpreuveLevel latestQcm(UUID userId, QuestionType qType, EpreuveType epreuve) {
        List<Attempt> attempts = attemptManager.findByUserFiltered(
                userId, AttemptType.MOCK_EXAM, Module.TCF, qType, null, SCAN_LIMIT);
        Attempt last = attempts.stream()
                .filter(a -> a.getFinishedAt() != null)
                .findFirst()
                .orElse(null);
        if (last == null) return EpreuveLevel.empty(epreuve);

        NiveauCecrl level = last.getCecrlLevel() != null
                ? levelEstimator.capB2(last.getCecrlLevel())
                : levelEstimator.levelFromWeighted(last.getWeightedScore(), last.getMaxWeightedScore());
        Integer calibrated = last.getMaxWeightedScore() != null
                ? levelEstimator.calibratedScore(last.getWeightedScore(), last.getMaxWeightedScore())
                : null;
        return new EpreuveLevel(
                epreuve, level, calibrated,
                last.getWeightedScore(), last.getMaxWeightedScore(),
                null, last.getFinishedAt());
    }

    /**
     * Dernière session de production (EE/EO) exploitable : le plus récent
     * attempt ayant au moins une submission EVALUATED. Niveau = plancher des
     * submissions évaluées (plafonné B2) ; {@code note20} = moyenne des notes.
     */
    private EpreuveLevel latestProduction(UUID userId, EpreuveType epreuve) {
        List<Attempt> attempts = attemptManager.findByUserAndEpreuve(userId, epreuve, SCAN_LIMIT);
        for (Attempt attempt : attempts) {
            List<ProductionSubmission> subs = productionSubmissionManager.findByAttemptId(attempt.getId());
            NiveauCecrl floor = null;
            List<BigDecimal> notes = new ArrayList<>();
            for (ProductionSubmission s : subs) {
                if (s.getStatut() != SubmissionStatut.EVALUATED) continue;
                AiEvaluation eval = aiEvaluationManager.findLatestBySubmissionId(s.getId()).orElse(null);
                if (eval == null || eval.getNiveauCecrl() == null) continue;
                floor = levelEstimator.min(floor, eval.getNiveauCecrl());
                if (eval.getNoteSur20() != null) notes.add(eval.getNoteSur20());
            }
            if (floor != null) {
                Instant when = attempt.getFinishedAt() != null
                        ? attempt.getFinishedAt() : attempt.getStartedAt();
                return new EpreuveLevel(
                        epreuve, levelEstimator.capB2(floor),
                        null, null, null, average(notes), when);
            }
        }
        return EpreuveLevel.empty(epreuve);
    }

    private static BigDecimal average(List<BigDecimal> notes) {
        if (notes.isEmpty()) return null;
        BigDecimal sum = notes.stream().reduce(BigDecimal.ZERO, BigDecimal::add);
        return sum.divide(BigDecimal.valueOf(notes.size()), 1, RoundingMode.HALF_UP);
    }
}

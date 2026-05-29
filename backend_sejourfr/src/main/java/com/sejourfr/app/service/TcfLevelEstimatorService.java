package com.sejourfr.app.service;

import com.sejourfr.app.dto.QcmAnswerResult;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.NiveauCecrl;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

/**
 * Source de vérité unique de la math CECRL côté TCF IRN.
 *
 * <p>Centralise :
 * <ul>
 *   <li>l'estimation du niveau d'une épreuve QCM (CO / CE) à partir des
 *       réponses, par score calibré + garde-fou « palier maîtrisé » ;</li>
 *   <li>le plafonnement à B2 (l'IRN ne classe pas au-delà) ;</li>
 *   <li>le niveau global = plancher (le plus faible) des épreuves.</li>
 * </ul>
 *
 * <p>Avant ce service, deux méthodes divergentes coexistaient (taux par strate
 * à 60 % pour l'examen module ; ratio pondéré par paliers pour l'examen
 * complet), si bien qu'un même examen CO pouvait donner deux niveaux selon le
 * contexte. Désormais le niveau est calculé ici une seule fois, persisté sur
 * {@code attempts.cecrl_level}, et relu partout (full exam, profil).
 */
@Service
public class TcfLevelEstimatorService {

    /** Poids par strate pour le score calibré (A2=1, B1=2, B2=3). */
    private static final Map<Difficulty, Integer> WEIGHTS =
            Map.of(Difficulty.A2, 1, Difficulty.B1, 2, Difficulty.B2, 3);

    /** Base et amplitude du score calibré façon TCF (100 → 499). */
    private static final int SCORE_BASE = 100;
    private static final int SCORE_SPAN = 399;

    /** Garde-fou « palier maîtrisé » : ratio mini + nombre d'items mini. */
    private static final double PALIER_PASS_RATIO = 0.70;
    private static final int PALIER_MIN_ITEMS = 6;

    /**
     * Score calibré 100-499 d'un QCM, dérivé du poids obtenu / poids max.
     * Réutilisable depuis un score pondéré déjà stocké (cf.
     * {@link #calibratedScore(Integer, Integer)}).
     */
    public int calibratedScore(List<QcmAnswerResult> answers) {
        int maxW = answers.stream().mapToInt(a -> weight(a.difficulty())).sum();
        int gotW = answers.stream()
                .filter(QcmAnswerResult::correct)
                .mapToInt(a -> weight(a.difficulty())).sum();
        return calibratedScore(gotW, maxW);
    }

    /** Variante depuis un score pondéré déjà calculé (weighted / maxWeighted). */
    public int calibratedScore(Integer weighted, Integer maxWeighted) {
        if (weighted == null || maxWeighted == null || maxWeighted <= 0) return SCORE_BASE;
        double ratio = Math.min(1.0, (double) weighted / maxWeighted);
        return (int) Math.round(SCORE_BASE + ratio * SCORE_SPAN);
    }

    /**
     * Niveau CECRL d'une épreuve QCM (CO / CE), plafonné à B2.
     *
     * <p>Deux lectures combinées :
     * <ol>
     *   <li><b>par score</b> : le score calibré place le candidat (≥400 B2,
     *       ≥300 B1, ≥200 A2, ≥101 A1, sinon A1 non atteint) ;</li>
     *   <li><b>par palier</b> : un niveau n'est « maîtrisé » que si ≥ 70 % de
     *       réussite sur ses propres items (≥ 6 items vus) — sinon on ne le
     *       crédite pas, même si le score global le suggère.</li>
     * </ol>
     * Le niveau retenu est <b>le plus prudent</b> des deux : un bon score tiré
     * par quelques questions faciles ne suffit pas à valider un palier non
     * réellement maîtrisé.
     */
    public NiveauCecrl estimateQcm(List<QcmAnswerResult> answers) {
        if (answers == null || answers.isEmpty()) return NiveauCecrl.A1_NON_ATTEINT;

        NiveauCecrl byScore = levelByScore(calibratedScore(answers));

        NiveauCecrl byPalier = NiveauCecrl.A1_NON_ATTEINT;
        for (Difficulty strata : List.of(Difficulty.A2, Difficulty.B1, Difficulty.B2)) {
            List<QcmAnswerResult> items = answers.stream()
                    .filter(a -> a.difficulty() == strata)
                    .toList();
            long ok = items.stream().filter(QcmAnswerResult::correct).count();
            if (items.size() >= PALIER_MIN_ITEMS
                    && (double) ok / items.size() >= PALIER_PASS_RATIO) {
                byPalier = toCecrl(strata);
            }
        }

        return capB2(min(byScore, byPalier));
    }

    /**
     * Niveau « par score » seul (sans garde-fou palier), depuis un score
     * pondéré déjà stocké. Fallback pour les examens module finis avant V415
     * (cecrl_level encore NULL) où l'on n'a plus le détail par question.
     */
    public NiveauCecrl levelFromWeighted(Integer weighted, Integer maxWeighted) {
        if (weighted == null || maxWeighted == null || maxWeighted <= 0) return null;
        return capB2(levelByScore(calibratedScore(weighted, maxWeighted)));
    }

    private static NiveauCecrl levelByScore(int score) {
        return score >= 400 ? NiveauCecrl.B2
             : score >= 300 ? NiveauCecrl.B1
             : score >= 200 ? NiveauCecrl.A2
             : score >= 101 ? NiveauCecrl.A1
             : NiveauCecrl.A1_NON_ATTEINT;
    }

    /** Plafonne tout niveau à B2 (cadre IRN). C1/C2 → B2. */
    public NiveauCecrl capB2(NiveauCecrl level) {
        if (level == null) return null;
        return level.ordinal() > NiveauCecrl.B2.ordinal() ? NiveauCecrl.B2 : level;
    }

    /** Plancher (le plus faible) de plusieurs niveaux, en ignorant les null, plafonné B2. */
    public NiveauCecrl floor(List<NiveauCecrl> levels) {
        NiveauCecrl floor = null;
        for (NiveauCecrl l : levels) {
            floor = min(floor, l);
        }
        return capB2(floor);
    }

    /** Min ordinal, en tolérant les null (un null est « inconnu », pas un plancher). */
    public NiveauCecrl min(NiveauCecrl a, NiveauCecrl b) {
        if (a == null) return b;
        if (b == null) return a;
        return a.ordinal() <= b.ordinal() ? a : b;
    }

    private static int weight(Difficulty d) {
        return d == null ? 0 : WEIGHTS.getOrDefault(d, 0);
    }

    private static NiveauCecrl toCecrl(Difficulty strata) {
        return switch (strata) {
            case A2 -> NiveauCecrl.A2;
            case B1 -> NiveauCecrl.B1;
            case B2 -> NiveauCecrl.B2;
            default -> NiveauCecrl.A1_NON_ATTEINT;
        };
    }
}

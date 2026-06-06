package com.sejourfr.app.service;

import com.sejourfr.app.dto.DashboardSummaryResponse;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.AnswerManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.ThemeManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Agrégat du tableau de bord web ({@code GET /api/me/dashboard}) : streak de
 * jours d'activité, total d'examens blancs, taux de réussite global, niveau
 * TCF estimé et stats par catégorie pour les deux modules. Toute la logique
 * vit ici — le front ne fait qu'afficher. (Le {@code DashboardService} sans
 * préfixe est celui de la console admin.)
 */
@Service
@RequiredArgsConstructor
public class UserDashboardService {

    /** Fuseau de référence des journées d'activité (produit franco-français). */
    private static final ZoneId PARIS = ZoneId.of("Europe/Paris");

    private final AttemptManager attemptManager;
    private final AnswerManager answerManager;
    private final QuestionManager questionManager;
    private final ThemeManager themeManager;
    private final AiEvaluationManager aiEvaluationManager;

    @Transactional(readOnly = true)
    public DashboardSummaryResponse summary(UUID userId) {
        final List<LocalDate> activityDates = attemptManager.findActivityDates(userId);
        final Streak streak = computeStreak(activityDates);

        final int mockExamsTotal = (int) attemptManager.countFinishedMockExams(userId);
        final MockExamCounts civiqueExams = civiqueMockExamCounts(userId);
        final MockExamCounts tcfExams = tcfMockExamCounts(userId);

        final long answered = answerManager.countAnsweredByUserAndModule(userId, Module.CIVIQUE)
                + answerManager.countAnsweredByUserAndModule(userId, Module.TCF);
        final long correct = answerManager.countCorrectByUserAndModule(userId, Module.CIVIQUE)
                + answerManager.countCorrectByUserAndModule(userId, Module.TCF);
        final Integer globalSuccessPercent = answered == 0
                ? null
                : (int) Math.round(100.0 * correct / answered);

        final NiveauCecrl estimatedTcfLevel = attemptManager.findLatestTcfWithCecrlLevel(userId)
                .map(a -> a.getFinalCecrlLevel() != null ? a.getFinalCecrlLevel() : a.getCecrlLevel())
                .orElse(null);

        final List<DashboardSummaryResponse.CategoryStat> tcf =
                new ArrayList<>(themeCategories(userId, Module.TCF, tcfExams.byCategory));
        tcf.add(productionCategory(userId, EpreuveType.TCF_EE, "TCF_EE", "Expression écrite"));
        tcf.add(productionCategory(userId, EpreuveType.TCF_EO, "TCF_EO", "Expression orale"));

        return new DashboardSummaryResponse(
                streak.current,
                streak.record,
                streak.activeToday,
                mockExamsTotal,
                civiqueExams.total,
                tcfExams.total,
                globalSuccessPercent,
                estimatedTcfLevel,
                themeCategories(userId, Module.CIVIQUE, civiqueExams.byCategory),
                tcf);
    }

    // ------------------------------------------------------------------------
    // Examens blancs par module / catégorie
    // ------------------------------------------------------------------------

    /**
     * Compteurs d'examens blancs finis d'un module : total + ventilation par
     * catégorie (clé = themeId civique ou name() du QuestionType TCF).
     */
    private record MockExamCounts(int total, Map<String, Integer> byCategory) {
    }

    /** Civique : examens thématiques ventilés par thème, complets dans le total. */
    private MockExamCounts civiqueMockExamCounts(UUID userId) {
        final List<Attempt> exams = attemptManager.findByUserFiltered(
                userId, AttemptType.MOCK_EXAM, Module.CIVIQUE, null, null, 500);
        int total = 0;
        final Map<String, Integer> byTheme = new HashMap<>();
        for (final Attempt a : exams) {
            if (a.getFinishedAt() == null) continue;
            total++;
            if (a.getLotThemeId() != null) {
                byTheme.merge(a.getLotThemeId().toString(), 1, Integer::sum);
            }
        }
        return new MockExamCounts(total, byTheme);
    }

    /**
     * TCF : examens module ventilés par épreuve QCM (CO/CE/STRUCTURE). Les
     * sous-attempts d'un examen complet sont exclus du total — seul le parent
     * TCF_COMPLET fini compte (sinon un examen complet pèserait 5).
     */
    private MockExamCounts tcfMockExamCounts(UUID userId) {
        final List<Attempt> exams = attemptManager.findByUserFiltered(
                userId, AttemptType.MOCK_EXAM, Module.TCF, null, null, 500);
        int total = 0;
        final Map<String, Integer> byEpreuve = new HashMap<>();
        for (final Attempt a : exams) {
            if (a.getFinishedAt() == null) continue;
            if (a.getParentAttempt() == null) total++;
            final QuestionType qt = a.getModuleExamQuestionType();
            if (qt != null) {
                byEpreuve.merge(qt.name(), 1, Integer::sum);
            }
        }
        return new MockExamCounts(total, byEpreuve);
    }

    // ------------------------------------------------------------------------
    // Catégories
    // ------------------------------------------------------------------------

    /**
     * Une entrée par thème officiel du module (ordre d'affichage du module),
     * y compris les thèmes jamais travaillés (percent null). Le percent est le
     * taux de réussite sur les questions distinctes tentées.
     *
     * @param mockExamsByCategory ventilation des examens blancs — clé =
     *                            themeId (civique) ou QuestionType.name() TCF
     *                            (le code thème {@code TCF_CO} → clé {@code CO})
     */
    private List<DashboardSummaryResponse.CategoryStat> themeCategories(
            UUID userId, Module module, Map<String, Integer> mockExamsByCategory) {
        // aggregateByTheme ne renvoie que les thèmes déjà tentés → on indexe
        // puis on déroule la liste complète des thèmes pour combler les trous.
        final Map<UUID, int[]> answeredCorrectByTheme = new HashMap<>();
        for (final Object[] row : answerManager.aggregateByTheme(userId, module)) {
            answeredCorrectByTheme.put((UUID) row[0],
                    new int[]{((Number) row[3]).intValue(), ((Number) row[4]).intValue()});
        }

        final List<DashboardSummaryResponse.CategoryStat> out = new ArrayList<>();
        for (final Theme theme : themeManager.findByModuleOrderedByDisplayOrder(module)) {
            final int[] ac = answeredCorrectByTheme.get(theme.getId());
            final int themeAnswered = ac == null ? 0 : ac[0];
            final int themeCorrect = ac == null ? 0 : ac[1];
            final int mockExams = mockExamsByCategory.getOrDefault(
                    theme.getId().toString(),
                    mockExamsByCategory.getOrDefault(
                            theme.getCode().replaceFirst("^TCF_", ""), 0));
            out.add(new DashboardSummaryResponse.CategoryStat(
                    theme.getId(),
                    theme.getCode(),
                    theme.getName(),
                    themeAnswered == 0 ? null : (int) Math.round(100.0 * themeCorrect / themeAnswered),
                    themeAnswered,
                    (int) questionManager.countActiveByTheme(theme.getId()),
                    mockExams,
                    null));
        }
        return out;
    }

    /**
     * Entrée synthétique EE/EO : dernière évaluation IA du user sur l'épreuve
     * (niveau CECRL + note /20 ramenée sur 100). Percent et level null si
     * aucune production évaluée.
     */
    private DashboardSummaryResponse.CategoryStat productionCategory(
            UUID userId, EpreuveType epreuve, String code, String label) {
        final AiEvaluation latest = aiEvaluationManager.findByUserAndEpreuve(userId, epreuve).stream()
                .max(Comparator.comparing(AiEvaluation::getEvaluatedAt))
                .orElse(null);

        Integer percent = null;
        NiveauCecrl level = null;
        if (latest != null) {
            level = latest.getNiveauCecrl();
            final BigDecimal note = latest.getNoteSur20();
            if (note != null) {
                percent = (int) Math.round(note.doubleValue() * 5);
            }
        }
        return new DashboardSummaryResponse.CategoryStat(null, code, label, percent, 0, 0, 0, level);
    }

    // ------------------------------------------------------------------------
    // Streak
    // ------------------------------------------------------------------------

    private record Streak(int current, int record, boolean activeToday) {
    }

    /**
     * Calcule la série courante et la série record à partir des jours
     * d'activité distincts triés DESC. La série courante n'est "vivante" que
     * si elle se termine aujourd'hui ou hier (une journée sans activité ne la
     * casse qu'à partir du lendemain).
     */
    private Streak computeStreak(List<LocalDate> datesDesc) {
        if (datesDesc.isEmpty()) {
            return new Streak(0, 0, false);
        }

        final LocalDate today = LocalDate.now(PARIS);
        final boolean activeToday = datesDesc.get(0).equals(today);

        int current = 0;
        if (activeToday || datesDesc.get(0).equals(today.minusDays(1))) {
            current = 1;
            for (int i = 1; i < datesDesc.size(); i++) {
                if (datesDesc.get(i).equals(datesDesc.get(i - 1).minusDays(1))) {
                    current++;
                } else {
                    break;
                }
            }
        }

        int record = 1;
        int run = 1;
        for (int i = 1; i < datesDesc.size(); i++) {
            if (datesDesc.get(i).equals(datesDesc.get(i - 1).minusDays(1))) {
                run++;
            } else {
                run = 1;
            }
            record = Math.max(record, run);
        }
        record = Math.max(record, current);

        return new Streak(current, record, activeToday);
    }
}

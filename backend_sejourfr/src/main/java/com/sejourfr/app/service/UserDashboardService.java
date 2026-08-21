package com.sejourfr.app.service;

import com.sejourfr.app.dto.DashboardSummaryResponse;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.dto.TcfLevelProfile;
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

    // ------------------------------------------------------------------------
    // Règle de progression (validée 2026-06-06) :
    //   progression = réussite × confiance
    //   - réussite  = questions distinctes réussies / répondues
    //   - confiance = min(1, répondues / min(40, taille du pool))
    //     (40 ≈ 2 examens blancs : un seul examen réussi ≠ "Solide",
    //     mais un gros pool n'écrase pas la note)
    //   EE/EO : réussite = moyenne des notes /20 des 3 dernières soumissions
    //   évaluées ×5 ; confiance = min(1, soumissions / 3).
    //   Module = moyenne des progressions de ses catégories ;
    //   global = moyenne de toutes les catégories renseignées.
    // ------------------------------------------------------------------------

    /** Échantillon de questions distinctes pour une confiance pleine (QCM). */
    private static final int QCM_CONFIDENCE_SAMPLE = 40;

    /** Nb de soumissions évaluées pour une confiance pleine (EE/EO). */
    private static final int PRODUCTION_CONFIDENCE_SAMPLE = 3;

    /** progression QCM = réussite × confiance (null si rien répondu). */
    private static Integer qcmProgress(int answered, int correct, int poolSize) {
        if (answered == 0) return null;
        final double reussite = (double) correct / answered;
        final int sample = Math.max(1, Math.min(QCM_CONFIDENCE_SAMPLE, poolSize));
        final double confiance = Math.min(1.0, (double) answered / sample);
        return (int) Math.round(100.0 * reussite * confiance);
    }

    private final AttemptManager attemptManager;
    private final AnswerManager answerManager;
    private final QuestionManager questionManager;
    private final ThemeManager themeManager;
    private final AiEvaluationManager aiEvaluationManager;
    private final TcfProfileService tcfProfileService;

    @Transactional(readOnly = true)
    public DashboardSummaryResponse summary(UUID userId) {
        final List<LocalDate> activityDates = attemptManager.findActivityDates(userId);
        final Streak streak = computeStreak(activityDates);

        final int mockExamsTotal = (int) attemptManager.countFinishedMockExams(userId);
        final MockExamCounts civiqueExams = civiqueMockExamCounts(userId);
        final MockExamCounts tcfExams = tcfMockExamCounts(userId);

        // Niveau TCF estimé : plancher des 4 épreuves, chacune retenant son
        // MEILLEUR résultat, une épreuve abandonnée sans rien rendre étant
        // exclue (cf. TcfProfileService). Dérivé serveur — aucun front ne le
        // recalcule, et son PÉRIMÈTRE part avec lui : sans ça, une seule épreuve
        // passée s'affichait comme un niveau TCF tout court.
        final TcfLevelProfile tcfProfile = tcfProfileService.levelProfile(userId);
        final NiveauCecrl estimatedTcfLevel = tcfProfile.globalLevel();

        final List<DashboardSummaryResponse.CategoryStat> tcf =
                new ArrayList<>(themeCategories(userId, Module.TCF, tcfExams.byCategory));
        tcf.add(productionCategory(userId, EpreuveType.TCF_EE, "TCF_EE", "Expression écrite"));
        tcf.add(productionCategory(userId, EpreuveType.TCF_EO, "TCF_EO", "Expression orale"));

        final List<DashboardSummaryResponse.CategoryStat> civique =
                themeCategories(userId, Module.CIVIQUE, civiqueExams.byCategory);

        // Progression globale = moyenne des catégories renseignées (les deux
        // modules confondus) — même règle que les fronts par module.
        final int[] sumCount = {0, 0};
        for (final var list : List.of(civique, tcf)) {
            for (final var c : list) {
                if (c.percent() != null) {
                    sumCount[0] += c.percent();
                    sumCount[1]++;
                }
            }
        }
        final Integer globalSuccessPercent =
                sumCount[1] == 0 ? null : Math.round((float) sumCount[0] / sumCount[1]);

        return new DashboardSummaryResponse(
                streak.current,
                streak.record,
                streak.activeToday,
                mockExamsTotal,
                civiqueExams.total,
                tcfExams.total,
                globalSuccessPercent,
                estimatedTcfLevel,
                tcfProfile.epreuvesCounted(),
                TcfLevelProfile.EPREUVES_EXPECTED,
                tcfProfile.partial(),
                // Même profil, publié domaine par domaine : ce n'est pas un
                // second calcul, c'est la même TcfLevelProfile mise en forme.
                TcfDomainProfileDto.of(tcfProfile),
                civique,
                tcf);
    }

    // ------------------------------------------------------------------------
    // Examens blancs par module / catégorie
    // ------------------------------------------------------------------------

    /**
     * Agrégat des examens blancs d'une catégorie : compte + record + les deux
     * derniers scores (tendance dernier vs avant-dernier sur la page
     * Progression). Alimenté en parcourant les attempts triés DESC :
     * 1ʳᵉ rencontre = dernier examen, 2ᵉ = avant-dernier.
     */
    static final class CategoryExamAgg {
        int count;
        Integer best;
        Integer last;
        Integer prev;

        void add(Integer score) {
            count++;
            if (score == null) return;
            if (best == null || score > best) best = score;
            if (last == null) last = score;
            else if (prev == null) prev = score;
        }
    }

    /**
     * Compteurs d'examens blancs finis d'un module : total + ventilation par
     * catégorie (clé = themeId civique ou name() du QuestionType TCF).
     */
    private record MockExamCounts(int total, Map<String, CategoryExamAgg> byCategory) {
    }

    /** Civique : examens thématiques ventilés par thème, complets dans le total. */
    private MockExamCounts civiqueMockExamCounts(UUID userId) {
        final List<Attempt> exams = attemptManager.findByUserFiltered(
                userId, AttemptType.MOCK_EXAM, Module.CIVIQUE, null, null, 500);
        int total = 0;
        final Map<String, CategoryExamAgg> byTheme = new HashMap<>();
        for (final Attempt a : exams) {
            if (a.getFinishedAt() == null) continue;
            total++;
            if (a.getLotThemeId() != null) {
                byTheme.computeIfAbsent(a.getLotThemeId().toString(), k -> new CategoryExamAgg())
                        .add(a.getScore());
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
        final Map<String, CategoryExamAgg> byEpreuve = new HashMap<>();
        for (final Attempt a : exams) {
            if (a.getFinishedAt() == null) continue;
            if (a.getParentAttempt() == null) total++;
            final QuestionType qt = a.getModuleExamQuestionType();
            if (qt != null) {
                byEpreuve.computeIfAbsent(qt.name(), k -> new CategoryExamAgg())
                        .add(a.getScore());
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
            UUID userId, Module module, Map<String, CategoryExamAgg> mockExamsByCategory) {
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
            CategoryExamAgg agg = mockExamsByCategory.get(theme.getId().toString());
            if (agg == null) {
                agg = mockExamsByCategory.get(theme.getCode().replaceFirst("^TCF_", ""));
            }
            final int poolSize = (int) questionManager.countActiveByTheme(theme.getId());
            out.add(new DashboardSummaryResponse.CategoryStat(
                    theme.getId(),
                    theme.getCode(),
                    theme.getName(),
                    qcmProgress(themeAnswered, themeCorrect, poolSize),
                    themeAnswered,
                    poolSize,
                    agg == null ? 0 : agg.count,
                    agg == null ? null : agg.best,
                    agg == null ? null : agg.last,
                    agg == null ? null : agg.prev,
                    null));
        }
        return out;
    }

    /**
     * Entrée synthétique EE/EO. Progression = moyenne des notes /20 des
     * {@value #PRODUCTION_CONFIDENCE_SAMPLE} dernières soumissions évaluées
     * ×5, pondérée par la confiance (nb de soumissions / 3) — même règle que
     * les QCM. Level = dernier niveau CECRL évalué.
     */
    private DashboardSummaryResponse.CategoryStat productionCategory(
            UUID userId, EpreuveType epreuve, String code, String label) {
        final List<AiEvaluation> recents = aiEvaluationManager.findByUserAndEpreuve(userId, epreuve)
                .stream()
                .sorted(Comparator.comparing(AiEvaluation::getEvaluatedAt).reversed())
                .toList();

        // « Dernier niveau CECRL EVALUE » : on saute les lignes qui n'en portent
        // pas — une production inexploitable (evaluabilite NON_EVALUABLE) n'a
        // rien observe, elle ne doit ni afficher un niveau qu'elle n'a pas, ni
        // effacer celui d'une production reellement corrigee avant elle.
        final NiveauCecrl level = recents.stream()
                .map(AiEvaluation::getNiveauCecrl)
                .filter(java.util.Objects::nonNull)
                .findFirst()
                .orElse(null);

        final List<BigDecimal> notes = recents.stream()
                .map(AiEvaluation::getNoteSur20)
                .filter(n -> n != null)
                .limit(PRODUCTION_CONFIDENCE_SAMPLE)
                .toList();
        Integer percent = null;
        if (!notes.isEmpty()) {
            final double avg = notes.stream().mapToDouble(BigDecimal::doubleValue).average().orElse(0);
            final double confiance =
                    Math.min(1.0, (double) notes.size() / PRODUCTION_CONFIDENCE_SAMPLE);
            percent = (int) Math.round(avg * 5 * confiance);
        }
        return new DashboardSummaryResponse.CategoryStat(
                null, code, label, percent, 0, 0, 0, null, null, null, level);
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

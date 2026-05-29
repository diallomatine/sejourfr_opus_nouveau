package com.sejourfr.app.service;

import com.sejourfr.app.dto.FullTcfExamResponse;
import com.sejourfr.app.dto.ProgressionSummaryResponse;
import com.sejourfr.app.dto.QuestionPublicResponse;
import com.sejourfr.app.dto.QuestionReviewResponse;
import com.sejourfr.app.dto.UserStatsResponse;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserQuestionStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.AnswerManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.manager.UserQuestionStatusManager;
import com.sejourfr.app.mapper.QuestionMapper;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Tout ce qui s'expose sous /api/me : stats, favoris, erreurs, revue,
 * profil. Le shuffle des choix utilise Question.id comme seed → l'ordre est
 * stable pour un favori / une erreur d'une lecture a l'autre.
 */
@Service
@RequiredArgsConstructor
public class MeService {

    private final AnswerManager answerManager;
    private final AttemptManager attemptManager;
    private final UserQuestionStatusManager statusManager;
    private final QuestionManager questionManager;
    private final UserManager userManager;
    private final QuestionMapper questionMapper;
    private final ThemeManager themeManager;
    private final AiEvaluationManager aiEvaluationManager;
    private final FullTcfExamService fullTcfExamService;

    // ------------------------------------------------------------------------
    // Profil
    // ------------------------------------------------------------------------

    @Transactional
    public void updateTargetProcedure(UUID userId, TargetProcedure procedure) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User introuvable"));
        user.setTargetProcedure(procedure);
        userManager.save(user);
    }

    // ------------------------------------------------------------------------
    // Stats
    // ------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public UserStatsResponse stats(UUID userId, Module module) {
        long attemptsTotal = attemptManager.countByUserId(userId);
        long answered = answerManager.countAnsweredByUserAndModule(userId, module);
        long correct = answerManager.countCorrectByUserAndModule(userId, module);
        double rate = answered == 0 ? 0.0 : (double) correct / answered;

        List<Object[]> rows = answerManager.aggregateByTheme(userId, module);
        List<UserStatsResponse.ThemeStatsResponse> byTheme = rows.stream()
                .map(r -> new UserStatsResponse.ThemeStatsResponse(
                        (UUID) r[0],
                        (String) r[1],
                        (String) r[2],
                        ((Number) r[3]).intValue(),
                        ((Number) r[4]).intValue(),
                        (int) questionManager.countActiveByTheme((UUID) r[0])
                ))
                .toList();

        return new UserStatsResponse(
                (int) attemptsTotal,
                (int) answered,
                (int) correct,
                rate,
                byTheme
        );
    }

    // ------------------------------------------------------------------------
    // Progression (écran "Progression" mobile)
    // ------------------------------------------------------------------------

    /**
     * Résumé de progression aligné sur les vrais examens passés par le user
     * (et pas l'activité brute du type {@link #stats}). Le front (écran
     * {@code StatsScreen}) ne fait qu'afficher cette structure — toute la
     * logique d'agrégation (examens blancs, thèmes consolidés, niveau CECRL
     * plafond, etc.) vit ici.
     */
    @Transactional(readOnly = true)
    public ProgressionSummaryResponse progressionSummary(UUID userId, Module module) {
        if (module == Module.CIVIQUE) {
            return civiqueProgression(userId);
        }
        return tcfProgression(userId);
    }

    private ProgressionSummaryResponse civiqueProgression(UUID userId) {
        // Tous les MOCK_EXAM civique du user (limit large pour bien couvrir
        // l'historique des deux variantes : examens blancs complets + théma).
        final List<Attempt> mockExams = attemptManager.findByUserFiltered(
                userId, AttemptType.MOCK_EXAM, Module.CIVIQUE, null, null, 500);

        // Examens blancs complets civique = MOCK_EXAM CIVIQUE finis sans
        // lotThemeId. Triés DESC par finishedAt pour exposer le dernier en tête.
        final List<Attempt> fullExams = mockExams.stream()
                .filter(a -> a.getFinishedAt() != null && a.getLotThemeId() == null)
                .sorted(Comparator.comparing(Attempt::getFinishedAt).reversed())
                .toList();

        Integer latestScore = fullExams.isEmpty() ? null : fullExams.get(0).getScore();
        Integer bestScore = fullExams.stream()
                .map(Attempt::getScore)
                .filter(s -> s != null)
                .max(Integer::compareTo)
                .orElse(null);

        // Thèmes "consolidés" : un thème dont au moins un examen thématique
        // (themeId non null) a été passé à ≥ 16/20 (seuil officiel des
        // examens thèmes-scopés, cf. AttemptService.CIVIQUE_THEME_EXAM_THRESHOLD).
        final Set<UUID> themesConsolidated = new HashSet<>();
        for (final Attempt a : mockExams) {
            if (a.getFinishedAt() == null || a.getLotThemeId() == null) continue;
            final Integer score = a.getScore();
            if (score != null && score >= 16) {
                themesConsolidated.add(a.getLotThemeId());
            }
        }

        final int themesTotal = themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE).size();

        return new ProgressionSummaryResponse(
                Module.CIVIQUE,
                new ProgressionSummaryResponse.CiviqueProgression(
                        fullExams.size(),
                        latestScore,
                        bestScore,
                        40,
                        32,
                        themesConsolidated.size(),
                        themesTotal),
                null);
    }

    private ProgressionSummaryResponse tcfProgression(UUID userId) {
        // Examens module TCF (CO/CE/STRUCTURE) finis — base pour les 3
        // stats cards (Épreuves QCM tentées, Meilleur QCM).
        final List<Attempt> moduleExams = attemptManager.findByUserFiltered(
                userId, AttemptType.MOCK_EXAM, Module.TCF, null, null, 500).stream()
                .filter(a -> a.getFinishedAt() != null && a.getModuleExamQuestionType() != null)
                .toList();

        final Set<QuestionType> qcmTried = new HashSet<>();
        for (final Attempt a : moduleExams) {
            qcmTried.add(a.getModuleExamQuestionType());
        }

        Integer bestWeightedScore = null;
        Integer bestWeightedMax = null;
        double bestRatio = -1.0;
        for (final Attempt a : moduleExams) {
            final Integer ws = a.getWeightedScore();
            final Integer mws = a.getMaxWeightedScore();
            if (ws == null || mws == null || mws == 0) continue;
            final double ratio = (double) ws / mws;
            if (ratio > bestRatio) {
                bestRatio = ratio;
                bestWeightedScore = ws;
                bestWeightedMax = mws;
            }
        }

        // Productions évaluées (stat card "EE / EO évaluées" /2). Une
        // épreuve compte comme "évaluée" dès qu'au moins 1 submission
        // a un niveau CECRL non null côté AiEvaluation.
        int productionsEvaluated = 0;
        for (final EpreuveType ep : List.of(EpreuveType.TCF_EE, EpreuveType.TCF_EO)) {
            final boolean hasAny = aiEvaluationManager.findByUserAndEpreuve(userId, ep).stream()
                    .anyMatch(e -> e.getNiveauCecrl() != null);
            if (hasAny) productionsEvaluated++;
        }

        // Dernier examen blanc complet TCF (TCF_COMPLET) — c'est ce qui
        // alimente le hero "Niveau TCF IRN". Si null, le mobile affiche une
        // CTA "Passe un examen blanc". Le calcul CECRL par épreuve + le
        // plancher final vivent dans `FullTcfExamService` qu'on délègue.
        ProgressionSummaryResponse.LastFullExam lastFullExam = null;
        final FullTcfExamResponse latest = fullTcfExamService.findLatestForUser(userId);
        if (latest != null) {
            NiveauCecrl coLvl = null, ceLvl = null, eeLvl = null, eoLvl = null;
            for (final FullTcfExamResponse.SubAttempt sub : latest.subAttempts()) {
                switch (sub.epreuve()) {
                    case TCF_CO -> coLvl = sub.cecrlLevel();
                    case TCF_CE -> ceLvl = sub.cecrlLevel();
                    case TCF_EE -> eeLvl = sub.cecrlLevel();
                    case TCF_EO -> eoLvl = sub.cecrlLevel();
                    default -> {
                    }
                }
            }
            lastFullExam = new ProgressionSummaryResponse.LastFullExam(
                    latest.id(),
                    latest.finishedAt(),
                    latest.status().name(),
                    latest.finalCecrlLevel(),
                    coLvl, ceLvl, eeLvl, eoLvl);
        }

        // Cible du user dérivée du parcours visé. CSP=A2, CR=B1, NAT=B2.
        NiveauCecrl target = null;
        final User user = userManager.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User introuvable"));
        final TargetProcedure proc = user.getTargetProcedure();
        if (proc != null) {
            target = targetToCecrl(proc);
        }

        return new ProgressionSummaryResponse(
                Module.TCF,
                null,
                new ProgressionSummaryResponse.TcfProgression(
                        qcmTried.size(),
                        3,
                        productionsEvaluated,
                        2,
                        bestWeightedScore,
                        bestWeightedMax,
                        lastFullExam,
                        target));
    }

    private static NiveauCecrl targetToCecrl(TargetProcedure proc) {
        return switch (proc) {
            case CSP -> NiveauCecrl.A2;
            case CR -> NiveauCecrl.B1;
            case NAT -> NiveauCecrl.B2;
        };
    }

    // ------------------------------------------------------------------------
    // Favoris
    // ------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<QuestionPublicResponse> favorites(UUID userId, Module module) {
        List<UUID> ids = statusManager.findFavoriteQuestionIds(userId, module);
        if (ids.isEmpty()) return List.of();
        return questionManager.findAllById(ids).stream()
                .map(this::toPublic)
                .toList();
    }

    @Transactional
    public void addFavorite(UUID userId, UUID questionId) {
        UserQuestionStatus status = statusManager.findByUserIdAndQuestionId(userId, questionId)
                .orElseGet(() -> createStatus(userId, questionId));
        status.setFavorite(true);
        status.setUpdatedAt(Instant.now());
        statusManager.save(status);
    }

    @Transactional
    public void removeFavorite(UUID userId, UUID questionId) {
        statusManager.findByUserIdAndQuestionId(userId, questionId)
                .ifPresent(s -> {
                    s.setFavorite(false);
                    s.setUpdatedAt(Instant.now());
                    statusManager.save(s);
                });
    }

    // ------------------------------------------------------------------------
    // Erreurs
    // ------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<QuestionPublicResponse> wrongAnswered(
            UUID userId, Module module, QuestionType questionType, UUID themeId) {
        List<UUID> ids = answerManager.findWrongQuestionIds(userId, module);
        if (ids.isEmpty()) return List.of();
        // Filtres appliqués côté Java après chargement. On re-filtre par
        // `q.module` en plus du filtre déjà appliqué côté query sur l'attempt :
        // garantit qu'aucune question CIVIQUE ne fuite côté TCF (et vice
        // versa) — défense en profondeur si jamais un attempt mixte
        // remontait des questions cross-module.
        return questionManager.findAllById(ids).stream()
                .filter(q -> module == null || q.getModule() == module)
                .filter(q -> questionType == null || q.getQuestionType() == questionType)
                .filter(q -> themeId == null
                        || (q.getTheme() != null && themeId.equals(q.getTheme().getId())))
                .map(this::toPublic)
                .toList();
    }

    // ------------------------------------------------------------------------
    // Revue detaillee d'une question (explication + bonnes reponses)
    // ------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public QuestionReviewResponse review(UUID userId, UUID questionId) {
        Question q = questionManager.findById(questionId)
                .orElseThrow(() -> new EntityNotFoundException("Question introuvable"));

        boolean answered = answerManager.hasUserAnsweredQuestion(userId, questionId);
        boolean favorited = statusManager.findByUserIdAndQuestionId(userId, questionId)
                .map(UserQuestionStatus::isFavorite)
                .orElse(false);
        if (!answered && !favorited) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Vous devez tenter ou marquer en favori cette question pour la consulter en révision.");
        }

        // Récupère la sélection de la dernière tentative pour pouvoir marquer
        // en rouge la réponse incorrecte côté mobile. Vide si jamais tentée
        // (cas d'une question favorite non répondue).
        var lastSelection = answered
                ? answerManager.findLatestSelectedChoiceIds(userId, questionId)
                : java.util.List.<UUID>of();
        return questionMapper.toReview(q, lastSelection);
    }

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------

    private UserQuestionStatus createStatus(UUID userId, UUID questionId) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User introuvable"));
        Question question = questionManager.findById(questionId)
                .orElseThrow(() -> new EntityNotFoundException("Question introuvable"));

        UserQuestionStatus s = new UserQuestionStatus();
        s.setUser(user);
        s.setQuestion(question);
        s.setFavorite(false);
        s.setUpdatedAt(Instant.now());
        return s;
    }

    /** Vue publique d'une question hors session : seed = Question.id (ordre stable). */
    private QuestionPublicResponse toPublic(Question q) {
        return questionMapper.toPublic(q, false, q.getId());
    }
}

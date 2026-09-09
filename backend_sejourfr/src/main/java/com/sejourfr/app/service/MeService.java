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
import com.sejourfr.app.enums.TargetLevel;
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
import java.time.LocalDate;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

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

    /**
     * Plafond d'erreurs exposees en revision, par module (CIVIQUE / TCF). On ne
     * renvoie que les plus recentes : au-dela, les anciennes erreurs sortent de
     * la liste (vue cappee, pas de suppression en base — cf.
     * {@code AnswerRepository.findRecentWrongQuestionIds}). Evite d'afficher des
     * centaines de questions et garde la revision actionnable.
     */
    static final int MAX_WRONG_PER_MODULE = 30;

    // ------------------------------------------------------------------------
    // Profil
    // ------------------------------------------------------------------------

    /**
     * Choix (ou changement) de la démarche visée.
     *
     * <p><b>Le serveur pose LUI-MÊME le palier de français exigé</b>
     * ({@link TargetProcedure#getRequiredTcfLevel()}) : c'est le seul point
     * d'écriture de {@code users.target_procedure}, donc le seul endroit où les
     * deux colonnes peuvent se désynchroniser. <b>L'inscription y passe aussi</b>
     * ({@code AuthService.register}, quand le candidat choisit sa démarche sur
     * l'écran de compte du diagnostic) : elle appelle cette méthode au lieu de
     * poser les colonnes elle-même. Elles se sont désynchronisées — le compte de
     * démonstration a longtemps porté {@code NAT} + {@code B1} parce que ce
     * service ne touchait que la procédure, et le candidat visant la
     * naturalisation était tiré vers le B1.
     *
     * <p><b>Correction serveur, pas refus</b> : le client n'envoie aucun niveau
     * ({@code UpdateTargetProcedureRequest} ne porte que la procédure), donc
     * aucune requête n'est <i>contradictoire</i> — c'est l'état stocké qui
     * l'était. Refuser aurait rejeté une demande parfaitement légitime.
     */
    @Transactional
    public void updateTargetProcedure(UUID userId, TargetProcedure procedure) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User introuvable"));
        user.setTargetProcedure(procedure);
        user.setTargetLevel(procedure == null ? null : procedure.getRequiredTcfLevel());
        userManager.save(user);
    }

    /**
     * Date d'examen declaree par le candidat (V047). {@code null} efface : « pas
     * encore de date » est une reponse pleine.
     *
     * <p>Aucune validation sur le passe : une date depassee est une information
     * vraie, et refuser une saisie empecherait de corriger une faute de frappe.
     * Ce que le serveur en affiche se decide a la lecture.
     */
    public void updateExamDate(UUID userId, LocalDate examDate) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User introuvable"));
        user.setExamDate(examDate);
        userManager.save(user);
    }

    // ------------------------------------------------------------------------
    // Stats
    // ------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public UserStatsResponse stats(UUID userId, Module module) {
        // Scopé au module comme tout le reste de la réponse : sans ça
        // /api/me/stats?module=CIVIQUE et ?module=TCF annonçaient le même
        // total (toutes sessions confondues) à côté de compteurs, eux, filtrés.
        long attemptsTotal = attemptManager.countByUserIdAndModule(userId, module);
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

        // Cible du user : la démarche fait PLANCHER (cf. TargetProcedure.niveauVise),
        // pas la valeur stockée seule — sinon une ligne héritée NAT + B1 afficherait
        // un objectif B1 à un candidat qui a besoin du B2.
        final User user = userManager.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User introuvable"));
        final TargetLevel vise = TargetProcedure.niveauVise(
                user.getTargetProcedure(), user.getTargetLevel());
        final NiveauCecrl target = vise == null ? null : NiveauCecrl.valueOf(vise.name());

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
        // TOUS les filtres (module, type, thème) descendent dans la requête, et
        // le plafond s'applique après eux : sinon on cherchait un type ou un
        // thème à l'intérieur des 30 dernières erreurs du module — un
        // utilisateur avec 225 CO ratées en voyait 8, et 0 sur un thème
        // civique qui en comptait 41. Le filtre CO inclut CO_IMAGE (cf.
        // AnswerManager.expandQuestionTypes).
        List<UUID> ids = answerManager.findRecentWrongQuestionIds(
                userId, module, questionType, themeId, MAX_WRONG_PER_MODULE);
        if (ids.isEmpty()) return List.of();
        // `findAllById` ne préserve pas l'ordre → on indexe par id puis on
        // ré-émet dans l'ordre de `ids` (récent d'abord).
        Map<UUID, Question> byId = questionManager.findAllById(ids).stream()
                .collect(Collectors.toMap(Question::getId, Function.identity()));
        return ids.stream()
                .map(byId::get)
                .filter(q -> q != null)
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

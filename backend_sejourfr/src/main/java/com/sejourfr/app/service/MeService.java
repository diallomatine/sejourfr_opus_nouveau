package com.sejourfr.app.service;

import com.sejourfr.app.dto.QuestionPublicResponse;
import com.sejourfr.app.dto.QuestionReviewResponse;
import com.sejourfr.app.dto.UserStatsResponse;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserQuestionStatus;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.AnswerManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.manager.UserQuestionStatusManager;
import com.sejourfr.app.mapper.QuestionMapper;
import com.sejourfr.app.service.journey.JourneyService;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Tout ce qui s'expose sous /api/me : stats, favoris, revue, profil. Le
 * shuffle des choix utilise Question.id comme seed → l'ordre est stable pour
 * un favori d'une lecture a l'autre.
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
    private final JourneyService journeyService;

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
        // 🛑 Dans la MEME transaction : le cycle en cours porte une copie de
        // l'objectif, et elle ne doit jamais contredire le profil (D-34).
        journeyService.alignerObjectif(userId);
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

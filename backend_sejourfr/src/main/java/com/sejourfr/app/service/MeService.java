package com.sejourfr.app.service;

import com.sejourfr.app.dto.QuestionPublicResponse;
import com.sejourfr.app.dto.QuestionReviewResponse;
import com.sejourfr.app.dto.UserStatsResponse;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserQuestionStatus;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.AnswerManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.QuestionManager;
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
import java.util.List;
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
                        ((Number) r[2]).intValue(),
                        ((Number) r[3]).intValue(),
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

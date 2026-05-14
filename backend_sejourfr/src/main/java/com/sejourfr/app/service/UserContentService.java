package com.sejourfr.app.service;

import com.sejourfr.app.dto.ChoicePublicResponse;
import com.sejourfr.app.dto.ChoiceReviewResponse;
import com.sejourfr.app.dto.MediaResponse;
import com.sejourfr.app.dto.QuestionPublicResponse;
import com.sejourfr.app.dto.QuestionReviewResponse;
import com.sejourfr.app.dto.UserStatsResponse;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserQuestionStatus;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.repository.*;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class UserContentService {

    private final AnswerRepository answerRepository;
    private final AttemptRepository attemptRepository;
    private final UserQuestionStatusRepository statusRepository;
    private final QuestionRepository questionRepository;
    private final UserRepository userRepository;

    public UserContentService(
            AnswerRepository answerRepository,
            AttemptRepository attemptRepository,
            UserQuestionStatusRepository statusRepository,
            QuestionRepository questionRepository,
            UserRepository userRepository
    ) {
        this.answerRepository = answerRepository;
        this.attemptRepository = attemptRepository;
        this.statusRepository = statusRepository;
        this.questionRepository = questionRepository;
        this.userRepository = userRepository;
    }

    // ------------------------------------------------------------------------
    // Stats
    // ------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public UserStatsResponse stats(UUID userId, Module module) {
        long attemptsTotal = attemptRepository.countByUserId(userId);
        long answered = answerRepository.countAnsweredByUserAndModule(userId, module);
        long correct = answerRepository.countCorrectByUserAndModule(userId, module);
        double rate = answered == 0 ? 0.0 : (double) correct / answered;

        List<Object[]> rows = answerRepository.aggregateByTheme(userId, module);
        List<UserStatsResponse.ThemeStatsResponse> byTheme = rows.stream()
                .map(r -> new UserStatsResponse.ThemeStatsResponse(
                        (UUID) r[0],
                        (String) r[1],
                        ((Number) r[2]).intValue(),
                        ((Number) r[3]).intValue(),
                        (int) questionRepository.countByThemeIdAndActiveTrue((UUID) r[0])
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
        List<UUID> ids = statusRepository.findFavoriteQuestionIds(userId, module);
        if (ids.isEmpty()) return List.of();
        return questionRepository.findAllById(ids).stream()
                .map(this::toPublic)
                .collect(Collectors.toList());
    }

    @Transactional
    public void addFavorite(UUID userId, UUID questionId) {
        UserQuestionStatus status = statusRepository
                .findByUserIdAndQuestionId(userId, questionId)
                .orElseGet(() -> createStatus(userId, questionId));
        status.setFavorite(true);
        status.setUpdatedAt(Instant.now());
        statusRepository.save(status);
    }

    @Transactional
    public void removeFavorite(UUID userId, UUID questionId) {
        statusRepository.findByUserIdAndQuestionId(userId, questionId)
                .ifPresent(s -> {
                    s.setFavorite(false);
                    s.setUpdatedAt(Instant.now());
                    statusRepository.save(s);
                });
    }

    // ------------------------------------------------------------------------
    // Erreurs
    // ------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<QuestionPublicResponse> wrongAnswered(UUID userId, Module module) {
        List<UUID> ids = answerRepository.findWrongQuestionIds(userId, module);
        if (ids.isEmpty()) return List.of();
        return questionRepository.findAllById(ids).stream()
                .map(this::toPublic)
                .collect(Collectors.toList());
    }

    // ------------------------------------------------------------------------
    // Revue détaillée d'une question (explication + bonnes réponses)
    // ------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public QuestionReviewResponse review(UUID userId, UUID questionId) {
        Question q = questionRepository.findById(questionId)
                .orElseThrow(() -> new EntityNotFoundException("Question introuvable"));

        boolean answered = answerRepository.hasUserAnsweredQuestion(userId, questionId);
        boolean favorited = statusRepository.findByUserIdAndQuestionId(userId, questionId)
                .map(UserQuestionStatus::isFavorite)
                .orElse(false);
        if (!answered && !favorited) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Vous devez tenter ou marquer en favori cette question pour la consulter en révision.");
        }

        return toReview(q);
    }

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------

    private UserQuestionStatus createStatus(UUID userId, UUID questionId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User introuvable"));
        Question question = questionRepository.findById(questionId)
                .orElseThrow(() -> new EntityNotFoundException("Question introuvable"));

        UserQuestionStatus s = new UserQuestionStatus();
        s.setUser(user);
        s.setQuestion(question);
        s.setFavorite(false);
        s.setUpdatedAt(Instant.now());
        return s;
    }

    private QuestionPublicResponse toPublic(Question q) {
        List<ChoicePublicResponse> choices = q.getChoices().stream()
                .sorted(Comparator.comparingInt(Choice::getDisplayOrder))
                .map(c -> new ChoicePublicResponse(c.getId(), c.getLabel(), c.getDisplayOrder()))
                .toList();

        MediaResponse media = q.getMedia() == null ? null : new MediaResponse(
                q.getMedia().getId(),
                q.getMedia().getType(),
                q.getMedia().getUrl(),
                q.getMedia().getDurationSeconds(),
                q.getMedia().getTranscript()
        );

        return new QuestionPublicResponse(
                q.getId(),
                q.getModule(),
                q.getTheme().getId(),
                q.getTheme().getName(),
                q.getDifficulty(),
                q.getQuestionType(),
                q.getStatement(),
                q.getPassage() != null ? q.getPassage().getContent() : null,
                media,
                choices
        );
    }

    private QuestionReviewResponse toReview(Question q) {
        List<ChoiceReviewResponse> choices = q.getChoices().stream()
                .sorted(Comparator.comparingInt(Choice::getDisplayOrder))
                .map(c -> new ChoiceReviewResponse(
                        c.getId(),
                        c.getLabel(),
                        c.getDisplayOrder(),
                        c.isCorrect()
                ))
                .toList();

        MediaResponse media = q.getMedia() == null ? null : new MediaResponse(
                q.getMedia().getId(),
                q.getMedia().getType(),
                q.getMedia().getUrl(),
                q.getMedia().getDurationSeconds(),
                q.getMedia().getTranscript()
        );

        return new QuestionReviewResponse(
                q.getId(),
                q.getModule(),
                q.getTheme().getId(),
                q.getTheme().getName(),
                q.getDifficulty(),
                q.getQuestionType(),
                q.getStatement(),
                q.getPassage() != null ? q.getPassage().getContent() : null,
                q.getExplanation(),
                media,
                choices
        );
    }
}

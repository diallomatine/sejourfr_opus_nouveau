package com.sejourfr.app.service;

import com.sejourfr.app.dto.*;
import com.sejourfr.app.entity.*;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.repository.*;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AttemptService {

    // Configuration par défaut MOCK_EXAM civique. À déplacer dans ExamTemplate plus tard.
    private static final int CIVIQUE_EXAM_SIZE = 40;
    private static final int CIVIQUE_EXAM_TIME = 45 * 60; // 45 min en secondes
    private static final int CIVIQUE_EXAM_THRESHOLD = 32;

    private static final int TCF_EXAM_SIZE = 60;
    private static final int TCF_EXAM_TIME = 90 * 60;

    private final AttemptRepository attemptRepository;
    private final AttemptQuestionRepository attemptQuestionRepository;
    private final AnswerRepository answerRepository;
    private final QuestionRepository questionRepository;
    private final UserRepository userRepository;

    public AttemptService(
            AttemptRepository attemptRepository,
            AttemptQuestionRepository attemptQuestionRepository,
            AnswerRepository answerRepository,
            QuestionRepository questionRepository,
            UserRepository userRepository
    ) {
        this.attemptRepository = attemptRepository;
        this.attemptQuestionRepository = attemptQuestionRepository;
        this.answerRepository = answerRepository;
        this.questionRepository = questionRepository;
        this.userRepository = userRepository;
    }

    // ------------------------------------------------------------------------
    // Création
    // ------------------------------------------------------------------------

    @Transactional
    public AttemptResponse start(UUID userId, StartAttemptRequest req) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User introuvable"));

        // Détermine la config selon le type
        int size;
        Integer timeLimit = null;
        Integer threshold = null;

        if (req.type() == AttemptType.MOCK_EXAM) {
            if (req.module() == Module.CIVIQUE) {
                size = CIVIQUE_EXAM_SIZE;
                timeLimit = CIVIQUE_EXAM_TIME;
                threshold = CIVIQUE_EXAM_THRESHOLD;
            } else {
                size = TCF_EXAM_SIZE;
                timeLimit = TCF_EXAM_TIME;
            }
        } else {
            // TRAINING / REVIEW : taille demandée, par défaut 10
            size = req.size() != null ? Math.clamp(req.size(), 1, 50) : 10;
        }

        // Sélection aléatoire des questions
        // Pour MOCK_EXAM, on ignore les filtres themeId/questionType : on prend
        // tout le module avec éventuellement la difficulté demandée.
        UUID themeId = req.type() == AttemptType.MOCK_EXAM ? null : req.themeId();
        var qType = req.type() == AttemptType.MOCK_EXAM ? null : req.questionType();

        List<Question> questions = questionRepository.findRandom(
                req.module(),
                themeId,
                req.difficulty(),
                qType,
                PageRequest.of(0, size)
        );

        if (questions.isEmpty()) {
            throw new IllegalStateException("Aucune question disponible pour ces critères");
        }

        // Crée l'attempt
        Attempt attempt = new Attempt();
        attempt.setUser(user);
        attempt.setType(req.type());
        attempt.setModule(req.module());
        attempt.setTotalQuestions(questions.size());
        attempt.setTimeLimitSeconds(timeLimit);
        attempt.setPassThreshold(threshold);
        attempt.setStartedAt(Instant.now());
        attempt = attemptRepository.save(attempt);

        // Crée les attempt_questions positionnés
        List<AttemptQuestion> aqList = new ArrayList<>();
        for (int i = 0; i < questions.size(); i++) {
            AttemptQuestion aq = new AttemptQuestion();
            aq.setAttempt(attempt);
            aq.setQuestion(questions.get(i));
            aq.setPosition(i);
            aqList.add(attemptQuestionRepository.save(aq));
        }

        return toAttemptResponse(attempt, aqList, false);
    }

    @Transactional(readOnly = true)
    public List<AttemptSummaryResponse> listMine(
            UUID userId,
            AttemptType type,
            Module module,
            int limit
    ) {
        int safeLimit = Math.max(1, Math.min(100, limit));
        Pageable pageable = PageRequest.of(0, safeLimit);

        List<Attempt> attempts = attemptRepository.findByUserFiltered(
                userId, type, module, pageable
        );

        return attempts.stream()
                .map(this::toSummary)
                .toList();
    }

    // ------------------------------------------------------------------------
    // Lecture
    // ------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public AttemptResponse getById(UUID userId, UUID attemptId) {
        Attempt attempt = loadAndCheck(userId, attemptId);
        List<AttemptQuestion> aqs =
                attemptQuestionRepository.findByAttemptIdOrderByPositionAsc(attemptId);
        boolean revealCorrect = attempt.getFinishedAt() != null;
        return toAttemptResponse(attempt, aqs, revealCorrect);
    }

    // ------------------------------------------------------------------------
    // Soumission d'une réponse
    // ------------------------------------------------------------------------

    @Transactional
    public AnswerResultResponse submitAnswer(UUID userId, UUID attemptId, SubmitAnswerRequest req) {
        Attempt attempt = loadAndCheck(userId, attemptId);
        if (attempt.getFinishedAt() != null) {
            throw new IllegalStateException("Session déjà terminée");
        }

        AttemptQuestion aq = attemptQuestionRepository.findById(req.attemptQuestionId())
                .orElseThrow(() -> new EntityNotFoundException("Question introuvable dans la session"));

        if (!aq.getAttempt().getId().equals(attemptId)) {
            throw new IllegalArgumentException("Cette question n'appartient pas à cette session");
        }

        Question question = aq.getQuestion();
        Set<UUID> correctIds = question.getChoices().stream()
                .filter(Choice::isCorrect)
                .map(Choice::getId)
                .collect(Collectors.toSet());
        Set<UUID> submitted = new HashSet<>(req.choiceIds());
        boolean correct = submitted.equals(correctIds);

        // Sauvegarde/MAJ de la réponse (une seule par attempt_question)
        Answer existing = aq.getAnswer();
        Answer answer = existing != null ? existing : new Answer();
        answer.setAttemptQuestion(aq);
        answer.setSelectedChoiceIds(new ArrayList<>(submitted));
        answer.setCorrect(correct);
        answer.setAnsweredAt(Instant.now());
        answerRepository.save(answer);

        aq.setAnswer(answer);
        attemptQuestionRepository.save(aq);

        // En entraînement : on renvoie la correction.
        // En examen blanc : on confirme juste l'enregistrement.
        if (attempt.getType() == AttemptType.TRAINING) {
            return new AnswerResultResponse(
                    true,
                    correct,
                    new ArrayList<>(correctIds),
                    question.getExplanation()
            );
        }
        return new AnswerResultResponse(true, null, null, null);
    }

    // ------------------------------------------------------------------------
    // Finalisation
    // ------------------------------------------------------------------------

    @Transactional
    public AttemptResponse finish(UUID userId, UUID attemptId) {
        Attempt attempt = loadAndCheck(userId, attemptId);
        if (attempt.getFinishedAt() != null) {
            // Idempotent : on renvoie l'état actuel
            List<AttemptQuestion> aqs =
                    attemptQuestionRepository.findByAttemptIdOrderByPositionAsc(attemptId);
            return toAttemptResponse(attempt, aqs, true);
        }

        List<AttemptQuestion> aqs =
                attemptQuestionRepository.findByAttemptIdOrderByPositionAsc(attemptId);

        int score = (int) aqs.stream()
                .filter(aq -> aq.getAnswer() != null && Boolean.TRUE.equals(aq.getAnswer().getCorrect()))
                .count();

        attempt.setFinishedAt(Instant.now());
        attempt.setScore(score);
        attemptRepository.save(attempt);

        return toAttemptResponse(attempt, aqs, true);
    }

    // ------------------------------------------------------------------------
    // Helpers privés
    // ------------------------------------------------------------------------

    private Attempt loadAndCheck(UUID userId, UUID attemptId) {
        Attempt attempt = attemptRepository.findById(attemptId)
                .orElseThrow(() -> new EntityNotFoundException("Session introuvable"));
        if (!attempt.getUser().getId().equals(userId)) {
            throw new AccessDeniedException("Cette session ne vous appartient pas");
        }
        return attempt;
    }

    private AttemptResponse toAttemptResponse(
            Attempt attempt,
            List<AttemptQuestion> aqs,
            boolean revealCorrect
    ) {
        List<AttemptQuestionResponse> aqResponses = aqs.stream()
                .map(aq -> toAttemptQuestionResponse(aq, revealCorrect))
                .toList();

        return new AttemptResponse(
                attempt.getId(),
                attempt.getType(),
                attempt.getModule(),
                attempt.getTotalQuestions(),
                attempt.getTimeLimitSeconds(),
                attempt.getPassThreshold(),
                attempt.getStartedAt(),
                attempt.getFinishedAt(),
                attempt.getScore(),
                aqResponses
        );
    }

    private AttemptQuestionResponse toAttemptQuestionResponse(
            AttemptQuestion aq,
            boolean revealCorrect
    ) {
        Answer answer = aq.getAnswer();
        List<UUID> selectedIds = answer != null
                ? new ArrayList<>(answer.getSelectedChoiceIds())
                : List.of();
        Boolean correct = answer != null && revealCorrect ? answer.getCorrect() : null;

        return new AttemptQuestionResponse(
                aq.getId(),
                aq.getPosition(),
                toQuestionPublic(aq.getQuestion(), revealCorrect),
                answer != null,
                selectedIds,
                correct
        );
    }

    private QuestionPublicResponse toQuestionPublic(Question q, boolean revealCorrect) {
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

    private AttemptSummaryResponse toSummary(Attempt a) {
        // Pour récupérer la difficulté représentative d'un attempt : on prend
        // la difficulté de la première question. On pourrait stocker une
        // difficulté au niveau de l'Attempt à terme.
        Difficulty diff = null;
        if (!a.getQuestions().isEmpty()) {
            diff = a.getQuestions().getFirst().getQuestion().getDifficulty();
        }

        return new AttemptSummaryResponse(
                a.getId(),
                a.getType(),
                a.getModule(),
                diff,
                a.getTotalQuestions(),
                a.getPassThreshold(),
                a.getStartedAt(),
                a.getFinishedAt(),
                a.getScore()
        );
    }
}

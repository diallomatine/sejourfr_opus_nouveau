package com.sejourfr.app.service;

import com.sejourfr.app.dto.*;
import com.sejourfr.app.entity.*;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
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

    // Configuration par défaut MOCK_EXAM sans ExamTemplate (fallback historique).
    // Pour les examens blancs branchés sur un template, ces valeurs sont lues
    // depuis ExamTemplate (durationSeconds, totalQuestions, passingScore).
    private static final int CIVIQUE_EXAM_SIZE = 40;
    private static final int CIVIQUE_EXAM_TIME = 45 * 60;
    private static final int CIVIQUE_EXAM_THRESHOLD = 32;

    private static final int TCF_EXAM_SIZE = 60;
    private static final int TCF_EXAM_TIME = 90 * 60;

    // Seuil de réussite par strate pour le calcul du niveau CECRL en TCF.
    // L'utilisateur "atteint" un niveau si son taux de bonnes réponses sur les
    // questions de ce niveau est >= 60 %.
    private static final double TCF_LEVEL_PASS_RATIO = 0.6;

    // Plafond d'entraînement TRAINING pour les comptes gratuits : au-delà,
    // on pousse l'utilisateur à passer Premium (et à utiliser l'app mobile).
    private static final int FREE_TRAINING_MAX_SIZE = 20;

    private final AttemptRepository attemptRepository;
    private final AttemptQuestionRepository attemptQuestionRepository;
    private final AnswerRepository answerRepository;
    private final QuestionRepository questionRepository;
    private final UserRepository userRepository;
    private final ExamTemplateRepository examTemplateRepository;
    private final SubscriptionService subscriptionService;

    public AttemptService(
            AttemptRepository attemptRepository,
            AttemptQuestionRepository attemptQuestionRepository,
            AnswerRepository answerRepository,
            QuestionRepository questionRepository,
            UserRepository userRepository,
            ExamTemplateRepository examTemplateRepository,
            SubscriptionService subscriptionService
    ) {
        this.attemptRepository = attemptRepository;
        this.attemptQuestionRepository = attemptQuestionRepository;
        this.answerRepository = answerRepository;
        this.questionRepository = questionRepository;
        this.userRepository = userRepository;
        this.examTemplateRepository = examTemplateRepository;
        this.subscriptionService = subscriptionService;
    }

    // ------------------------------------------------------------------------
    // Création
    // ------------------------------------------------------------------------

    @Transactional
    public AttemptResponse start(UUID userId, StartAttemptRequest req) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User introuvable"));

        // Branche template : si un examTemplateId est fourni, c'est lui qui
        // pilote la config (durée, taille, seuil) et la composition (rules).
        if (req.examTemplateId() != null) {
            ExamTemplate template = examTemplateRepository.findById(req.examTemplateId())
                    .orElseThrow(() -> new EntityNotFoundException("Examen blanc introuvable"));
            return startFromTemplate(user, template);
        }

        // Branche legacy : MOCK_EXAM sans template, TRAINING, REVIEW.
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
            int requested = req.size() != null ? req.size() : 10;
            int hardMax = 50;
            // Plafond gratuit sur le TRAINING : le web (et l'app sans abonnement)
            // s'arrête à 20 questions par session pour pousser au Premium et au
            // mobile. Pas de plafond pour REVIEW (l'user revoit ses erreurs).
            if (req.type() == AttemptType.TRAINING && !subscriptionService.isPremium(userId)) {
                hardMax = FREE_TRAINING_MAX_SIZE;
            }
            size = Math.clamp(requested, 1, hardMax);
        }

        UUID themeId = req.type() == AttemptType.MOCK_EXAM ? null : req.themeId();
        var qType = req.type() == AttemptType.MOCK_EXAM ? null : req.questionType();
        Difficulty effectiveDifficulty = resolveDifficulty(user, req.module(), req.difficulty());

        List<Question> questions = questionRepository.findRandom(
                req.module(),
                themeId,
                effectiveDifficulty,
                qType,
                PageRequest.of(0, size)
        );

        if (questions.isEmpty()) {
            throw new IllegalStateException("Aucune question disponible pour ces critères");
        }

        Attempt attempt = new Attempt();
        attempt.setUser(user);
        attempt.setType(req.type());
        attempt.setModule(req.module());
        attempt.setTotalQuestions(questions.size());
        attempt.setTimeLimitSeconds(timeLimit);
        attempt.setPassThreshold(threshold);
        attempt.setStartedAt(Instant.now());
        attempt = attemptRepository.save(attempt);

        List<AttemptQuestion> aqList = persistAttemptQuestions(attempt, questions);
        return toAttemptResponse(attempt, aqList, false);
    }

    /**
     * Démarre un examen blanc à partir d'un ExamTemplate publié. La composition
     * est dérivée des ExamTemplateRule (thème + difficulté + type + count). Si
     * les règles ne suffisent pas à remplir totalQuestions, on complète par un
     * tirage libre dans le module (jamais de doublon intra-attempt grâce à un
     * suivi des ids déjà tirés).
     */
    private AttemptResponse startFromTemplate(User user, ExamTemplate template) {
        if (!template.isPublished()) {
            throw new AccessDeniedException("Examen blanc non disponible");
        }
        if (!template.isFree() && !subscriptionService.isPremium(user.getId())) {
            throw new AccessDeniedException("Examen blanc réservé aux abonnés");
        }

        List<Question> picked = pickQuestionsForTemplate(template);
        if (picked.isEmpty()) {
            throw new IllegalStateException("Aucune question disponible pour cet examen blanc");
        }

        Attempt attempt = new Attempt();
        attempt.setUser(user);
        attempt.setExamTemplate(template);
        attempt.setType(AttemptType.MOCK_EXAM);
        attempt.setModule(template.getModule());
        attempt.setTotalQuestions(picked.size());
        attempt.setTimeLimitSeconds(template.getDurationSeconds());
        // Pour le TCF on conserve passingScore en base (0 par convention), mais
        // l'évaluation côté front s'appuie sur levelAchieved, pas sur ce seuil.
        attempt.setPassThreshold(template.getPassingScore());
        attempt.setStartedAt(Instant.now());
        attempt = attemptRepository.save(attempt);

        List<AttemptQuestion> aqList = persistAttemptQuestions(attempt, picked);
        return toAttemptResponse(attempt, aqList, false);
    }

    private List<Question> pickQuestionsForTemplate(ExamTemplate template) {
        LinkedHashSet<Question> picked = new LinkedHashSet<>();
        List<UUID> exclude = new ArrayList<>();

        // Règles ordonnées par position (l'ordre est porté par @OrderBy sur l'entité).
        for (ExamTemplateRule rule : template.getRules()) {
            int needed = rule.getQuestionCount();
            if (needed <= 0) continue;

            UUID themeId = rule.getTheme() != null ? rule.getTheme().getId() : null;
            List<Question> drawn = questionRepository.findRandomExcluding(
                    template.getModule(),
                    themeId,
                    rule.getDifficulty(),
                    rule.getQuestionType(),
                    exclude,
                    PageRequest.of(0, needed)
            );
            for (Question q : drawn) {
                if (picked.add(q)) exclude.add(q.getId());
            }
        }

        // Fallback : si les règles n'ont pas comblé totalQuestions (stock faible),
        // on complète sans contrainte autre que le module, en évitant les doublons.
        int target = template.getTotalQuestions();
        int missing = target - picked.size();
        if (missing > 0) {
            List<Question> extra = questionRepository.findRandomExcluding(
                    template.getModule(),
                    null,
                    null,
                    null,
                    exclude,
                    PageRequest.of(0, missing)
            );
            for (Question q : extra) {
                if (picked.add(q)) exclude.add(q.getId());
            }
        }

        return new ArrayList<>(picked);
    }

    private List<AttemptQuestion> persistAttemptQuestions(Attempt attempt, List<Question> questions) {
        List<AttemptQuestion> aqList = new ArrayList<>(questions.size());
        for (int i = 0; i < questions.size(); i++) {
            AttemptQuestion aq = new AttemptQuestion();
            aq.setAttempt(attempt);
            aq.setQuestion(questions.get(i));
            aq.setPosition(i);
            aqList.add(attemptQuestionRepository.save(aq));
        }
        return aqList;
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

        // Pour le TCF, on calcule en plus le niveau CECRL atteint à partir du
        // taux de réussite par strate A2/B1/B2. Civique : levelAchieved reste null.
        if (attempt.getModule() == Module.TCF) {
            attempt.setLevelAchieved(computeLevelAchieved(aqs));
        }

        attemptRepository.save(attempt);

        return toAttemptResponse(attempt, aqs, true);
    }

    /**
     * Niveau CECRL atteint : on retient le plus haut niveau A2/B1/B2 où le
     * taux de bonnes réponses sur les questions de cette strate dépasse le
     * seuil {@link #TCF_LEVEL_PASS_RATIO}. Si même A2 n'est pas atteint, on
     * renvoie null.
     */
    private TargetLevel computeLevelAchieved(List<AttemptQuestion> aqs) {
        TargetLevel result = null;
        for (TargetLevel level : List.of(TargetLevel.A2, TargetLevel.B1, TargetLevel.B2)) {
            Difficulty strata = toDifficulty(level);
            long total = aqs.stream()
                    .filter(aq -> aq.getQuestion().getDifficulty() == strata)
                    .count();
            if (total == 0) continue;

            long correct = aqs.stream()
                    .filter(aq -> aq.getQuestion().getDifficulty() == strata)
                    .filter(aq -> aq.getAnswer() != null && Boolean.TRUE.equals(aq.getAnswer().getCorrect()))
                    .count();

            if ((double) correct / total >= TCF_LEVEL_PASS_RATIO) {
                result = level;
            }
        }
        return result;
    }

    private Difficulty toDifficulty(TargetLevel level) {
        return switch (level) {
            case A2 -> Difficulty.A2;
            case B1 -> Difficulty.B1;
            case B2 -> Difficulty.B2;
        };
    }

    // ------------------------------------------------------------------------
    // Helpers privés
    // ------------------------------------------------------------------------

    /**
     * Détermine la difficulté à appliquer pour un attempt : la valeur explicite
     * si présente, sinon dérivée du parcours visé par l'utilisateur.
     *
     * Module CIVIQUE : CSP/CR/NAT directement.
     * Module TCF     : CSP→A2, CR→B1, NAT→B2.
     *
     * Retourne null si l'utilisateur n'a pas encore choisi de parcours, auquel
     * cas la sélection se fait sur tous les niveaux.
     */
    private Difficulty resolveDifficulty(User user, Module module, Difficulty requested) {
        if (requested != null) return requested;
        TargetProcedure path = user.getTargetProcedure();
        if (path == null) return null;

        if (module == Module.CIVIQUE) {
            return switch (path) {
                case CSP -> Difficulty.CSP;
                case CR -> Difficulty.CR;
                case NAT -> Difficulty.NAT;
            };
        }
        return switch (path) {
            case CSP -> Difficulty.A2;
            case CR -> Difficulty.B1;
            case NAT -> Difficulty.B2;
        };
    }

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

        ExamTemplate template = attempt.getExamTemplate();
        UUID templateId = template != null ? template.getId() : null;
        String templateSlug = template != null ? template.getSlug() : null;
        String templateName = template != null ? template.getName() : null;

        return new AttemptResponse(
                attempt.getId(),
                attempt.getType(),
                attempt.getModule(),
                templateId,
                templateSlug,
                templateName,
                attempt.getTotalQuestions(),
                attempt.getTimeLimitSeconds(),
                attempt.getPassThreshold(),
                attempt.getStartedAt(),
                attempt.getFinishedAt(),
                attempt.getScore(),
                attempt.getLevelAchieved(),
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

        // Seed déterministe par AttemptQuestion : l'ordre est stable d'une lecture
        // à l'autre (reprise, refresh) mais différent à chaque nouvelle session,
        // ce qui empêche l'utilisateur de mémoriser des positions.
        long seed = aq.getId().getMostSignificantBits() ^ aq.getId().getLeastSignificantBits();
        return new AttemptQuestionResponse(
                aq.getId(),
                aq.getPosition(),
                toQuestionPublic(aq.getQuestion(), revealCorrect, seed),
                answer != null,
                selectedIds,
                correct
        );
    }

    private QuestionPublicResponse toQuestionPublic(Question q, boolean revealCorrect, long shuffleSeed) {
        List<Choice> ordered = q.getChoices().stream()
                .sorted(Comparator.comparingInt(Choice::getDisplayOrder))
                .collect(Collectors.toCollection(ArrayList::new));
        Collections.shuffle(ordered, new Random(shuffleSeed));
        List<ChoicePublicResponse> choices = new ArrayList<>(ordered.size());
        for (int i = 0; i < ordered.size(); i++) {
            Choice c = ordered.get(i);
            choices.add(new ChoicePublicResponse(c.getId(), c.getLabel(), i, revealCorrect ? c.isCorrect() : null));
        }

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
                revealCorrect ? q.getExplanation() : null,
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

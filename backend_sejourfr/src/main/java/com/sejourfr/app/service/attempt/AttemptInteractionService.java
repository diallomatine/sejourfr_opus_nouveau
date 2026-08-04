package com.sejourfr.app.service.attempt;

import com.sejourfr.app.dto.AnswerResultResponse;
import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.AttemptSummaryResponse;
import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.entity.Answer;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.Choice;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.manager.AnswerManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.mapper.AttemptMapper;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Cycle de vie post-start d'un attempt : lecture, soumission de réponse et
 * finalisation. Extrait d'AttemptService pour isoler la mécanique de jeu de
 * la logique de composition / dispatch de démarrage.
 */
@Service
@RequiredArgsConstructor
public class AttemptInteractionService {

    private static final int LIST_LIMIT_MIN = 1;
    private static final int LIST_LIMIT_MAX = 100;

    private final AttemptManager attemptManager;
    private final AttemptQuestionManager attemptQuestionManager;
    private final AnswerManager answerManager;
    private final AttemptScoringService scoringService;
    private final AttemptMapper mapper;

    // ------------------------------------------------------------------------
    // Lecture
    // ------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public AttemptResponse getById(UUID userId, UUID attemptId) {
        Attempt attempt = loadAndCheck(userId, attemptId);
        List<AttemptQuestion> aqs = attemptQuestionManager.findByAttemptOrderedByPosition(attemptId);
        boolean revealCorrect = attempt.getFinishedAt() != null;
        return mapper.toResponse(attempt, aqs, revealCorrect);
    }

    @Transactional(readOnly = true)
    public List<AttemptSummaryResponse> listMine(
            UUID userId,
            AttemptType type,
            Module module,
            QuestionType moduleExamQuestionType,
            UUID themeId,
            int limit) {
        int safeLimit = Math.max(LIST_LIMIT_MIN, Math.min(LIST_LIMIT_MAX, limit));
        List<Attempt> attempts = attemptManager.findByUserFiltered(
                userId, type, module, moduleExamQuestionType, themeId, safeLimit);
        return attempts.stream().map(mapper::toSummary).toList();
    }

    /**
     * Lookup d'un attempt guest pour la branche publique. Renvoie l'attempt
     * SEULEMENT si user IS NULL ET client_ip matche. Toute non-correspondance
     * (id inexistant, attempt d'un user, autre IP) est traitee en 404 par
     * l'appelant pour ne pas reveler l'existence.
     */
    @Transactional(readOnly = true)
    public Attempt loadGuestAttempt(UUID attemptId, String clientIp) {
        return attemptManager.findGuestByIdAndIp(attemptId, clientIp)
                .orElseThrow(() -> new EntityNotFoundException("Session introuvable"));
    }

    /**
     * Variante de {@link #getById(UUID, UUID)} sans controle user (l'appelant
     * a deja valide l'IP via {@link #loadGuestAttempt}).
     */
    @Transactional(readOnly = true)
    public AttemptResponse readAttempt(Attempt attempt) {
        List<AttemptQuestion> aqs = attemptQuestionManager.findByAttemptOrderedByPosition(attempt.getId());
        boolean revealCorrect = attempt.getFinishedAt() != null;
        return mapper.toResponse(attempt, aqs, revealCorrect);
    }

    // ------------------------------------------------------------------------
    // Soumission d'une reponse
    // ------------------------------------------------------------------------

    @Transactional
    public AnswerResultResponse submitAnswer(UUID userId, UUID attemptId, SubmitAnswerRequest req) {
        Attempt attempt = loadAndCheck(userId, attemptId);
        if (attempt.getFinishedAt() != null) {
            throw new IllegalStateException("Session déjà terminée");
        }
        return doSubmitAnswer(attempt, req);
    }

    /**
     * Variante de {@link #submitAnswer(UUID, UUID, SubmitAnswerRequest)} qui
     * skip le controle user (deja fait via IP cote guest).
     */
    @Transactional
    public AnswerResultResponse submitAnswerForAttempt(Attempt attempt, SubmitAnswerRequest req) {
        if (attempt.getFinishedAt() != null) {
            throw new IllegalStateException("Session déjà terminée");
        }
        return doSubmitAnswer(attempt, req);
    }

    private AnswerResultResponse doSubmitAnswer(Attempt attempt, SubmitAnswerRequest req) {
        AttemptQuestion aq = attemptQuestionManager.findById(req.attemptQuestionId())
                .orElseThrow(() -> new EntityNotFoundException("Question introuvable dans la session"));

        if (!aq.getAttempt().getId().equals(attempt.getId())) {
            throw new IllegalArgumentException("Cette question n'appartient pas à cette session");
        }

        Question question = aq.getQuestion();
        Set<UUID> questionChoiceIds = question.getChoices().stream()
                .map(Choice::getId)
                .collect(Collectors.toSet());
        Set<UUID> correctIds = question.getChoices().stream()
                .filter(Choice::isCorrect)
                .map(Choice::getId)
                .collect(Collectors.toSet());
        Set<UUID> submitted = new HashSet<>(req.choiceIds());
        // Les choix soumis doivent appartenir à CETTE question. Sans ce contrôle,
        // un choiceId pris sur une autre question était accepté et persisté dans
        // answers.selected_choice_ids — sans effet sur le score, mais la revue
        // affichait ensuite une sélection qui n'existe pas dans la question.
        if (!questionChoiceIds.containsAll(submitted)) {
            throw new IllegalArgumentException(
                    "Un choix soumis n'appartient pas à cette question");
        }
        boolean correct = submitted.equals(correctIds);

        // Sauvegarde/MAJ de la reponse (une seule par attempt_question)
        Answer existing = aq.getAnswer();
        Answer answer = existing != null ? existing : new Answer();
        answer.setAttemptQuestion(aq);
        answer.setSelectedChoiceIds(new ArrayList<>(submitted));
        answer.setCorrect(correct);
        answer.setAnsweredAt(Instant.now());
        answerManager.save(answer);

        aq.setAnswer(answer);
        attemptQuestionManager.save(aq);

        // En entrainement : on renvoie la correction. En examen blanc : on
        // confirme juste l'enregistrement.
        if (attempt.getType() == AttemptType.TRAINING) {
            return new AnswerResultResponse(true, correct, new ArrayList<>(correctIds), question.getExplanation());
        }
        return new AnswerResultResponse(true, null, null, null);
    }

    // ------------------------------------------------------------------------
    // Finalisation
    // ------------------------------------------------------------------------

    @Transactional
    public AttemptResponse finish(UUID userId, UUID attemptId) {
        Attempt attempt = loadAndCheck(userId, attemptId);
        return doFinish(attempt);
    }

    /** Variante de {@link #finish(UUID, UUID)} qui skip le controle user. */
    @Transactional
    public AttemptResponse finishAttempt(Attempt attempt) {
        return doFinish(attempt);
    }

    private AttemptResponse doFinish(Attempt attempt) {
        UUID attemptId = attempt.getId();

        // Attempts production (EE/EO) : pas de questions ni de score QCM — on
        // pose juste finishedAt + TERMINE. Appelé par les fronts à la fin
        // d'une session d'examen production (ou à l'expiration du chrono EE) ;
        // le bilan comptera les tâches non rendues à 0 (ProductionBilanService).
        if (attempt.getEpreuve() == EpreuveType.TCF_EE || attempt.getEpreuve() == EpreuveType.TCF_EO) {
            if (attempt.getFinishedAt() == null) {
                attempt.setFinishedAt(Instant.now());
                attempt.setStatus(AttemptStatus.TERMINE);
                attemptManager.save(attempt);
            }
            return mapper.toResponse(attempt, List.of(), true);
        }

        List<AttemptQuestion> aqs = attemptQuestionManager.findByAttemptOrderedByPosition(attemptId);

        if (attempt.getFinishedAt() != null) {
            // Idempotent : on renvoie l'etat actuel.
            return mapper.toResponse(attempt, aqs, true);
        }

        int score = (int) aqs.stream()
                .filter(aq -> aq.getAnswer() != null && Boolean.TRUE.equals(aq.getAnswer().getCorrect()))
                .count();

        attempt.setFinishedAt(Instant.now());
        attempt.setScore(score);

        if (attempt.getModule() == Module.TCF) {
            // Les examens template TCF (diagnostic CO→CE) ont aussi leurs
            // strates garanties depuis la composition sectionnée (8 A2 + 9 B1
            // + 8 B2 par épreuve) : même notation calibrée que les examens module.
            boolean stratifiedExam = attempt.getModuleExamQuestionType() != null
                    || (attempt.getType() == AttemptType.MOCK_EXAM && attempt.getExamTemplate() != null);
            if (stratifiedExam) {
                // Examen module TCF (CO/CE/STRUCTURE), examen template, ou
                // sous-attempt CO/CE d'un examen blanc complet : strates
                // A2/B1/B2 garanties à la composition → niveau CECRL rigoureux
                // (score calibré + garde-fou palier), source de vérité unique
                // stockée sur cecrl_level et projetée sur level_achieved
                // (A2/B1/B2). On persiste aussi le score pondéré
                // (A2=1, B1=2, B2=3) qui dérive le score calibré 100-499.
                // Niveau global = plancher des épreuves (règle TCF IRN : il
                // faut le niveau partout). Mono-épreuve : équivaut à
                // estimateQcm sur tout l'attempt.
                NiveauCecrl cecrl = scoringService.estimatePerEpreuveFloor(aqs);
                attempt.setCecrlLevel(cecrl);
                attempt.setLevelAchieved(AttemptScoringService.toTargetLevel(cecrl));
                attempt.setWeightedScore(scoringService.computeWeightedScore(aqs, true));
                attempt.setMaxWeightedScore(scoringService.computeWeightedScore(aqs, false));
            } else {
                // Entraînement TCF libre : strates non garanties (pool aléatoire),
                // le garde-fou palier n'aurait pas de sens → on garde le niveau
                // indicatif par strate sans renseigner cecrl_level.
                attempt.setLevelAchieved(scoringService.computeLevelAchieved(aqs));
            }
        }

        attemptManager.save(attempt);
        return mapper.toResponse(attempt, aqs, true);
    }

    private Attempt loadAndCheck(UUID userId, UUID attemptId) {
        Attempt attempt = attemptManager.findById(attemptId)
                .orElseThrow(() -> new EntityNotFoundException("Session introuvable"));
        // Un attempt sans user (demo guest, cf. PublicAttemptService) ne peut
        // pas appartenir a un user connecte.
        if (attempt.getUser() == null || !attempt.getUser().getId().equals(userId)) {
            throw new AccessDeniedException("Cette session ne vous appartient pas");
        }
        return attempt;
    }
}

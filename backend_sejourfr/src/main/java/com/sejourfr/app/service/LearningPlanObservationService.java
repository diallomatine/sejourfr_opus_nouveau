package com.sejourfr.app.service;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.service.competence.CompetenceAnalysisFields;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Écrit les signaux sourcés qui alimentent le Plan, sans heuristique textuelle.
 *
 * <p><b>Aucun diagnostic n'est exigé pour observer</b> (règle levée le
 * 2026-08-12). Auparavant, tant qu'aucune session n'était {@code COMPLETED},
 * rien n'était enregistré : un candidat qui travaillait ses micro-compétences ou
 * ses productions sans jamais passer le diagnostic n'accumulait strictement
 * aucun historique, et le jour où il le passait, tout ce travail était perdu.
 * Les observations s'accumulent donc toujours ; c'est le <b>Plan</b>
 * ({@link LearningPlanService}) qui continue de réclamer un diagnostic terminé
 * pour s'activer et rendre ses priorités.
 */
@Service
@RequiredArgsConstructor
public class LearningPlanObservationService {

    private final LearningPlanObservationManager observationManager;
    private final UserSkillAttemptManager skillAttemptManager;

    public void recordProduction(
            ProductionSubmission submission,
            List<Skill> allowedSkills,
            Map<String, Object> analysis,
            boolean baseline) {
        Map<String, Skill> skillsByCode = new LinkedHashMap<>();
        allowedSkills.forEach(skill -> skillsByCode.put(skill.getCode(), skill));
        LearningPlanSourceType sourceType = sourceType(submission, baseline);
        Object raw = analysis.get("skills");
        if (!(raw instanceof List<?> observations)) return;
        for (Object item : observations) {
            if (!(item instanceof Map<?, ?> value)) continue;
            Skill skill = skillsByCode.get(text(value.get("skill_code")));
            if (skill == null) continue;
            if (observationManager.findBySource(
                    submission.getUser().getId(), skill.getId(), sourceType, submission.getId()).isPresent()) {
                continue;
            }
            LearningPlanSkillStatus status = LearningPlanSkillStatus.valueOf(text(value.get("status")));
            boolean observed = Boolean.TRUE.equals(value.get("observed"));
            LearningPlanObservation observation = new LearningPlanObservation();
            observation.setUser(submission.getUser());
            observation.setSkill(skill);
            observation.setSourceType(sourceType);
            observation.setSourceId(submission.getId());
            observation.setSubjectId(submission.getProductionTask().getId());
            observation.setObserved(observed);
            observation.setStatus(status);
            observation.setEvidence(observed ? nullableText(value.get("evidence")) : null);
            observation.setExplanation(nullableText(value.get("explanation")));
            observation.setConfidence(ObservationConfidence.valueOf(text(value.get("confidence"))));
            observation.setBaseline(baseline);
            observation.setObservedAt(Instant.now());
            saveIdempotently(observation);
        }
    }

    /**
     * Un micro-exercice ciblé affine la priorité, mais une réussite unique ne
     * déclare jamais la compétence SOLID. La confirmation doit venir ensuite
     * d'une production complète indépendante.
     */
    public void recordSkillAttempt(UUID attemptId) {
        UserSkillAttempt attempt = skillAttemptManager.findByIdWithPrompt(attemptId).orElse(null);
        if (attempt == null || attempt.getStatut() != SkillAttemptStatut.EVALUATED
                || attempt.getCriterionStatus() == null) {
            return;
        }
        Skill skill = attempt.getSkillPrompt().getSkill();
        if (observationManager.findBySource(attempt.getUser().getId(), skill.getId(),
                LearningPlanSourceType.SKILL_TRAINING, attemptId).isPresent()) return;

        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setUser(attempt.getUser());
        observation.setSkill(skill);
        observation.setSourceType(LearningPlanSourceType.SKILL_TRAINING);
        observation.setSourceId(attemptId);
        // Le SUJET, pas la tentative : trois reprises du meme petit sujet apres
        // correction ne sont pas trois preuves independantes.
        observation.setSubjectId(attempt.getSkillPrompt().getId());
        observation.setObserved(true);
        observation.setStatus(attempt.getCriterionStatus() == SkillCriterionStatus.VALIDATED
                ? LearningPlanSkillStatus.TO_REINFORCE : LearningPlanSkillStatus.PRIORITY);
        String production = attempt.getWrittenProduction() != null
                ? attempt.getWrittenProduction() : attempt.getTranscript();
        observation.setEvidence(truncate(production, 500));
        // Repli VERSION PAR VERSION : la priorite d'amelioration (contrat v1/v2)
        // n'existe plus sous v3, ou l'axe de progres tient en trois mots. Sans ce
        // repli, la bascule aurait vide en silence l'explication de toutes les
        // observations issues des micro-exercices.
        observation.setExplanation(
                nullableText(CompetenceAnalysisFields.explication(attempt.getAnalysisJson())));
        observation.setConfidence(ObservationConfidence.MEDIUM);
        observation.setBaseline(false);
        observation.setObservedAt(attempt.getUpdatedAt());
        saveIdempotently(observation);
    }

    private static LearningPlanSourceType sourceType(
            ProductionSubmission submission, boolean baseline) {
        boolean oral = submission.getProductionTask().getEpreuve() == EpreuveType.TCF_EO;
        if (baseline) return oral
                ? LearningPlanSourceType.DIAGNOSTIC_EO : LearningPlanSourceType.DIAGNOSTIC_EE;
        if (isMockExam(submission)) return oral
                ? LearningPlanSourceType.MOCK_EXAM_EO : LearningPlanSourceType.MOCK_EXAM_EE;
        return oral ? LearningPlanSourceType.PRODUCTION_EO : LearningPlanSourceType.PRODUCTION_EE;
    }

    /**
     * Une production d'<b>examen blanc</b> : c'est la preuve la moins assistee
     * dont on dispose, d'ou son poids le plus fort dans le moteur de maitrise.
     *
     * <p>Deux formes, marquees differemment a la creation de l'attempt :
     * une session d'examen productive autonome porte un {@code slotNumber}
     * ({@code AttemptService.startProductionAttempt}), une epreuve d'examen
     * blanc TCF <b>complet</b> est un sous-attempt rattache au parent
     * {@code TCF_COMPLET} ({@code FullTcfExamService}). Aucune des deux ne
     * declenche de requete supplementaire ici : le {@code slot_number} et la
     * clef etrangere {@code parent_attempt_id} sont deja sur la ligne
     * {@code attempts}, chargee en {@code JOIN FETCH} avec la soumission.
     */
    private static boolean isMockExam(ProductionSubmission submission) {
        Attempt attempt = submission.getAttempt();
        return attempt != null
                && (attempt.getSlotNumber() != null || attempt.getParentAttempt() != null);
    }

    private static String text(Object value) { return value == null ? "" : value.toString().trim(); }
    private static String nullableText(Object value) {
        String text = text(value);
        return text.isEmpty() ? null : text;
    }
    private static String truncate(String value, int max) {
        if (value == null) return null;
        String clean = value.strip();
        return clean.length() <= max ? clean : clean.substring(0, max);
    }

    private void saveIdempotently(LearningPlanObservation observation) {
        try {
            observationManager.save(observation);
        } catch (DataIntegrityViolationException concurrentDuplicate) {
            // uq_learning_plan_observation_source : un retry ou deux workers
            // concurrents aboutissent au même signal, jamais à un doublon.
        }
    }
}

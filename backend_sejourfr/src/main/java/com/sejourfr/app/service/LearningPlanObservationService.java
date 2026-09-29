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
import com.sejourfr.app.progression.domain.EvidenceEntryPoint;
import com.sejourfr.app.progression.domain.EvidenceSourceType;
import com.sejourfr.app.progression.service.ProductiveEvidenceAdapter;
import com.sejourfr.app.progression.service.ProductiveEvidenceAdapter.ObservationCompetence;
import com.sejourfr.app.service.competence.CompetenceAnalysisFields;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
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
@Slf4j
public class LearningPlanObservationService {

    private final LearningPlanObservationManager observationManager;
    private final UserSkillAttemptManager skillAttemptManager;
    private final ProductiveEvidenceAdapter productiveEvidenceAdapter;

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
        recordProductionProgression(submission, allowedSkills, analysis, baseline);
    }

    /**
     * La même évaluation, versée au <b>moteur de progression V4.2</b>
     * (docs/regles/progression.md).
     *
     * <p>Second producteur, à côté des observations du Plan : les deux coexistent
     * le temps du shadow mode. L'ancien alimente le Plan servi aujourd'hui, le
     * nouveau écrit dans son registre et prédit sans rien piloter.
     *
     * <p><b>Best-effort, jamais bloquant</b> : la livraison de son évaluation au
     * candidat ne doit pas dépendre de ce que le moteur en fait.
     */
    private void recordProductionProgression(ProductionSubmission submission,
                                             List<Skill> allowedSkills,
                                             Map<String, Object> analysis, boolean baseline) {
        if (submission.getUser() == null) {
            return;
        }
        try {
            Map<String, Skill> skillsByCode = new LinkedHashMap<>();
            allowedSkills.forEach(skill -> skillsByCode.put(skill.getCode(), skill));
            if (!(analysis.get("skills") instanceof List<?> observations)) {
                return;
            }
            List<ObservationCompetence> pourLeMoteur = new ArrayList<>();
            for (Object item : observations) {
                if (!(item instanceof Map<?, ?> value)) continue;
                String code = text(value.get("skill_code"));
                if (!skillsByCode.containsKey(code)) continue;
                pourLeMoteur.add(new ObservationCompetence(
                        code,
                        Boolean.TRUE.equals(value.get("observed")),
                        LearningPlanSkillStatus.valueOf(text(value.get("status"))),
                        ObservationConfidence.valueOf(text(value.get("confidence")))));
            }
            EpreuveType epreuve = submission.getProductionTask().getEpreuve();
            productiveEvidenceAdapter.ingererProduction(
                    submission.getUser().getId(),
                    submission.getAttempt() == null ? submission.getId()
                            : submission.getAttempt().getId(),
                    submission.getProductionTask().getId(),
                    epreuve == EpreuveType.TCF_EO
                            ? com.sejourfr.app.enums.SkillSection.EO
                            : com.sejourfr.app.enums.SkillSection.EE,
                    sourceProgression(submission, baseline),
                    entryPointProgression(submission, baseline),
                    Instant.now(),
                    pourLeMoteur);
        } catch (RuntimeException echec) {
            log.warn("Progression non alimentée pour la production {} : {}",
                    submission.getId(), echec.toString());
        }
    }

    /**
     * §5 — la <b>valeur pédagogique</b> de la production, jamais son point
     * d'entrée. Un examen blanc est la preuve la moins assistée dont on
     * dispose ; une tâche complète hors examen reste une preuve de transfert
     * (§17) ; un diagnostic ne verrouille jamais seul un palier (§16, T08).
     */
    private static EvidenceSourceType sourceProgression(ProductionSubmission submission,
                                                        boolean baseline) {
        if (baseline) {
            return EvidenceSourceType.DIAGNOSTIC;
        }
        if (!isMockExam(submission)) {
            return EvidenceSourceType.FULL_TASK;
        }
        Attempt attempt = submission.getAttempt();
        return attempt != null && attempt.getParentAttempt() != null
                ? EvidenceSourceType.FULL_MOCK_EXAM
                : EvidenceSourceType.DOMAIN_MOCK;
    }

    /** 🛑 Trace produit uniquement — n'entre dans aucun calcul (§1, T24). */
    private static EvidenceEntryPoint entryPointProgression(ProductionSubmission submission,
                                                            boolean baseline) {
        if (baseline) return EvidenceEntryPoint.DIAGNOSTIC;
        return isMockExam(submission) ? EvidenceEntryPoint.EXAM_HUB : EvidenceEntryPoint.PLAN;
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
        recordSkillAttemptProgression(attempt, skill);
    }

    /**
     * Le même micro-sujet, versé au moteur de progression.
     *
     * <p>Il y entre en {@code MICRO_SKILL} : poids 0,35, et masse de confiance
     * <b>plafonnée</b> (§11.1). Cinquante micro-sujets parfaits ne rendront
     * jamais une compétence {@code SOLID} à eux seuls — il faudra une vraie
     * tâche. C'est la différence entre savoir appliquer une consigne isolée et
     * savoir produire.
     */
    private void recordSkillAttemptProgression(UserSkillAttempt attempt, Skill skill) {
        if (attempt.getUser() == null) {
            return;
        }
        try {
            // Un micro-sujet affiche une checklist, une amorce, une astuce :
            // c'est sa raison d'être pédagogique, et c'est une assistance
            // réelle. Une preuve assistée doit peser moins (§8.2).
            boolean guide = attempt.getSkillPrompt().getChecklist() != null
                    || attempt.getSkillPrompt().getAnswerStarter() != null;
            productiveEvidenceAdapter.ingererMicroSujet(
                    attempt.getUser().getId(), attempt.getId(),
                    attempt.getSkillPrompt().getId(), attempt.getSkillPrompt().getSection(),
                    skill.getCode(), attempt.getCriterionStatus(), guide,
                    attempt.getUpdatedAt());
        } catch (RuntimeException echec) {
            log.warn("Progression non alimentée pour le micro-sujet {} : {}",
                    attempt.getId(), echec.toString());
        }
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

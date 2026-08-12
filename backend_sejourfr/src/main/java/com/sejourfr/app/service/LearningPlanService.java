package com.sejourfr.app.service;

import com.sejourfr.app.config.DiagnosticProperties;
import com.sejourfr.app.dto.LearningPlanDto;
import com.sejourfr.app.dto.LearningPlanPriorityDto;
import com.sejourfr.app.dto.LearningPlanSkillDto;
import com.sejourfr.app.dto.PlanChangeDto;
import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.dto.PlanSkillRefDto;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanState;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.temporal.TemporalAdjusters;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Le Plan dit quoi faire maintenant ; les statistiques historiques restent
 * séparées.
 *
 * <p><b>Le Plan reste intégralement visible</b>, y compris pour un compte sans
 * accès TCF : aucune priorité, aucune compétence observée et aucun compteur
 * n'est masqué. Seul un {@code locked} est posé, décidé par
 * {@link SkillAccessService} — masquer l'information priverait le candidat du
 * résultat de sa propre production. En revanche l'étape n'est pas
 * <b>finissable</b> sans abonnement : un compte gratuit joue 2 des
 * {@value LearningPlanStep#PROMPTS_PAR_ETAPE} sujets de l'étape.
 *
 * <p><b>Une priorité est une étape</b>, et une étape ce sont les
 * {@value LearningPlanStep#PROMPTS_PAR_ETAPE} premiers sujets actifs de sa
 * compétence (cf. {@link LearningPlanStep}) — pas ses 15 sujets. Les compteurs
 * d'étape voyagent <b>à côté</b> de ceux de la compétence, qui gardent la
 * sémantique de {@code SkillDto} et servent les cartes « compétences
 * observées » ({@code LearningPlanSkillDto}), lesquelles ne sont pas des étapes.
 */
@Service
@RequiredArgsConstructor
public class LearningPlanService {

    private static final ZoneId PARIS = ZoneId.of("Europe/Paris");

    private final DiagnosticProperties diagnosticProperties;
    private final ProductionTaskManager taskManager;
    private final DiagnosticSessionManager sessionManager;
    private final LearningPlanObservationManager observationManager;
    private final LearningPlanPriorityResolver priorityResolver;
    private final RecommendedExerciseSelector exerciseSelector;
    private final ReassessmentExerciseSelector reassessmentSelector;
    private final SkillProgressCounter progressCounter;
    private final SkillMasteryResolver masteryResolver;
    private final SkillAccessService accessService;

    @Transactional(readOnly = true)
    public LearningPlanDto get(UUID userId) {
        DiagnosticSession completed = sessionManager.findLatestCompleted(userId).orElse(null);
        if (completed == null) {
            DiagnosticSession inProgress = currentSession(userId);
            return new LearningPlanDto(
                    inProgress == null ? LearningPlanState.NEEDS_DIAGNOSTIC
                            : LearningPlanState.DIAGNOSTIC_IN_PROGRESS,
                    inProgress == null ? null : inProgress.getId(), null,
                    null, List.of(), List.of(), 0, 0, true);
        }

        // L'ordre des priorités vit dans LearningPlanPriorityResolver : c'est le
        // même code qui décide, côté accès, quelle compétence reste ouverte à un
        // compte gratuit. Deux copies auraient fini par désigner deux étapes n°1.
        List<LearningPlanObservation> allObservations =
                observationManager.findAllByUserWithSkill(userId);
        Map<UUID, LearningPlanObservation> latest =
                priorityResolver.latestObservedBySkill(allObservations);
        List<LearningPlanObservation> actionable = priorityResolver.actionable(latest.values());
        List<LearningPlanObservation> observedItems = latest.values().stream()
                .sorted(Comparator.comparing(LearningPlanObservation::getObservedAt).reversed())
                .limit(8)
                .toList();

        // Priorites et compétences observées se recouvrent largement : on les
        // compte ENSEMBLE, en une seule passe, plutot qu'une requete par carte.
        Set<UUID> skillIds = new LinkedHashSet<>();
        actionable.forEach(item -> skillIds.add(item.getSkill().getId()));
        observedItems.forEach(item -> skillIds.add(item.getSkill().getId()));
        Map<UUID, SkillProgressCounter.SkillProgress> progress =
                progressCounter.bySkillIds(userId, skillIds);
        // Le moteur de maitrise se branche sur l'historique DEJA charge par le
        // resolveur de priorites : le Plan lit toutes les observations du
        // candidat, il n'a aucune raison de les relire.
        Map<UUID, SkillMasteryEngine.SkillMastery> mastery =
                masteryResolver.fromObservations(allObservations, skillIds);
        // Résolu ici et transmis au sélecteur : le Plan pose « locked » sur les
        // priorités, les compétences observées ET l'exercice recommandé, ça ne
        // se calcule qu'une fois par appel.
        SkillAccessService.SkillAccess access = accessService.resolve(userId);
        Map<UUID, PlanRecommendedExerciseDto> exercises = exerciseSelector.selectAll(
                userId, actionable.stream().map(LearningPlanObservation::getSkill).toList(),
                access);

        // BASCULE DE L'ETAPE : quand le moteur juge la competence prete a etre
        // verifiee, la meme carte cesse de proposer un micro-sujet et propose une
        // vraie tache. L'etape ne se dedouble jamais. Si la tache n'a aucun sujet
        // publie, la verification est simplement absente et le micro-exercice
        // reste — rien ne casse.
        List<Skill> toVerify = actionable.stream()
                .filter(item -> mastery(mastery, item).readyForReassessment())
                .map(LearningPlanObservation::getSkill)
                .toList();
        Map<UUID, PlanRecommendedExerciseDto> verifications =
                toVerify.isEmpty() ? Map.of() : reassessmentSelector.selectAll(userId, toVerify);

        List<LearningPlanPriorityDto> priorities = actionable.stream()
                .map(item -> priority(item,
                        nextExercise(item, mastery(mastery, item), exercises, verifications),
                        progress(progress, item), mastery(mastery, item),
                        access.isSkillLocked(item.getSkill().getId())))
                .toList();

        List<LearningPlanSkillDto> observed = observedItems.stream()
                .map(item -> {
                    SkillProgressCounter.SkillProgress counts = progress(progress, item);
                    return new LearningPlanSkillDto(
                            item.getSkill().getId(), item.getSkill().getCode(),
                            item.getSkill().getTitle(), item.getSkill().getSection(),
                            item.getStatus(), item.getObservedAt(),
                            counts.promptCount(), counts.attemptedCount(), counts.validatedCount(),
                            mastery(mastery, item).state(),
                            access.isSkillLocked(item.getSkill().getId()));
                })
                .toList();
        int observedCount = latest.size();
        int activities = Math.toIntExact(observationManager.countSince(userId, startOfWeek()));
        return new LearningPlanDto(
                LearningPlanState.ACTIVE, completed.getId(), completed.getCompletedAt(),
                priorities.isEmpty() ? null : priorities.getFirst(),
                priorities.size() <= 1 ? List.of() : priorities.subList(1, priorities.size()),
                observed, observedCount, activities, true);
    }

    /**
     * Ce que cette production vient de changer dans le Plan, ou rien.
     *
     * <p>Calcule <b>a la lecture</b>, a partir des observations reellement
     * ecrites par cette soumission. C'est ce qui rend la course sans consequence :
     * les observations sont posees apres la correction, en best-effort et hors
     * transaction ; tant qu'elles ne sont pas la, le bloc est simplement absent,
     * et la lecture suivante le rend. Aucun etat d'echec, aucun rejeu.
     *
     * <p>« Confirmee » veut dire {@code SOLID} <b>en situation</b> : les
     * observations du diagnostic (la baseline) et des micro-exercices ne peuvent
     * pas confirmer, par construction du moteur de maitrise. La « nouvelle
     * priorite » n'est annoncee que si c'est bien <b>cette</b> production qui l'a
     * designee — sinon le candidat lirait comme une nouveaute une etape qu'il a
     * deja sous les yeux.
     */
    @Transactional(readOnly = true)
    public Optional<PlanChangeDto> changeAfterProduction(UUID userId, UUID submissionId) {
        if (submissionId == null) return Optional.empty();
        List<LearningPlanObservation> all = observationManager.findAllByUserWithSkill(userId);
        List<LearningPlanObservation> fromSubmission = all.stream()
                .filter(item -> submissionId.equals(item.getSourceId()))
                .filter(item -> item.getSourceType() != null && item.getSourceType().isContextual())
                .filter(LearningPlanObservation::isObserved)
                .toList();
        if (fromSubmission.isEmpty()) return Optional.empty();

        LearningPlanObservation confirmed = fromSubmission.stream()
                .filter(item -> item.getStatus() == LearningPlanSkillStatus.SOLID)
                .min(Comparator
                        .comparingInt(LearningPlanService::confidenceRank)
                        .thenComparing(item -> item.getSkill().getCode()))
                .orElse(null);

        LearningPlanObservation top = priorityResolver
                .actionable(priorityResolver.latestObservedBySkill(all).values()).stream()
                .findFirst()
                .orElse(null);
        boolean nouvelle = top != null
                && submissionId.equals(top.getSourceId())
                && (confirmed == null
                        || !top.getSkill().getId().equals(confirmed.getSkill().getId()));

        if (confirmed == null && !nouvelle) return Optional.empty();
        return Optional.of(new PlanChangeDto(
                confirmed == null ? null : ref(confirmed),
                nouvelle ? ref(top) : null));
    }

    /** La plus sure d'abord : a plusieurs confirmations, on n'en annonce qu'une. */
    private static int confidenceRank(LearningPlanObservation observation) {
        ObservationConfidence confidence = observation.getConfidence();
        if (confidence == null) return 1;
        return switch (confidence) {
            case HIGH -> 0;
            case MEDIUM -> 1;
            case LOW -> 2;
        };
    }

    private static PlanSkillRefDto ref(LearningPlanObservation observation) {
        return new PlanSkillRefDto(
                observation.getSkill().getId(), observation.getSkill().getCode(),
                observation.getSkill().getTitle(), observation.getSkill().getSection());
    }

    /**
     * L'exercice de l'etape : la verification en situation quand le signal est
     * pose ET qu'un sujet est disponible, le micro-exercice sinon.
     */
    private static PlanRecommendedExerciseDto nextExercise(
            LearningPlanObservation observation,
            SkillMasteryEngine.SkillMastery mastery,
            Map<UUID, PlanRecommendedExerciseDto> exercises,
            Map<UUID, PlanRecommendedExerciseDto> verifications) {
        UUID skillId = observation.getSkill().getId();
        if (mastery.readyForReassessment() && verifications.containsKey(skillId)) {
            return verifications.get(skillId);
        }
        return exercises.get(skillId);
    }

    private DiagnosticSession currentSession(UUID userId) {
        String code = diagnosticProperties.getInitialCode();
        Integer version = taskManager.findLatestActiveDiagnosticVersion(code).orElse(null);
        return version == null ? null
                : sessionManager.findByUserAndVersionWithContent(userId, code, version).orElse(null);
    }

    private LearningPlanPriorityDto priority(
            LearningPlanObservation observation,
            PlanRecommendedExerciseDto exercise,
            SkillProgressCounter.SkillProgress counts,
            SkillMasteryEngine.SkillMastery mastery,
            boolean locked) {
        LearningPlanStep.Progress step = counts.step();
        return new LearningPlanPriorityDto(
                observation.getSkill().getId(), observation.getSkill().getCode(),
                observation.getSkill().getTitle(), observation.getSkill().getSection(),
                observation.getStatus(), observation.getExplanation(), observation.getEvidence(),
                observation.getConfidence(), observation.getObservedAt(), exercise,
                counts.promptCount(), counts.attemptedCount(), counts.validatedCount(),
                step.promptCount(), step.attemptedCount(), step.validatedCount(),
                step.completed(), mastery.state(), mastery.readyForReassessment(), locked);
    }

    private static SkillMasteryEngine.SkillMastery mastery(
            Map<UUID, SkillMasteryEngine.SkillMastery> mastery,
            LearningPlanObservation observation) {
        return mastery.getOrDefault(
                observation.getSkill().getId(), SkillMasteryEngine.SkillMastery.NONE);
    }

    private static SkillProgressCounter.SkillProgress progress(
            Map<UUID, SkillProgressCounter.SkillProgress> progress,
            LearningPlanObservation observation) {
        return progress.getOrDefault(
                observation.getSkill().getId(), SkillProgressCounter.SkillProgress.EMPTY);
    }

    private static Instant startOfWeek() {
        ZonedDateTime now = ZonedDateTime.now(PARIS);
        return now.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
                .toLocalDate().atStartOfDay(PARIS).toInstant();
    }
}

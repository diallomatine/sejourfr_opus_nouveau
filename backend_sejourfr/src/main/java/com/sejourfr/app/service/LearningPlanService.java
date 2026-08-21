package com.sejourfr.app.service;

import com.sejourfr.app.config.DiagnosticProperties;
import com.sejourfr.app.dto.LearningPlanCompletedStepDto;
import com.sejourfr.app.dto.LearningPlanDto;
import com.sejourfr.app.dto.LearningPlanPriorityDto;
import com.sejourfr.app.dto.LearningPlanSkillDto;
import com.sejourfr.app.dto.PlanChangeDto;
import com.sejourfr.app.dto.PlanRecentChangesDto;
import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.dto.PlanSeanceDto;
import com.sejourfr.app.dto.PlanSkillRefDto;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanState;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanCycleState;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.manager.UserManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.temporal.TemporalAdjusters;
import java.util.Comparator;
import java.util.LinkedHashMap;
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
 *
 * <p><b>Une étape franchie ne disparaît pas du parcours</b> : elle passe de
 * {@code priorities} à {@code completedSteps} et s'affiche cochée, avant l'étape
 * courante. Sortir des priorités, c'est avancer, pas effacer.
 *
 * <p><b>Deux blocs se dérivent de tout ce qui précède, sans une requête de
 * plus.</b> La <b>séance du jour</b> ({@link PlanSeanceBuilder}) republie les
 * priorités et le jalon sous forme d'entraînements bornés, et ne lit
 * <b>aucune date</b> — c'est ce qui rend la règle « sticky » gratuite : sans
 * nouvelle observation, les priorités ne bougent pas, donc la séance non plus.
 * « <b>Ce qui a changé</b> » ({@link PlanRecentChangesResolver}) fait rejouer le
 * moteur de maîtrise sur l'historique déjà chargé, arrêté au début d'une
 * fenêtre puis complet : la différence des deux états <b>est</b> le changement,
 * et son absence — le cas normal — se dit par un bloc {@code null}.
 */
@Service
@RequiredArgsConstructor
public class LearningPlanService {

    /**
     * Etapes <b>franchies</b> republiées dans le parcours, les plus récentes.
     *
     * <p>Elles s'accumulent sans fin — un candidat assidu en aligne des dizaines
     * — et un parcours de quarante étapes ne se lit plus. Cinq est le même ordre
     * de grandeur que ce que le Plan sert déjà par ailleurs
     * ({@value LearningPlanPriorityResolver#MAX_PRIORITIES} priorités, 8
     * compétences observées) : de quoi montrer un chemin parcouru sans noyer
     * l'étape en cours, qui reste ce que le Plan vient dire. L'historique
     * complet, lui, appartient à l'écran Progression.
     */
    public static final int MAX_COMPLETED_STEPS = 5;

    private static final ZoneId PARIS = ZoneId.of("Europe/Paris");

    private final DiagnosticProperties diagnosticProperties;
    private final ProductionTaskManager taskManager;
    private final DiagnosticSessionManager sessionManager;
    private final LearningPlanObservationManager observationManager;
    private final LearningPlanPriorityResolver priorityResolver;
    private final RecommendedExerciseSelector exerciseSelector;
    private final ReassessmentExerciseSelector reassessmentSelector;
    private final PlanMilestoneSelector milestoneSelector;
    private final SkillProgressCounter progressCounter;
    private final SkillMasteryResolver masteryResolver;
    private final SkillAccessService accessService;
    private final PlanCycleResolver cycleResolver;
    private final PlanSeanceBuilder seanceBuilder;
    private final PlanRecentChangesResolver recentChangesResolver;
    private final UserManager userManager;

    @Transactional(readOnly = true)
    public LearningPlanDto get(UUID userId) {
        User user = userManager.findById(userId).orElse(null);
        DiagnosticSession completed = sessionManager.findLatestCompleted(userId).orElse(null);
        if (completed == null) {
            DiagnosticSession inProgress = currentSession(userId);
            // Le profil et le cycle sont servis MEME SANS DIAGNOSTIC : c'est
            // exactement l'ecran dont a besoin un candidat qui a fait une serie
            // de comprehension sans jamais passer le diagnostic (brief §3, §6).
            // Le diagnostic decide des PRIORITES, pas de la connaissance qu'on a
            // de ses domaines.
            PlanCycleResolver.Resolution profil =
                    cycleResolver.resolve(user, List.of(), List.of());
            return new LearningPlanDto(
                    inProgress == null ? LearningPlanState.NEEDS_DIAGNOSTIC
                            : LearningPlanState.DIAGNOSTIC_IN_PROGRESS,
                    inProgress == null ? null : inProgress.getId(), null,
                    List.of(), null, List.of(), List.of(), 0, 0, true, null,
                    profil.domaines(), profil.cycle(),
                    // Aucune priorite, donc aucune seance et rien qui ait bouge :
                    // le Plan sert le profil, pas une journee de travail.
                    new PlanSeanceDto(List.of(), 0), null);
        }

        // L'ordre des priorités vit dans LearningPlanPriorityResolver : c'est le
        // même code qui décide, côté accès, quelle compétence reste ouverte à un
        // compte gratuit. Deux copies auraient fini par désigner deux étapes n°1.
        // Il reçoit l'historique ENTIER, pas seulement la dernière observation de
        // chaque compétence : c'est lui qui écarte les compétences dont le
        // transfert est déjà prouvé en situation — « une fois réussi, on passe à
        // la compétence suivante ».
        List<LearningPlanObservation> allObservations =
                observationManager.findAllByUserWithSkill(userId);
        Map<UUID, LearningPlanObservation> latest =
                priorityResolver.latestObservedBySkill(allObservations);
        // Le moteur de maitrise se branche sur l'historique DEJA charge : le Plan
        // lit toutes les observations du candidat, il n'a aucune raison de les
        // relire. Le calcul porte sur TOUTES les competences observees, pas
        // seulement sur celles des cartes : le jalon d'epreuve compte les
        // competences transferees, et une competence dont le transfert est prouve
        // n'est jamais une priorite.
        //
        // Il est calcule AVANT les priorites et leur est passe : c'est lui qui
        // decide desormais qu'une competence sort du parcours, et le recalculer
        // dans le resolveur ferait tourner deux fois le meme calcul par lecture.
        Map<UUID, SkillMasteryEngine.SkillMastery> mastery =
                masteryResolver.fromObservations(allObservations, latest.keySet());
        List<LearningPlanObservation> actionable =
                priorityResolver.actionable(allObservations, mastery);
        // Les etapes FRANCHIES restent dans le parcours, cochees, au lieu de
        // disparaitre : sans elles le candidat perdait la trace de ce qu'il avait
        // passe. Bornees aux plus recentes — elles s'accumulent sans fin.
        List<LearningPlanObservation> franchies =
                priorityResolver.franchies(allObservations, mastery).stream()
                        .limit(MAX_COMPLETED_STEPS)
                        .toList();
        List<LearningPlanObservation> observedItems = latest.values().stream()
                .sorted(Comparator.comparing(LearningPlanObservation::getObservedAt).reversed())
                .limit(8)
                .toList();

        // Priorites, etapes franchies et compétences observées se recouvrent
        // largement : on les compte ENSEMBLE, en une seule passe (2 requetes quel
        // que soit le nombre de competences), plutot qu'une requete par carte.
        Set<UUID> skillIds = new LinkedHashSet<>();
        actionable.forEach(item -> skillIds.add(item.getSkill().getId()));
        franchies.forEach(item -> skillIds.add(item.getSkill().getId()));
        observedItems.forEach(item -> skillIds.add(item.getSkill().getId()));
        // Résolu ici et transmis aux sélecteurs : le Plan pose « locked » sur
        // les priorités, les compétences observées ET l'exercice recommandé.
        // Ça ne se calcule qu'une fois par appel.
        SkillAccessService.SkillAccess access = accessService.resolve(userId);
        Map<UUID, SkillProgressCounter.SkillProgress> progress =
                progressCounter.bySkillIds(userId, skillIds);
        Map<UUID, PlanRecommendedExerciseDto> exercises = exerciseSelector.selectAll(
                userId, actionable.stream().map(LearningPlanObservation::getSkill).toList(),
                access);

        // BASCULE DE L'ETAPE : quand le moteur juge la competence prete a etre
        // verifiee ET que l'etape est TERMINEE, la meme carte cesse de proposer
        // un micro-sujet et propose une vraie tache. L'etape ne se dedouble
        // jamais. Si la tache n'a aucun sujet publie, la verification est
        // simplement absente et le micro-exercice reste — rien ne casse.
        //
        // La SECONDE condition manquait : le moteur ne voit pas l'etape, et un
        // candidat ayant valide 2 des 5 sujets se voyait proposer « verifier ma
        // progression » sous un anneau affichant 2/5.
        //
        // Le perimetre de cette condition est l'ETAPE ENTIERE (les 5 sujets
        // editoriaux), pas ce que l'acces du candidat lui ouvre. C'est un
        // ARBITRAGE PRODUIT du proprietaire (2026-08-14) : la verification de
        // progression est PREMIUM. Un compte gratuit plafonne a 2 sujets sur 5
        // (SkillAccessService.FREE_PROMPTS_PER_SKILL), donc il ne bascule
        // jamais — et par voie de consequence aucune de ses competences
        // n'atteint SOLID (qui exige la preuve contextualisee que seule cette
        // verification apporte), donc il ne voit pas non plus les jalons de
        // PlanMilestoneSelector, dont le declencheur d'epreuve demande >= 2
        // competences SOLID. Ces trois consequences sont VOULUES : ce n'est pas
        // un bug freemium, ne pas retablir un comptage des sujets ouverts pour
        // les « corriger ».
        Map<UUID, Boolean> readyToVerify = new LinkedHashMap<>();
        actionable.forEach(item -> readyToVerify.put(item.getSkill().getId(),
                mastery(mastery, item).readyForReassessment()
                        && progress(progress, item).step().completed()));
        List<Skill> toVerify = actionable.stream()
                .filter(item -> Boolean.TRUE.equals(readyToVerify.get(item.getSkill().getId())))
                .map(LearningPlanObservation::getSkill)
                .toList();
        Map<UUID, PlanRecommendedExerciseDto> verifications =
                toVerify.isEmpty() ? Map.of() : reassessmentSelector.selectAll(userId, toVerify);

        List<LearningPlanPriorityDto> priorities = actionable.stream()
                .map(item -> priority(item,
                        nextExercise(item, readyToVerify, exercises, verifications),
                        progress(progress, item), mastery(mastery, item),
                        Boolean.TRUE.equals(readyToVerify.get(item.getSkill().getId())),
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
        // De la plus ancienne a la plus recente : c'est le sens dans lequel un
        // parcours se lit, et les etapes franchies precedent l'etape courante.
        List<LearningPlanCompletedStepDto> completedSteps = franchies.reversed().stream()
                .map(item -> completedStep(item, progress(progress, item), mastery(mastery, item)))
                .toList();
        int observedCount = latest.size();
        int activities = Math.toIntExact(observationManager.countSince(userId, startOfWeek()));
        // Le CYCLE de palier : d'ou part le candidat, quel palier se construit,
        // et l'etat des quatre domaines. Il recoit les priorites DEJA ordonnees
        // — leur absence est ce qui ouvre le gate, et la premiere d'entre elles
        // designe le domaine « Priorite forte ». Deux lectures de l'ordre des
        // priorites auraient fini par se contredire a l'ecran.
        PlanCycleResolver.Resolution profil =
                cycleResolver.resolve(user, allObservations, actionable);
        // Le JALON vit a cote des priorites, il ne les remplace pas : les etapes
        // continuent de porter leur propre exercice. Absent tant qu'aucune
        // epreuve n'a majoritairement transfere — cas normal, pas une erreur.
        // Le gate de palier lui est passe, jamais servi a cote : c'est le meme
        // examen blanc complet, et il n'a qu'un seul designateur.
        PlanRecommendedExerciseDto milestone = milestoneSelector.select(
                userId, latest.values(), mastery, allObservations,
                profil.cycle().state() == PlanCycleState.READY_FOR_GATE_MOCK,
                Instant.now()).orElse(null);
        // LA SEANCE est une VUE de ce qui precede : elle ne choisit aucun
        // exercice, elle ordonne et borne ceux que les trois autorites ont deja
        // designes, et recalcule le total de minutes. Aucune date n'y entre —
        // c'est ce qui rend la stickiness gratuite : sans nouvelle observation,
        // les priorites ne bougent pas, donc la seance non plus.
        Map<UUID, Skill> skillsDesPriorites = new LinkedHashMap<>();
        actionable.forEach(item -> skillsDesPriorites.put(
                item.getSkill().getId(), item.getSkill()));
        PlanSeanceDto seance = seanceBuilder.build(priorities, skillsDesPriorites, milestone);
        // CE QUI A CHANGE : le meme moteur, joue deux fois sur l'historique deja
        // charge — aucune requete, aucune regle recopiee. La priorite n°1 lui est
        // passee telle que le resolveur l'a designee : ce bloc ne peut donc pas
        // nommer une autre etape que celle affichee juste au-dessus.
        PlanRecentChangesDto changes = recentChangesResolver.resolve(
                allObservations, mastery,
                actionable.isEmpty() ? null : actionable.getFirst(), Instant.now())
                .orElse(null);
        return new LearningPlanDto(
                LearningPlanState.ACTIVE, completed.getId(), completed.getCompletedAt(),
                completedSteps,
                priorities.isEmpty() ? null : priorities.getFirst(),
                priorities.size() <= 1 ? List.of() : priorities.subList(1, priorities.size()),
                observed, observedCount, activities, true, milestone,
                profil.domaines(), profil.cycle(), seance, changes);
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

        LearningPlanObservation top = priorityResolver.actionable(all).stream()
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
            Map<UUID, Boolean> readyToVerify,
            Map<UUID, PlanRecommendedExerciseDto> exercises,
            Map<UUID, PlanRecommendedExerciseDto> verifications) {
        UUID skillId = observation.getSkill().getId();
        if (Boolean.TRUE.equals(readyToVerify.get(skillId)) && verifications.containsKey(skillId)) {
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
            boolean readyForReassessment,
            boolean locked) {
        LearningPlanStep.Progress step = counts.step();
        return new LearningPlanPriorityDto(
                observation.getSkill().getId(), observation.getSkill().getCode(),
                observation.getSkill().getTitle(), observation.getSkill().getSection(),
                observation.getStatus(), observation.getExplanation(), observation.getEvidence(),
                observation.getConfidence(), observation.getObservedAt(), exercise,
                counts.promptCount(), counts.attemptedCount(), counts.validatedCount(),
                step.promptCount(), step.attemptedCount(), step.validatedCount(),
                step.completed(), step.promptIds(),
                mastery.state(), readyForReassessment, locked);
    }

    /**
     * Une etape franchie : la meme carte qu'une priorite, sans exercice ni
     * cadenas — il n'y a plus rien a y faire, et une etape franchie n'est pas
     * une porte commerciale.
     */
    private static LearningPlanCompletedStepDto completedStep(
            LearningPlanObservation observation,
            SkillProgressCounter.SkillProgress counts,
            SkillMasteryEngine.SkillMastery mastery) {
        LearningPlanStep.Progress step = counts.step();
        return new LearningPlanCompletedStepDto(
                observation.getSkill().getId(), observation.getSkill().getCode(),
                observation.getSkill().getTitle(), observation.getSkill().getSection(),
                observation.getObservedAt(),
                step.promptCount(), step.attemptedCount(), step.validatedCount(),
                step.promptIds(), mastery.state());
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

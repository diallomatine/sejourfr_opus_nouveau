package com.sejourfr.app.service;

import com.sejourfr.app.config.DiagnosticProperties;
import com.sejourfr.app.dto.LearningPlanCompletedStepDto;
import com.sejourfr.app.dto.LearningPlanDto;
import com.sejourfr.app.dto.LearningPlanPriorityDto;
import com.sejourfr.app.dto.LearningPlanSkillDto;
import com.sejourfr.app.dto.PlanChangeDto;
import com.sejourfr.app.dto.PlanDomainDto;
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
import com.sejourfr.app.dto.PlanDomainAssessmentDto;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanActionNature;
import com.sejourfr.app.enums.PlanCycleState;
import com.sejourfr.app.enums.PlanExerciseKind;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.plan.PlanConfig;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
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
    private final PlanDomainAssessmentResolver assessmentResolver;
    private final PlanAcquisitionSelector acquisitionSelector;
    private final PlanContentAvailability contentAvailability;
    private final PlanActionRanker actionRanker;
    private final PlanConfig planConfig;
    private final PlanDomainSkillResolver domainSkillResolver;
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
            // Les competences de chaque epreuve sont servies AUSSI ici : sans
            // diagnostic elles sont toutes NOT_OBSERVED, ce qui est exactement
            // ce que l'ecran doit montrer — un referentiel entier a decouvrir,
            // pas quatre cartes vides. Seul le verrou est une vraie information,
            // et il se lit chez son unique autorite.
            List<PlanDomainDto> domaines = domainSkillResolver.attach(
                    profil.domaines(), profil.referentiel(),
                    Map.of(), Map.of(), Map.of(), accessService.resolve(userId, null));
            return new LearningPlanDto(
                    inProgress == null ? LearningPlanState.NEEDS_DIAGNOSTIC
                            : LearningPlanState.DIAGNOSTIC_IN_PROGRESS,
                    inProgress == null ? null : inProgress.getId(), null,
                    List.of(), null, List.of(), List.of(), 0, 0, true, null,
                    domaines, profil.cycle(),
                    // Aucun diagnostic termine : les deux domaines d'expression
                    // pointent vers le diagnostic, les deux de comprehension vers
                    // leur examen blanc de module. C'est exactement l'ecran
                    // d'onboarding du brief §6 — et il n'est jamais vide.
                    assessmentResolver.resolve(domaines, false),
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

        // La DERNIERE ACTIVITE de chaque competence, tiree de l'historique DEJA
        // charge : une passe, zero requete. Elle sert deux fois — la coche de la
        // seance (un fait, jamais un booleen « fait aujourd'hui ») et, ci-dessous,
        // « cette competence a-t-elle deja ete travaillee ? », qui decide de ce
        // qu'il reste a APPRENDRE.
        Map<UUID, Instant> lastActivity = priorityResolver.lastActivityBySkill(allObservations);
        // Le CYCLE de palier : d'ou part le candidat, quel palier se construit,
        // et l'etat des quatre domaines. Il recoit les priorites DEJA ordonnees
        // — leur absence est ce qui ouvre le gate, et la premiere d'entre elles
        // designe le domaine « Priorite forte ». Deux lectures de l'ordre des
        // priorites auraient fini par se contredire a l'ecran.
        PlanCycleResolver.Resolution profil =
                cycleResolver.resolve(user, allObservations, actionable);
        // CE QU'IL RESTE A APPRENDRE. Le Plan savait reparer, il ne savait pas
        // enseigner : un candidat sans fragilite mais a un palier entier de son
        // objectif n'avait rien a faire. Ces competences ne sont PAS des
        // observations — elles n'entrent ni dans le moteur de maitrise, ni dans
        // une moyenne, ni dans un compte de fragilites — et elles ne remplissent
        // rien : le selecteur ne rend que des competences du palier en
        // construction reellement jamais travaillees, donc zero quand il n'y en
        // a pas.
        // 🛑 AUCUN PLAFOND ICI. Le pool est calcule ENTIER, et c'est l'affichage
        // qui coupe (plan-config, display.*). Le budget « 5 - fragilites » qui
        // vivait a cette ligne etait le trou principal du 2026-08-25 : un
        // plafond d'ecran servait de budget de production a QUATRE domaines, et
        // les deux places restantes partaient toujours au domaine le plus
        // urgent. Dix actions vraies existaient, deux etaient servies.
        //
        // Le palier vient desormais de chaque DOMAINE, plus du cycle global.
        PlanContentAvailability.Disponibilite disponibilite = contentAvailability.charger();
        List<Skill> acquisitions = acquisitionSelector.select(
                userId, profil.domaines(), lastActivity.keySet(),
                profil.cycle().objectiveLevel(), disponibilite);

        // Priorites, competences a acquerir, etapes franchies et compétences
        // observées se recouvrent largement : on les compte ENSEMBLE, en une
        // seule passe (2 requetes quel que soit le nombre de competences),
        // plutot qu'une requete par carte.
        Set<UUID> skillIds = new LinkedHashSet<>();
        actionable.forEach(item -> skillIds.add(item.getSkill().getId()));
        acquisitions.forEach(skill -> skillIds.add(skill.getId()));
        franchies.forEach(item -> skillIds.add(item.getSkill().getId()));
        observedItems.forEach(item -> skillIds.add(item.getSkill().getId()));
        // Résolu ici et transmis aux sélecteurs : le Plan pose « locked » sur
        // les priorités, les compétences observées ET l'exercice recommandé.
        // Ça ne se calcule qu'une fois par appel.
        //
        // La PREMIERE PLACE lui est passee, pas redemandee : le Plan vient de
        // l'etablir (premiere fragilite, a defaut premiere acquisition), et
        // c'est elle que le freemium ouvre. La faire recalculer par le service
        // d'acces ferait tourner le cycle de palier une seconde fois dans la
        // meme lecture — et rendrait le cout du Plan dependant du nombre de
        // fragilites du candidat, ce que ses deux tests de cout interdisent.
        Optional<UUID> focusSkillId = PlanFocusResolver.focus(actionable, acquisitions);
        SkillAccessService.SkillAccess access = accessService.resolve(
                userId, focusSkillId.orElse(null));
        Map<UUID, SkillProgressCounter.SkillProgress> progress =
                progressCounter.bySkillIds(userId, skillIds);
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
        //
        // Elle est calculee AVANT le classement : c'est elle qui decide de la
        // NATURE d'une fragilite (A_RENFORCER ou A_VERIFIER), et la nature est
        // le premier terme du score.
        Map<UUID, Boolean> readyToVerify = new LinkedHashMap<>();
        actionable.forEach(item -> readyToVerify.put(item.getSkill().getId(),
                mastery(mastery, item).readyForReassessment()
                        && progress(progress, item).step().completed()));

        // LE POOL COMPLET : toutes les fragilites, toutes les acquisitions.
        // Rien n'est tronque ici — c'est exactement ce que le 2026-08-25 a
        // coute : un plafond d'affichage servait de budget de production.
        //
        // FILTRE DE FAISABILITE (§8) : une competence sans contenu publie ne
        // porte aucune action. Il s'applique au POOL, pas a `actionable` qui
        // vient d'etre passe au cycle — une fragilite reelle reste une
        // fragilite meme si son catalogue est vide, et elle ne doit pas ouvrir
        // le gate de palier par disparition.
        Map<UUID, LearningPlanObservation> fragilitesParSkill = new LinkedHashMap<>();
        actionable.forEach(item -> fragilitesParSkill.put(item.getSkill().getId(), item));
        List<Skill> fragilites = actionable.stream()
                .map(LearningPlanObservation::getSkill).toList();
        // Le palier d'une fragilite est celui que porte la competence : en
        // comprehension c'est lui qui dit dans quel stock la serie ciblee va
        // tirer. Sans lui, TOUTE competence de comprehension serait jugee
        // inexecutable — et le Plan perdrait des fragilites reelles.
        Map<UUID, TargetLevel> palierDesFragilites = new LinkedHashMap<>();
        fragilites.forEach(skill -> {
            TargetLevel palier = PlanCycleResolver.palier(skill.getTargetLevel());
            if (palier != null) palierDesFragilites.put(skill.getId(), palier);
        });
        List<Skill> fragilesExecutables =
                disponibilite.filtrer(fragilites, palierDesFragilites);
        Map<UUID, Skill> acquisitionsParSkill = new LinkedHashMap<>();
        acquisitions.forEach(skill -> acquisitionsParSkill.put(skill.getId(), skill));

        List<PlanActionRanker.Action> pool = new ArrayList<>();
        for (Skill skill : fragilesExecutables) {
            LearningPlanObservation item = fragilitesParSkill.get(skill.getId());
            pool.add(new PlanActionRanker.Action(
                    skill.getId(), skill.getCode(), skill.getSection(),
                    Boolean.TRUE.equals(readyToVerify.get(skill.getId()))
                            ? PlanActionNature.A_VERIFIER : PlanActionNature.A_RENFORCER,
                    item.getConfidence(), item.getObservedAt()));
        }
        for (Skill skill : acquisitions) {
            pool.add(new PlanActionRanker.Action(
                    skill.getId(), skill.getCode(), skill.getSection(),
                    PlanActionNature.A_ACQUERIR, null, null));
        }
        Map<com.sejourfr.app.enums.SkillSection, PlanDomainDto> domainesParSection =
                new LinkedHashMap<>();
        profil.domaines().forEach(domaine -> domainesParSection.putIfAbsent(
                PlanCycleResolver.section(domaine.epreuve()), domaine));
        // CLASSEMENT puis COMPOSITION, poids et plafonds lus en configuration.
        // La premiere place est epinglee : c'est celle que le freemium ouvre, et
        // un classement qui la deplacerait cadenasserait l'etape n°1.
        List<PlanActionRanker.Action> composed = actionRanker.classer(
                pool, domainesParSection, profil.cycle().objectiveLevel(),
                focusSkillId.orElse(null));

        // L'AFFICHAGE coupe, et lui seul. Les exercices ne sont resolus que pour
        // ce qui est reellement affiche : le pool peut compter vingt actions, en
        // charger les sujets serait payer une lecture de catalogue par lecture
        // du Plan.
        List<PlanActionRanker.Action> affichees = composed.stream()
                .limit(planConfig.display().prioritiesMaxActions())
                .toList();
        List<Skill> aExercer = affichees.stream()
                .map(action -> acquisitionsParSkill.containsKey(action.skillId())
                        ? acquisitionsParSkill.get(action.skillId())
                        : fragilitesParSkill.get(action.skillId()).getSkill())
                .toList();
        Map<UUID, PlanRecommendedExerciseDto> exercises =
                exerciseSelector.selectAll(userId, aExercer, access);
        List<Skill> toVerify = affichees.stream()
                .filter(action -> action.nature() == PlanActionNature.A_VERIFIER)
                .map(action -> fragilitesParSkill.get(action.skillId()).getSkill())
                .toList();
        Map<UUID, PlanRecommendedExerciseDto> verifications =
                toVerify.isEmpty() ? Map.of() : reassessmentSelector.selectAll(userId, toVerify);

        // LES CARTES, dans l'ordre du classement — fragilites et acquisitions
        // melangees, parce que « reparer » et « apprendre » sont deux actions du
        // meme parcours et que c'est le score qui les departage, plus leur
        // categorie.
        List<LearningPlanPriorityDto> priorities = new ArrayList<>();
        for (PlanActionRanker.Action action : affichees) {
            PlanRecommendedExerciseDto exercise = exercises.get(action.skillId());
            LearningPlanObservation fragilite = fragilitesParSkill.get(action.skillId());
            if (fragilite != null) {
                boolean verifier = action.nature() == PlanActionNature.A_VERIFIER;
                priorities.add(priority(fragilite,
                        verifier && verifications.containsKey(action.skillId())
                                ? verifications.get(action.skillId()) : exercise,
                        progress(progress, fragilite), mastery(mastery, fragilite),
                        verifier, access.isSkillLocked(action.skillId())));
                continue;
            }
            // Sans exercice publie, une acquisition n'a rien a proposer et
            // n'entre pas — jamais une carte sans action. Le filtre §8 rend ce
            // cas quasi impossible ; il reste la ceinture.
            if (exercise == null) continue;
            priorities.add(acquisition(acquisitionsParSkill.get(action.skillId()), exercise,
                    progress.getOrDefault(action.skillId(),
                            SkillProgressCounter.SkillProgress.EMPTY),
                    access.isSkillLocked(action.skillId())));
        }

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
        // Le JALON vit a cote des priorites, il ne les remplace pas : les etapes
        // continuent de porter leur propre exercice. Absent tant qu'aucune
        // epreuve n'a majoritairement transfere — cas normal, pas une erreur.
        // Le gate de palier lui est passe, jamais servi a cote : c'est le meme
        // examen blanc complet, et il n'a qu'un seul designateur.
        PlanRecommendedExerciseDto milestone = milestoneSelector.select(
                userId, latest.values(), mastery, allObservations,
                profil.cycle().state() == PlanCycleState.READY_FOR_GATE_MOCK,
                Instant.now()).orElse(null);
        // 🛑 PROFIL INCOMPLET : PAS D'EXAMEN DE PALIER (brief §77). Le gate du
        // cycle exige deja les 4/4 (PlanCycleResolver), mais l'ECHELLE des
        // jalons, elle, ne connait pas le profil : un candidat dont l'ecrit et
        // l'oral ont transfere et fait leurs preuves se voyait proposer l'examen
        // blanc COMPLET alors que sa comprehension n'avait jamais ete mesuree —
        // exactement le cas que le brief nomme (« EE solide, EO solide, CO non
        // evaluee, CE non evaluee »). On ne confirme pas un palier sur deux
        // domaines sur quatre : le Plan met d'abord en avant « Completer mon
        // profil » (domainesAEvaluer, juste au-dessus), puis recalcule.
        //
        // Le jalon d'EPREUVE (EE ou EO) reste servi : ce n'est pas un controle
        // de palier, c'est la mesure d'une seule epreuve, et rien n'oblige a
        // connaitre les quatre domaines pour la passer.
        if (!profil.cycle().profileComplete()
                && milestone != null
                && milestone.kind() == PlanExerciseKind.FULL_TCF_MOCK_EXAM) {
            milestone = null;
        }
        // LA SEANCE est une VUE de ce qui precede : elle ne choisit aucun
        // exercice, elle ordonne et borne ceux que les trois autorites ont deja
        // designes, et recalcule le total de minutes. Aucune date n'y entre —
        // c'est ce qui rend la stickiness gratuite : sans nouvelle observation,
        // les priorites ne bougent pas, donc la seance non plus.
        Map<UUID, Skill> skillsDesPriorites = new LinkedHashMap<>();
        aExercer.forEach(skill -> skillsDesPriorites.put(skill.getId(), skill));
        // LA MESURE INDISPENSABLE ouvre la seance : le candidat a produit sur ce
        // domaine et le correcteur n'a rien pu y observer. Tant qu'on ne l'a pas
        // mesure, les exercices qui suivent travaillent a l'aveugle. C'est le
        // second sens de NOT_OBSERVED — « la production etait inutilisable »,
        // a ne pas confondre avec « ce palier n'a pas encore ete aborde », qui
        // se traite par une acquisition. Zero requete, meme resolution que
        // « Completer mon profil ».
        PlanDomainAssessmentDto mesure = assessmentResolver
                .indispensable(profil.domaines(), allObservations, true)
                .orElse(null);
        PlanSeanceDto seance = seanceBuilder.build(mesure, priorities, skillsDesPriorites,
                lastActivity, milestone);
        // CE QUI A CHANGE : le meme moteur, joue deux fois sur l'historique deja
        // charge — aucune requete, aucune regle recopiee. La priorite n°1 lui est
        // passee telle que le resolveur l'a designee : ce bloc ne peut donc pas
        // nommer une autre etape que celle affichee juste au-dessus.
        PlanRecentChangesDto changes = recentChangesResolver.resolve(
                allObservations, mastery,
                actionable.isEmpty() ? null : actionable.getFirst(), Instant.now())
                .orElse(null);
        // LES COMPETENCES DE CHAQUE EPREUVE : la meme verite que les cartes
        // ci-dessus, rangee par domaine. La NATURE vient des cartes elles-memes
        // — la recalculer aurait fini par dire « a acquerir » ici et « a
        // renforcer » la. Une competence absente de cette table n'a aucune
        // nature : le Plan ne demande rien dessus, et on ne fabrique pas une
        // action pour remplir une colonne.
        Map<UUID, PlanActionNature> natures = new LinkedHashMap<>();
        composed.forEach(action -> natures.put(action.skillId(), action.nature()));
        List<PlanDomainDto> domaines = domainSkillResolver.attach(
                profil.domaines(), profil.referentiel(), latest, mastery, natures, access);
        return new LearningPlanDto(
                LearningPlanState.ACTIVE, completed.getId(), completed.getCompletedAt(),
                completedSteps,
                priorities.isEmpty() ? null : priorities.getFirst(),
                priorities.size() <= 1 ? List.of() : priorities.subList(1, priorities.size()),
                observed, observedCount, activities, true, milestone,
                domaines, profil.cycle(),
                // « Completer mon profil » survit au diagnostic : un candidat
                // evalue en EE/EO garde CO et CE a mesurer, et la session
                // terminee ne se rejoue pas — ces domaines-la, s'ils manquaient
                // encore, retomberaient sur une production.
                assessmentResolver.resolve(domaines, true),
                seance, changes);
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
                // Une etape qui bascule en verification le DIT : c'est la meme
                // carte, au meme endroit, avec une autre action — et c'est cette
                // nature que les fronts lisent, jamais la nullite d'un champ.
                readyForReassessment ? PlanActionNature.A_VERIFIER
                        : PlanActionNature.A_RENFORCER,
                observation.getStatus(), observation.getExplanation(), observation.getEvidence(),
                observation.getConfidence(), observation.getObservedAt(), exercise,
                counts.promptCount(), counts.attemptedCount(), counts.validatedCount(),
                step.promptCount(), step.attemptedCount(), step.validatedCount(),
                step.completed(), step.promptIds(),
                mastery.state(), readyForReassessment, locked);
    }

    /**
     * Une competence <b>a acquerir</b> : la meme carte qu'une priorite, sans rien
     * d'observe.
     *
     * <p>🛑 {@code status}, {@code explanation}, {@code evidence},
     * {@code confidence}, {@code observedAt} et {@code masteryState} valent
     * <b>{@code null}</b>, et c'est le fait meme : rien n'a ete constate sur
     * cette competence, donc rien n'a echoue. On n'invente pas un verdict pour
     * remplir un champ — <i>null = inconnu, jamais mauvais</i>. Les compteurs
     * d'etape valent 0, ce qui est exact.
     *
     * <p>{@code readyForReassessment} vaut {@code false} : on ne verifie pas ce
     * qui n'a jamais ete travaille.
     */
    private static LearningPlanPriorityDto acquisition(
            Skill skill,
            PlanRecommendedExerciseDto exercise,
            SkillProgressCounter.SkillProgress counts,
            boolean locked) {
        LearningPlanStep.Progress step = counts.step();
        return new LearningPlanPriorityDto(
                skill.getId(), skill.getCode(), skill.getTitle(), skill.getSection(),
                PlanActionNature.A_ACQUERIR,
                null, null, null, null, null, exercise,
                counts.promptCount(), counts.attemptedCount(), counts.validatedCount(),
                step.promptCount(), step.attemptedCount(), step.validatedCount(),
                step.completed(), step.promptIds(),
                null, false, locked);
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

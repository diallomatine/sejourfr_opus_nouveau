package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanCycleDto;
import com.sejourfr.app.dto.PlanDomainDto;
import com.sejourfr.app.dto.PlanDomainLevelDto;
import com.sejourfr.app.dto.PlanDomainTaskDto;
import com.sejourfr.app.dto.PlanPathStepDto;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.PlanCycleState;
import com.sejourfr.app.enums.PlanDomainPriority;
import com.sejourfr.app.enums.PlanPathStepKind;
import com.sejourfr.app.enums.PlanPathStepStatus;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.SkillManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Le <b>cycle de palier</b> et les <b>quatre domaines</b> du Plan : « ou j'en
 * suis » et « ou je vais ».
 *
 * <p><b>Tout est derive a la lecture, rien n'est persiste</b> — aucune table
 * {@code plan_cycles}, aucune migration, aucun job. Le cycle se reconstruit du
 * profil TCF ({@link TcfProfileService}) et de l'historique d'observations deja
 * charge par {@link LearningPlanService}, exactement comme
 * {@code SkillMasteryState}, {@code SituationDansNiveau} et
 * {@code ContinuiteSimulation}. Recalibrer un seuil de maitrise deplace le cycle
 * au prochain appel.
 *
 * <h2>Les trois regles, et d'ou elles viennent</h2>
 * <ol>
 *   <li><b>Le palier vise est le cran au-dessus</b>, jamais l'objectif
 *       directement : A2 &rarr; B1 &rarr; B2 (brief §37). Il est plafonne par
 *       l'objectif du candidat.</li>
 *   <li><b>L'objectif n'est pas « B2 » en dur</b> : c'est
 *       {@link TargetProcedure#niveauVise}, la demarche faisant <b>plancher</b>.
 *       Cette table a vecu en six copies divergentes dans ce depot ; elle n'est
 *       pas reecrite ici, elle est <b>appelee</b>.</li>
 *   <li><b>Le niveau d'un domaine vient de {@link TcfProfileService}</b>, unique
 *       autorite, celle-la meme que publie le dashboard. Le recalculer ici
 *       ferait repondre deux surfaces differemment a la meme question — defaut
 *       deja corrige une fois sur le niveau TCF estime.</li>
 * </ol>
 *
 * <h2>Le declencheur de l'examen de palier</h2>
 * Le brief (§78) demande trois conditions : profil <b>4/4</b>, aucune competence
 * bloquante pour le palier vise, et toutes les priorites du cycle transferees.
 * Sur notre modele, les deux dernieres sont <b>la meme phrase</b> :
 * {@code LearningPlanPriorityResolver.actionable} rend exactement les
 * competences observees fragiles dont le transfert n'est pas prouve. Le gate se
 * lit donc « profil complet, plus aucune priorite actionnable, objectif pas
 * encore atteint » — <b>aucun seuil nouveau, aucune cle de configuration</b>.
 *
 * <p>🛑 <b>Une competence JAMAIS OBSERVEE ne bloque pas le gate</b>, et c'est
 * voulu : c'est le principe {@code null = inconnu, jamais mauvais}, et c'est
 * precisement l'examen blanc complet qui viendrait l'observer. La refuser pour
 * manque de donnees enfermerait le candidat (brief §96 : une competence non
 * observee n'est pas une faiblesse). Ce qu'un palier non consolide bloque, c'est
 * la <b>lecture du niveau du domaine</b> ({@code blockingLevel}), pas le gate.
 *
 * <h2>Cout</h2>
 * Trois requetes, quel que soit le nombre de competences : le profil TCF (qui a
 * les siennes), les six competences de comprehension en un lot, et le compte des
 * competences actives des six taches en un lot. Les etats de maitrise des
 * paliers de comprehension se calculent sur l'historique <b>deja en memoire</b>
 * ({@code SkillMasteryResolver.fromObservations}), sans une requete de plus.
 */
@Component
@RequiredArgsConstructor
public class PlanCycleResolver {

    /** Les paliers de comprehension, du plus bas au plus haut. L'ordre est la regle. */
    private static final List<TargetLevel> PALIERS =
            List.of(TargetLevel.A2, TargetLevel.B1, TargetLevel.B2);

    private final TcfProfileService profileService;
    private final ComprehensionLevelResolver comprehensionLevelResolver;
    private final SkillMasteryResolver masteryResolver;
    private final SkillManager skillManager;

    /**
     * Ce que le Plan ajoute a sa reponse : le cycle et les quatre domaines.
     *
     * <p>Le gate n'est pas un champ : il se lit
     * {@code cycle.state() == READY_FOR_GATE_MOCK}. Une seconde source dirait un
     * jour l'inverse de la premiere.
     */
    public record Resolution(PlanCycleDto cycle, List<PlanDomainDto> domaines) {}

    /**
     * Le cycle et les domaines de ce candidat.
     *
     * @param user            le candidat, pour sa demarche et son palier declare
     *                        — l'objectif ne se devine pas.
     * @param allObservations tout son historique, <b>deja charge</b> par le Plan.
     * @param actionable      les priorites restantes, telles que
     *                        {@code LearningPlanPriorityResolver} les ordonne :
     *                        la premiere designe le domaine « Priorite forte »,
     *                        et leur absence ouvre le gate.
     */
    public Resolution resolve(
            User user,
            List<LearningPlanObservation> allObservations,
            List<LearningPlanObservation> actionable) {

        // Aucun candidat resolu : rien a mesurer, et surtout aucune requete a
        // emettre avec un identifiant nul.
        TcfLevelProfile profile = user == null
                ? new TcfLevelProfile(null, null, null, null, null)
                : profileService.levelProfile(user.getId());
        int evalues = profile.epreuvesCounted();
        boolean profilComplet = evalues == TcfLevelProfile.EPREUVES_EXPECTED;

        TargetLevel objectif = user == null ? null
                : TargetProcedure.niveauVise(user.getTargetProcedure(), user.getTargetLevel());
        NiveauCecrl depart = profile.globalLevel();
        boolean objectifAtteint = objectif != null && depart != null
                && depart.ordinal() >= niveau(objectif).ordinal();
        TargetLevel vise = palierVise(depart, objectif);

        // Les trois conditions du brief §78, dites une seule fois. Rien de plus :
        // « aucune competence bloquante » et « toutes les priorites solides »
        // sont la meme phrase sur notre modele.
        boolean gate = profilComplet && !objectifAtteint && actionable.isEmpty();
        PlanCycleState etat = !profilComplet ? PlanCycleState.BUILDING_BASELINE
                : objectifAtteint ? PlanCycleState.TARGET_STABILIZATION
                : gate ? PlanCycleState.READY_FOR_GATE_MOCK
                : PlanCycleState.TRAINING;

        PlanCycleDto cycle = new PlanCycleDto(
                depart, vise, objectif, etat,
                evalues, TcfLevelProfile.EPREUVES_EXPECTED, profilComplet,
                chemin(depart, vise, objectif, profilComplet, objectifAtteint));

        return new Resolution(cycle, domaines(profile, allObservations, actionable, vise, objectif));
    }

    // ------------------------------------------------------------------------
    // Cycle
    // ------------------------------------------------------------------------

    /**
     * Le palier que ce cycle construit : le premier cran <b>strictement
     * au-dessus</b> du niveau mesure, plafonne par l'objectif.
     *
     * <p>Sans aucune mesure, c'est {@code A2} : on commence par le bas, on ne
     * suppose pas un niveau. Au-dela du {@code B2} il n'y a rien a construire —
     * le profil TCF IRN s'arrete la.
     */
    private static TargetLevel palierVise(NiveauCecrl depart, TargetLevel objectif) {
        TargetLevel candidat = TargetLevel.B2;
        for (TargetLevel palier : PALIERS) {
            if (depart == null || niveau(palier).ordinal() > depart.ordinal()) {
                candidat = palier;
                break;
            }
        }
        if (objectif != null && candidat.ordinal() > objectif.ordinal()) return objectif;
        return candidat;
    }

    /**
     * Le chemin, de la premiere etape a la derniere : completer le profil, puis
     * un palier par cran jusqu'a l'objectif, puis stabiliser.
     *
     * <p><b>Les paliers deja acquis restent affiches, coches</b> : ils ne
     * disparaissent pas du chemin, sinon le candidat perdrait la trace de ce
     * qu'il a franchi — meme raison que les etapes franchies du parcours de
     * competences.
     *
     * <p>Exactement une etape est {@code CURRENT}, et le profil incomplet passe
     * <b>avant</b> tout le reste (brief §77) : on ne fait pas construire un
     * palier a quelqu'un dont on n'a pas mesure les quatre domaines.
     */
    private static List<PlanPathStepDto> chemin(
            NiveauCecrl depart, TargetLevel vise, TargetLevel objectif,
            boolean profilComplet, boolean objectifAtteint) {
        List<PlanPathStepDto> etapes = new ArrayList<>();
        etapes.add(new PlanPathStepDto(PlanPathStepKind.COMPLETE_PROFILE, null,
                profilComplet ? PlanPathStepStatus.DONE : PlanPathStepStatus.CURRENT));

        TargetLevel plafond = objectif == null ? TargetLevel.B2 : objectif;
        for (TargetLevel palier : PALIERS) {
            if (palier.ordinal() > plafond.ordinal()) break;
            PlanPathStepStatus statut;
            if (depart != null && depart.ordinal() >= niveau(palier).ordinal()) {
                statut = PlanPathStepStatus.DONE;
            } else if (profilComplet && !objectifAtteint && palier == vise) {
                statut = PlanPathStepStatus.CURRENT;
            } else {
                statut = PlanPathStepStatus.UPCOMING;
            }
            etapes.add(new PlanPathStepDto(PlanPathStepKind.BUILD_LEVEL, palier, statut));
        }

        etapes.add(new PlanPathStepDto(PlanPathStepKind.STABILIZE, null,
                profilComplet && objectifAtteint
                        ? PlanPathStepStatus.CURRENT : PlanPathStepStatus.UPCOMING));
        return List.copyOf(etapes);
    }

    // ------------------------------------------------------------------------
    // Domaines
    // ------------------------------------------------------------------------

    /**
     * Les quatre domaines, <b>toujours les quatre</b>, tries par urgence par le
     * serveur (a egalite, l'ordre des epreuves du TCF). Aucun front ne reordonne
     * et aucun front ne complete les trous : une liste trouee ferait disparaitre
     * de l'ecran exactement ce que « Completer mon profil » doit montrer.
     */
    private List<PlanDomainDto> domaines(
            TcfLevelProfile profile,
            List<LearningPlanObservation> allObservations,
            List<LearningPlanObservation> actionable,
            TargetLevel vise,
            TargetLevel objectif) {

        Map<EpreuveType, NiveauCecrl> niveaux = new EnumMap<>(EpreuveType.class);
        put(niveaux, EpreuveType.TCF_CO, profile.co());
        put(niveaux, EpreuveType.TCF_CE, profile.ce());
        put(niveaux, EpreuveType.TCF_EO, profile.eo());
        put(niveaux, EpreuveType.TCF_EE, profile.ee());

        EpreuveType domainePrioritaire = actionable.isEmpty()
                ? null : epreuve(section(actionable.getFirst()));
        Set<EpreuveType> avecPriorite = new HashSet<>();
        for (LearningPlanObservation item : actionable) {
            EpreuveType epreuve = epreuve(section(item));
            if (epreuve != null) avecPriorite.add(epreuve);
        }

        Map<SkillSection, Map<TargetLevel, Skill>> comprehension = comprehensionParPalier();
        Map<UUID, SkillMasteryEngine.SkillMastery> maitrise = masteryResolver.fromObservations(
                allObservations, idsDeComprehension(comprehension));
        Map<SkillTaskCode, Integer> observeesParTache = observeesParTache(allObservations);
        Map<SkillTaskCode, Long> totalParTache =
                skillManager.countActiveByTaskCode(List.of(SkillTaskCode.values()));

        List<PlanDomainDto> domaines = new ArrayList<>();
        for (EpreuveType epreuve : TcfDomainProfileDto.ORDRE) {
            SkillSection section = section(epreuve);
            NiveauCecrl niveau = niveaux.get(epreuve);
            List<PlanDomainLevelDto> paliers = section.isComprehension()
                    ? paliers(comprehension.getOrDefault(section, Map.of()), maitrise)
                    : List.of();
            TargetLevel consolide = section.isComprehension()
                    ? comprehensionLevelResolver.niveauConsolide(etats(paliers)).orElse(null)
                    : null;
            TargetLevel bloquant = section.isComprehension() ? suivant(consolide) : null;
            List<PlanDomainTaskDto> taches = section.isProduction()
                    ? taches(section, observeesParTache, totalParTache)
                    : List.of();
            domaines.add(new PlanDomainDto(
                    epreuve, niveau != null, niveau,
                    priorite(niveau, epreuve, domainePrioritaire, avecPriorite, vise, objectif),
                    consolide, bloquant, paliers, taches));
        }
        domaines.sort(Comparator
                .comparingInt((PlanDomainDto item) -> item.priority().ordinal())
                .thenComparingInt(item -> TcfDomainProfileDto.ORDRE.indexOf(item.epreuve())));
        return List.copyOf(domaines);
    }

    /**
     * Ce que le Plan fait de ce domaine.
     *
     * <p>L'ordre des cas <b>est</b> la regle, et il se lit de haut en bas :
     * <ol>
     *   <li>jamais mesure &rarr; {@code A_EVALUER}, et rien d'autre : un domaine
     *       non evalue n'est pas une faiblesse, il manque des donnees ;</li>
     *   <li>il porte la priorite n&deg;1 du Plan &rarr; {@code FORTE}. C'est la
     *       meme priorite que la carte « a faire maintenant », lue chez la meme
     *       autorite : la pastille et l'etape ne peuvent pas se contredire ;</li>
     *   <li>il porte une autre priorite, ou il est <b>sous</b> le palier que le
     *       cycle construit &rarr; {@code A_TRAVAILLER} ;</li>
     *   <li>il a atteint l'objectif &rarr; {@code ENTRETIEN} ;</li>
     *   <li>sinon il a depasse le palier du cycle sans atteindre l'objectif
     *       &rarr; {@code PAS_ENCORE_PRIORITAIRE} : le Plan cible le domaine qui
     *       bloque le palier <b>courant</b> (brief §93), pas celui qui est deja
     *       devant.</li>
     * </ol>
     */
    private static PlanDomainPriority priorite(
            NiveauCecrl niveau, EpreuveType epreuve, EpreuveType domainePrioritaire,
            Set<EpreuveType> avecPriorite, TargetLevel vise, TargetLevel objectif) {
        if (niveau == null) return PlanDomainPriority.A_EVALUER;
        if (epreuve == domainePrioritaire) return PlanDomainPriority.FORTE;
        if (avecPriorite.contains(epreuve)) return PlanDomainPriority.A_TRAVAILLER;
        if (niveau.ordinal() < niveau(vise).ordinal()) return PlanDomainPriority.A_TRAVAILLER;
        TargetLevel plafond = objectif == null ? TargetLevel.B2 : objectif;
        if (niveau.ordinal() >= niveau(plafond).ordinal()) return PlanDomainPriority.ENTRETIEN;
        return PlanDomainPriority.PAS_ENCORE_PRIORITAIRE;
    }

    /** Les trois paliers d'un domaine de comprehension, du plus bas au plus haut. */
    private static List<PlanDomainLevelDto> paliers(
            Map<TargetLevel, Skill> competences,
            Map<UUID, SkillMasteryEngine.SkillMastery> maitrise) {
        List<PlanDomainLevelDto> paliers = new ArrayList<>();
        boolean bloquantTrouve = false;
        for (TargetLevel palier : PALIERS) {
            Skill skill = competences.get(palier);
            if (skill == null) continue;
            SkillMasteryEngine.SkillMastery etat = maitrise.get(skill.getId());
            SkillMasteryState state = etat == null ? null : etat.state();
            boolean bloquant = !bloquantTrouve && state != SkillMasteryState.SOLID;
            if (bloquant) bloquantTrouve = true;
            paliers.add(new PlanDomainLevelDto(
                    palier, skill.getId(), skill.getCode(), state, bloquant));
        }
        return List.copyOf(paliers);
    }

    /** Les trois taches d'un domaine d'expression, dans l'ordre du referentiel. */
    private static List<PlanDomainTaskDto> taches(
            SkillSection section,
            Map<SkillTaskCode, Integer> observees,
            Map<SkillTaskCode, Long> totaux) {
        List<PlanDomainTaskDto> taches = new ArrayList<>();
        for (SkillTaskCode code : SkillTaskCode.of(section)) {
            taches.add(new PlanDomainTaskDto(
                    code, code.getTacheNumero(),
                    observees.getOrDefault(code, 0),
                    Math.toIntExact(totaux.getOrDefault(code, 0L))));
        }
        return List.copyOf(taches);
    }

    /**
     * Competences de comprehension indexees par (domaine, palier). Une seule
     * requete de six lignes ; la premiere competence gagne, comme chez
     * {@code ComprehensionObservationService}.
     */
    private Map<SkillSection, Map<TargetLevel, Skill>> comprehensionParPalier() {
        Map<SkillSection, Map<TargetLevel, Skill>> parDomaine =
                new EnumMap<>(SkillSection.class);
        for (Skill skill : skillManager.findActiveComprehension()) {
            if (skill.getSection() == null || !skill.getSection().isComprehension()) continue;
            TargetLevel palier = palier(skill.getTargetLevel());
            if (palier == null) continue;
            parDomaine
                    .computeIfAbsent(skill.getSection(), key -> new EnumMap<>(TargetLevel.class))
                    .putIfAbsent(palier, skill);
        }
        return parDomaine;
    }

    private static Set<UUID> idsDeComprehension(
            Map<SkillSection, Map<TargetLevel, Skill>> comprehension) {
        Set<UUID> ids = new LinkedHashSet<>();
        comprehension.values().forEach(paliers ->
                paliers.values().forEach(skill -> ids.add(skill.getId())));
        return ids;
    }

    /**
     * Combien de competences <b>distinctes</b> de chaque tache ont deja ete
     * observees au moins une fois. Lu sur l'historique deja charge : zero
     * requete.
     */
    private static Map<SkillTaskCode, Integer> observeesParTache(
            List<LearningPlanObservation> observations) {
        Map<SkillTaskCode, Set<UUID>> parTache = new HashMap<>();
        for (LearningPlanObservation item : observations) {
            if (!item.isObserved() || item.getSkill() == null) continue;
            SkillTaskCode code = item.getSkill().getTaskCode();
            if (code == null) continue;
            parTache.computeIfAbsent(code, key -> new HashSet<>()).add(item.getSkill().getId());
        }
        Map<SkillTaskCode, Integer> comptes = new LinkedHashMap<>();
        parTache.forEach((code, ids) -> comptes.put(code, ids.size()));
        return comptes;
    }

    /** L'etat de chaque palier, sous la forme qu'attend {@link ComprehensionLevelResolver}. */
    private static Map<TargetLevel, SkillMasteryState> etats(List<PlanDomainLevelDto> paliers) {
        Map<TargetLevel, SkillMasteryState> etats = new EnumMap<>(TargetLevel.class);
        paliers.forEach(palier -> etats.put(palier.niveau(), palier.masteryState()));
        return etats;
    }

    /**
     * Le palier qui bloque : celui qui suit immediatement le dernier consolide,
     * {@code null} quand les trois le sont. Derive du resultat de
     * {@link ComprehensionLevelResolver} — la regle de prerequis n'est pas
     * recopiee ici.
     */
    private static TargetLevel suivant(TargetLevel consolide) {
        if (consolide == null) return PALIERS.getFirst();
        int rang = PALIERS.indexOf(consolide);
        return rang < 0 || rang + 1 >= PALIERS.size() ? null : PALIERS.get(rang + 1);
    }

    private static void put(
            Map<EpreuveType, NiveauCecrl> niveaux, EpreuveType epreuve, NiveauCecrl niveau) {
        if (niveau != null) niveaux.put(epreuve, niveau);
    }

    private static SkillSection section(LearningPlanObservation observation) {
        return observation.getSkill() == null ? null : observation.getSkill().getSection();
    }

    /** Le domaine d'une competence, dit dans le vocabulaire des epreuves. */
    private static EpreuveType epreuve(SkillSection section) {
        if (section == null) return null;
        return switch (section) {
            case CO -> EpreuveType.TCF_CO;
            case CE -> EpreuveType.TCF_CE;
            case EO -> EpreuveType.TCF_EO;
            case EE -> EpreuveType.TCF_EE;
        };
    }

    /** L'inverse, pour les quatre epreuves du profil et elles seules. */
    private static SkillSection section(EpreuveType epreuve) {
        return switch (epreuve) {
            case TCF_CO -> SkillSection.CO;
            case TCF_CE -> SkillSection.CE;
            case TCF_EO -> SkillSection.EO;
            default -> SkillSection.EE;
        };
    }

    /** Le palier CECRL correspondant, pour comparer sur une seule echelle. */
    private static NiveauCecrl niveau(TargetLevel palier) {
        return switch (palier) {
            case A2 -> NiveauCecrl.A2;
            case B1 -> NiveauCecrl.B1;
            case B2 -> NiveauCecrl.B2;
        };
    }

    /** {@code null} pour un palier hors {@code A2/B1/B2}. */
    private static TargetLevel palier(String targetLevel) {
        if (targetLevel == null) return null;
        for (TargetLevel palier : PALIERS) {
            if (palier.name().equals(targetLevel)) return palier;
        }
        return null;
    }
}

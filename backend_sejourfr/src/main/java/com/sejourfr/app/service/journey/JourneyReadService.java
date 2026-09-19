package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyBlocDto;
import com.sejourfr.app.dto.JourneyCycleDto;
import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.dto.JourneyNextStepDto;
import com.sejourfr.app.dto.JourneyStepDto;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyProgressUnit;
import com.sejourfr.app.enums.JourneyState;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.enums.JourneyStepStatus;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.JourneySuggestionType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.manager.JourneyManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.dto.PlanDomainAssessmentDto;
import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.service.NiveauActuelEpreuveResolver;
import com.sejourfr.app.service.PlanDomainAssessmentResolver;
import com.sejourfr.app.service.ProductionAccessService;
import com.sejourfr.app.service.RecommendedExerciseSelector;
import com.sejourfr.app.service.SkillAccessService;
import com.sejourfr.app.service.SkillProgressCounter;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Predicate;

/**
 * <b>Le parcours tel qu'on le LIT</b> : ce qui est verrouille, quelle etape est
 * courante, et quel statut chaque etape affiche.
 *
 * <p>⚠️ <b>Plus aucun fenetrage d'affichage</b> (P6, 2026-09-18). La liste
 * {@code steps} et le compteur {@code hiddenUpcomingCount} du DTO ont disparu
 * avec la bascule des deux fronts sur {@code blocs}, et la methode
 * {@code filtrer(...)} de §14 — les N dernieres closes, le lot courant, les
 * {@code upcomingVisible} suivantes — avec eux. Cette lecture ne tronque donc
 * plus rien : elle sert <b>toutes</b> les etapes non obsoletes, rangees par
 * epreuve.
 *
 * <h2>🛑 Tout l'etat est derive ici, rien n'est relu d'une colonne</h2>
 * <p>Arbitrage D-7 : seuls la <b>structure</b> de la file et la <b>cloture</b>
 * d'une etape sont persistes. {@code CURRENT}, {@code locked} et les cinq
 * statuts d'affichage se recalculent a chaque appel. Consequence voulue : un
 * abonnement souscrit change l'ecran <b>sans une seule ecriture en base</b>, et
 * recalibrer le moteur de maitrise ne reinterprete <b>aucune</b> etape deja
 * close.
 *
 * <h2>🛑 La circularite de D-1 a disparu avec l'exemption (D-18)</h2>
 * <p>Jusqu'au 2026-09-18, ce service devait passer a {@code SkillAccessService}
 * la <b>premiere etape non cloturee</b>, verrous ignores, parce que le freemium
 * ouvrait d'office la competence de la premiere place du Plan (arbitrage du
 * 2026-08-21 : « un candidat non abonne pourra travailler sa priorite 1, vu
 * qu'elle est visible »). Lui passer {@code CURRENT} aurait ete circulaire —
 * {@code CURRENT} depend de {@code locked}, qui depend de l'acces.
 *
 * <p>D-18 <b>revoque cette exemption</b> : travailler une competence depuis le
 * Plan est premium, sans exception. Il n'y a donc plus rien a deverrouiller, et
 * l'acces se lit desormais <b>tel quel</b>. L'ordre de promotion de D-1
 * (« {@code CURRENT} = premiere etape non cloturee <b>et executable</b> »)
 * reste valable mot pour mot ; pour un compte gratuit il ne designe simplement
 * plus rien — {@code current == null}, {@link JourneyState#LOCKED} permanent,
 * la carte nomme la premiere etape verrouillee et ouvre le paywall. <b>C'est
 * l'effet voulu.</b>
 *
 * <p>🛑 <b>Et la contradiction #1 du depot n'est pas rouverte</b> : le cycle,
 * les priorites, les niveaux mesures et les compteurs <b>restent servis</b>. Ce
 * qui se ferme est l'<b>execution</b>, jamais l'affichage — un {@code locked}
 * servi, jamais une donnee masquee.
 *
 * <h2>« Executable » veut dire FINISSABLE, pas « ouverte »</h2>
 * <p>La distinction reste vraie et reste utile : une etape d'expression sans
 * aucun sujet publie est « ouverte » sans pouvoir se clore
 * ({@code LearningPlanStep.Progress.completed()} refuse de declarer finie une
 * etape vide). La laisser prendre la main figerait le parcours sur une carte
 * sans action.
 *
 * <h2>Le cycle borne se LIT ici aussi (D-12)</h2>
 * <p>Les quatre blocs, l'avancement du cycle et les issues de fin de cycle sont
 * derives de la <b>meme</b> liste d'etapes, par {@link JourneyBlocResolver}. 🛑
 * Ils sont batis sur <b>toutes</b> les etapes non obsoletes : un plafond
 * d'AFFICHAGE n'est pas un budget de contenu, et un bloc derive d'une liste
 * tronquee aurait annonce « 1 competence restante » la ou il en restait trois.
 */
@Service
@RequiredArgsConstructor
public class JourneyReadService {

    private final TcfJourneyConfig config;
    private final SkillAccessService accessService;
    private final SkillProgressCounter progressCounter;
    private final ProductionAccessService productionAccessService;
    private final LearningPlanObservationManager observationManager;
    private final NiveauActuelEpreuveResolver mesureResolver;
    private final PlanDomainAssessmentResolver assessmentResolver;
    private final JourneyBlocResolver blocResolver;
    private final JourneyManager journeyManager;
    private final RecommendedExerciseSelector exerciseSelector;

    /** L'etat lu d'une etape : le fait persiste, plus tout ce qui s'en derive. */
    private record Etat(JourneyStep step, JourneyStepStatus status, boolean locked,
                        JourneyStepDto.JourneyProgressDto progress) {}

    /**
     * Le parcours d'un candidat qui n'a <b>pas declare d'objectif</b> (arbitrage
     * D-3) : aucun parcours n'existe en base, et ce n'est pas un parcours vide.
     *
     * <p>Le distinguer de {@link JourneyState#UP_TO_DATE} evite de feliciter un
     * candidat qui n'a rien commence.
     */
    public JourneyDto sansObjectif() {
        return new JourneyDto(null, JourneyState.NEEDS_OBJECTIVE, null, null,
                null, List.of(), null);
    }

    /**
     * Le parcours, lu.
     *
     * @param toutesLesEtapes les etapes du parcours dans l'ordre de la file,
     *                        competence et lot <b>deja charges</b>.
     */
    public JourneyDto lire(Journey journey, List<JourneyStep> toutesLesEtapes) {
        UUID userId = journey.getUser().getId();
        List<JourneyStep> ouvertes = toutesLesEtapes.stream()
                .filter(JourneyStep::estOuverte)
                .toList();

        Map<UUID, SkillProgressCounter.SkillProgress> progressionExpression =
                progressionDesCompetencesDExpression(userId, ouvertes);

        // 🛑 PLUS AUCUNE PREMIERE ETAPE A DEVERROUILLER (D-18) : l'exemption du
        // 2026-08-21 (« un candidat non abonne pourra travailler sa priorite 1,
        // vu qu'elle est visible ») est REVOQUEE, donc la circularite
        // CURRENT ⇄ locked que D-1 avait resolue n'existe plus. On lit l'acces
        // tel qu'il est, sans rien lui souffler.
        SkillAccessService.SkillAccess access = accessService.resolve(userId);
        Map<UUID, Series> seriesParCompetence = seriesDepuisLaCreation(userId, ouvertes);
        // 🛑 LE VERROU DE PRODUCTION EST **PAR EPREUVE** depuis D-17 bis : deux
        // gratuites nominatives (une EE, une EO) ne se ferment pas ensemble.
        // Une lecture par epreuve reellement presente dans la file, jamais une
        // par etape.
        Set<EpreuveType> examensDeProductionVerrouilles =
                examensDeProductionVerrouilles(userId, ouvertes);
        Set<EpreuveType> blocsAvecCompetenceOuverte = blocsAvecCompetenceOuverte(ouvertes);

        // 🛑 **L'EXERCICE DE CHAQUE ETAPE EST SERVI** (meme raisonnement qu'A24) :
        // la liste des priorites du Plan est une vue bornee a 5, la file ne
        // l'est pas. Un LOT unique pour tout le parcours — le cout ne grandit
        // pas avec le nombre d'etapes.
        Map<UUID, PlanRecommendedExerciseDto> exercices =
                exercicesDesCompetences(userId, toutesLesEtapes, access);

        Map<UUID, Etat> etats = new LinkedHashMap<>();
        for (JourneyStep step : toutesLesEtapes) {
            boolean locked = estVerrouillee(step, access, progressionExpression,
                    examensDeProductionVerrouilles, blocsAvecCompetenceOuverte);
            etats.put(step.getId(), new Etat(step,
                    statutHorsPromotion(step, toutesLesEtapes), locked,
                    progression(step, progressionExpression, seriesParCompetence)));
        }

        JourneyStep courante = elire(ouvertes, etats, progressionExpression);
        if (courante != null) {
            Etat etat = etats.get(courante.getId());
            etats.put(courante.getId(), new Etat(etat.step(), JourneyStepStatus.CURRENT,
                    etat.locked(), etat.progress()));
        }

        // 🛑 LES BLOCS SONT BATIS SUR **TOUTES** LES ETAPES NON OBSOLETES : un
        // plafond d'AFFICHAGE n'est pas un budget de contenu. Un bloc derive
        // d'une liste deja tronquee aurait annonce « 1 competence restante » la
        // ou il en restait trois — exactement l'incident du 2026-08-25, en plus
        // discret. Le fenetrage de §14 a d'ailleurs disparu avec `steps` (P6) :
        // il n'existe plus une seule liste tronquee dans cette lecture.
        List<JourneyStep> affichables = toutesLesEtapes.stream()
                .filter(step -> etats.get(step.getId()).status() != JourneyStepStatus.OBSOLETE)
                .toList();
        JourneyBlocResolver.Vue vue = blocResolver.lire(
                numeroDuCycle(journey), affichables, courante,
                step -> dto(etats.get(step.getId()), exercices), jamaisMesuree(userId));

        JourneyState state = etat(affichables, ouvertes, courante);
        return new JourneyDto(
                journey.getTargetLevel(),
                state,
                courante == null ? null : dto(etats.get(courante.getId()), exercices),
                suggestion(state, userId),
                vue.cycle(),
                vue.blocs(),
                nextStep(vue.cycle()));
    }

    /**
     * <b>Le rang du cycle</b> : nombre de cycles <b>historises</b> du module,
     * plus un. Le premier cycle vaut donc 1.
     *
     * <p>🛑 <b>Compte, pas persiste</b> : un compteur sur {@code journey} aurait
     * pu diverger de l'historique reel, et c'est l'historique que la page
     * Progression lira. Une seule requete, sur l'index
     * {@code idx_journey_user_module_status}.
     */
    private int numeroDuCycle(Journey journey) {
        // 🛑 LA REGLE DU RANG N'EST PAS ECRITE ICI (JourneyCycleRank) : la page
        // Progression la lit aussi, et deux copies d'un meme nombre finissent
        // par diverger. Tous les predecesseurs du cycle en cours sont
        // historises, donc « cycles crees avant lui » = « cycles historises ».
        return JourneyCycleRank.rang(journeyManager.compterHistorises(
                journey.getUser().getId(), journey.getModule()));
    }

    /**
     * « Cette epreuve n'a-t-elle <b>jamais</b> ete mesuree ? » — relaye de
     * {@code NiveauActuelEpreuveResolver.mesure}, son <b>unique autorite</b>
     * (arbitrage du 2026-09-16 : « il n'existe qu'UNE notion de mesuree »).
     *
     * <p><b>Memoise, et interroge au plus quatre fois</b> : la reponse coute
     * plusieurs requetes, et seuls les blocs candidats a {@code A_EVALUER} la
     * demandent.
     */
    private Predicate<EpreuveType> jamaisMesuree(UUID userId) {
        Map<EpreuveType, Boolean> connues = new LinkedHashMap<>();
        return epreuve -> connues.computeIfAbsent(
                epreuve, cle -> !mesureResolver.mesure(userId, cle).mesuree());
    }

    /**
     * Les issues de fin de cycle (spec §6). {@code null} tant que le cycle n'est
     * pas termine : ces deux gestes historisent le cycle en cours.
     *
     * <p>🛑 <b>A la fin d'un cycle de mesure, l'actualisation est la SEULE
     * issue</b> : enchainer un second examen blanc complet n'a aucun sens
     * pedagogique, et le proposer ferait tourner le candidat en rond entre deux
     * mesures sans travail entre elles.
     */
    private static JourneyNextStepDto nextStep(JourneyCycleDto cycle) {
        if (!cycle.complete()) return null;
        return new JourneyNextStepDto(!cycle.cycleDeMesure(), true);
    }

    // ------------------------------------------------------------ §5 bis : verrou

    /**
     * <b>Cette etape peut-elle etre menee a son terme avec l'acces du
     * candidat ?</b> — decide par les <b>trois autorites existantes</b>, jamais
     * par une regle ecrite ici.
     *
     * <table>
     *   <tr><th>Etape</th><th>Verrouillee quand</th><th>Autorite</th></tr>
     *   <tr><td>{@code TRAIN_SKILL} expression</td>
     *       <td>moins de sujets <b>ouverts</b> que l'etape n'en compte
     *           (gratuit : 2 &lt; 5)</td>
     *       <td>{@code SkillAccessService} + {@code LearningPlanStep}</td></tr>
     *   <tr><td>{@code TRAIN_SKILL} comprehension</td>
     *       <td>la competence est verrouillee (gratuit : {@code CO-A2} /
     *           {@code CE-A2} seuls ouverts)</td>
     *       <td>{@code SkillAccessService}</td></tr>
     *   <tr><td>{@code SECTION_EXAM}, toute epreuve</td>
     *       <td>une competence du <b>meme bloc</b> reste ouverte</td>
     *       <td><b>le cycle lui-meme</b> (D-15)</td></tr>
     *   <tr><td>{@code SECTION_EXAM} CO/CE</td>
     *       <td>rien d'autre — slot 1 offert <b>et rejouable a volonte</b>,
     *           tirage aleatoire pour tout compte inscrit</td>
     *       <td>{@code AttemptService.enforceMockExamSlotAccess}</td></tr>
     *   <tr><td>{@code SECTION_EXAM} EE/EO</td>
     *       <td>la gratuite d'examen blanc <b>de cette epreuve</b> est consommee
     *           (D-17 bis : deux gratuites nominatives, jamais un verrou
     *           global)</td>
     *       <td>{@code ProductionAccessService}</td></tr>
     *   <tr><td>{@code DIAGNOSTIC}</td><td><b>jamais</b></td><td>—</td></tr>
     * </table>
     *
     * <h3>🛑 Le verrou du bloc S'AJOUTE, il ne remplace rien (D-15)</h3>
     * <p>« L'examen d'un bloc est verrouille tant qu'une competence du meme bloc
     * n'est pas cloturee. » Un bloc <b>sans</b> competence a donc son examen
     * ouvert <b>immediatement</b> — c'est le cas de « Évaluer mon niveau » sur
     * une epreuve jamais mesuree, et il ne fallait surtout pas le fermer.
     *
     * <p>Ce verrou-ci est <b>pedagogique</b> : il dit « finis ce que tu as
     * prevu avant de te remesurer ». Les autres sont <b>commerciaux</b>. Les
     * deux se cumulent, et aucun n'annule l'autre.
     */
    private boolean estVerrouillee(
            JourneyStep step,
            SkillAccessService.SkillAccess access,
            Map<UUID, SkillProgressCounter.SkillProgress> progressionExpression,
            Set<EpreuveType> examensDeProductionVerrouilles,
            Set<EpreuveType> blocsAvecCompetenceOuverte) {
        return switch (step.getType()) {
            case DIAGNOSTIC -> false;
            case SECTION_EXAM -> blocsAvecCompetenceOuverte.contains(step.getExamType())
                    || examensDeProductionVerrouilles.contains(step.getExamType());
            case TRAIN_SKILL -> {
                Skill skill = step.getSkill();
                if (skill == null) yield false;
                if (access.isSkillLocked(skill.getId())) yield true;
                if (skill.getSection() != null && skill.getSection().isComprehension()) {
                    // Une serie ciblee n'a pas de plafond interne : competence
                    // ouverte ⇒ etape finissable.
                    yield false;
                }
                // 🛑 Expression : l'etape n'est finissable que si le candidat a
                // acces a TOUS ses sujets. Un compte gratuit plafonne a 2 sur 5
                // et ne la clot donc jamais — c'est un arbitrage produit, pas un
                // bug, et D-1 en tire la consequence : elle reste affichee,
                // cadenassee, et ne prend pas la main.
                SkillProgressCounter.SkillProgress progress = progressionExpression.get(skill.getId());
                if (progress == null) yield false;
                List<UUID> sujets = progress.step().promptIds();
                if (sujets.isEmpty()) yield false;
                yield sujets.stream().anyMatch(access::isPromptLocked);
            }
        };
    }

    /**
     * Les epreuves de <b>production</b> dont l'examen est ferme par le freemium
     * — <b>une par une</b> (D-17 bis).
     *
     * <p>🛑 <b>Deux gratuites nominatives</b> : un candidat qui a use son examen
     * blanc EE garde son examen blanc EO. Un verrou global aurait ferme les deux
     * des la premiere consommee, et prive le candidat de la gratuite qu'il
     * possede encore.
     *
     * <p>Une lecture par epreuve <b>reellement presente</b> dans la file : sur
     * un parcours sans etape d'examen de production, ce resolveur ne fait aucune
     * requete.
     */
    private Set<EpreuveType> examensDeProductionVerrouilles(
            UUID userId, List<JourneyStep> ouvertes) {
        Set<EpreuveType> candidates = new LinkedHashSet<>();
        for (JourneyStep step : ouvertes) {
            if (step.getType() == JourneyStepType.SECTION_EXAM && estProduction(step)) {
                candidates.add(step.getExamType());
            }
        }
        if (candidates.isEmpty()) return Set.of();
        Set<EpreuveType> verrouillees = new LinkedHashSet<>();
        for (EpreuveType epreuve : candidates) {
            if (productionAccessService.isProductionExamLocked(userId, epreuve)) {
                verrouillees.add(epreuve);
            }
        }
        return verrouillees;
    }

    /**
     * Les epreuves dont une <b>competence</b> reste a travailler — celles dont
     * l'examen est donc verrouille (D-15).
     *
     * <p>Une seule passe sur les etapes ouvertes, partagee par les quatre blocs :
     * le verrou ne se recalcule pas etape par etape.
     */
    private static Set<EpreuveType> blocsAvecCompetenceOuverte(List<JourneyStep> ouvertes) {
        Set<EpreuveType> epreuves = new LinkedHashSet<>();
        for (JourneyStep step : ouvertes) {
            if (step.getType() == JourneyStepType.TRAIN_SKILL && step.getExamType() != null) {
                epreuves.add(step.getExamType());
            }
        }
        return epreuves;
    }

    /**
     * L'etape <b>courante</b> : la premiere ouverte <b>et executable</b>
     * (arbitrage D-1).
     *
     * <p>« Executable » exclut deux choses : une etape <b>verrouillee</b>, et une
     * etape d'expression <b>sans aucun sujet publie</b> — celle-la ne peut pas se
     * clore non plus ({@code Progress.completed()} refuse de declarer finie une
     * etape vide, et c'est juste : il n'y a rien a y faire). La laisser prendre
     * la main figerait le parcours sur une carte sans action. Ce cas est rare :
     * {@code PlanContentAvailability} ecarte deja du pool les competences sans
     * contenu au moment ou l'evaluation les designe.
     */
    private JourneyStep elire(
            List<JourneyStep> ouvertes,
            Map<UUID, Etat> etats,
            Map<UUID, SkillProgressCounter.SkillProgress> progressionExpression) {
        for (JourneyStep step : ouvertes) {
            if (etats.get(step.getId()).locked()) continue;
            if (sansContenu(step, progressionExpression)) continue;
            return step;
        }
        return null;
    }

    private static boolean sansContenu(
            JourneyStep step, Map<UUID, SkillProgressCounter.SkillProgress> progression) {
        if (step.getType() != JourneyStepType.TRAIN_SKILL) return false;
        Skill skill = step.getSkill();
        if (skill == null || skill.getSection() == null || skill.getSection().isComprehension()) {
            return false;
        }
        SkillProgressCounter.SkillProgress progress = progression.get(skill.getId());
        return progress == null || progress.step().promptIds().isEmpty();
    }

    // ------------------------------------------------------------- §5 : statuts

    /**
     * Le statut d'affichage, <b>hors promotion</b> — la promotion pose ensuite
     * {@code CURRENT} sur une seule etape.
     *
     * <p>🛑 <b>{@code SKIPPED} se derive de l'ORDRE DE CLOTURE</b>, il n'est
     * jamais persiste : une etape est « deja maitrisee / deja travaillee » quand
     * une etape de position <b>inferieure</b> a ete close <b>apres</b> elle, ou
     * ne l'est <b>toujours pas</b>. Autrement dit : le candidat l'a resolue avant
     * d'y arriver — par un entrainement libre, ou en passant devant une etape
     * verrouillee.
     */
    private static JourneyStepStatus statutHorsPromotion(
            JourneyStep step, List<JourneyStep> toutes) {
        if (step.estOuverte()) return JourneyStepStatus.UPCOMING;
        if (step.getResolution() == JourneyStepResolution.SUPERSEDED) {
            return JourneyStepStatus.OBSOLETE;
        }
        for (JourneyStep precedente : toutes) {
            if (precedente.getPosition() >= step.getPosition()) break;
            if (precedente.getResolution() == JourneyStepResolution.SUPERSEDED) continue;
            if (precedente.estOuverte()
                    || precedente.getClosedAt().isAfter(step.getClosedAt())) {
                return JourneyStepStatus.SKIPPED;
            }
        }
        return JourneyStepStatus.COMPLETED;
    }

    // --------------------------------------------------------- R8 : progression

    private Map<UUID, SkillProgressCounter.SkillProgress> progressionDesCompetencesDExpression(
            UUID userId, List<JourneyStep> ouvertes) {
        Set<UUID> skillIds = new LinkedHashSet<>();
        for (JourneyStep step : ouvertes) {
            Skill skill = step.getSkill();
            if (skill != null && skill.getSection() != null && skill.getSection().isProduction()) {
                skillIds.add(skill.getId());
            }
        }
        return skillIds.isEmpty() ? Map.of() : progressCounter.bySkillIds(userId, skillIds);
    }

    /**
     * <b>Les series d'une competence de comprehension</b> depuis la creation de
     * son etape : combien ont ete <b>terminees</b>, et combien ont ete
     * <b>reussies</b>.
     *
     * @param terminees series jouees jusqu'au bout, reussite indifferente
     * @param reussies  sous-ensemble des precedentes dont le verdict est
     *                  {@code SOLID}. 🛑 Toujours {@code <= terminees} : c'est ce
     *                  qui rend l'echappatoire de D-16 atteignable en dernier.
     */
    private record Series(int terminees, int reussies) {

        private static final Series AUCUNE = new Series(0, 0);
    }

    /**
     * Les <b>series ciblees</b> jouees sur chaque competence de comprehension
     * ouverte, <b>depuis la creation de son etape</b> (R8, arbitrage D-16).
     *
     * <p>Une serie terminee ecrit <b>une observation</b> de comprehension par
     * competence touchee ({@code ComprehensionObservationService}) : les compter
     * par {@code sourceId} distinct compte donc les <b>sessions</b>, et une seule
     * requete suffit pour toutes les etapes.
     *
     * <h3>🛑 « Reussie » est LUE, elle n'est jamais recalculee ici</h3>
     * <p>Le verdict d'une serie de comprehension est <b>deja ecrit</b> :
     * {@code ComprehensionObservationService} pose
     * {@code learning_plan_observations.status = SOLID} des que le ratio de bonnes
     * reponses atteint {@code learning-plan.comprehension.solid-ratio} (0.80).
     * On relit donc ce statut — <b>aucune 8<sup>e</sup> declaration du seuil</b>,
     * aucun second ratio, une regle une autorite. Recalculer le ratio ici aurait
     * aussi relu un {@code evidence} textuel, ce qui est pire.
     *
     * <p>⚠️ <b>Un {@code NOT_OBSERVED} compte comme TERMINEE, jamais comme
     * REUSSIE</b> : la serie a bien ete jouee (c'est du travail fourni, il
     * alimente donc l'echappatoire), mais trop peu de questions du palier y sont
     * tombees pour qu'elle prouve quoi que ce soit — et « non observe » reste
     * <b>inconnu, jamais mauvais</b>.
     *
     * <p>🛑 <b>D-16 revoque ici la doctrine de D-5</b> (« le quota mesure le
     * travail fourni, pas la reussite ») : une etape se clot desormais sur
     * {@code trainSeriesQuota} series <b>reussies</b>, <b>ou</b> sur
     * {@code trainSeriesFallbackQuota} series terminees — l'echappatoire existant
     * pour une raison nommee, <b>un candidat faible ne doit jamais rester
     * bloque</b> sur une etape.
     */
    private Map<UUID, Series> seriesDepuisLaCreation(
            UUID userId, List<JourneyStep> ouvertes) {
        Map<UUID, Instant> depuis = new LinkedHashMap<>();
        for (JourneyStep step : ouvertes) {
            Skill skill = step.getSkill();
            if (skill != null && skill.getSection() != null
                    && skill.getSection().isComprehension()) {
                depuis.put(skill.getId(), step.getCreatedAt());
            }
        }
        if (depuis.isEmpty()) return Map.of();
        Instant plusAncienne = depuis.values().stream().min(Instant::compareTo).orElseThrow();
        List<LearningPlanObservation> observations =
                observationManager.findByUserAndSkillsSince(userId, depuis.keySet(), plusAncienne);
        Map<UUID, Set<UUID>> terminees = new LinkedHashMap<>();
        Map<UUID, Set<UUID>> reussies = new LinkedHashMap<>();
        for (LearningPlanObservation observation : observations) {
            if (observation.getSourceType() == null
                    || !observation.getSourceType().isComprehension()) {
                continue;
            }
            UUID skillId = observation.getSkill().getId();
            Instant creation = depuis.get(skillId);
            if (creation == null || observation.getObservedAt().isBefore(creation)) continue;
            terminees.computeIfAbsent(skillId, key -> new LinkedHashSet<>())
                    .add(observation.getSourceId());
            if (observation.getStatus() == LearningPlanSkillStatus.SOLID) {
                reussies.computeIfAbsent(skillId, key -> new LinkedHashSet<>())
                        .add(observation.getSourceId());
            }
        }
        Map<UUID, Series> compte = new LinkedHashMap<>();
        terminees.forEach((skillId, sessions) -> compte.put(skillId, new Series(
                sessions.size(),
                reussies.getOrDefault(skillId, Set.of()).size())));
        return compte;
    }

    /**
     * <b>LES ETAPES DONT LE QUOTA EST ATTEINT</b> — l'<b>autorite unique</b> de
     * R8, partagee par la lecture (ce que l'ecran montre) et par l'ecriture (ce
     * qui clot une etape, {@code JourneyService.onTrainingProgress}).
     *
     * <p>🛑 <b>Pourquoi une methode publique et pas le {@code progress} servi.</b>
     * Jusqu'a D-16, la cloture relisait {@code progress.done >= progress.quota}
     * de la vue servie : une seule regle, parce qu'un seul compteur. D-16 en
     * introduit <b>deux</b> — series reussies et series terminees — et tranche
     * que l'echappatoire <b>ne s'affiche pas</b>. Les deux lecteurs doivent donc
     * partager la <b>fonction</b>, puisqu'ils ne peuvent plus partager le
     * <b>nombre</b>. C'est le seul moyen qu'une etape ne se close jamais sur une
     * regle differente de celle qui l'a calculee.
     *
     * @param toutesLesEtapes les etapes du parcours, competence <b>deja
     *                        chargee</b> ; les etapes closes sont ignorees.
     */
    public Set<UUID> etapesAuQuota(UUID userId, List<JourneyStep> toutesLesEtapes) {
        List<JourneyStep> ouvertes = toutesLesEtapes.stream()
                .filter(JourneyStep::estOuverte)
                .toList();
        if (ouvertes.isEmpty()) return Set.of();
        Map<UUID, SkillProgressCounter.SkillProgress> expression =
                progressionDesCompetencesDExpression(userId, ouvertes);
        Map<UUID, Series> series = seriesDepuisLaCreation(userId, ouvertes);
        Set<UUID> atteintes = new LinkedHashSet<>();
        for (JourneyStep step : ouvertes) {
            if (quotaAtteint(step, expression, series)) atteintes.add(step.getId());
        }
        return atteintes;
    }

    /**
     * Le quota de <b>cette</b> etape est-il atteint ?
     *
     * <table>
     *   <tr><th>Etape</th><th>Close quand</th><th>Autorite du chiffre</th></tr>
     *   <tr><td>{@code TRAIN_SKILL} comprehension</td>
     *       <td>{@code trainSeriesQuota} series <b>reussies</b>, <b>ou</b>
     *           {@code trainSeriesFallbackQuota} series <b>terminees</b></td>
     *       <td>{@code plan/tcf-journey-config-v2.json} (D-16)</td></tr>
     *   <tr><td>{@code TRAIN_SKILL} expression</td>
     *       <td>tous les sujets de l'etape traites</td>
     *       <td>{@code LearningPlanStep.PROMPTS_PAR_ETAPE}, hors configuration
     *           (D-5)</td></tr>
     *   <tr><td>tout le reste</td><td><b>jamais</b> — un examen ne se compte
     *       pas</td><td>—</td></tr>
     * </table>
     */
    private boolean quotaAtteint(
            JourneyStep step,
            Map<UUID, SkillProgressCounter.SkillProgress> expression,
            Map<UUID, Series> series) {
        if (step.getType() != JourneyStepType.TRAIN_SKILL) return false;
        Skill skill = step.getSkill();
        if (skill == null || skill.getSection() == null) return false;
        if (skill.getSection().isComprehension()) {
            Series compte = series.getOrDefault(skill.getId(), Series.AUCUNE);
            return compte.reussies() >= config.trainSeriesQuota()
                    || compte.terminees() >= config.trainSeriesFallbackQuota();
        }
        JourneyStepDto.JourneyProgressDto progres = progression(step, expression, series);
        return progres != null && progres.quota() > 0 && progres.done() >= progres.quota();
    }

    /**
     * L'avancement servi. 🛑 <b>L'unite est servie</b>
     * ({@link JourneyProgressUnit}), jamais deduite par un front de la nullite de
     * {@code taskCode} : ce serait recopier une regle du referentiel dans les
     * deux fronts.
     *
     * <h3>🛑 En comprehension, l'ecran compte les series REUSSIES — et elles
     * seules</h3>
     * <p>D-16 donne deux chemins de cloture ({@code trainSeriesQuota} reussies
     * <b>ou</b> {@code trainSeriesFallbackQuota} terminees). Le compteur servi
     * est celui des <b>reussies</b>, sur le quota des reussies :
     * <ul>
     *   <li>c'est le seul objectif qu'on ait envie de donner au candidat —
     *       afficher « 2 series ratees sur 4 » invite a <b>echouer vite</b> pour
     *       se debarrasser d'une etape, exactement le contraire de son but ;</li>
     *   <li>l'echappatoire est un <b>filet</b>, pas une cible : elle ne se
     *       merite pas, elle se declenche. Un filet annonce n'en est plus un ;</li>
     *   <li>un seul champ {@code done}/{@code quota} ne peut porter qu'<b>une</b>
     *       echelle. Servir la plus exigeante des deux ne <b>survend jamais</b>
     *       l'avancement : l'etape peut se clore plus tot que le compteur ne le
     *       laisse croire, jamais plus tard.</li>
     * </ul>
     * <p>Consequence assumee et voulue : une etape close par l'echappatoire
     * l'est alors que l'ecran affichait par exemple « 1/2 ». Elle apparait comme
     * terminee, et le candidat n'a rien perdu — c'est le sens du filet.
     * 🛑 <b>Le DTO ne change pas</b> : aucun front n'a a apprendre un second
     * compteur pour une regle qu'on a decide de ne pas lui montrer.
     */
    private JourneyStepDto.JourneyProgressDto progression(
            JourneyStep step,
            Map<UUID, SkillProgressCounter.SkillProgress> expression,
            Map<UUID, Series> series) {
        if (step.getType() != JourneyStepType.TRAIN_SKILL) return null;
        Skill skill = step.getSkill();
        if (skill == null || skill.getSection() == null) return null;
        if (skill.getSection().isComprehension()) {
            return new JourneyStepDto.JourneyProgressDto(
                    series.getOrDefault(skill.getId(), Series.AUCUNE).reussies(),
                    config.trainSeriesQuota(),
                    JourneyProgressUnit.SERIES);
        }
        SkillProgressCounter.SkillProgress progress = expression.get(skill.getId());
        if (progress == null) {
            return new JourneyStepDto.JourneyProgressDto(0, 0, JourneyProgressUnit.PROMPT);
        }
        // 🛑 Le denominateur est la TAILLE DE L'ETAPE, son unique autorite
        // (LearningPlanStep.PROMPTS_PAR_ETAPE, borne par les sujets reellement
        // publies) : on n'invente jamais un « /5 » qu'on ne saurait pas servir.
        return new JourneyStepDto.JourneyProgressDto(
                progress.step().attemptedCount(),
                progress.step().promptCount(),
                JourneyProgressUnit.PROMPT);
    }

    // ------------------------------------------------------------- §8 : etats

    /**
     * <b>L'etat d'ensemble</b>, et la frontiere exacte entre les deux etats de
     * « plus rien d'ouvert ».
     *
     * <ul>
     *   <li>des etapes cloturees, plus <b>aucune</b> ouverte ⇒
     *       {@link JourneyState#CYCLE_COMPLETED} : le cycle est termine, l'ecran
     *       affiche « Prochaine étape » et ses deux issues (spec §6) ;</li>
     *   <li><b>aucune etape du tout</b> ⇒ {@link JourneyState#UP_TO_DATE}, qui
     *       garde son sens : rien n'est prevu et rien ne reste a prevoir. C'est
     *       le « cas vide » de la spec §6 — un cycle en attente vide, promu, sur
     *       un candidat dont les quatre epreuves sont mesurees. 🛑 Aucun second
     *       etat n'a ete invente pour dire la meme chose.</li>
     * </ul>
     */
    private static JourneyState etat(
            List<JourneyStep> affichables, List<JourneyStep> ouvertes, JourneyStep courante) {
        if (ouvertes.isEmpty()) {
            return affichables.isEmpty()
                    ? JourneyState.UP_TO_DATE
                    : JourneyState.CYCLE_COMPLETED;
        }
        // Des etapes restent, mais aucune n'est executable : la carte montrera la
        // premiere, verrouillee, avec son paywall (R16, D-1).
        return courante == null ? JourneyState.LOCKED : JourneyState.IN_PROGRESS;
    }

    /**
     * La suggestion d'examen blanc complet — <b>hors file</b> (§8).
     *
     * <p>🛑 Seulement quand les <b>4 epreuves sont mesurees</b> : on ne confirme
     * pas un palier sur deux domaines sur quatre. « Mesuree » est lu chez son
     * <b>unique autorite</b> ({@code NiveauActuelEpreuveResolver.mesure},
     * arbitrage du 2026-09-16), jamais recompte ici. R12 garantit qu'une epreuve
     * non mesuree a deja son etape dans la file, donc ce cas ne se presente que
     * sur un parcours reellement a jour.
     */
    private JourneySuggestionType suggestion(JourneyState state, UUID userId) {
        if (state != JourneyState.UP_TO_DATE) return null;
        for (EpreuveType epreuve : TcfDomainProfileDto.ORDRE) {
            if (!mesureResolver.mesure(userId, epreuve).mesuree()) return null;
        }
        return JourneySuggestionType.MOCK_EXAM;
    }

    // ------------------------------------------------------------------- mapping

    private static boolean estProduction(JourneyStep step) {
        SkillSection section = com.sejourfr.app.util.TcfDomaine.section(step.getExamType());
        return section != null && section.isProduction();
    }

    private JourneyStepDto dto(
            Etat etat, Map<UUID, PlanRecommendedExerciseDto> exercices) {
        JourneyStep step = etat.step();
        Skill skill = step.getSkill();
        return new JourneyStepDto(
                step.getId(),
                step.getType(),
                step.getPurpose(),
                etat.status(),
                // 🛑 LE BLOC EST SERVI, nature + code + libelle (D-47) : le front
                // affiche `bloc.label` et ne branche jamais sur le module.
                step.blocRef(),
                skill == null ? null : skill.getSection(),
                skill == null ? null : skill.getTaskCode(),
                // 🛑 Le CODE et le TITRE viennent de l'unite travaillable, quelle
                // qu'elle soit : une competence TCF ou une unite officielle
                // civique. `uniteLabel()` porte cette uniformite a la source.
                skill == null ? null : skill.getCode(),
                step.uniteLabel(),
                step.getLot() == null ? null : step.getLot().getId(),
                step.getSourceAssessmentId(),
                step.getPosition(),
                etat.progress(),
                etat.locked(),
                mesureDe(step),
                exerciceDe(step, exercices));
    }

    /**
     * <b>Le micro-exercice de chaque competence de la file</b>, indexe par
     * competence — <b>un seul lot</b>, quel que soit le nombre d'etapes.
     *
     * <p>🛑 <b>Aucune regle nouvelle</b> : {@code RecommendedExerciseSelector}
     * reste l'unique autorite du « quel sujet proposer sur cette competence »,
     * et sa signature en lot existe <b>precisement</b> pour un appelant qui a
     * plusieurs competences a evaluer d'affilee. Le parcours en devient le
     * troisieme lecteur, pas une troisieme regle.
     *
     * <p><b>Deux requetes, pas une par etape</b> : les sujets actifs et les
     * dernieres tentatives sont chargees en lot par le selecteur. L'{@code
     * access} est celui deja resolu par {@link #lire}, il n'est pas recalcule.
     * Un parcours sans etape d'entrainement ne coute <b>rien</b>.
     */
    private Map<UUID, PlanRecommendedExerciseDto> exercicesDesCompetences(
            UUID userId, List<JourneyStep> etapes, SkillAccessService.SkillAccess access) {
        Map<UUID, Skill> competences = new LinkedHashMap<>();
        for (JourneyStep step : etapes) {
            if (step.getType() != JourneyStepType.TRAIN_SKILL) continue;
            Skill skill = step.getSkill();
            if (skill != null) competences.putIfAbsent(skill.getId(), skill);
        }
        if (competences.isEmpty()) return Map.of();
        return exerciseSelector.selectAll(userId, competences.values(), access);
    }

    /**
     * L'exercice <b>servi</b> sur cette etape, ou {@code null}.
     *
     * <p>{@code null} sur une etape d'examen (elle porte {@link #mesureDe} a la
     * place) et sur une competence <b>sans sujet publie</b> — le selecteur
     * l'omet alors de sa map, et c'est le cas que le garde-fou attend : la ligne
     * nomme l'etape, sans bouton.
     */
    private static PlanRecommendedExerciseDto exerciceDe(
            JourneyStep step, Map<UUID, PlanRecommendedExerciseDto> exercices) {
        if (step.getType() != JourneyStepType.TRAIN_SKILL) return null;
        Skill skill = step.getSkill();
        return skill == null ? null : exercices.get(skill.getId());
    }

    /**
     * <b>Par quoi mesurer l'epreuve de cette etape</b>, ou {@code null} hors
     * {@code SECTION_EXAM}.
     *
     * <p>🛑 <b>Relayee, jamais composee</b> : c'est le meme
     * {@code PlanDomainAssessmentResolver.pour} que la fiche d'un domaine,
     * « Completer mon profil », l'Accueil, Reviser et la seance. Le parcours
     * devient son sixieme appelant, pas une sixieme regle.
     *
     * <p><b>Zero requete</b> : la methode est une table de natures, elle ne lit
     * ni la base ni l'historique.
     *
     * <p>Elle est servie <b>meme sur une epreuve deja mesuree</b>, et c'est
     * tout l'interet : un point d'etape {@code REASSESS} ne se retrouve ni dans
     * {@code domainesAEvaluer} (qui ne liste que le jamais-mesure) ni dans la
     * seance (qui ne porte que la mesure indispensable).
     */
    private PlanDomainAssessmentDto mesureDe(JourneyStep step) {
        if (step.getType() != JourneyStepType.SECTION_EXAM) return null;
        return assessmentResolver.pour(step.getExamType());
    }
}

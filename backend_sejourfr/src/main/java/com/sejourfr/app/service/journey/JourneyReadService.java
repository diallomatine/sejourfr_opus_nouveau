package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyDto;
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
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.dto.PlanDomainAssessmentDto;
import com.sejourfr.app.service.NiveauActuelEpreuveResolver;
import com.sejourfr.app.service.PlanDomainAssessmentResolver;
import com.sejourfr.app.service.ProductionAccessService;
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

/**
 * <b>Le parcours tel qu'on le LIT</b> : ce qui est verrouille, quelle etape est
 * courante, quel statut chaque etape affiche, et lesquelles l'ecran montre.
 *
 * <h2>🛑 Tout l'etat est derive ici, rien n'est relu d'une colonne</h2>
 * <p>Arbitrage D-7 : seuls la <b>structure</b> de la file et la <b>cloture</b>
 * d'une etape sont persistes. {@code CURRENT}, {@code locked} et les cinq
 * statuts d'affichage se recalculent a chaque appel. Consequence voulue : un
 * abonnement souscrit change l'ecran <b>sans une seule ecriture en base</b>, et
 * recalibrer le moteur de maitrise ne reinterprete <b>aucune</b> etape deja
 * close.
 *
 * <h2>L'ordre de la promotion casse une circularite, et il est normatif</h2>
 * <p>{@code SkillAccessService} ouvre d'office a un compte gratuit la competence
 * de la <b>premiere place du Plan</b>, quelle que soit sa nature (arbitrage du
 * 2026-08-21 : « un candidat non abonne pourra travailler sa priorite 1, vu
 * qu'elle est visible »). Il recoit donc la <b>premiere etape non cloturee</b>,
 * <b>verrous ignores</b> — et jamais {@code CURRENT} :
 * <ul>
 *   <li>lui passer {@code CURRENT} serait <b>circulaire</b> : {@code CURRENT}
 *       depend de {@code locked}, qui depend de l'acces ;</li>
 *   <li>lui passer une etape <b>deja deverrouillee</b> rendrait l'exemption
 *       inutile, et priverait le candidat gratuit de l'acces a sa <b>vraie</b>
 *       priorite n&deg;1.</li>
 * </ul>
 *
 * <h2>« Executable » veut dire FINISSABLE, pas « ouverte »</h2>
 * <p>C'est la lecture de D-1 qui rend l'arbitrage vrai. Un compte gratuit a bien
 * acces a <b>2 sujets sur 5</b> de sa premiere competence — l'etape est donc
 * ouverte — mais elle ne se clot <b>jamais</b>
 * ({@code LearningPlanStep.Progress.completed()} exige les 5, arbitrage produit
 * du 2026-08-14 : « la verification est premium, ne pas le reparer »). La
 * declarer executable aurait fige son parcours definitivement sur elle, ce que
 * D-1 existe precisement pour eviter.
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
        return new JourneyDto(null, JourneyState.NEEDS_OBJECTIVE, null, List.of(), 0, null);
    }

    /**
     * Le parcours, lu.
     *
     * @param toutesLesEtapes les etapes du parcours dans l'ordre de la file,
     *                        competence et lot <b>deja charges</b>.
     * @param expandAll       {@code true} pour rendre toutes les etapes non
     *                        obsoletes au lieu du sous-ensemble de §14.
     */
    public JourneyDto lire(Journey journey, List<JourneyStep> toutesLesEtapes, boolean expandAll) {
        UUID userId = journey.getUser().getId();
        List<JourneyStep> ouvertes = toutesLesEtapes.stream()
                .filter(JourneyStep::estOuverte)
                .toList();

        Map<UUID, SkillProgressCounter.SkillProgress> progressionExpression =
                progressionDesCompetencesDExpression(userId, ouvertes);

        // 🛑 LA PREMIERE ETAPE D'ENTRAINEMENT OUVERTE, VERROUS IGNORES : c'est
        // elle que le freemium ouvre d'office, et c'est ce qui casse la
        // circularite CURRENT ⇄ locked (cf. l'en-tete de classe).
        //
        // 🛑 **Les etapes SANS CONTENU sont sautees, exactement comme dans
        // {@link #elire}** (correctif du 2026-09-17) : l'exemption doit tomber
        // sur l'etape qui prendra reellement la main. Sans ce saut, une
        // competence d'expression sans aucun sujet publie consommait
        // l'exemption — elle n'a rien a ouvrir —, la main passait a l'etape
        // suivante, et le compte gratuit lisait donc une etape sans y avoir
        // acces. C'est le meme filtre qui aligne `PlanFocusResolver`, l'autre
        // lecteur de cette premiere place.
        UUID focusSkillId = ouvertes.stream()
                .filter(step -> step.getType() == JourneyStepType.TRAIN_SKILL)
                .filter(step -> !sansContenu(step, progressionExpression))
                .map(JourneyStep::getSkill)
                .filter(java.util.Objects::nonNull)
                .map(Skill::getId)
                .findFirst()
                .orElse(null);
        SkillAccessService.SkillAccess access = accessService.resolve(userId, focusSkillId);
        Map<UUID, Integer> seriesParCompetence = seriesTermineesDepuisLaCreation(userId, ouvertes);
        // Le verrou EE/EO est le meme quel que soit le nombre d'etapes
        // concernees : une seule lecture, et seulement si une etape le demande.
        boolean examenDeProductionVerrouille = ouvertes.stream().anyMatch(
                step -> step.getType() == JourneyStepType.SECTION_EXAM && estProduction(step))
                && productionAccessService.isProductionExamLocked(userId);

        Map<UUID, Etat> etats = new LinkedHashMap<>();
        for (JourneyStep step : toutesLesEtapes) {
            boolean locked = estVerrouillee(
                    step, access, progressionExpression, examenDeProductionVerrouille);
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

        List<JourneyStep> affichables = toutesLesEtapes.stream()
                .filter(step -> etats.get(step.getId()).status() != JourneyStepStatus.OBSOLETE)
                .toList();
        List<JourneyStep> visibles = expandAll
                ? affichables
                : filtrer(affichables, courante, etats);
        int repliees = (int) affichables.stream()
                .filter(JourneyStep::estOuverte)
                .filter(step -> !visibles.contains(step))
                .count();

        JourneyState state = etat(ouvertes, courante);
        return new JourneyDto(
                journey.getTargetLevel(),
                state,
                courante == null ? null : dto(etats.get(courante.getId())),
                visibles.stream().map(step -> dto(etats.get(step.getId()))).toList(),
                repliees,
                suggestion(state, userId));
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
     *   <tr><td>{@code SECTION_EXAM} CO/CE</td>
     *       <td><b>jamais</b> — slot 1 offert <b>et rejouable a volonte</b>,
     *           tirage aleatoire pour tout compte inscrit</td>
     *       <td>{@code AttemptService.enforceMockExamSlotAccess}</td></tr>
     *   <tr><td>{@code SECTION_EXAM} EE/EO</td>
     *       <td>le quota d'examen blanc de production est consomme</td>
     *       <td>{@code ProductionAccessService}</td></tr>
     *   <tr><td>{@code DIAGNOSTIC}</td><td><b>jamais</b></td><td>—</td></tr>
     * </table>
     */
    private boolean estVerrouillee(
            JourneyStep step,
            SkillAccessService.SkillAccess access,
            Map<UUID, SkillProgressCounter.SkillProgress> progressionExpression,
            boolean examenDeProductionVerrouille) {
        return switch (step.getType()) {
            case DIAGNOSTIC -> false;
            case SECTION_EXAM -> estProduction(step) && examenDeProductionVerrouille;
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
     * Les <b>series ciblees terminees</b> sur chaque competence de comprehension
     * ouverte, <b>depuis la creation de son etape</b> (R8, arbitrage D-5).
     *
     * <p>Une serie terminee ecrit <b>une observation</b> de comprehension par
     * competence touchee ({@code ComprehensionObservationService}) : les compter
     * par {@code sourceId} distinct compte donc les <b>sessions</b>, et une seule
     * requete suffit pour toutes les etapes.
     *
     * <p>🛑 <b>Les {@code NOT_OBSERVED} comptent</b>, et c'est voulu : le quota
     * mesure le <b>travail fourni</b>, pas la reussite — meme doctrine que
     * {@code Progress.completed()}, qui compte les sujets « traites, pas
     * valides ». Une serie ou trop peu de questions d'un palier sont tombees a
     * quand meme ete jouee.
     */
    private Map<UUID, Integer> seriesTermineesDepuisLaCreation(
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
        Map<UUID, Set<UUID>> sessionsParCompetence = new LinkedHashMap<>();
        for (LearningPlanObservation observation : observations) {
            if (observation.getSourceType() == null
                    || !observation.getSourceType().isComprehension()) {
                continue;
            }
            UUID skillId = observation.getSkill().getId();
            Instant creation = depuis.get(skillId);
            if (creation == null || observation.getObservedAt().isBefore(creation)) continue;
            sessionsParCompetence
                    .computeIfAbsent(skillId, key -> new LinkedHashSet<>())
                    .add(observation.getSourceId());
        }
        Map<UUID, Integer> compte = new LinkedHashMap<>();
        sessionsParCompetence.forEach((skillId, sessions) -> compte.put(skillId, sessions.size()));
        return compte;
    }

    /**
     * L'avancement servi. 🛑 <b>L'unite est servie</b>
     * ({@link JourneyProgressUnit}), jamais deduite par un front de la nullite de
     * {@code taskCode} : ce serait recopier une regle du referentiel dans les
     * deux fronts.
     */
    private JourneyStepDto.JourneyProgressDto progression(
            JourneyStep step,
            Map<UUID, SkillProgressCounter.SkillProgress> expression,
            Map<UUID, Integer> series) {
        if (step.getType() != JourneyStepType.TRAIN_SKILL) return null;
        Skill skill = step.getSkill();
        if (skill == null || skill.getSection() == null) return null;
        if (skill.getSection().isComprehension()) {
            return new JourneyStepDto.JourneyProgressDto(
                    series.getOrDefault(skill.getId(), 0),
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

    // ---------------------------------------------------------- §14 : affichage

    /**
     * Ce que l'ecran montre (§14). Tout le reste se replie derriere « Voir les
     * etapes suivantes », et rien n'est <b>supprime</b> : une etape existe ou
     * n'existe pas, elle ne se cache pas selon l'abonnement.
     */
    private List<JourneyStep> filtrer(
            List<JourneyStep> affichables, JourneyStep courante, Map<UUID, Etat> etats) {
        Set<UUID> retenues = new LinkedHashSet<>();

        // Les dernieres etapes closes : de quoi voir le chemin parcouru sans
        // noyer l'etape en cours. L'historique complet appartient a la
        // Progression.
        List<JourneyStep> closes = affichables.stream()
                .filter(step -> !step.estOuverte())
                .toList();
        closes.stream()
                .skip(Math.max(0, closes.size() - config.display().recentCompletedVisible()))
                .forEach(step -> retenues.add(step.getId()));

        long positionCourante = courante == null ? Long.MAX_VALUE : courante.getPosition();
        if (courante != null) retenues.add(courante.getId());

        for (JourneyStep step : affichables) {
            if (!step.estOuverte()) continue;
            // 🛑 R16 — une etape VERROUILLEE placee AVANT l'etape courante reste
            // visible, a sa place. C'est elle que le freemium doit montrer : la
            // masquer priverait le candidat de l'information la plus utile qu'il
            // possede, et c'est exactement ce que la contradiction #1 du depot a
            // tranche le 2026-08-21.
            if (step.getPosition() < positionCourante && etats.get(step.getId()).locked()) {
                retenues.add(step.getId());
            }
            // Tout le lot courant, CHECKPOINT COMPRIS — jamais masque : le
            // candidat doit voir ou son cycle de travail s'arrete.
            if (courante != null && courante.getLot() != null && step.getLot() != null
                    && courante.getLot().getId().equals(step.getLot().getId())) {
                retenues.add(step.getId());
            }
        }

        int aVenir = 0;
        for (JourneyStep step : affichables) {
            if (!step.estOuverte() || step.getPosition() <= positionCourante) continue;
            if (retenues.contains(step.getId())) continue;
            if (aVenir++ >= config.display().upcomingVisible()) break;
            retenues.add(step.getId());
        }
        return affichables.stream().filter(step -> retenues.contains(step.getId())).toList();
    }

    // ------------------------------------------------------------- §8 : etats

    private static JourneyState etat(List<JourneyStep> ouvertes, JourneyStep courante) {
        if (ouvertes.isEmpty()) return JourneyState.UP_TO_DATE;
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

    private JourneyStepDto dto(Etat etat) {
        JourneyStep step = etat.step();
        Skill skill = step.getSkill();
        return new JourneyStepDto(
                step.getId(),
                step.getType(),
                step.getPurpose(),
                etat.status(),
                step.getExamType(),
                skill == null ? null : skill.getSection(),
                skill == null ? null : skill.getTaskCode(),
                skill == null ? null : skill.getCode(),
                skill == null ? null : skill.getTitle(),
                step.getLot() == null ? null : step.getLot().getId(),
                step.getSourceAssessmentId(),
                step.getPosition(),
                etat.progress(),
                etat.locked(),
                mesureDe(step));
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

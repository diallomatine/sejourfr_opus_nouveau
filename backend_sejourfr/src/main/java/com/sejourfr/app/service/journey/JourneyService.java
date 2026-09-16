package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyAssessmentEvent;
import com.sejourfr.app.entity.JourneyLot;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyLotStatus;
import com.sejourfr.app.enums.JourneyStepPurpose;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.JourneyLotManager;
import com.sejourfr.app.manager.JourneyManager;
import com.sejourfr.app.manager.JourneyStepManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.NiveauActuelEpreuveResolver;
import com.sejourfr.app.service.SkillMasteryEngine;
import com.sejourfr.app.service.SkillMasteryResolver;
import com.sejourfr.app.service.TcfProfileService;
import com.sejourfr.app.util.TcfDomaine;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * <b>Le parcours TCF</b> : la couche d'orchestration qui range en file ce que les
 * evaluations ont designe.
 *
 * <h2>Ce que ce service ne fait pas, et ne doit jamais faire</h2>
 * <p>Il ne <b>mesure</b> rien, ne <b>note</b> rien, ne <b>calcule</b> aucun
 * niveau et ne <b>decide</b> d'aucune maitrise. Chaque fait qu'il utilise est
 * lu chez son autorite :
 * <ul>
 *   <li>les priorites : {@code learning_plan_observations} ;</li>
 *   <li>l'ordre de gravite : {@link JourneyLotBuilder}, qui reproduit celui de
 *       {@code LearningPlanPriorityResolver} ;</li>
 *   <li>« transfert prouve » : {@code SkillMasteryEngine} ;</li>
 *   <li>le niveau par epreuve : {@code TcfProfileService.levelProfile} ;</li>
 *   <li>« epreuve mesuree » : {@code NiveauActuelEpreuveResolver.mesure} ;</li>
 *   <li>le niveau cible : {@code TargetProcedure.niveauVise}.</li>
 * </ul>
 *
 * <h2>Best-effort, et ca ne se negocie pas</h2>
 * <p>{@link #onAssessmentCompleted} et {@link #onTrainingProgress} tournent dans
 * leur <b>propre transaction</b> ({@link Propagation#REQUIRES_NEW}) et leurs
 * appelants avalent leurs exceptions. Un bug d'orchestration ne doit
 * <b>jamais</b> faire echouer la correction d'un QCM, la livraison d'une
 * evaluation payante, ni une reponse HTTP. La lecture suivante rattrape.
 *
 * <h2>Serialise, jamais concurrent</h2>
 * <p>Toute ecriture prend le <b>verrou pessimiste</b> du parcours (R14). Deux
 * evaluations qui se terminent en meme temps — une production corrigee en
 * asynchrone pendant que le candidat finit un QCM — ajoutent donc leurs lots
 * l'une apres l'autre, et les deux entrent.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class JourneyService {

    private final JourneyManager journeyManager;
    private final JourneyLotManager lotManager;
    private final JourneyStepManager stepManager;
    private final JourneyEvaluationFilter evaluationFilter;
    private final JourneyLotBuilder lotBuilder;
    private final JourneyReadService readService;
    private final LearningPlanObservationManager observationManager;
    private final SkillMasteryResolver masteryResolver;
    private final TcfProfileService profileService;
    private final NiveauActuelEpreuveResolver mesureResolver;
    private final UserManager userManager;

    // =====================================================================
    // Lecture
    // =====================================================================

    /**
     * Le parcours du candidat, cree paresseusement si besoin (R19).
     *
     * <p>🛑 <b>Cette lecture ECRIT</b> la premiere fois, et c'est le bootstrap :
     * le parcours d'un utilisateur existant se reconstruit a partir de ses
     * evaluations passees, sans migration de donnees. Un utilisateur qui n'ouvre
     * jamais le Plan n'a jamais de parcours.
     */
    @Transactional
    public JourneyDto lire(UUID userId, boolean expandAll) {
        Optional<Journey> journey = getOrCreate(userId);
        if (journey.isEmpty()) return readService.sansObjectif();
        Journey courant = journey.get();
        return readService.lire(courant, stepManager.findAll(courant.getId()), expandAll);
    }

    // =====================================================================
    // R18 / R19 — creation et bootstrap
    // =====================================================================

    /**
     * Le parcours du niveau cible courant, cree et amorce si besoin.
     *
     * @return {@link Optional#empty()} quand le candidat n'a <b>pas declare
     *         d'objectif</b> (arbitrage D-3). 🛑 Aucun parcours n'est alors cree :
     *         en fabriquer un « par defaut » reviendrait a choisir un objectif a
     *         sa place, puis a batir une file entiere sur cette supposition.
     */
    @Transactional
    public Optional<Journey> getOrCreate(UUID userId) {
        User user = userManager.findById(userId).orElse(null);
        if (user == null) return Optional.empty();
        TargetLevel cible = TargetProcedure.niveauVise(
                user.getTargetProcedure(), user.getTargetLevel());
        if (cible == null) return Optional.empty();

        Optional<Journey> existant = journeyManager.find(userId, cible);
        if (existant.isPresent()) return existant;

        Journey journey = new Journey();
        journey.setUser(user);
        journey.setTargetLevel(cible);
        journey = journeyManager.save(journey);
        amorcer(journey, user, cible);
        return Optional.of(journey);
    }

    /**
     * <b>R19 — le bootstrap.</b> Il ne rejoue pas l'historique etape par etape :
     * il reconstruit directement l'etat a partir d'une <b>evaluation de
     * reference par epreuve</b>.
     *
     * <p>🛑 <b>Aucune etape close n'est fabriquee depuis l'historique</b> : la
     * timeline d'un nouveau parcours commence par ce qu'il reste a faire. Inventer
     * des etapes « deja faites » donnerait au candidat un parcours qu'il n'a pas
     * vecu.
     *
     * <p>🛑 <b>Aucun appel LLM, aucun recalcul d'evaluation</b> : les observations
     * ne dependent pas du niveau cible, seule leur <b>selection</b> en depend.
     * C'est ce qui rend un changement d'objectif gratuit — et c'est pourquoi il
     * ne force jamais un nouveau diagnostic.
     */
    private void amorcer(Journey journey, User user, TargetLevel cible) {
        List<LearningPlanObservation> tout =
                observationManager.findAllByUserWithSkill(user.getId());
        // 🛑 MEME FILTRE QU'EN COURS DE ROUTE (D-6) : une observation
        // d'entrainement n'amorce rien, quelle que soit son anciennete. Sans
        // cela, le bootstrap batirait une file qu'aucune evaluation ulterieure
        // ne saurait reproduire.
        List<LearningPlanObservation> evaluations = evaluationFilter.retenir(tout);
        if (evaluations.isEmpty()) {
            // Aucune evaluation exploitable : c'est le seul cas ou le parcours
            // demande un diagnostic (R19.8).
            ajouter(journey, diagnostic(journey));
            return;
        }

        Map<EpreuveType, UUID> references = referencesParEpreuve(evaluations);
        Set<UUID> maitrisees = maitriseesCeJour(tout, evaluations);
        TcfLevelProfile profil = profileService.levelProfile(user.getId());
        creerLots(journey,
                lotBuilder.depuisHistorique(references, evaluations, maitrisees, cible, profil));
        ajouterLesEpreuvesNonMesurees(journey, user.getId());

        // R19.7 — TOUTES les evaluations historiques sont enregistrees d'un coup.
        // Elles ne seront jamais retraitees, et R14 garantit qu'aucune plus
        // ancienne ne modifiera ensuite la structure.
        enregistrerLHistorique(journey, evaluations);
    }

    /**
     * L'evaluation de <b>reference</b> de chaque epreuve (R19.2) : la plus
     * recente qui <b>mesure</b> l'epreuve, a defaut le plus recent diagnostic
     * rapide ayant produit des priorites pour elle.
     *
     * <p>Les observations arrivent de la plus recente a la plus ancienne : la
     * premiere rencontree fait donc foi, sans tri supplementaire.
     */
    private Map<EpreuveType, UUID> referencesParEpreuve(
            List<LearningPlanObservation> evaluations) {
        Map<EpreuveType, UUID> mesurantes = new LinkedHashMap<>();
        Map<EpreuveType, UUID> repli = new LinkedHashMap<>();
        for (LearningPlanObservation observation : evaluations) {
            Skill skill = observation.getSkill();
            if (skill == null) continue;
            EpreuveType epreuve = TcfDomaine.epreuve(skill.getSection());
            if (epreuve == null) continue;
            LearningPlanSourceType source = observation.getSourceType();
            boolean baseline = source == LearningPlanSourceType.DIAGNOSTIC_EE
                    || source == LearningPlanSourceType.DIAGNOSTIC_EO;
            if (baseline) {
                repli.putIfAbsent(epreuve, observation.getSourceId());
            } else {
                mesurantes.putIfAbsent(epreuve, observation.getSourceId());
            }
        }
        Map<EpreuveType, UUID> references = new LinkedHashMap<>();
        for (EpreuveType epreuve : TcfDomainProfileDto.ORDRE) {
            UUID reference = mesurantes.get(epreuve);
            if (reference == null) reference = repli.get(epreuve);
            if (reference != null) references.put(epreuve, reference);
        }
        return references;
    }

    // =====================================================================
    // §7.2 — une evaluation se termine
    // =====================================================================

    /**
     * <b>Une evaluation est terminee</b> (§7.2).
     *
     * <p>Appele <b>apres</b> l'ecriture des observations, et pour une bonne
     * raison : en comprehension, la competence est <b>derivee du contenu des
     * questions</b> par {@code ComprehensionObservationService} — l'appelant ne
     * la connait pas avant. Le parcours lit donc ce qui a <b>reellement</b> ete
     * ecrit.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void onAssessmentCompleted(UUID userId, JourneyEvaluation evaluation) {
        Optional<Journey> trouve = getOrCreate(userId);
        if (trouve.isEmpty()) return;
        Journey journey = journeyManager.findForUpdate(trouve.get().getId()).orElse(null);
        if (journey == null) return;

        // R14 — un sourceAssessmentId n'est traite qu'une fois. Le bootstrap a
        // deja enregistre tout l'historique, donc une evaluation qui vient de
        // creer le parcours retombe ici sans effet : c'est exactement ce qu'on
        // veut, elle est deja dans la file.
        if (journeyManager.dejaTraitee(journey.getId(), evaluation.sourceAssessmentId())) return;
        enregistrer(journey, evaluation);

        List<LearningPlanObservation> tout = observationManager.findAllByUserWithSkill(userId);
        List<LearningPlanObservation> evaluations = evaluationFilter.retenir(tout);

        cloreLEtapeDiagnostic(journey, evaluation);

        boolean tropAncienne = false;
        if (evaluation.mesureUneEpreuve()) {
            tropAncienne = estTropAncienne(journey, evaluation);
            if (!tropAncienne) {
                cloreLEtapeDEvaluation(journey, evaluation);
                cloreOuRemplacerLeLot(journey, evaluation);
            }
        }

        if (!tropAncienne) {
            TargetLevel cible = journey.getTargetLevel();
            Set<UUID> maitrisees = maitriseesCeJour(tout, evaluations);
            List<JourneyLotBuilder.Lot> lots = lotBuilder.depuisEvaluation(
                    evaluation.sourceAssessmentId(), evaluations, maitrisees, cible,
                    profileService.levelProfile(userId));
            // R11 — un diagnostic rapide ne remplace jamais un lot ouvert : il
            // ne cree un lot que pour les epreuves qui n'en ont pas.
            if (!evaluation.mesureUneEpreuve()) {
                lots = lots.stream()
                        .filter(lot -> lotManager.findOuvert(journey.getId(), lot.epreuve()).isEmpty())
                        .toList();
            }
            creerLots(journey, lots);
        }

        ajouterLesEpreuvesNonMesurees(journey, userId);
        journeyManager.save(journey);
    }

    /**
     * <b>R14 — une evaluation arrivee en retard ne defait pas une plus
     * recente.</b>
     *
     * <p>Cas reel : une session jouee hors ligne sur mobile, synchronisee deux
     * jours plus tard. Elle est <b>enregistree</b> — donc jamais retraitee — mais
     * ne touche pas la structure de son epreuve : sans ce garde-fou, l'examen de
     * mardi remplacerait le lot que celui de mercredi vient de creer.
     */
    private boolean estTropAncienne(Journey journey, JourneyEvaluation evaluation) {
        Optional<Instant> derniere =
                journeyManager.derniereMesure(journey.getId(), evaluation.examType());
        boolean ancienne = derniere.isPresent()
                && evaluation.completedAt().isBefore(derniere.get());
        if (ancienne) {
            log.info("Parcours {} : evaluation {} ({}) ignoree pour anciennete — {} < {}",
                    journey.getId(), evaluation.sourceAssessmentId(), evaluation.examType(),
                    evaluation.completedAt(), derniere.get());
        }
        return ancienne;
    }

    /**
     * L'etape {@code DIAGNOSTIC} ouverte, s'il y en a une, est close : le
     * candidat n'a plus a faire un diagnostic dont une evaluation vient de
     * repondre a la question.
     */
    private void cloreLEtapeDiagnostic(Journey journey, JourneyEvaluation evaluation) {
        for (JourneyStep step : stepManager.findAll(journey.getId())) {
            if (step.getType() != JourneyStepType.DIAGNOSTIC || !step.estOuverte()) continue;
            if (step.clore(JourneyStepResolution.SATISFIED_BY_ASSESSMENT,
                    evaluation.sourceAssessmentId(), evaluation.completedAt())) {
                stepManager.save(step);
            }
        }
    }

    /**
     * L'etape « {Epreuve} — Evaluer mon niveau » ouverte de cette epreuve est
     * close : <b>on ne demande jamais au candidat de refaire un examen qu'il
     * vient de passer</b> (R7), meme s'il l'a lance hors du Plan.
     */
    private void cloreLEtapeDEvaluation(Journey journey, JourneyEvaluation evaluation) {
        for (JourneyStep step : stepManager.findAll(journey.getId())) {
            if (step.getType() != JourneyStepType.SECTION_EXAM || !step.estOuverte()) continue;
            if (step.getPurpose() != JourneyStepPurpose.INITIAL_ASSESSMENT) continue;
            if (evaluation.examType() != step.getExamType()) continue;
            if (step.clore(JourneyStepResolution.SATISFIED_BY_ASSESSMENT,
                    evaluation.sourceAssessmentId(), evaluation.completedAt())) {
                stepManager.save(step);
            }
        }
    }

    /**
     * <b>R7 — un examen fait toujours autorite</b>, depuis le Plan ou ailleurs.
     *
     * <ul>
     *   <li>tous les entrainements du lot sont faits ⇒ son checkpoint est
     *       <b>satisfait</b>, meme s'il n'avait pas encore pris la main, et le lot
     *       est {@code CLOSED} ;</li>
     *   <li>des entrainements restent ⇒ l'examen devient la nouvelle reference :
     *       ce qui reste, <b>checkpoint compris</b>, passe {@code SUPERSEDED},
     *       donc invisible, et le lot est remplace.</li>
     * </ul>
     */
    private void cloreOuRemplacerLeLot(Journey journey, JourneyEvaluation evaluation) {
        JourneyLot lot = lotManager.findOuvert(journey.getId(), evaluation.examType()).orElse(null);
        if (lot == null) return;
        List<JourneyStep> restantes = stepManager.findOuvertesDuLot(lot.getId());
        boolean entrainementsRestants = restantes.stream()
                .anyMatch(step -> step.getType() == JourneyStepType.TRAIN_SKILL);

        JourneyStepResolution motif = entrainementsRestants
                ? JourneyStepResolution.SUPERSEDED
                : JourneyStepResolution.SATISFIED_BY_ASSESSMENT;
        for (JourneyStep step : restantes) {
            if (step.clore(motif, evaluation.sourceAssessmentId(), evaluation.completedAt())) {
                stepManager.save(step);
            }
        }
        lot.clore(entrainementsRestants ? JourneyLotStatus.SUPERSEDED : JourneyLotStatus.CLOSED,
                evaluation.sourceAssessmentId(), evaluation.completedAt());
        lotManager.save(lot);
    }

    // =====================================================================
    // §7.3 — un entrainement avance
    // =====================================================================

    /**
     * <b>Un entrainement a progresse</b> (§7.3) — il peut <b>clore</b> une etape,
     * jamais en <b>creer</b> une (R1).
     *
     * @param skillIds les competences <b>reellement observees</b> par cet
     *                 entrainement. En comprehension, l'appelant ne les connait
     *                 qu'apres l'ecriture des observations : c'est la raison du
     *                 branchement tardif (B-13).
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void onTrainingProgress(UUID userId, Collection<UUID> skillIds) {
        if (skillIds == null || skillIds.isEmpty()) return;
        Optional<Journey> trouve = getOrCreate(userId);
        if (trouve.isEmpty()) return;
        Journey journey = journeyManager.findForUpdate(trouve.get().getId()).orElse(null);
        if (journey == null) return;

        List<JourneyStep> concernees = stepManager.findAll(journey.getId()).stream()
                .filter(JourneyStep::estOuverte)
                .filter(step -> step.getType() == JourneyStepType.TRAIN_SKILL)
                .filter(step -> step.getSkill() != null
                        && skillIds.contains(step.getSkill().getId()))
                .toList();
        // 🛑 R1 : aucune etape concernee ⇒ RIEN. Un entrainement qui detecte une
        // faiblesse nouvelle ne l'ajoute pas au parcours ; elle y entrera si une
        // evaluation la detecte.
        if (concernees.isEmpty()) return;

        Instant maintenant = Instant.now();
        JourneyDto vue = readService.lire(journey, stepManager.findAll(journey.getId()), true);
        Map<UUID, com.sejourfr.app.dto.JourneyStepDto> vues = new LinkedHashMap<>();
        vue.steps().forEach(step -> vues.put(step.id(), step));

        Map<UUID, SkillMasteryEngine.SkillMastery> maitrise = masteryResolver.bySkillIds(
                userId, concernees.stream().map(step -> step.getSkill().getId()).toList());

        for (JourneyStep step : concernees) {
            UUID skillId = step.getSkill().getId();
            SkillMasteryEngine.SkillMastery etat = maitrise.get(skillId);
            JourneyStepResolution motif = null;
            if (etat != null && etat.transferProven()) {
                motif = JourneyStepResolution.MASTERED;
            } else {
                com.sejourfr.app.dto.JourneyStepDto servie = vues.get(step.getId());
                // Le quota est LU sur la progression servie : c'est la meme
                // autorite que l'ecran, donc l'etape ne peut pas se clore sur un
                // compteur different de celui que le candidat a lu.
                if (servie != null && servie.progress() != null
                        && servie.progress().quota() > 0
                        && servie.progress().done() >= servie.progress().quota()) {
                    motif = JourneyStepResolution.QUOTA_REACHED;
                }
            }
            if (motif != null && step.clore(motif, null, maintenant)) {
                stepManager.save(step);
            }
        }
        journeyManager.save(journey);
    }

    // =====================================================================
    // Ecriture de la file
    // =====================================================================

    /** Cree les lots dans l'ordre recu, chacun suivi de son checkpoint (R3, R4). */
    private void creerLots(Journey journey, List<JourneyLotBuilder.Lot> lots) {
        for (JourneyLotBuilder.Lot prevu : lots) {
            JourneyLot lot = new JourneyLot();
            lot.setJourney(journey);
            lot.setExamType(prevu.epreuve());
            lot.setStatus(JourneyLotStatus.OPEN);
            lot.setSourceAssessmentId(prevu.sourceAssessmentId());
            lot = lotManager.save(lot);

            for (JourneyLotBuilder.Priorite priorite : prevu.priorites()) {
                JourneyStep step = new JourneyStep();
                step.setJourney(journey);
                step.setLot(lot);
                step.setType(JourneyStepType.TRAIN_SKILL);
                step.setExamType(prevu.epreuve());
                step.setSkill(priorite.skill());
                step.setSeverityRank(priorite.rang());
                step.setSourceAssessmentId(prevu.sourceAssessmentId());
                ajouter(journey, step);
            }

            // R3 — un lot est TOUJOURS clos par un examen de son epreuve. Sans
            // lui, le candidat travaillerait sans jamais savoir si ca a marche.
            JourneyStep checkpoint = new JourneyStep();
            checkpoint.setJourney(journey);
            checkpoint.setLot(lot);
            checkpoint.setType(JourneyStepType.SECTION_EXAM);
            checkpoint.setPurpose(JourneyStepPurpose.REASSESS);
            checkpoint.setExamType(prevu.epreuve());
            checkpoint.setSourceAssessmentId(prevu.sourceAssessmentId());
            ajouter(journey, checkpoint);
        }
    }

    /**
     * <b>R12 — les epreuves non mesurees</b>, apres les nouveaux lots.
     *
     * <p>🛑 « Mesuree » est lu chez son <b>unique autorite</b>
     * ({@code NiveauActuelEpreuveResolver.mesure} — arbitrage du 2026-09-16, « il
     * n'existe qu'UNE notion de mesuree »), jamais recompte ici. Et « par quoi la
     * mesurer » appartient a {@code PlanDomainAssessmentResolver} : la file ne
     * porte que l'epreuve, le front compose l'action.
     */
    private void ajouterLesEpreuvesNonMesurees(Journey journey, UUID userId) {
        Set<EpreuveType> dejaPrevues = new LinkedHashSet<>();
        for (JourneyStep step : stepManager.findAll(journey.getId())) {
            if (step.getType() == JourneyStepType.SECTION_EXAM && step.estOuverte()) {
                dejaPrevues.add(step.getExamType());
            }
        }
        for (EpreuveType epreuve : TcfDomainProfileDto.ORDRE) {
            if (dejaPrevues.contains(epreuve)) continue;
            if (mesureResolver.mesure(userId, epreuve).mesuree()) continue;
            JourneyStep step = new JourneyStep();
            step.setJourney(journey);
            step.setType(JourneyStepType.SECTION_EXAM);
            step.setPurpose(JourneyStepPurpose.INITIAL_ASSESSMENT);
            step.setExamType(epreuve);
            ajouter(journey, step);
        }
    }

    private JourneyStep diagnostic(Journey journey) {
        JourneyStep step = new JourneyStep();
        step.setJourney(journey);
        step.setType(JourneyStepType.DIAGNOSTIC);
        return step;
    }

    /**
     * Ajoute une etape <b>en fin de file</b> (R4) : elle ne remplace jamais
     * l'etape courante, ne passe jamais devant un examen prevu, n'interrompt
     * jamais un autre lot.
     */
    private void ajouter(Journey journey, JourneyStep step) {
        step.setPosition(journey.consommerPosition());
        stepManager.save(step);
        journeyManager.save(journey);
    }

    // =====================================================================
    // Journal des evaluations
    // =====================================================================

    private void enregistrer(Journey journey, JourneyEvaluation evaluation) {
        JourneyAssessmentEvent event = new JourneyAssessmentEvent();
        event.setJourney(journey);
        event.setSourceAssessmentId(evaluation.sourceAssessmentId());
        event.setAssessmentKind(evaluation.kind());
        event.setExamType(evaluation.examType());
        event.setCompletedAt(evaluation.completedAt());
        journeyManager.enregistrer(event);
    }

    /**
     * R19.7 — <b>tout</b> l'historique est enregistre a la creation du parcours.
     *
     * <p>La <b>nature</b> et l'<b>epreuve</b> sont deduites de la source de
     * l'observation, seule information disponible sans relire trois tables : une
     * observation de diagnostic rapide n'a pas d'epreuve (R11), une observation
     * d'examen porte celle de sa competence. C'est suffisant pour ce a quoi ce
     * journal sert — l'idempotence et la chronologie par epreuve.
     */
    private void enregistrerLHistorique(
            Journey journey, List<LearningPlanObservation> evaluations) {
        Map<UUID, JourneyEvaluation> parSource = new LinkedHashMap<>();
        for (LearningPlanObservation observation : evaluations) {
            UUID source = observation.getSourceId();
            if (source == null || parSource.containsKey(source)) continue;
            Skill skill = observation.getSkill();
            if (skill == null) continue;
            boolean baseline = observation.getSourceType() == LearningPlanSourceType.DIAGNOSTIC_EE
                    || observation.getSourceType() == LearningPlanSourceType.DIAGNOSTIC_EO;
            parSource.put(source, baseline
                    ? JourneyEvaluation.diagnosticRapide(source, observation.getObservedAt())
                    : new JourneyEvaluation(source,
                            com.sejourfr.app.enums.JourneyAssessmentKind.SECTION_EXAM,
                            TcfDomaine.epreuve(skill.getSection()), observation.getObservedAt()));
        }
        parSource.values().forEach(evaluation -> enregistrer(journey, evaluation));
    }

    // =====================================================================
    // Maitrise
    // =====================================================================

    /**
     * Les competences dont le <b>transfert est prouve aujourd'hui</b> — lues chez
     * {@code SkillMasteryEngine}, sur l'historique <b>deja charge</b> : aucune
     * requete de plus.
     *
     * <p>Elles n'entrent jamais dans un lot (R19.4) : redemander ce qui est acquis
     * ferait tourner le parcours en rond.
     */
    private Set<UUID> maitriseesCeJour(
            List<LearningPlanObservation> tout, List<LearningPlanObservation> evaluations) {
        Set<UUID> candidates = new LinkedHashSet<>();
        for (LearningPlanObservation observation : evaluations) {
            if (observation.getSkill() != null) candidates.add(observation.getSkill().getId());
        }
        if (candidates.isEmpty()) return Set.of();
        // 🛑 Le moteur recoit TOUT l'historique, pas seulement les evaluations :
        // un petit sujet reussi compte dans la maitrise (c'est le sens meme du
        // module Competences), meme s'il ne peut pas creer d'etape.
        Map<UUID, SkillMasteryEngine.SkillMastery> maitrise =
                masteryResolver.fromObservations(tout, candidates);
        Set<UUID> prouvees = new LinkedHashSet<>();
        maitrise.forEach((skillId, etat) -> {
            if (etat != null && etat.transferProven()) prouvees.add(skillId);
        });
        return prouvees;
    }
}

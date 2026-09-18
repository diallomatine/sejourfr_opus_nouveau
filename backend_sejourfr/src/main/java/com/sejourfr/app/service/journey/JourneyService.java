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
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.JourneyStepPurpose;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.Module;
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
 *
 * <h2>Le cycle est BORNE : deux destinations, jamais une seule (D-13)</h2>
 * <p>Un cycle amorce ne grossit plus. Une evaluation qui se termine pendant
 * qu'il tourne fait <b>deux</b> choses distinctes :
 * <ol>
 *   <li>dans le cycle <b>EN COURS</b>, elle <b>clot</b> ce qu'elle a le droit de
 *       clore — l'examen de son bloc, si et seulement si ce bloc etait pret
 *       (R1, {@link #cloreLExamenDuBloc}) ;</li>
 *   <li>dans le cycle <b>EN ATTENTE</b>, invisible du candidat, elle depose les
 *       priorites <b>nouvellement</b> detectees ({@link #mettreEnAttente}).</li>
 * </ol>
 * <p>Le cycle en attente devient le cycle courant par une <b>transition</b>
 * explicite, que le candidat declenche ({@link JourneyCycleService}). Rien ne
 * se promeut tout seul : « actualiser mon plan » est un geste, pas un effet de
 * bord.
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
    public JourneyDto lire(UUID userId) {
        Optional<Journey> journey = getOrCreate(userId);
        if (journey.isEmpty()) return readService.sansObjectif();
        Journey courant = journey.get();
        return readService.lire(courant, stepManager.findAll(courant.getId()));
    }

    // =====================================================================
    // R18 / R19 — creation et bootstrap
    // =====================================================================

    /**
     * Le <b>cycle en cours</b> du candidat sur le module TCF, cree et amorce si
     * besoin.
     *
     * <p>🛑 <b>Un changement d'objectif ne cree pas un second cycle</b> (D-13) :
     * le cycle en cours survit et son niveau cible est mis a jour. L'historiser
     * jetterait le plan que le candidat a sous les yeux, et un ping-pong
     * d'objectif polluerait son historique de cycles ; les priorites deja
     * designees ne deviennent pas fausses parce que la cible a bouge — seul
     * l'<b>ordre</b> des lots s'en trouve recalcule, et il est derive a la
     * lecture.
     *
     * @return {@link Optional#empty()} quand le candidat n'a <b>pas declare
     *         d'objectif</b> (arbitrage D-3). 🛑 Aucun cycle n'est alors cree :
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

        Optional<Journey> existant =
                journeyManager.find(userId, Module.TCF, JourneyStatus.EN_COURS);
        if (existant.isPresent()) {
            Journey courant = existant.get();
            if (courant.getTargetLevel() != cible) {
                courant.setTargetLevel(cible);
                journeyManager.save(courant);
            }
            return existant;
        }

        Journey journey = new Journey();
        journey.setUser(user);
        journey.setTargetLevel(cible);
        journey.setModule(Module.TCF);
        journey.setStatus(JourneyStatus.EN_COURS);
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
        //
        // 🛑 LA CLE D'IDEMPOTENCE PORTE LE journey_id, DONC LE CYCLE QUI LA
        // PORTE EST UN CHOIX, PAS UN DETAIL. Le garde-fou est interroge sur le
        // cycle EN COURS, et lui seul : c'est le point d'entree du traitement,
        // celui que tous les branchements atteignent. Le cycle EN ATTENTE
        // enregistre l'evaluation lui AUSSI, mais seulement quand il a
        // reellement recu des priorites — un evenement par cycle ecrit, donc,
        // et jamais de ligne « pour memoire » : sa promotion en fera un cycle
        // en cours, et son journal doit alors dire la verite sur ce qui l'a
        // construit.
        if (journeyManager.dejaTraitee(
                userId, journey.getModule(), evaluation.sourceAssessmentId())) {
            return;
        }
        enregistrer(journey, evaluation);

        List<LearningPlanObservation> tout = observationManager.findAllByUserWithSkill(userId);
        List<LearningPlanObservation> evaluations = evaluationFilter.retenir(tout);
        List<JourneyStep> etapes = stepManager.findAll(journey.getId());
        // 🛑 LU AVANT TOUTE CLOTURE : l'etape DIAGNOSTIC qu'on est sur le point
        // de fermer est precisement ce qui dit « ce cycle attend encore son
        // amorce ». La lire apres aurait envoye en attente les priorites du
        // diagnostic qui vient d'ouvrir le parcours.
        boolean amorce = attendSonAmorce(etapes);

        cloreLEtapeDiagnostic(journey, etapes, evaluation);

        boolean tropAncienne = false;
        if (evaluation.mesureUneEpreuve()) {
            tropAncienne = estTropAncienne(journey, evaluation);
            if (!tropAncienne) cloreLExamenDuBloc(journey, etapes, evaluation);
        }

        if (!tropAncienne) {
            TargetLevel cible = journey.getTargetLevel();
            Set<UUID> maitrisees = maitriseesCeJour(tout, evaluations);
            List<JourneyLotBuilder.Lot> lots = lotBuilder.depuisEvaluation(
                    evaluation.sourceAssessmentId(), evaluations, maitrisees, cible,
                    profileService.levelProfile(userId));
            if (amorce) {
                creerLots(journey, filtrerLeDiagnostic(journey, lots, evaluation));
            } else {
                mettreEnAttente(journey, etapes, lots, evaluations, evaluation);
            }
        }

        ajouterLesEpreuvesNonMesurees(journey, userId);
        journeyManager.save(journey);
    }

    /**
     * <b>R11 — un diagnostic rapide ne remplace jamais un lot ouvert</b> : il ne
     * cree un lot que pour les epreuves qui n'en ont pas.
     */
    private List<JourneyLotBuilder.Lot> filtrerLeDiagnostic(
            Journey destination, List<JourneyLotBuilder.Lot> lots, JourneyEvaluation evaluation) {
        if (evaluation.mesureUneEpreuve()) return lots;
        return lots.stream()
                .filter(lot -> lotManager.findOuvert(destination.getId(), lot.epreuve()).isEmpty())
                .toList();
    }

    /**
     * <b>Ce cycle attend-il encore son amorce ?</b> — la question qui decide ou
     * vont les priorites d'une evaluation (D-13).
     *
     * <p>Un cycle <b>amorce</b> est borne : il ne grossit plus, et ce qu'une
     * evaluation detecte pendant qu'il tourne part dans le cycle EN ATTENTE. Un
     * cycle qui <b>attend son amorce</b> ne porte <b>ni lot ni examen</b> : au
     * mieux une etape {@code DIAGNOSTIC} (amorce C de la spec §2, « aucune
     * evaluation, le Plan demande le diagnostic »), au pire rien du tout. La
     * premiere evaluation qui arrive <b>est</b> son amorce, qu'elle soit le
     * diagnostic attendu (amorce A) ou un examen passe a la place (amorce B).
     *
     * <p>🛑 <b>Pourquoi « aucun examen » et pas seulement « aucun lot »</b> : un
     * <b>cycle de mesure</b> (spec §6) n'a ni lot ni etape d'entrainement, et
     * c'est sa nature meme. Sans cette condition, le premier examen d'un cycle
     * de mesure y aurait cree un lot d'entrainement — donc detruit, a la lecture
     * suivante, le fait que c'etait un cycle de mesure, et prive le candidat de
     * la mesure qu'il etait venu chercher.
     *
     * <p>⚠️ <b>Un cycle VIDE attend son amorce</b>, et c'est ce qui evite une
     * boucle : apres une actualisation sans rien en attente, le cycle promu est
     * vide. Si la premiere evaluation suivante partait encore « en attente », le
     * candidat lirait un plan vide juste apres avoir passe un examen, et devrait
     * actualiser une seconde fois pour voir son travail.
     */
    private static boolean attendSonAmorce(List<JourneyStep> etapes) {
        for (JourneyStep step : etapes) {
            if (step.getLot() != null) return false;
            if (step.getType() == JourneyStepType.SECTION_EXAM) return false;
        }
        return true;
    }

    // =====================================================================
    // §5 / D-13 — le cycle EN ATTENTE
    // =====================================================================

    /**
     * <b>Les priorites detectees pendant le cycle en cours vont dans le cycle
     * EN ATTENTE</b> (D-13, spec §5).
     *
     * <p>🛑 <b>Ceci revoque R2</b> — « les priorites au-dela ne sont ni stockees
     * ni mises en attente ». Ce qui change est la <b>destination</b> de ce qui
     * deborde, pas le plafond : {@code maxPrioritiesPerLot} reste a 3 (D-20).
     *
     * <h3>Ce qui n'est PAS recree, et pourquoi</h3>
     * <ul>
     *   <li>une competence <b>encore ouverte</b> dans le cycle en cours : elle
     *       est deja due, la remettre en attente ferait travailler deux fois la
     *       meme chose ;</li>
     *   <li>une competence <b>deja cloturee</b> dans le cycle en cours — <b>sauf
     *       regression mesuree</b>. La regle appliquee est stricte : on ne la
     *       recree que si l'observation de <b>cette</b> evaluation la classe
     *       {@code PRIORITY}, le signal le plus fort. Un {@code TO_REINFORCE}
     *       sur une competence deja travaillee ne rouvre <b>rien</b> : sinon
     *       chaque examen rendrait tout le cycle precedent a refaire, et le
     *       candidat ne finirait jamais un cycle.</li>
     * </ul>
     * ⚠️ Une etape {@code SUPERSEDED} ne compte pas comme cloturee : elle n'a
     * jamais ete travaillee, la file l'avait seulement rendue caduque.
     *
     * <p><b>Creation paresseuse</b> : le cycle en attente n'est cree que s'il
     * reste vraiment quelque chose a y mettre. Aucune ligne vide d'avance.
     */
    private void mettreEnAttente(
            Journey enCours,
            List<JourneyStep> etapesDuCycleEnCours,
            List<JourneyLotBuilder.Lot> lots,
            List<LearningPlanObservation> evaluations,
            JourneyEvaluation evaluation) {
        List<JourneyLotBuilder.Lot> nouveautes = nouveautes(
                lots, etapesDuCycleEnCours,
                prioritairesDe(evaluations, evaluation.sourceAssessmentId()));
        if (nouveautes.isEmpty()) return;

        Journey attente = cycleEnAttente(enCours);
        nouveautes = filtrerLeDiagnostic(attente, nouveautes, evaluation);
        if (nouveautes.isEmpty()) return;

        remplacerLesLotsEnAttente(attente, nouveautes, evaluation);
        creerLots(attente, nouveautes);
        enregistrer(attente, evaluation);
        journeyManager.save(attente);
    }

    /**
     * Le cycle <b>EN ATTENTE</b> du candidat, cree <b>paresseusement</b> (D-13).
     *
     * <p>🛑 <b>Invisible du candidat</b> : {@code getOrCreate} ne le rend
     * jamais, et {@code GET /api/me/plan/journey} ne lit que le cycle en cours.
     * Il n'a pas de niveau d'entree : celui-la s'ecrit a sa <b>promotion</b>,
     * depuis le niveau de sortie du cycle qu'il remplace.
     */
    private Journey cycleEnAttente(Journey enCours) {
        UUID userId = enCours.getUser().getId();
        Optional<Journey> existant =
                journeyManager.find(userId, enCours.getModule(), JourneyStatus.EN_ATTENTE);
        if (existant.isPresent()) return existant.get();
        Journey attente = new Journey();
        attente.setUser(enCours.getUser());
        attente.setModule(enCours.getModule());
        attente.setStatus(JourneyStatus.EN_ATTENTE);
        attente.setTargetLevel(enCours.getTargetLevel());
        return journeyManager.save(attente);
    }

    /**
     * Les competences que <b>cette</b> evaluation classe {@code PRIORITY} — le
     * signal le plus fort, et le seul qui rouvre une competence deja cloturee
     * dans le cycle en cours (D-13, « sauf regression mesuree »).
     */
    private static Set<UUID> prioritairesDe(
            List<LearningPlanObservation> evaluations, UUID sourceAssessmentId) {
        Set<UUID> prioritaires = new LinkedHashSet<>();
        for (LearningPlanObservation observation : evaluations) {
            if (!sourceAssessmentId.equals(observation.getSourceId())) continue;
            if (observation.getStatus() != LearningPlanSkillStatus.PRIORITY) continue;
            if (observation.getSkill() != null) prioritaires.add(observation.getSkill().getId());
        }
        return prioritaires;
    }

    /**
     * Les lots ramenes a ce qui est reellement <b>nouveau</b> pour le candidat,
     * rangs recalcules.
     *
     * <p>Un lot qui se vide entierement disparait : un lot sans priorite serait
     * un examen de plus, sur une epreuve que ce cycle-la ne travaille pas.
     */
    private static List<JourneyLotBuilder.Lot> nouveautes(
            List<JourneyLotBuilder.Lot> lots,
            List<JourneyStep> etapesDuCycleEnCours,
            Set<UUID> prioritaires) {
        Map<UUID, JourneyStep> dejaDansLeCycle = new LinkedHashMap<>();
        for (JourneyStep step : etapesDuCycleEnCours) {
            if (step.getType() != JourneyStepType.TRAIN_SKILL || step.getSkill() == null) continue;
            dejaDansLeCycle.putIfAbsent(step.getSkill().getId(), step);
        }
        List<JourneyLotBuilder.Lot> retenus = new ArrayList<>();
        for (JourneyLotBuilder.Lot lot : lots) {
            List<JourneyLotBuilder.Priorite> priorites = new ArrayList<>();
            for (JourneyLotBuilder.Priorite priorite : lot.priorites()) {
                if (aRefaire(dejaDansLeCycle.get(priorite.skill().getId()),
                        prioritaires.contains(priorite.skill().getId()))) {
                    priorites.add(new JourneyLotBuilder.Priorite(
                            priorite.skill(), priorites.size()));
                }
            }
            if (!priorites.isEmpty()) {
                retenus.add(new JourneyLotBuilder.Lot(
                        lot.epreuve(), lot.sourceAssessmentId(), List.copyOf(priorites)));
            }
        }
        return List.copyOf(retenus);
    }

    private static boolean aRefaire(JourneyStep dansLeCycle, boolean regressionMesuree) {
        if (dansLeCycle == null) return true;
        // Encore due dans le cycle en cours : rien a remettre en attente.
        if (dansLeCycle.estOuverte()) return false;
        // Rendue caduque par la file, jamais travaillee : elle peut revenir.
        if (dansLeCycle.getResolution() == JourneyStepResolution.SUPERSEDED) return true;
        return regressionMesuree;
    }

    /**
     * <b>Le seul emploi qui reste a {@code SUPERSEDED}</b> (portee exacte de la
     * revocation D-15) : une evaluation plus recente <b>remplace</b> le lot
     * qu'une plus ancienne avait mis en attente sur la meme epreuve.
     *
     * <p>Pourquoi c'est legitime ici, et nulle part ailleurs : un lot du cycle
     * <b>EN ATTENTE</b> n'a jamais ete montre au candidat, donc jamais
     * travaille. Le garder en plus du nouveau violerait R5 (« au plus un lot
     * ouvert par epreuve »), et le garder <b>a la place</b> du nouveau ferait
     * travailler le candidat sur une mesure perimee — « un examen fait toujours
     * autorite ».
     *
     * <p>🛑 <b>Ce n'est pas le cas revoque</b> : D-15 a supprime le
     * {@code SUPERSEDED} d'un lot du cycle <b>en cours</b> qu'un examen
     * traversait alors que son travail restait du. Ce travail-la reste du.
     */
    private void remplacerLesLotsEnAttente(
            Journey attente, List<JourneyLotBuilder.Lot> lots, JourneyEvaluation evaluation) {
        for (JourneyLotBuilder.Lot nouveau : lots) {
            JourneyLot perime =
                    lotManager.findOuvert(attente.getId(), nouveau.epreuve()).orElse(null);
            if (perime == null) continue;
            for (JourneyStep step : stepManager.findOuvertesDuLot(perime.getId())) {
                if (step.clore(JourneyStepResolution.SUPERSEDED,
                        evaluation.sourceAssessmentId(), evaluation.completedAt())) {
                    stepManager.save(step);
                }
            }
            perime.clore(JourneyLotStatus.SUPERSEDED,
                    evaluation.sourceAssessmentId(), evaluation.completedAt());
            lotManager.save(perime);
        }
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
        Optional<Instant> derniere = journeyManager.derniereMesure(
                journey.getUser().getId(), journey.getModule(), evaluation.examType());
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
    private void cloreLEtapeDiagnostic(
            Journey journey, List<JourneyStep> etapes, JourneyEvaluation evaluation) {
        for (JourneyStep step : etapes) {
            if (step.getType() != JourneyStepType.DIAGNOSTIC || !step.estOuverte()) continue;
            if (step.clore(JourneyStepResolution.SATISFIED_BY_ASSESSMENT,
                    evaluation.sourceAssessmentId(), evaluation.completedAt())) {
                stepManager.save(step);
            }
        }
    }

    /**
     * <b>R1 — un examen passe hors du plan clot l'examen de son bloc SI ET
     * SEULEMENT SI ce bloc etait pret</b> (arbitrage <b>D-15</b>, 2026-09-18).
     *
     * <p>« Pret » veut dire : <b>aucune competence du meme bloc ne reste
     * ouverte</b>. C'est exactement le verrou que la lecture applique a l'etape
     * {@code SECTION_EXAM} — l'ecriture et la lecture posent donc la <b>meme</b>
     * question, et un candidat ne peut pas valider par un examen une etape que
     * son ecran lui montrait cadenassee.
     *
     * <table>
     *   <tr><th>Bloc</th><th>Examen passe ailleurs</th><th>Effet</th></tr>
     *   <tr><td>son examen seul</td><td>via Reviser</td>
     *       <td>✅ l'etape est cloturee</td></tr>
     *   <tr><td>3 competences dues + son examen</td><td>via Reviser</td>
     *       <td>❌ <b>rien n'est valide</b> — l'examen compte comme
     *           entrainement</td></tr>
     *   <tr><td>3 competences faites + son examen</td><td>examen complet</td>
     *       <td>✅ l'etape est cloturee</td></tr>
     * </table>
     *
     * <h3>🛑 CE QUE D-15 A REVOQUE</h3>
     * <p>La regle de la spec v2 §7.2 (2026-09-17) disait : « des etapes
     * {@code TRAIN_SKILL} du lot sont encore en attente → les etapes non
     * cloturees du lot <b>et son checkpoint</b> sont cloturees avec
     * {@code resolution = SUPERSEDED}, lot → {@code SUPERSEDED} ». Elle est
     * <b>supprimee pour ce cas precis</b> : passer un examen ne « saute » plus
     * le travail restant, qui <b>reste du</b>. L'examen reste evidemment jouable
     * — il ne fait simplement plus avancer le cycle, et ses priorites partent
     * dans le cycle en attente (D-13).
     *
     * <p>{@link JourneyStepResolution#SUPERSEDED} reste dans l'enum et garde son
     * autre emploi : le remplacement d'un lot <b>en attente</b> par une
     * evaluation plus recente ({@link #remplacerLesLotsEnAttente}).
     */
    private void cloreLExamenDuBloc(
            Journey journey, List<JourneyStep> etapes, JourneyEvaluation evaluation) {
        EpreuveType epreuve = evaluation.examType();
        boolean competencesDues = etapes.stream()
                .filter(JourneyStep::estOuverte)
                .anyMatch(step -> step.getType() == JourneyStepType.TRAIN_SKILL
                        && step.getExamType() == epreuve);
        if (competencesDues) {
            log.info("Parcours {} : examen {} passe hors du plan, mais le bloc {} a encore des "
                            + "competences dues — rien n'est valide (R1, D-15)",
                    journey.getId(), evaluation.sourceAssessmentId(), epreuve);
            return;
        }
        for (JourneyStep step : etapes) {
            if (step.getType() != JourneyStepType.SECTION_EXAM || !step.estOuverte()) continue;
            if (step.getExamType() != epreuve) continue;
            if (step.clore(JourneyStepResolution.SATISFIED_BY_ASSESSMENT,
                    evaluation.sourceAssessmentId(), evaluation.completedAt())) {
                stepManager.save(step);
            }
        }
        // Le lot a rempli son office : ses entrainements etaient faits, et son
        // point d'etape vient d'etre satisfait par une mesure. Il se ferme
        // CLOSED — jamais SUPERSEDED : rien n'a ete saute.
        JourneyLot lot = lotManager.findOuvert(journey.getId(), epreuve).orElse(null);
        if (lot == null) return;
        lot.clore(JourneyLotStatus.CLOSED,
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
        // 🛑 LE QUOTA EST LU CHEZ SON AUTORITE UNIQUE, jamais recompte ici
        // (D-16). {@code JourneyReadService.etapesAuQuota} est la MEME fonction
        // que celle qui alimente l'ecran — c'est ce qui garantit qu'une etape ne
        // se clot pas sur une regle differente de celle qui l'a calculee.
        //
        // ⚠️ Depuis D-16, cette regle ne se lit plus dans le `progress` servi :
        // une etape de comprehension a DEUX chemins de cloture (2 series
        // reussies OU 4 terminees) et l'echappatoire ne s'affiche pas. Les deux
        // lecteurs partagent donc la fonction, faute de pouvoir partager le
        // nombre.
        Set<UUID> auQuota = readService.etapesAuQuota(
                userId, stepManager.findAll(journey.getId()));

        Map<UUID, SkillMasteryEngine.SkillMastery> maitrise = masteryResolver.bySkillIds(
                userId, concernees.stream().map(step -> step.getSkill().getId()).toList());

        for (JourneyStep step : concernees) {
            UUID skillId = step.getSkill().getId();
            SkillMasteryEngine.SkillMastery etat = maitrise.get(skillId);
            JourneyStepResolution motif = null;
            if (etat != null && etat.transferProven()) {
                motif = JourneyStepResolution.MASTERED;
            } else if (auQuota.contains(step.getId())) {
                motif = JourneyStepResolution.QUOTA_REACHED;
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
    void ajouterLesEpreuvesNonMesurees(Journey journey, UUID userId) {
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
    void ajouter(Journey journey, JourneyStep step) {
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

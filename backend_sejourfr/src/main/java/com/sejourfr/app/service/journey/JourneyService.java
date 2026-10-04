package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.dto.CivicPlanDto;
import com.sejourfr.app.entity.CivicOfficialUnit;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyAssessmentEvent;
import com.sejourfr.app.entity.JourneyLot;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyAssessmentKind;
import com.sejourfr.app.enums.JourneyFinDeCycle;
import com.sejourfr.app.enums.JourneyLotStatus;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.JourneyStepPurpose;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.LearningPlanSourceType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.JourneyLotManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.util.ApresCommit;
import com.sejourfr.app.manager.JourneyManager;
import com.sejourfr.app.manager.JourneyStepManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.NiveauActuelEpreuveResolver;
import com.sejourfr.app.service.SkillMasteryEngine;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.service.SkillMasteryResolver;
import com.sejourfr.app.service.TcfProfileService;
import com.sejourfr.app.service.plancivique.CivicPlanService;
import com.sejourfr.app.util.TcfDomaine;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
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
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

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
    // 🛑 L'AUTORITE UNIQUE de « quelles observations cette evaluation a-t-elle
    // produites ? ». Comparer `evaluation.sourceAssessmentId()` au
    // `source_id` d'une observation de production ne matche JAMAIS : le premier
    // est un attempt (ou une session), le second une soumission.
    private final JourneyObservationSources observationSources;
    private final JourneyLotBuilder lotBuilder;
    private final JourneyReadService readService;
    private final JourneyCycleAffinage cycleAffinage;
    private final AttemptManager attemptManager;
    private final ProductionSubmissionManager submissionManager;
    // 🛑 Le rejeu part APRES le commit de la lecture : il doit passer par le
    // PROXY, sinon son `REQUIRES_NEW` (et le verrou pessimiste de R14) sauterait.
    private final ObjectProvider<JourneyService> self;
    private final LearningPlanObservationManager observationManager;
    private final SkillMasteryResolver masteryResolver;
    private final TcfProfileService profileService;
    private final NiveauActuelEpreuveResolver mesureResolver;
    private final SkillManager skillManager;
    private final UserManager userManager;
    // ⚠️ Cote civique : l'ordre des priorites est LU chez le plan derive (D-36),
    // les unites chez le referentiel (D-48), les thematiques chez `themes`.
    private final CivicPlanService civicPlanService;
    private final ThemeManager themeManager;
    // 🛑 LA COMPOSITION DU CYCLE CIVIQUE A UNE AUTORITE (D-67) : la meme que
    // celle qui annonce le nombre de priorites du cycle suivant.
    private final JourneyCycleSuivant cycleSuivant;
    // 🛑 L'unique facon d'historiser un cycle (actualisation, jalon, lancement).
    private final JourneyHistorisation historisation;

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
    public JourneyDto lire(UUID userId, Module module) {
        Optional<Journey> journey = getOrCreate(userId, module);
        if (journey.isEmpty()) return readService.sansObjectif();
        Journey courant = journey.get();
        List<JourneyStep> etapes = stepManager.findAll(courant.getId());
        // 🛑 EN PREMIER : une etape rouverte redevient une competence DUE, et
        // les deux filets suivants lisent ce fait (garde D-15).
        boolean relire = rouvrirLesEtapesCloseesSansSeries(courant, etapes);
        relire |= cloreLesEtapesDExpressionAuQuota(courant, etapes);
        relire |= rattraperLesEvaluationsInitiales(courant, etapes);
        relire |= rattraperLesExamensNonSignales(courant, etapes);
        // 🛑 EN DERNIER : un bloc vide se juge sur la file deja reparee.
        relire |= completerLesBlocsVides(courant, etapes);
        if (relire) {
            etapes = stepManager.findAll(courant.getId());
        }
        return readService.lire(courant, etapes);
    }

    /**
     * <b>Le filet des examens NON SIGNALES</b> (bug du 2026-09-27, mesure en
     * base) : un examen blanc d'epreuve termine <b>pendant</b> ce cycle, que le
     * parcours n'a jamais recu.
     *
     * <p>Constat : l'examen blanc EE d'un compte gratuit, en cycle d'affinage,
     * etait passe et corrige — aucune ligne au journal, l'etape « Examen
     * blanc » EE restait ouverte et s'affichait verrouillee (gratuite desormais
     * consommee). La voie de l'analyse ({@code porterAuParcours}) levait hors
     * session et le signal etait perdu ; rien ne le rejouait jamais.
     *
     * <p>🛑 <b>Ce filet ne decide rien de nouveau</b> : il <b>rejoue</b> le
     * signal manque. L'etape d'examen du bloc se clot ici (memes gardes que
     * {@link #cloreLExamenDuBloc}, donc D-15 hors affinage), pour que l'ecran lu
     * maintenant soit juste ; le traitement complet ({@link #onAssessmentCompleted}
     * : journal, priorites en attente) part <b>apres le commit</b> de cette
     * lecture. Le journal le rend idempotent.
     *
     * <p>Gardes : l'examen doit etre <b>posterieur a la creation du cycle</b>
     * (R19 ne fabrique aucune etape « deja faite »), <b>non journalise</b>, et —
     * en production — <b>sans correction en cours</b> : le signaler avant la 3e
     * analyse perdrait ses priorites (B-13).
     *
     * @return {@code true} si une etape a ete close
     */
    private boolean rattraperLesExamensNonSignales(Journey journey, List<JourneyStep> etapes) {
        if (journey.getModule() != Module.TCF || journey.getCreatedAt() == null) return false;
        UUID userId = journey.getUser().getId();
        Boolean affinage = null;
        boolean cloture = false;
        for (EpreuveType epreuve : TcfDomainProfileDto.ORDRE) {
            NiveauActuelEpreuveResolver.Mesure mesure = mesureResolver.mesure(userId, epreuve);
            if (!mesure.mesuree()) continue;
            if (journeyManager.dejaTraitee(userId, Module.TCF, mesure.attemptId())) continue;
            Attempt examen = attemptManager.findById(mesure.attemptId()).orElse(null);
            if (examen == null || examen.getFinishedAt() == null
                    || examen.getFinishedAt().isBefore(journey.getCreatedAt())) continue;
            if ((epreuve == EpreuveType.TCF_EE || epreuve == EpreuveType.TCF_EO)
                    && JourneyProductionBridge.enAttenteDeCorrection(
                            submissionManager.findByAttemptId(examen.getId()))) continue;

            JourneyEvaluation evaluation = new JourneyEvaluation(examen.getId(),
                    JourneyProductionBridge.natureDeLEvaluation(examen), epreuve,
                    examen.getFinishedAt());
            if (affinage == null) affinage = cycleAffinage.pour(journey);
            cloture |= cloreLesEtapesDExamen(etapes, evaluation, affinage);
            log.info("Parcours {} : examen {} ({}) jamais signale — rejoue a la lecture",
                    journey.getId(), examen.getId(), epreuve);
            ApresCommit.executer("Parcours TCF, rattrapage de l'examen " + examen.getId(),
                    () -> self.getObject().onAssessmentCompleted(userId, evaluation));
        }
        return cloture;
    }

    /**
     * <b>Un examen blanc de production vient d'etre SOUMIS en entier, ses
     * corrections tournent encore</b> (2026-09-27).
     *
     * <p>« Il suffit de l'avoir passe » (R1, commit {@code 002447a0}) : l'etape
     * d'examen du bloc se clot <b>des la fin de l'examen</b>, sans attendre
     * l'analyse. Sinon, pendant les secondes ou les minutes de correction, un
     * compte gratuit voyait l'examen qu'il venait de passer « Réservé à l'offre
     * complète » — sa gratuite etait deja consommee par la premiere analyse.
     *
     * <p>🛑 <b>Rien n'est journalise ici</b> : le journal appartient a
     * l'evaluation complete (voie de l'analyse), qui porte les priorites. La
     * journaliser maintenant ferait taire cette voie-la par idempotence, et les
     * priorites de l'examen seraient perdues (B-13). Seule la <b>cloture</b>
     * est avancee, par la meme fonction et sous les memes gardes.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void onProductionExamSubmitted(UUID userId, JourneyEvaluation evaluation) {
        if (!evaluation.mesureUneEpreuve()) return;
        Optional<Journey> trouve = getOrCreate(userId, Module.TCF);
        if (trouve.isEmpty()) return;
        Journey journey = journeyManager.findForUpdate(trouve.get().getId()).orElse(null);
        if (journey == null) return;
        if (journeyManager.dejaTraitee(userId, Module.TCF, evaluation.sourceAssessmentId())) return;
        cloreLesEtapesDExamen(stepManager.findAll(journey.getId()), evaluation,
                cycleAffinage.pour(journey));
    }

    /**
     * <b>Le filet de lecture de R12</b> : une etape « Évaluer mon niveau »
     * ({@code INITIAL_ASSESSMENT}) encore ouverte sur une epreuve <b>desormais
     * mesuree</b> est satisfaite par cette mesure.
     *
     * <p>🛑 <b>Sa premisse est fausse, donc elle n'a plus d'objet</b> : R12 ne
     * la pose que parce que l'epreuve « n'a jamais ete mesuree », et « mesuree »
     * a une seule autorite ({@code NiveauActuelEpreuveResolver.mesure}). Le
     * chemin normal la ferme deja a la fin de l'examen (R1,
     * {@link #cloreLExamenDuBloc}) ; ce filet rattrape ce que ce chemin a rate —
     * un signal best-effort perdu, ou l'etape recreee a tort avant le correctif
     * {@code ApresCommit} du 2026-09-26 (l'examen CO etait passe, le Plan
     * affichait encore « Examen a passer »). « La lecture suivante rattrape » :
     * c'est la promesse de ce service, elle est tenue ici.
     *
     * <p>Les memes gardes que l'ecriture, et aucune autre : pas d'etape d'un
     * bloc qui a encore des competences dues (D-15), pas d'examen de reevaluation
     * ({@code REASSESS}) — celui-la mesure un progres <b>posterieur</b> au
     * travail du bloc, et une mesure plus ancienne ne peut pas le satisfaire.
     *
     * @return {@code true} si une etape a ete close
     */
    private boolean rattraperLesEvaluationsInitiales(Journey journey, List<JourneyStep> etapes) {
        if (journey.getModule() != Module.TCF) return false;
        // Paresseux : la question ne coute une requete que si un bloc a encore
        // des competences dues, et la lecture ordinaire n'en paie aucune.
        Boolean affinage = null;
        boolean cloture = false;
        Instant maintenant = Instant.now();
        for (JourneyStep step : etapes) {
            if (step.getType() != JourneyStepType.SECTION_EXAM || !step.estOuverte()) continue;
            if (step.getPurpose() != JourneyStepPurpose.INITIAL_ASSESSMENT) continue;
            EpreuveType epreuve = step.getExamType();
            if (epreuve == null) continue;
            // 🛑 D-15 ne vaut pas en cycle d'affinage (D-64) : meme garde que
            // l'ecriture, `cloreLExamenDuBloc`.
            if (competencesDues(etapes, epreuve)) {
                if (affinage == null) affinage = cycleAffinage.pour(journey);
                if (!affinage) continue;
            }
            NiveauActuelEpreuveResolver.Mesure mesure =
                    mesureResolver.mesure(journey.getUser().getId(), epreuve);
            if (!mesure.mesuree()) continue;
            // 🛑 D-69 ter (2026-09-28) : un examen passe AVANT la creation du
            // cycle ne ferme JAMAIS son etape — il ne fermait que parce que
            // l'epreuve etait « mesuree », ce qui a coche CO et CE dans un
            // cycle d'examens tout neuf (constat de prod).
            if (!passePendantLeCycle(journey, mesure.attemptId())) continue;
            if (step.clore(JourneyStepResolution.SATISFIED_BY_ASSESSMENT,
                    mesure.attemptId(), maintenant)) {
                stepManager.save(step);
                cloture = true;
            }
        }
        return cloture;
    }

    /** L'examen {@code attemptId} s'est-il termine APRES la creation de ce cycle ? */
    private boolean passePendantLeCycle(Journey journey, UUID attemptId) {
        if (journey.getCreatedAt() == null || attemptId == null) return false;
        return attemptManager.findById(attemptId)
                .map(Attempt::getFinishedAt)
                .map(fin -> !fin.isBefore(journey.getCreatedAt()))
                .orElse(false);
    }

    /**
     * « Ce bloc a-t-il encore des competences dues ? » — le verrou D-15, pose
     * une fois pour l'ecriture (R1) et pour le filet de lecture.
     */
    private static boolean competencesDues(List<JourneyStep> etapes, EpreuveType epreuve) {
        return etapes.stream()
                .filter(JourneyStep::estOuverte)
                .anyMatch(step -> step.getType() == JourneyStepType.TRAIN_SKILL
                        && step.getExamType() == epreuve);
    }

    // =====================================================================
    // R18 / R19 — creation et bootstrap
    // =====================================================================

    /**
     * Le <b>cycle en cours</b> du candidat <b>sur ce module</b>, cree si besoin.
     *
     * <p>🛑 <b>Le module est un PARAMETRE, il ne se devine pas.</b> Il etait en
     * dur (D-50) : {@code find(userId, Module.TCF, ...)} et
     * {@code setModule(Module.TCF)}. Un candidat civique obtenait donc un cycle
     * TCF et jamais le sien. Chaque module a son objectif, sa creation et son
     * amorce — d'ou deux chemins, et non un {@code if} au milieu d'un seul.
     *
     * <p>D-13 tient pour les deux : <b>un seul cycle EN_COURS par (candidat,
     * module)</b>, garanti par un index partiel depuis V067.
     *
     * <p>🛑 <b>Un changement d'objectif ne cree pas un second cycle</b> (D-13) :
     * le cycle en cours survit et son niveau cible est mis a jour. L'historiser
     * jetterait le plan que le candidat a sous les yeux, et un ping-pong
     * d'objectif polluerait son historique de cycles ; les priorites deja
     * designees ne deviennent pas fausses parce que la cible a bouge — seul
     * l'<b>ordre</b> des lots s'en trouve recalcule, et il est derive a la
     * lecture.
     *
     * @param module le module dont on veut le cycle. 🛑 Jamais deduit d'un
     *               etat du candidat : un abonne peut preparer les deux.
     * @return {@link Optional#empty()} quand le candidat n'a <b>pas declare
     *         l'objectif de CE module</b> (arbitrage D-3, transpose) — un
     *         palier cote TCF, une mention cote civique. 🛑 Aucun cycle n'est
     *         alors cree :
     *         en fabriquer un « par defaut » reviendrait a choisir un objectif a
     *         sa place, puis a batir une file entiere sur cette supposition.
     */
    @Transactional
    public Optional<Journey> getOrCreate(UUID userId, Module module) {
        User user = userManager.findById(userId).orElse(null);
        if (user == null) return Optional.empty();
        return switch (module) {
            case TCF -> cycleTcf(user);
            case CIVIQUE -> cycleCivique(user);
        };
    }

    /**
     * <b>Aligne l'objectif des cycles EN COURS deja crees</b> sur le profil, au
     * moment meme ou le candidat change de demarche.
     *
     * <p>🛑 <b>{@code users.target_procedure} est l'autorite</b>, le cycle n'en
     * porte qu'une copie. Elle ne se realignait qu'a la lecture du parcours
     * ({@link #getOrCreate}) : entre le changement et cette lecture, tout ce qui
     * lit le cycle directement (le detail d'une etape, l'historique) montrait
     * encore l'ancien objectif. Appele par {@code MeService.updateTargetProcedure},
     * le seul point d'ecriture de la demarche.
     *
     * <p>D-34 / A27 : le cycle <b>survit avec le meme id</b>, seul son objectif
     * change. 🛑 <b>Aucun cycle n'est cree ici</b> : un candidat qui n'a jamais
     * ouvert son Plan n'a pas de parcours, et ce n'est pas un changement de
     * demarche qui doit lui en fabriquer un (R19).
     */
    @Transactional
    public void alignerObjectif(UUID userId) {
        User user = userManager.findById(userId).orElse(null);
        if (user == null) return;
        TargetLevel cible = TargetProcedure.niveauVise(
                user.getTargetProcedure(), user.getTargetLevel());
        if (cible != null) {
            journeyManager.find(userId, Module.TCF, JourneyStatus.EN_COURS)
                    .ifPresent(courant -> alignerTcf(courant, cible));
        }
        TargetProcedure mention = user.getTargetProcedure();
        if (mention != null) {
            journeyManager.find(userId, Module.CIVIQUE, JourneyStatus.EN_COURS)
                    .ifPresent(courant -> alignerCivique(courant, mention));
        }
    }

    /** A27 : le cycle TCF survit, son palier cible est mis a jour. */
    private void alignerTcf(Journey courant, TargetLevel cible) {
        if (courant.getTargetLevel() == cible) return;
        courant.poserObjectif(cible);
        journeyManager.save(courant);
    }

    /**
     * D-34 : changer de mention ne detruit pas le cycle — A27 s'applique telle
     * quelle, le cycle survit avec le MEME id et son objectif est mis a jour.
     * Historiser jetterait le plan que le candidat a sous les yeux.
     */
    private void alignerCivique(Journey courant, TargetProcedure mention) {
        if (courant.getTargetProcedure() == mention) return;
        courant.poserObjectif(mention);
        journeyManager.save(courant);
    }

    /**
     * Le cycle EN COURS du module, ou — s'il n'existe pas — le <b>verrou de
     * creation</b> pris, puis une seconde lecture (D-69, 2026-09-28).
     *
     * <p>🛑 <b>Une seule creation, meme sous lectures concurrentes.</b> Le Plan
     * par defaut naît a la premiere lecture du parcours, et l'Accueil, le Plan
     * et Reviser le lisent en meme temps a la premiere connexion. Le chemin
     * ordinaire (le cycle existe) ne paie aucun verrou ; seul un compte sans
     * cycle le prend, et le second appelant retrouve, apres l'attente, le cycle
     * que le premier a cree.
     */
    private Optional<Journey> cycleEnCoursOuVerrou(UUID userId, Module module) {
        Optional<Journey> existant = journeyManager.find(userId, module, JourneyStatus.EN_COURS);
        if (existant.isPresent() && !existant.get().isReinitialiserAuLancement()) return existant;
        journeyManager.verrouillerLaCreation(userId, module);
        Optional<Journey> relu = journeyManager.find(userId, module, JourneyStatus.EN_COURS);
        if (relu.isPresent() && relu.get().isReinitialiserAuLancement()) {
            return Optional.of(reinitialiserAuLancement(relu.get()));
        }
        return relu;
    }

    /**
     * <b>Le lancement du cycle d'examens pour TOUS</b> (D-69 ter, 2026-09-28,
     * decision du proprietaire : « mettre a TOUT LE MONDE un plan NON FAIT avec
     * uniquement des examens blancs »).
     *
     * <p>Un cycle marque par V082 (vivant au deploiement) est remplace a sa
     * premiere lecture, <b>une seule fois</b>, sous le verrou de creation :
     * <ol>
     *   <li>le cycle en cours est historise {@code INTERROMPU} (le geste du
     *       jalon D-68 : « mis de cote »), sa sortie lue chez son autorite ;</li>
     *   <li>le cycle EN ATTENTE (TCF) est <b>vide</b> de ses lots : ses
     *       priorites datent d'avant le lancement, les examens du nouveau cycle
     *       les recalculent (D-67). Il n'est jamais montre, rien ne se perd a
     *       l'ecran ; ses lignes restent en base ({@code SUPERSEDED}) ;</li>
     *   <li>un <b>cycle d'examens</b> neuf devient courant — il naît non
     *       marque, donc n'est jamais reinitialise a son tour.</li>
     * </ol>
     * Les cycles deja historises ne bougent pas ; aucun resultat d'examen ni de
     * serie n'est touche.
     */
    private Journey reinitialiserAuLancement(Journey ancien) {
        Journey enCours = journeyManager.findForUpdate(ancien.getId()).orElse(ancien);
        UUID userId = enCours.getUser().getId();
        Module module = enCours.getModule();
        Instant maintenant = Instant.now();

        Journey neuf = new Journey();
        neuf.setUser(enCours.getUser());
        neuf.setModule(module);
        if (module == Module.CIVIQUE) {
            neuf.poserObjectif(enCours.getTargetProcedure());
            neuf.setEntryScore(historisation.historiserCivique(enCours, JourneyFinDeCycle.INTERROMPU));
        } else {
            neuf.poserObjectif(enCours.getTargetLevel());
            neuf.setEntryLevel(historisation.historiserTcf(enCours, JourneyFinDeCycle.INTERROMPU));
        }

        journeyManager.find(userId, module, JourneyStatus.EN_ATTENTE).ifPresent(attente -> {
            for (JourneyStep step : stepManager.findAll(attente.getId())) {
                if (step.clore(JourneyStepResolution.SUPERSEDED, null, maintenant)) {
                    stepManager.save(step);
                }
            }
            for (JourneyLot lot : lotManager.findOuverts(attente.getId())) {
                lot.clore(JourneyLotStatus.SUPERSEDED, null, maintenant);
                lotManager.save(lot);
            }
            attente.setReinitialiserAuLancement(false);
            journeyManager.save(attente);
        });

        neuf.setStatus(JourneyStatus.EN_COURS);
        neuf = journeyManager.saveEtFlush(neuf);
        if (module == Module.CIVIQUE) {
            poserLeCycleDExamensCivique(neuf);
        } else {
            poserLeCycleDExamens(neuf, userId);
        }
        log.info("Lancement D-69 ter : cycle {} ({}) historise INTERROMPU, cycle d'examens {} ouvert",
                enCours.getId(), module, neuf.getId());
        return neuf;
    }

    /**
     * Le cycle <b>TCF</b> : son objectif est un palier CECRL, lu chez
     * {@code TargetProcedure.niveauVise()} et jamais recalcule ici.
     */
    private Optional<Journey> cycleTcf(User user) {
        TargetLevel cible = TargetProcedure.niveauVise(
                user.getTargetProcedure(), user.getTargetLevel());
        if (cible == null) return Optional.empty();

        Optional<Journey> existant = cycleEnCoursOuVerrou(user.getId(), Module.TCF);
        if (existant.isPresent()) {
            alignerTcf(existant.get(), cible);
            return existant;
        }

        Journey journey = new Journey();
        journey.setUser(user);
        journey.poserObjectif(cible);
        journey.setModule(Module.TCF);
        journey.setStatus(JourneyStatus.EN_COURS);
        journey = journeyManager.save(journey);
        amorcer(journey, user, cible);
        return Optional.of(journey);
    }

    /**
     * Le cycle <b>CIVIQUE</b> : son objectif est une <b>mention</b>.
     *
     * <p>🛑 <b>L'objectif civique NE SE DERIVE PAS de {@code niveauVise()}</b>,
     * et c'est le piege de ce point. {@code niveauVise(CSP, null)} rend
     * {@code A2} — le <b>plancher de francais</b> de la demarche —, jamais
     * {@code null} : un candidat purement civique ne « sort » donc pas a sec, il
     * obtenait un cycle <b>TCF</b> et <b>jamais</b> de cycle civique. Ce que dit
     * la mention, c'est la demarche visee ; ce que dit {@code niveauVise}, c'est
     * le francais qu'elle exige. Deux questions, deux reponses.
     *
     * <p>🛑 <b>{@code target_level} reste NUL</b> : {@code chk_journey_objectif}
     * (V069) exige exactement un objectif, et {@code poserObjectif} garantit
     * l'exclusivite a la source plutot qu'au flush.
     *
     * <p>⚠️ <b>Aucune amorce ici, et c'est un manque assume, pas un oubli.</b>
     * Les priorites civiques viennent du <b>diagnostic civique</b> et se posent
     * au grain de l'<b>unite officielle</b> (D-48) : c'est le point suivant de
     * P8.4, avec son ordre lu chez {@code CivicPrioriteScorer} (D-36). D'ici la
     * un cycle civique naitra <b>vide</b> — ce qu'aucun ecran ne montre encore,
     * le Plan civique lisant toujours son plan derive (D-50, P8.7).
     */
    private Optional<Journey> cycleCivique(User user) {
        TargetProcedure mention = user.getTargetProcedure();
        if (mention == null) return Optional.empty();

        Optional<Journey> existant = cycleEnCoursOuVerrou(user.getId(), Module.CIVIQUE);
        if (existant.isPresent()) {
            alignerCivique(existant.get(), mention);
            return existant;
        }

        Journey journey = new Journey();
        journey.setUser(user);
        journey.poserObjectif(mention);
        journey.setModule(Module.CIVIQUE);
        journey.setStatus(JourneyStatus.EN_COURS);
        journey = journeyManager.save(journey);
        amorcerCivique(journey, user);
        return Optional.of(journey);
    }

    /**
     * <b>L'amorce d'un cycle civique</b> (spec §2, transposee sans ecart).
     *
     * <ul>
     *   <li><b>Diagnostic fait</b> ⇒ les thematiques prioritaires sont
     *       <b>peuplees</b> de leurs unites, les autres passent en « Évaluer mon
     *       niveau » ;</li>
     *   <li><b>rien de fait</b> ⇒ <b>les cinq</b> thematiques en « Évaluer mon
     *       niveau ».</li>
     * </ul>
     *
     * <p>🛑 <b>UN CYCLE CIVIQUE N'EST DONC JAMAIS VIDE</b> — c'est ce qui ferme
     * A60. Le pire cas est cinq examens a passer, pas une ligne muette qui a
     * l'air d'un cycle sans en etre un.
     *
     * <p>🛑 <b>L'ordre des priorites est LU, jamais recalcule</b>
     * ({@code CivicPlanService.ordrePourLeCycle}, D-36). Le cycle projette cet
     * ordre sur les <b>unites officielles</b> (D-48) et s'arrete la.
     *
     * <p>⚠️ <b>Le 3e cas de la spec n'est pas servi, et c'est remonte</b> :
     * « examen de theme passe sans diagnostic ⇒ ce theme peuple ». Il est
     * <b>inatteignable</b> aujourd'hui, parce que {@code CivicPlanService} ne
     * construit aucun plan sans diagnostic termine : sans plan, il n'existe
     * aucune cible a poser, donc rien avec quoi « peupler ». Ce cas retombe
     * volontairement sur « les cinq a evaluer » — et R1 fermera l'etape du
     * theme deja passe quand son examen sera journalise.
     */
    /**
     * L'amorce civique, <b>reutilisable</b> : {@code JourneyCycleService} s'en
     * sert pour ouvrir le cycle suivant apres une historisation — il n'y a pas
     * de cycle en attente civique (les priorites sont derivees, D-36).
     */
    void amorcerCycleCivique(Journey journey, User user) {
        amorcerCivique(journey, user);
    }

    private void amorcerCivique(Journey journey, User user) {
        peuplerLeCycleCivique(journey, civicPlanService.ordrePourLeCycle(user.getId()));
    }

    /**
     * <b>Peupler un cycle civique</b> : les unites prioritaires dans leurs
     * blocs, puis « Évaluer mon niveau » sur ce que rien ne peuple.
     *
     * <p>🛑 <b>Une seule autorite, DEUX appelants</b> : l'amorce d'un cycle
     * ({@link #amorcerCivique}) et le <b>diagnostic civique</b> qui se termine
     * pendant qu'un cycle tourne ({@link #peuplerDepuisLeDiagnostic}). Les deux
     * posent exactement le meme contenu — une seconde version « pour le
     * diagnostic » aurait diverge des la premiere evolution du grain.
     */
    private void peuplerLeCycleCivique(Journey journey, CivicPlanService.OrdreDuPlan ordre) {
        creerLotsCiviques(journey, ordre);
        ajouterLesThematiquesNonPeuplees(journey);
    }

    /**
     * Les unites prioritaires, <b>groupees par thematique</b>, chacune avec son
     * lot et son examen de cloture.
     *
     * <p>🛑 <b>Le grain est l'UNITE OFFICIELLE</b> (D-48) : une cible du plan
     * derive est une <b>notion</b>, et plusieurs notions tombent dans la meme
     * unite. On garde alors le <b>meilleur rang</b> — la premiere rencontree,
     * puisque la liste arrive deja ordonnee.
     *
     * <p>⚠️ <b>Une cible au grain THEME ne devient pas une priorite</b> : elle
     * dit « on ne sait pas quelle notion », et le cycle ne peut pas nommer une
     * unite qu'il ne connait pas. Sa thematique retombe alors sur « Évaluer mon
     * niveau », ce qui est exactement la bonne reponse a une absence de mesure —
     * <b>{@code null} = inconnu, jamais mauvais</b>.
     *
     * <p>🛑 <b>R11, cote civique</b> : un bloc qui porte deja un lot
     * <b>ouvert</b> n'en recoit pas un second. C'est mot pour mot ce que
     * {@link #filtrerLeDiagnostic} fait par epreuve cote TCF — « un diagnostic
     * ne remplace jamais un lot ouvert, il ne cree un lot que pour les blocs qui
     * n'en ont pas ». A l'amorce, aucun lot n'existe et le filtre ne coute rien ;
     * quand un diagnostic se termine pendant qu'un cycle tourne, c'est lui qui
     * empeche de redemander un travail deja du.
     */
    private void creerLotsCiviques(Journey journey, CivicPlanService.OrdreDuPlan ordre) {
        // 🛑 LA SELECTION A UNE AUTORITE (D-67) : `JourneyCycleSuivant`, la
        // meme qui sert le nombre annonce sous « Actualiser mon plan ».
        List<JourneyCycleSuivant.ThematiqueRetenue> retenues = cycleSuivant.unitesRetenues(ordre);
        if (retenues.isEmpty()) return;

        // 🛑 R11 — LU AVANT LA PREMIERE ECRITURE : les examens deja ouverts du
        // cycle disent quels blocs portent deja leur point d'etape. Les relire
        // apres coup aurait vu ceux qu'on vient d'ecrire.
        Set<String> blocsAvecExamenOuvert = stepManager.findAll(journey.getId()).stream()
                .filter(step -> step.getType() == JourneyStepType.SECTION_EXAM)
                .filter(JourneyStep::estOuverte)
                .map(JourneyStep::blocCode)
                .filter(Objects::nonNull)
                .collect(Collectors.toCollection(LinkedHashSet::new));

        for (JourneyCycleSuivant.ThematiqueRetenue retenue : retenues) {
            Theme thematique = retenue.thematique();
            List<CivicOfficialUnit> unites = retenue.unites();
            // R11 : ce bloc a deja un lot ouvert ⇒ on ne le remplace pas.
            if (lotManager.findOuvertParTheme(journey.getId(), thematique.getId()).isPresent()) {
                continue;
            }
            JourneyLot lot = new JourneyLot();
            lot.setJourney(journey);
            lot.poserBloc(thematique);
            lot.setStatus(JourneyLotStatus.OPEN);
            lot.setSourceAssessmentId(ordre.sourceAssessmentId());
            JourneyLot enregistre = lotManager.save(lot);

            int rang = 1;
            for (CivicOfficialUnit unite : unites) {
                JourneyStep step = new JourneyStep();
                step.setJourney(journey);
                step.setLot(enregistre);
                step.setType(JourneyStepType.TRAIN_SKILL);
                step.poserBloc(thematique);
                step.poserUnite(unite);
                step.setSeverityRank(rang++);
                step.setSourceAssessmentId(ordre.sourceAssessmentId());
                ajouter(journey, step);
            }

            // R3 — un lot est TOUJOURS clos par l'examen de son bloc. Ici c'est
            // l'examen de la thematique (20 questions, `CivicExamFormat`).
            //
            // 🛑 SAUF SI CE BLOC EN PORTE DEJA UN OUVERT, et c'est le cas du
            // diagnostic qui peuple un cycle deja amorce : le bloc porte alors
            // son « Évaluer mon niveau » (A65), qui EST l'examen de ce bloc.
            // En ecrire un second aurait donne deux examens ouverts pour une
            // seule thematique -- deux etapes dans l'avancement du cycle, une
            // seule montree (`JourneyBlocResolver.examenDuBloc`). R3 est
            // satisfaite : le bloc a bien un examen ouvert, et
            // `cloreLExamenDuBlocCivique` clot les examens du BLOC, pas ceux du
            // lot.
            if (blocsAvecExamenOuvert.contains(thematique.getCode())) continue;
            JourneyStep checkpoint = new JourneyStep();
            checkpoint.setJourney(journey);
            checkpoint.setLot(enregistre);
            checkpoint.setType(JourneyStepType.SECTION_EXAM);
            checkpoint.setPurpose(JourneyStepPurpose.REASSESS);
            checkpoint.poserBloc(thematique);
            checkpoint.setSourceAssessmentId(ordre.sourceAssessmentId());
            ajouter(journey, checkpoint);
        }
    }

    /**
     * <b>« Évaluer mon niveau » sur les thematiques que rien ne peuple</b> —
     * pendant civique de {@code ajouterLesEpreuvesNonMesurees} (R12).
     *
     * <p>🛑 <b>Les CINQ thematiques sont couvertes</b>, toujours : le cycle
     * civique porte tout le programme de l'arrete, pas seulement ce que le
     * diagnostic a pointe.
     */
    private void ajouterLesThematiquesNonPeuplees(Journey journey) {
        Set<String> dejaPrevues = stepManager.findAll(journey.getId()).stream()
                .filter(step -> step.blocCode() != null)
                .map(JourneyStep::blocCode)
                .collect(Collectors.toCollection(LinkedHashSet::new));

        for (Theme thematique : themeManager
                .findByModuleOrderedByDisplayOrder(Module.CIVIQUE)) {
            if (dejaPrevues.contains(thematique.getCode())) continue;
            JourneyStep mesure = new JourneyStep();
            mesure.setJourney(journey);
            mesure.setType(JourneyStepType.SECTION_EXAM);
            // « Évaluer mon niveau » : cette thematique n'a jamais ete mesuree.
            mesure.setPurpose(JourneyStepPurpose.INITIAL_ASSESSMENT);
            mesure.poserBloc(thematique);
            ajouter(journey, mesure);
        }
    }

    /**
     * <b>Ce qu'un EXAMEN civique apprend au cycle</b> — le journal (D-51) et
     * <b>R1</b>.
     *
     * <h3>🛑 Un examen COMPLET ecrit SIX lignes</h3>
     * <p>Une {@code CIVIC_EXAM} <b>globale</b> — il mesure le programme entier —,
     * plus une {@code CIVIC_THEME_EXAM} par thematique dont le bloc etait
     * <b>debloque</b>. Motif (D-51) : le <b>cycle de mesure</b> est fait de cinq
     * blocs qui ne contiennent QUE leur examen, tous debloques, et c'est
     * precisement l'examen complet qui doit les cloturer. Sans ces lignes, il
     * n'aurait aucun moyen de se fermer.
     *
     * <h3>🛑 R1 — passee, pas reussie</h3>
     * <p>Une etape d'examen se clot <b>en etant passee</b>, jamais en etant
     * reussie, ni au TCF ni au civique : l'examen <b>mesure</b>, il ne
     * sanctionne pas. Et il ne clot que les blocs <b>debloques</b> — une unite
     * encore ouverte dans le bloc, et rien n'est valide (D-15).
     */
    private void traiterLEvaluationCivique(Journey journey, JourneyEvaluation evaluation) {
        enregistrer(journey, evaluation);
        if (evaluation.kind() == JourneyAssessmentKind.CIVIC_DIAGNOSTIC) {
            peuplerDepuisLeDiagnostic(journey, evaluation);
            journeyManager.save(journey);
            return;
        }

        List<JourneyStep> etapes = stepManager.findAll(journey.getId());
        List<Theme> cibles = evaluation.mesureUneThematique()
                ? themeManager.findById(evaluation.themeId()).map(List::of).orElse(List.of())
                : themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE);

        for (Theme thematique : cibles) {
            if (!cloreLExamenDuBlocCivique(journey, etapes, thematique, evaluation)) continue;
            // 🛑 LA LIGNE PAR THEMATIQUE N'EST ECRITE QUE POUR UN EXAMEN
            // COMPLET : pour un examen de theme, l'evaluation elle-meme EST la
            // `CIVIC_THEME_EXAM`, et la reecrire violerait
            // `uq_journey_assessment_event_par_theme`.
            if (evaluation.kind() == JourneyAssessmentKind.CIVIC_EXAM) {
                enregistrer(journey, evaluation.sourceAssessmentId(),
                        JourneyAssessmentKind.CIVIC_THEME_EXAM, null,
                        thematique.getId(), evaluation.completedAt());
            }
        }
        journeyManager.save(journey);
    }

    /**
     * <b>🛑 LE DIAGNOSTIC CIVIQUE PEUPLE, IL NE CLOT PAS</b> — le pendant
     * civique de <b>R11</b> (arbitrage du proprietaire, 2026-09-20).
     *
     * <h3>Le defaut que cette methode corrige, mesure en base</h3>
     * <p>Un diagnostic civique est un {@code MOCK_EXAM} <b>sans</b>
     * {@code lot_theme_id} : il etait donc pris pour un <b>examen blanc
     * complet</b> et passait par {@link JourneyEvaluation#examenCivique}. Il
     * <b>clotait les cinq blocs</b> — ⟦SQL⟧ un candidat a 11/40 lisait « les cinq
     * thematiques TERMINÉ », avec « Actualiser mon plan » pour seule issue. Le
     * discriminant manquant est {@code attempts.civic_diagnostic_id}, deja
     * persiste, exactement comme {@code lot_theme_id} (A74).
     *
     * <h3>🛑 Le point dur : {@code attendSonAmorce} ne s'applique PAS ici</h3>
     * <p>Un cycle civique n'est <b>jamais</b> vide (A65) : au pire il porte
     * cinq examens « Évaluer mon niveau ». {@link #attendSonAmorce} rendrait
     * donc {@code false} pour tout cycle civique, et les priorites du diagnostic
     * partiraient « en attente » — c'est-a-dire <b>nulle part</b>, puisqu'il n'y
     * a pas de cycle EN ATTENTE civique (A78) et que les priorites civiques sont
     * <b>derivees</b>. <b>R11 est la regle qui resout ca</b>, et elle ne parle
     * pas d'amorce : « un diagnostic cree un lot pour tout bloc qui n'en a pas
     * <b>ouvert</b> ». C'est {@code creerLotsCiviques} qui la porte, par bloc.
     *
     * <h3>🛑 Aucune etape d'examen n'est close</h3>
     * <p>{@code cloreLExamenDuBlocCivique} n'est atteint que par une evaluation
     * qui <b>mesure</b> un axe. Le diagnostic n'en mesure aucun (D-51 : son axe
     * est {@code null}), et D-51 reste intact pour l'examen COMPLET, qui doit
     * toujours clore les cinq blocs d'un cycle de mesure.
     */
    private void peuplerDepuisLeDiagnostic(Journey journey, JourneyEvaluation evaluation) {
        // 🛑 L'ORDRE EST CELUI DU DIAGNOSTIC NOMME PAR L'EVALUATION, pas « du
        // dernier termine » : au moment ou le cycle traite ce diagnostic, sa
        // session est encore IN_PROGRESS en base (elle passe a COMPLETED au
        // `POST /result`, apres le `finish` qui nous amene ici). Motif complet
        // et mesure : `CivicPlanService.ordreDuDiagnostic`.
        peuplerLeCycleCivique(journey, civicPlanService.ordreDuDiagnostic(
                journey.getUser().getId(), evaluation.sourceAssessmentId()));
    }

    /**
     * Clot l'examen d'<b>un</b> bloc civique, s'il etait debloque.
     *
     * @return {@code true} si le bloc etait debloque — donc si cette thematique
     *         a bien ete <b>validee</b> par cet examen.
     */
    private boolean cloreLExamenDuBlocCivique(
            Journey journey, List<JourneyStep> etapes, Theme thematique,
            JourneyEvaluation evaluation) {

        String bloc = thematique.getCode();
        boolean unitesDues = etapes.stream()
                .filter(JourneyStep::estOuverte)
                .anyMatch(step -> step.getType() == JourneyStepType.TRAIN_SKILL
                        && bloc.equals(step.blocCode()));
        if (unitesDues) {
            log.info("Cycle {} : examen civique {} passe, mais le bloc {} a encore des unites "
                            + "dues — rien n'est valide (R1, D-15)",
                    journey.getId(), evaluation.sourceAssessmentId(), bloc);
            return false;
        }

        boolean cloture = false;
        for (JourneyStep step : etapes) {
            if (step.getType() != JourneyStepType.SECTION_EXAM || !step.estOuverte()) continue;
            if (!bloc.equals(step.blocCode())) continue;
            if (step.clore(JourneyStepResolution.SATISFIED_BY_ASSESSMENT,
                    evaluation.sourceAssessmentId(), evaluation.completedAt())) {
                stepManager.save(step);
                cloture = true;
            }
        }
        if (!cloture) return false;

        // Le lot a rempli son office : ses unites etaient faites, et son point
        // d'etape vient d'etre satisfait par une mesure. CLOSED, jamais
        // SUPERSEDED -- rien n'a ete saute.
        lotManager.findOuvertParTheme(journey.getId(), thematique.getId()).ifPresent(lot -> {
            lot.clore(JourneyLotStatus.CLOSED,
                    evaluation.sourceAssessmentId(), evaluation.completedAt());
            lotManager.save(lot);
        });
        return true;
    }

    /**
     * <b>Ce qu'une serie civique fait avancer</b> — le pendant civique de
     * {@link #onTrainingProgress}.
     *
     * <p>🛑 <b>La MEME regle, sur l'UNITE</b> (D-48) : le quota est lu chez son
     * autorite unique, {@code JourneyReadService.etapesAuQuota}, qui compte
     * desormais aussi par unite officielle. Une etape civique ne se clot donc
     * jamais sur une regle differente de celle qui l'affiche.
     *
     * <p>🛑 <b>R1 : aucune etape concernee ⇒ RIEN.</b> Une serie qui revele une
     * faiblesse nouvelle ne l'ajoute pas au cycle ; elle y entrera si une
     * <b>evaluation</b> la designe.
     *
     * <p>⚠️ <b>Aucune notion de « maitrise transferee » ici</b>, contrairement au
     * TCF : {@code SkillMasteryEngine} <b>leve</b> sur une source civique (A50),
     * et il a raison — une unite officielle n'est pas une competence, et aucun
     * poids n'a ete defini pour elle. Le seul motif de cloture civique est donc
     * le quota (R2).
     *
     * @param uniteIds les unites <b>reellement observees</b>, rendues par
     *                 {@code CivicObservationService.record}.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void onTrainingProgressCivique(UUID userId, Collection<UUID> uniteIds) {
        if (uniteIds == null || uniteIds.isEmpty()) return;
        Optional<Journey> trouve = getOrCreate(userId, Module.CIVIQUE);
        if (trouve.isEmpty()) return;
        Journey journey = journeyManager.findForUpdate(trouve.get().getId()).orElse(null);
        if (journey == null) return;

        List<JourneyStep> concernees = stepManager.findAll(journey.getId()).stream()
                .filter(JourneyStep::estOuverte)
                .filter(step -> step.getType() == JourneyStepType.TRAIN_SKILL)
                .filter(step -> step.uniteId() != null && uniteIds.contains(step.uniteId()))
                .toList();
        if (concernees.isEmpty()) return;

        Instant maintenant = Instant.now();
        Set<UUID> auQuota = readService.etapesAuQuota(
                userId, stepManager.findAll(journey.getId()));

        for (JourneyStep step : concernees) {
            if (auQuota.contains(step.getId())
                    && step.clore(JourneyStepResolution.QUOTA_REACHED, null, maintenant)) {
                stepManager.save(step);
            }
        }
        journeyManager.save(journey);
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
        if (!porteUnDiagnosticRapide(evaluations)) {
            // 🛑 D-69 (2026-09-28, decision du proprietaire, revisee le meme
            // jour) : SANS DIAGNOSTIC RAPIDE, LE PREMIER CYCLE EST TOUJOURS LE
            // CYCLE D'EXAMENS — les quatre epreuves, chacune son seul examen
            // blanc, examens deja passes ou non. La branche « examens deja
            // passes ⇒ cycle de travail direct » est SUPPRIMEE : sur un compte
            // dont les quatre epreuves etaient mesurees sans priorite ouverte,
            // elle rendait un cycle VIDE (« Votre parcours est a jour », aucun
            // bloc). Un examen anterieur au cycle ne ferme rien (R19) ; ses
            // priorites reviendront par l'examen du cycle. Le diagnostic arrive
            // ensuite sur ce cycle intact ⇒ il l'amorce (D-64,
            // `cycleDExamensParDefautIntact`).
            poserLeCycleDExamens(journey, user.getId());
            return;
        }

        // 🛑 LA TRADUCTION, UNE FOIS POUR TOUTE L'AMORCE : l'historique se lit
        // par les observations, donc par des ids de SOUMISSION cote production.
        // Le parcours, lui, ne connait que des identites d'evaluation.
        Map<UUID, UUID> identites = observationSources.identitesParObservation(evaluations);
        Map<EpreuveType, JourneyObservationSources.Sources> references =
                referencesParEpreuve(evaluations, identites);
        Set<UUID> maitrisees = maitriseesCeJour(tout, evaluations);
        TcfLevelProfile profil = profileService.levelProfile(user.getId());
        creerLots(journey,
                lotBuilder.depuisHistorique(references, evaluations, maitrisees, cible, profil));
        ajouterLesEpreuvesNonMesurees(journey, user.getId());

        // R19.7 — TOUTES les evaluations historiques sont enregistrees d'un coup.
        // Elles ne seront jamais retraitees, et R14 garantit qu'aucune plus
        // ancienne ne modifiera ensuite la structure.
        enregistrerLHistorique(journey, evaluations, identites);
    }

    /**
     * L'evaluation de <b>reference</b> de chaque epreuve (R19.2) : la plus
     * recente qui <b>mesure</b> l'epreuve, a defaut le plus recent diagnostic
     * rapide ayant produit des priorites pour elle.
     *
     * <p>Les observations arrivent de la plus recente a la plus ancienne : la
     * premiere rencontree fait donc foi, sans tri supplementaire.
     */
    private Map<EpreuveType, JourneyObservationSources.Sources> referencesParEpreuve(
            List<LearningPlanObservation> evaluations, Map<UUID, UUID> identites) {
        Map<UUID, Set<UUID>> sourcesParIdentite = new LinkedHashMap<>();
        Map<EpreuveType, UUID> mesurantes = new LinkedHashMap<>();
        Map<EpreuveType, UUID> repli = new LinkedHashMap<>();
        for (LearningPlanObservation observation : evaluations) {
            UUID sourceId = observation.getSourceId();
            if (sourceId == null) continue;
            UUID identite = JourneyObservationSources.identite(identites, sourceId);
            sourcesParIdentite
                    .computeIfAbsent(identite, cle -> new LinkedHashSet<>(Set.of(cle)))
                    .add(sourceId);
            Skill skill = observation.getSkill();
            if (skill == null) continue;
            EpreuveType epreuve = TcfDomaine.epreuve(skill.getSection());
            if (epreuve == null) continue;
            LearningPlanSourceType source = observation.getSourceType();
            boolean baseline = source == LearningPlanSourceType.DIAGNOSTIC_EE
                    || source == LearningPlanSourceType.DIAGNOSTIC_EO;
            if (baseline) {
                repli.putIfAbsent(epreuve, identite);
            } else {
                mesurantes.putIfAbsent(epreuve, identite);
            }
        }
        Map<EpreuveType, JourneyObservationSources.Sources> references = new LinkedHashMap<>();
        for (EpreuveType epreuve : TcfDomainProfileDto.ORDRE) {
            UUID reference = mesurantes.get(epreuve);
            if (reference == null) reference = repli.get(epreuve);
            if (reference == null) continue;
            references.put(epreuve, new JourneyObservationSources.Sources(reference,
                    Set.copyOf(sourcesParIdentite.getOrDefault(reference, Set.of(reference)))));
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
        // 🛑 Le module vient de la NATURE de l'evaluation, jamais d'un parametre
        // a cote : les deux pourraient alors se contredire, et une evaluation
        // civique classee TCF n'alimenterait aucun cycle -- en silence.
        Optional<Journey> trouve = getOrCreate(userId, evaluation.kind().module());
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
        if (journey.getModule() == Module.CIVIQUE) {
            traiterLEvaluationCivique(journey, evaluation);
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
        boolean amorce = attendSonAmorce(etapes)
                || (evaluation.kind() == JourneyAssessmentKind.QUICK_DIAGNOSTIC
                        && cycleDExamensParDefautIntact(journey, etapes));
        // 🛑 LU AVANT TOUTE ECRITURE, lui aussi : un cycle qui attend son amorce
        // n'a pas encore de lot, donc n'est pas (encore) d'affinage — et c'est
        // juste, il n'a rien a deverrouiller ni a mettre en attente.
        boolean affinage = cycleAffinage.pour(journey);

        cloreLEtapeDiagnostic(journey, etapes, evaluation);

        boolean tropAncienne = false;
        if (evaluation.mesureUneEpreuve()) {
            tropAncienne = estTropAncienne(journey, evaluation);
            if (!tropAncienne) cloreLExamenDuBloc(journey, etapes, evaluation, affinage);
        }

        if (!tropAncienne) {
            TargetLevel cible = journey.getTargetLevel();
            Set<UUID> maitrisees = maitriseesCeJour(tout, evaluations);
            // 🛑 L'identite RESTE l'attempt / la session (A11). Ce qui change,
            // c'est la JOINTURE : les observations de production sont clavetees
            // sur leurs soumissions, et c'est `observationSources` — l'autorite
            // unique — qui les rattache a leur evaluation.
            JourneyObservationSources.Sources sources = observationSources.pour(evaluation);
            // 🛑 Le garde : zero PRIORITE est normal (R9), zero OBSERVATION
            // rattachee ne l'est jamais. C'est ce qui rend la prochaine
            // occurrence visible en dix minutes au lieu de trois heures.
            observationSources.verifierLeJoin(evaluation, sources, evaluations);
            List<JourneyLotBuilder.Lot> lots = lotBuilder.depuisEvaluation(
                    sources, evaluations, maitrisees, cible,
                    profileService.levelProfile(userId));
            if (amorce) {
                creerLots(journey, filtrerLeDiagnostic(journey, lots, evaluation),
                        epreuvesAvecExamenOuvert(etapes));
            } else {
                mettreEnAttente(journey, etapes, lots, evaluations, evaluation, sources, affinage);
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

    /**
     * <b>Le cycle d'examens PAR DEFAUT, encore intact</b> — le seul cycle porteur
     * d'examens qu'un diagnostic rapide a encore le droit d'<b>amorcer</b>
     * (D-69, 2026-09-28).
     *
     * <p>🛑 <b>Pourquoi</b> : le Plan par defaut naît a la premiere lecture, et
     * le parcours invite → compte → analyse fait arriver l'analyse du
     * diagnostic <b>apres</b> la creation du compte. Sans cette porte, les
     * priorites du diagnostic partaient dans le cycle en attente, et le compte
     * qui vient de faire son diagnostic perdait son cycle d'AFFINAGE (D-64).
     *
     * <p><b>Intact</b> = premier cycle TCF du candidat, sans lot ni
     * competence, et <b>aucune etape close</b> (une etape rendue obsolete ne
     * compte pas). Des qu'un examen y a ete passe, le cycle a commence : le
     * diagnostic suit alors la regle ordinaire (D-13, cycle en attente), et un
     * examen, lui, n'amorce jamais ce cycle — ses priorites vont au cycle
     * suivant, c'est l'objet meme d'un cycle d'examens.
     */
    private boolean cycleDExamensParDefautIntact(Journey journey, List<JourneyStep> etapes) {
        if (journey.getModule() != Module.TCF) return false;
        boolean porteUnExamen = false;
        for (JourneyStep step : etapes) {
            if (step.getLot() != null || step.getType() == JourneyStepType.TRAIN_SKILL) return false;
            if (step.getResolution() == JourneyStepResolution.SUPERSEDED) continue;
            if (!step.estOuverte()) return false;
            if (step.getType() == JourneyStepType.SECTION_EXAM) porteUnExamen = true;
        }
        return porteUnExamen
                && journeyManager.compterHistorises(journey.getUser().getId(), Module.TCF) == 0;
    }

    /** Les epreuves dont le cycle porte deja un examen ouvert. */
    private static Set<EpreuveType> epreuvesAvecExamenOuvert(List<JourneyStep> etapes) {
        Set<EpreuveType> epreuves = new LinkedHashSet<>();
        for (JourneyStep step : etapes) {
            if (step.getType() == JourneyStepType.SECTION_EXAM && step.estOuverte()
                    && step.getExamType() != null) {
                epreuves.add(step.getExamType());
            }
        }
        return epreuves;
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
            JourneyEvaluation evaluation,
            JourneyObservationSources.Sources sources,
            boolean affinage) {
        List<JourneyLotBuilder.Lot> nouveautes = nouveautes(
                lots, etapesDuCycleEnCours,
                prioritairesDe(evaluations, sources), affinage);
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
            List<LearningPlanObservation> evaluations,
            JourneyObservationSources.Sources sources) {
        Set<UUID> prioritaires = new LinkedHashSet<>();
        for (LearningPlanObservation observation : evaluations) {
            // 🛑 `contient`, jamais `equals` : cote production le `source_id`
            // d'une observation est une SOUMISSION, l'identite un attempt.
            if (!sources.contient(observation.getSourceId())) continue;
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
            Set<UUID> prioritaires,
            boolean affinage) {
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
                        prioritaires.contains(priorite.skill().getId()), affinage)) {
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

    private static boolean aRefaire(
            JourneyStep dansLeCycle, boolean regressionMesuree, boolean affinage) {
        if (dansLeCycle == null) return true;
        // Encore due dans le cycle en cours : rien a remettre en attente.
        // 🛑 SAUF EN CYCLE D'AFFINAGE (D-64) : elle n'y est pas DUE, elle y est
        // FACULTATIVE, et l'actualisation l'historisera telle quelle. L'examen
        // qui la redetecte doit donc la porter au cycle suivant — sinon le
        // candidat qui n'a fait « que les examens » perdrait precisement les
        // priorites que ces examens viennent de confirmer.
        if (dansLeCycle.estOuverte()) return affinage;
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
        // 🛑 L'evaluation jugee est EXCLUE de la comparaison : elle vient d'etre
        // journalisee, et relue arrondie a la microseconde elle se trouvait
        // « plus ancienne qu'elle-meme » (prod, 2026-10-03 : examen CE ignore,
        // ses priorites perdues pour le cycle suivant).
        Optional<Instant> derniere = journeyManager.derniereMesure(
                journey.getUser().getId(), journey.getModule(), evaluation.examType(),
                evaluation.sourceAssessmentId());
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
            Journey journey, List<JourneyStep> etapes, JourneyEvaluation evaluation,
            boolean affinage) {
        EpreuveType epreuve = evaluation.examType();
        boolean dues = competencesDues(etapes, epreuve);
        // 🛑 CYCLE D'AFFINAGE (2026-09-27, D-64) : D-15 ne s'y applique pas.
        if (dues && !affinage) {
            log.info("Parcours {} : examen {} passe hors du plan, mais le bloc {} a encore des "
                            + "competences dues — rien n'est valide (R1, D-15)",
                    journey.getId(), evaluation.sourceAssessmentId(), epreuve);
            return;
        }
        cloreLesEtapesDExamen(etapes, evaluation, affinage);
        // En affinage, des competences facultatives restent travaillables : le
        // lot n'a pas fini son office, il reste ouvert (son examen, lui, est
        // clos). Il sera historise avec le cycle.
        if (dues) return;
        // Le lot a rempli son office : ses entrainements etaient faits, et son
        // point d'etape vient d'etre satisfait par une mesure. Il se ferme
        // CLOSED — jamais SUPERSEDED : rien n'a ete saute.
        JourneyLot lot = lotManager.findOuvert(journey.getId(), epreuve).orElse(null);
        if (lot == null) return;
        lot.clore(JourneyLotStatus.CLOSED,
                evaluation.sourceAssessmentId(), evaluation.completedAt());
        lotManager.save(lot);
    }

    /**
     * <b>LA cloture de l'etape d'examen d'un bloc</b> — l'unique fonction qui
     * la pose, pour les trois chemins : l'evaluation complete
     * ({@link #cloreLExamenDuBloc}), la fin d'un examen de production encore en
     * correction ({@link #onProductionExamSubmitted}) et le filet de lecture
     * ({@link #rattraperLesExamensNonSignales}).
     *
     * <p>Garde D-15 : un bloc qui a encore des competences dues ne voit pas son
     * examen valide — <b>sauf en cycle d'affinage</b> (D-64), ou elles sont
     * facultatives.
     *
     * @return {@code true} si une etape a ete close
     */
    private boolean cloreLesEtapesDExamen(
            List<JourneyStep> etapes, JourneyEvaluation evaluation, boolean affinage) {
        EpreuveType epreuve = evaluation.examType();
        if (epreuve == null) return false;
        if (!affinage && competencesDues(etapes, epreuve)) return false;
        boolean cloture = false;
        for (JourneyStep step : etapes) {
            if (step.getType() != JourneyStepType.SECTION_EXAM || !step.estOuverte()) continue;
            if (step.getExamType() != epreuve) continue;
            if (step.clore(JourneyStepResolution.SATISFIED_BY_ASSESSMENT,
                    evaluation.sourceAssessmentId(), evaluation.completedAt())) {
                stepManager.save(step);
                cloture = true;
            }
        }
        return cloture;
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
        // Des `Skill` : c'est le TCF, et rien d'autre. Le pendant civique
        // travaille des UNITES OFFICIELLES (D-48) et aura son propre point
        // d'entree -- `SkillMasteryEngine` LEVE deja sur une source civique
        // (A50) plutot que d'inventer un poids.
        Optional<Journey> trouve = getOrCreate(userId, Module.TCF);
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

        // 🛑 D-65 (2026-09-27, decision du proprietaire) : « UNE ETAPE EXIGE
        // TOUJOURS SES SERIES ». Le quota est le SEUL motif de cloture d'une
        // etape d'entrainement. La maitrise transferee (`MASTERED`) la fermait
        // avant son quota — etape CO close a 1/2 series sur une serie a 19/20.
        // Le moteur de maitrise continue de dire si la competence est acquise
        // (priorites, etats servis) ; il ne clot plus l'etape.
        for (JourneyStep step : concernees) {
            if (auQuota.contains(step.getId())
                    && step.clore(JourneyStepResolution.QUOTA_REACHED, null, maintenant)) {
                stepManager.save(step);
            }
        }
        journeyManager.save(journey);
    }

    /**
     * <b>La reparation de D-65, a la lecture</b> : dans le cycle <b>EN COURS</b>,
     * une etape d'entrainement close {@code MASTERED} ou
     * {@code SATISFIED_BY_ASSESSMENT} — donc sans ses series — est rouverte.
     *
     * <p>Pourquoi a la lecture et pas par migration : c'est la promesse de ce
     * service (« la lecture suivante rattrape »), aucune ligne n'est effacee,
     * et un cycle <b>historise</b> n'est jamais relu par ici — son historique
     * reste fige. Si l'etape a <b>deja</b> son quota, elle est aussitot close
     * {@code QUOTA_REACHED} par la meme autorite que l'ecriture
     * ({@code JourneyReadService.etapesAuQuota}).
     *
     * <p>🛑 <b>Garde : le lot doit etre encore OUVERT.</b> Un lot {@code CLOSED}
     * a ete valide par l'examen de son bloc ; rouvrir une etape derriere un
     * examen deja passe remettrait du travail avant un examen qui ne se
     * repassera pas. Ce cas est laisse tel quel.
     *
     * @return {@code true} si une etape a change
     */
    private boolean rouvrirLesEtapesCloseesSansSeries(Journey journey, List<JourneyStep> etapes) {
        List<JourneyStep> rouvertes = new ArrayList<>();
        for (JourneyStep step : etapes) {
            if (step.getLot() != null && step.getLot().getStatus() != JourneyLotStatus.OPEN) continue;
            if (step.rouvrirUneClotureSansSeries()) {
                stepManager.save(step);
                rouvertes.add(step);
            }
        }
        if (rouvertes.isEmpty()) return false;
        log.info("Parcours {} : {} etape(s) close(s) sans leurs series rouverte(s) (D-65)",
                journey.getId(), rouvertes.size());
        Set<UUID> auQuota = readService.etapesAuQuota(journey.getUser().getId(), etapes);
        Instant maintenant = Instant.now();
        for (JourneyStep step : rouvertes) {
            if (auQuota.contains(step.getId())
                    && step.clore(JourneyStepResolution.QUOTA_REACHED, null, maintenant)) {
                stepManager.save(step);
            }
        }
        return true;
    }

    /**
     * <b>Le filet de D-71, a la lecture</b> : dans le cycle <b>EN COURS</b>, une
     * etape d'<b>expression</b> encore ouverte dont tous les sujets sont deja
     * traites est close {@code QUOTA_REACHED}.
     *
     * <p>Pourquoi : l'ecriture ne clot une etape qu'a l'arrivee de l'analyse
     * d'un petit sujet ({@link #onTrainingProgress}). Quand la taille d'etape
     * baisse ({@code LearningPlanStep.PROMPTS_PAR_ETAPE}, 5 &rarr; 3 le
     * 2026-10-04), une etape ouverte qui avait deja ses 3 premiers sujets
     * traites serait restee « 3/3, Etape terminee » a l'ecran tout en restant
     * {@code journey.current} jusqu'a une soumission de plus. La lecture la
     * clot donc, par la <b>meme</b> autorite que l'ecriture
     * ({@code JourneyReadService.etapesAuQuota}) — jamais une regle a part.
     *
     * <p>🛑 Rien n'est reecrit hors du cycle en cours : les cycles historises
     * ne passent pas par ici, et une etape deja close ({@code QUOTA_REACHED} a
     * 5/5 compris) n'est jamais touchee. Meme garde que D-65 : le <b>lot</b>
     * doit etre encore ouvert. La comprehension et le civique (series) ne sont
     * pas concernes : leur quota n'a pas change.
     *
     * @return {@code true} si une etape a ete close
     */
    private boolean cloreLesEtapesDExpressionAuQuota(Journey journey, List<JourneyStep> etapes) {
        List<JourneyStep> candidates = etapes.stream()
                .filter(JourneyStep::estOuverte)
                .filter(step -> step.getType() == JourneyStepType.TRAIN_SKILL)
                .filter(step -> step.getLot() == null
                        || step.getLot().getStatus() == JourneyLotStatus.OPEN)
                .filter(step -> step.getSkill() != null
                        && step.getSkill().getSection() != null
                        && step.getSkill().getSection().isProduction())
                .toList();
        if (candidates.isEmpty()) return false;
        Set<UUID> auQuota = readService.etapesAuQuota(journey.getUser().getId(), candidates);
        if (auQuota.isEmpty()) return false;
        Instant maintenant = Instant.now();
        int closes = 0;
        for (JourneyStep step : candidates) {
            if (auQuota.contains(step.getId())
                    && step.clore(JourneyStepResolution.QUOTA_REACHED, null, maintenant)) {
                stepManager.save(step);
                closes++;
            }
        }
        if (closes == 0) return false;
        log.info("Parcours {} : {} etape(s) d'expression deja au quota close(s) a la lecture (D-71)",
                journey.getId(), closes);
        return true;
    }

    // =====================================================================
    // Ecriture de la file
    // =====================================================================

    /** Cree les lots dans l'ordre recu, chacun suivi de son checkpoint (R3, R4). */
    private void creerLots(Journey journey, List<JourneyLotBuilder.Lot> lots) {
        creerLots(journey, lots, Set.of());
    }

    /**
     * @param examensOuverts les epreuves dont le bloc porte <b>deja</b> un
     *                       examen ouvert. 🛑 R3 y est deja satisfaite : le lot
     *                       ne recoit pas de second checkpoint — deux examens
     *                       ouverts pour un seul bloc compteraient deux etapes
     *                       dans l'avancement, une seule montree. C'est le cas
     *                       du diagnostic qui amorce le cycle d'examens par
     *                       defaut (D-69) ; meme regle que le civique
     *                       ({@link #creerLotsCiviques}).
     */
    private void creerLots(
            Journey journey, List<JourneyLotBuilder.Lot> lots, Set<EpreuveType> examensOuverts) {
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
            if (examensOuverts.contains(prevu.epreuve())) continue;
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
     * <b>D-70 — aucun bloc d'un cycle de travail ne reste VIDE</b> (decision du
     * proprietaire, 2026-10-03 : « si le plan est fini et qu'on n'a rien trouve
     * a travailler, toujours proposer des examens blancs ; ici on a eu A1, donc
     * il devrait proposer des seances en A2, B1, et meme B2 »).
     *
     * <p>Constat de prod ({@code user@sejourfr.fr}) : le cycle actualise ne
     * portait que des lots EO et EE ; les blocs CO et CE, sans aucune etape,
     * etaient servis {@code TERMINE} — « termines » sans qu'on y ait rien fait,
     * pour une epreuve a A1 sous un objectif B2.
     *
     * <p>Pour chaque epreuve sans AUCUNE etape (obsoletes exclues), dans
     * l'ordre du TCF :
     * <ol>
     *   <li><b>comprehension mesuree sous l'objectif</b> : la competence de
     *       chaque palier entre le niveau du domaine (lecture Plan, D-2) et
     *       l'objectif ({@link JourneyLotBuilder#versLObjectif}), puis son
     *       examen blanc (R3) ;</li>
     *   <li><b>sinon</b> — expression, objectif atteint, niveau inconnu — un
     *       <b>examen blanc</b> seul : {@code REASSESS} si l'epreuve est mesuree,
     *       {@code INITIAL_ASSESSMENT} sinon (R12).</li>
     * </ol>
     *
     * <p>🛑 <b>Cycles de rang ≥ 2 seulement</b> : le premier cycle a sa propre
     * composition (cycle d'examens D-69, affinage D-64), qui pose deja un examen
     * par bloc. Appele a l'actualisation ET a la lecture : c'est la lecture qui
     * repare, sans migration, les cycles promus avant cette regle.
     *
     * <p>🛑 Rien d'anterieur ne ferme ces etapes : un examen passe avant la
     * creation du cycle ne clot jamais une de ses etapes (D-69 ter).
     *
     * @return {@code true} si des etapes ont ete ajoutees
     */
    boolean completerLesBlocsVides(Journey journey, List<JourneyStep> etapes) {
        if (journey.getModule() != Module.TCF
                || journey.getStatus() != JourneyStatus.EN_COURS) return false;
        if (blocsVides(etapes).isEmpty()) return false;
        UUID userId = journey.getUser().getId();
        if (journeyManager.compterHistorises(userId, Module.TCF) == 0) return false;

        // Deux lectures simultanees ne completent pas deux fois : la seconde
        // attend, relit la file, et n'y trouve plus de bloc vide.
        journeyManager.verrouillerLaCreation(userId, Module.TCF);
        Journey verrouille = journeyManager.findForUpdate(journey.getId()).orElse(null);
        if (verrouille == null) return false;
        Set<EpreuveType> vides = blocsVides(stepManager.findAll(verrouille.getId()));
        if (vides.isEmpty()) return false;

        TargetLevel cible = verrouille.getTargetLevel();
        TcfLevelProfile profil = profileService.levelProfile(userId);
        List<LearningPlanObservation> tout = observationManager.findAllByUserWithSkill(userId);
        Set<UUID> maitrisees = maitriseesCeJour(tout, evaluationFilter.retenir(tout));
        List<Skill> comprehension = skillManager.findActiveComprehension();

        List<JourneyLotBuilder.Lot> lots = new ArrayList<>();
        Map<EpreuveType, Boolean> examensSeuls = new LinkedHashMap<>();
        for (EpreuveType epreuve : TcfDomainProfileDto.ORDRE) {
            if (!vides.contains(epreuve)) continue;
            NiveauActuelEpreuveResolver.Mesure mesure = mesureResolver.mesure(userId, epreuve);
            JourneyLotBuilder.Lot lot = mesure.mesuree()
                    ? lotBuilder.versLObjectif(epreuve, mesure.attemptId(),
                            niveauDuDomaine(profil, epreuve), cible, comprehension, maitrisees)
                    : null;
            if (lot != null) lots.add(lot);
            else examensSeuls.put(epreuve, mesure.mesuree());
        }
        creerLots(verrouille, lotBuilder.ordonner(lots, cible, profil));
        examensSeuls.forEach((epreuve, mesuree) -> {
            JourneyStep examen = new JourneyStep();
            examen.setJourney(verrouille);
            examen.setType(JourneyStepType.SECTION_EXAM);
            examen.setPurpose(mesuree
                    ? JourneyStepPurpose.REASSESS : JourneyStepPurpose.INITIAL_ASSESSMENT);
            examen.setExamType(epreuve);
            ajouter(verrouille, examen);
        });
        journeyManager.save(verrouille);
        log.info("Parcours {} : blocs vides completes (D-70) — paliers {}, examens seuls {}",
                verrouille.getId(), lots.stream().map(JourneyLotBuilder.Lot::epreuve).toList(),
                examensSeuls.keySet());
        return true;
    }

    /** Les epreuves dont le cycle ne porte AUCUNE etape (obsoletes exclues). */
    private static Set<EpreuveType> blocsVides(List<JourneyStep> etapes) {
        Set<EpreuveType> vides = new LinkedHashSet<>(TcfDomainProfileDto.ORDRE);
        for (JourneyStep step : etapes) {
            if (step.getResolution() == JourneyStepResolution.SUPERSEDED) continue;
            if (step.getExamType() != null) vides.remove(step.getExamType());
        }
        return vides;
    }

    /** Le niveau du DOMAINE, lecture Plan (D-2) — celle qui ordonne deja les lots. */
    private static NiveauCecrl niveauDuDomaine(
            TcfLevelProfile profil, EpreuveType epreuve) {
        if (profil == null) return null;
        return switch (epreuve) {
            case TCF_CO -> profil.co();
            case TCF_CE -> profil.ce();
            case TCF_EE -> profil.ee();
            case TCF_EO -> profil.eo();
            default -> null;
        };
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
        // ⚠️ AXE : CHEMIN TCF ASSUME (DETTE-A1). Cette amorce pose les epreuves
        // non mesurees du TCF ; un `null` civique entre sans dommage dans le
        // LinkedHashSet et ne correspondra a aucune des quatre. L'amorce
        // civique est un autre chemin (P8.4 point 4), au grain de l'unite.
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

    /**
     * <b>Le cycle d'EXAMENS</b> : un {@code SECTION_EXAM} par epreuve, dans
     * {@code TcfDomainProfileDto.ORDRE}, chacun la seule etape de son bloc.
     *
     * <p>🛑 <b>Une seule construction, trois emplois</b> : le Plan par defaut
     * (D-69), le jalon d'examen complet (D-68, {@code JourneyCycleService}) et
     * le lancement (D-69 ter). Quatre etapes OUVERTES, une seule nature ; un
     * examen passe AVANT le cycle n'en ferme aucune.
     */
    void poserLeCycleDExamens(Journey journey, UUID userId) {
        for (EpreuveType epreuve : TcfDomainProfileDto.ORDRE) {
            JourneyStep step = new JourneyStep();
            step.setJourney(journey);
            step.setType(JourneyStepType.SECTION_EXAM);
            // D-69 ter : UNE seule nature, « Examen blanc » — plus de
            // distinction « Évaluer / Vérifier ». Un examen anterieur au cycle
            // ne ferme jamais cette etape (filets de lecture gardes par la
            // date de creation du cycle).
            step.setPurpose(JourneyStepPurpose.INITIAL_ASSESSMENT);
            step.setExamType(epreuve);
            ajouter(journey, step);
        }
    }

    /**
     * <b>Le cycle d'examens CIVIQUE</b> : un examen par thematique, dans l'ordre
     * d'affichage du module — le jalon D-68 et le lancement D-69 ter.
     */
    void poserLeCycleDExamensCivique(Journey journey) {
        for (Theme thematique : themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE)) {
            JourneyStep step = new JourneyStep();
            step.setJourney(journey);
            step.setType(JourneyStepType.SECTION_EXAM);
            step.setPurpose(JourneyStepPurpose.INITIAL_ASSESSMENT);
            step.poserBloc(thematique);
            ajouter(journey, step);
        }
    }

    /** L'historique porte-t-il un diagnostic RAPIDE (sa baseline EE / EO) ? */
    private static boolean porteUnDiagnosticRapide(List<LearningPlanObservation> evaluations) {
        return evaluations.stream().anyMatch(observation ->
                observation.getSourceType() == LearningPlanSourceType.DIAGNOSTIC_EE
                        || observation.getSourceType() == LearningPlanSourceType.DIAGNOSTIC_EO);
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
        enregistrer(journey, evaluation.sourceAssessmentId(), evaluation.kind(),
                evaluation.examType(), evaluation.themeId(), evaluation.completedAt());
    }

    /**
     * Une ligne du journal. 🛑 <b>L'axe est EXACTEMENT celui de la nature</b>
     * ({@code chk_journey_assessment_mesure}, V071) : l'invariant de
     * {@link JourneyEvaluation} l'a deja verifie a la ligne fautive.
     */
    private void enregistrer(
            Journey journey, UUID sourceAssessmentId, JourneyAssessmentKind kind,
            EpreuveType epreuve, UUID themeId, Instant completedAt) {
        JourneyAssessmentEvent event = new JourneyAssessmentEvent();
        event.setJourney(journey);
        event.setSourceAssessmentId(sourceAssessmentId);
        event.setAssessmentKind(kind);
        event.setExamType(epreuve);
        if (themeId != null) {
            event.setTheme(themeManager.findById(themeId).orElse(null));
        }
        event.setCompletedAt(completedAt);
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
            Journey journey, List<LearningPlanObservation> evaluations,
            Map<UUID, UUID> identites) {
        Map<UUID, JourneyEvaluation> parIdentite = new LinkedHashMap<>();
        for (LearningPlanObservation observation : evaluations) {
            UUID source = observation.getSourceId();
            if (source == null) continue;
            // 🛑 L'IDENTITE D'EVALUATION, JAMAIS L'ID D'OBSERVATION. Le journal
            // est interroge par `dejaTraitee` avec ce que le chemin LIVE passe —
            // un attempt, une session. Y ecrire des ids de soumission faisait
            // porter a la colonne DEUX espaces d'identifiants, et la meme
            // evaluation etait alors traitee une seconde fois juste apres
            // l'amorce. Effet de bord voulu : les 3 taches d'une epreuve, et les
            // deux productions d'un diagnostic, se replient sur UNE ligne.
            UUID identite = JourneyObservationSources.identite(identites, source);
            if (parIdentite.containsKey(identite)) continue;
            Skill skill = observation.getSkill();
            if (skill == null) continue;
            boolean baseline = observation.getSourceType() == LearningPlanSourceType.DIAGNOSTIC_EE
                    || observation.getSourceType() == LearningPlanSourceType.DIAGNOSTIC_EO;
            parIdentite.put(identite, baseline
                    ? JourneyEvaluation.diagnosticRapide(identite, observation.getObservedAt())
                    : new JourneyEvaluation(identite,
                            JourneyAssessmentKind.SECTION_EXAM,
                            TcfDomaine.epreuve(skill.getSection()), observation.getObservedAt()));
        }
        parIdentite.values().forEach(evaluation -> enregistrer(journey, evaluation));
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

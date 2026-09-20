package com.sejourfr.app.service;

import com.sejourfr.app.dto.FullTcfExamResponse;
import com.sejourfr.app.dto.FullTcfExamSummaryResponse;
import com.sejourfr.app.dto.ProductionAttemptStartRequest;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.attempt.AttemptInteractionService;
import com.sejourfr.app.service.journey.JourneyProductionBridge;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Orchestration d'un examen blanc TCF complet (les 4 épreuves enchaînées :
 * CO + CE + EE + EO). Un appel à {@link #start} crée un parent portant
 * {@code epreuve = TCF_COMPLET} et les 4 sous-attempts qui en dépendent —
 * atomique, transactionnel.
 *
 * <p><b>Il n'y a plus de chrono global.</b> Chaque épreuve porte sa propre
 * durée ({@code DureeEpreuve}), le temps restant de l'une ne se transfère
 * <b>jamais</b> à la suivante, et l'abandon-reprise entre deux épreuves est
 * officiellement supporté : un compte à rebours d'ensemble y serait
 * structurellement faux (le candidat qui reprend le lendemain trouverait
 * l'examen expiré). Le parent ne porte donc plus de
 * {@code time_limit_seconds} ; {@code timer_started_at} y reste, mais comme
 * <b>trace du début réel</b> de l'examen, plus comme ancre d'un décompte.
 *
 * <p>Le niveau CECRL final est le plancher des sous-épreuves <b>réellement
 * passées</b> (règle officielle TCF IRN) : une épreuve verrouillée par le
 * freemium ou restée sans niveau exploitable en est exclue, jamais comptée au
 * plus bas. Il est posé à la {@link #finish finalisation}, à condition que
 * toutes les évaluations IA EE/EO soient remontées {@code EVALUATED}.
 *
 * <p>Les sous-attempts vivent indépendamment :
 * <ul>
 *   <li>CO / CE : 25 QCM A2/B1/B2 progressifs, score pondéré X/50.
 *       Composition + chrono via {@link AttemptService#startModuleExamSubAttempt}
 *       (CO 20 min, CE 35 min — mêmes durées qu'en standalone).</li>
 *   <li>EE / EO : 3 tâches par épreuve, attached au sous-attempt EE/EO via
 *       {@code production_submissions.attempt_id}. Évaluation IA asynchrone.</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FullTcfExamService {

    private static final int HISTORY_LIMIT_MAX = 100;

    /** Nombre de slots de la grille d'examens blancs complets (cf. V110). */
    static final int EXAM_SLOTS = 20;

    private final AttemptManager attemptManager;
    private final UserManager userManager;
    private final AttemptService attemptService;
    private final AttemptInteractionService attemptInteractionService;
    private final ProductionAccessService productionAccessService;
    private final FullTcfExamResponseBuilder responseBuilder;
    private final JourneyProductionBridge journeyProductionBridge;

    // ------------------------------------------------------------------------
    // Création
    // ------------------------------------------------------------------------

    /**
     * Crée un examen blanc TCF complet : parent {@code TCF_COMPLET} + 4
     * sous-attempts (CO, CE, EE, EO) en une seule transaction.
     *
     * <p><b>Freemium</b> — accessible aux comptes gratuits, pas seulement aux
     * abonnés TCF : une épreuve de production y est incluse, évaluée par l'IA,
     * tant que <b>sa</b> gratuité n'a pas été consommée. Une épreuve dont la
     * gratuité est consommée est verrouillée (pré-terminée, marquée
     * {@code production_locked}) ; l'examen reste jouable sur le reste. Une
     * épreuve verrouillée n'a <b>pas</b> de niveau et sort du plancher global —
     * le verrou est commercial, pas linguistique. Les abonnés TCF ont un accès
     * illimité aux 4 épreuves.
     *
     * <p>🛑 <b>Le verrou est PAR ÉPREUVE depuis D-17 bis</b> (2026-09-18) : deux
     * gratuités nominatives, une EE et une EO. Un candidat qui a usé son examen
     * blanc EE garde son examen blanc EO, et l'examen complet doit le lui
     * donner. Un verrou global aurait fermé les deux dès la première consommée.
     *
     * <p>🛑 <b>Et il se lit sur le LEDGER</b>, plus sur l'existence d'une
     * soumission ({@code hasFullExamProductionSubmission}, révoqué) : une tâche
     * déposée dont le correcteur échoue ne consomme rien, donc ne doit rien
     * fermer.
     */
    @Transactional
    public FullTcfExamResponse start(UUID userId, Integer slotNumber) {
        int slot = validateSlot(slotNumber);
        User user = userManager.findById(userId)
                .orElseThrow(() -> new NotFoundException("User introuvable : " + userId));

        // La règle vit dans ProductionAccessService, qui la sert AUSSI en lecture
        // au jalon du Plan : deux copies auraient fini par afficher un cadenas
        // que le serveur ne pose pas, ou l'inverse.
        Set<EpreuveType> verrouillees = EnumSet.noneOf(EpreuveType.class);
        for (EpreuveType epreuve : List.of(EpreuveType.TCF_EE, EpreuveType.TCF_EO)) {
            if (productionAccessService.isFullExamProductionLocked(userId, epreuve)) {
                verrouillees.add(epreuve);
            }
        }
        // 🛑 Le drapeau du PARENT ne vaut que pour les DEUX épreuves fermées : il
        // est lu comme « toute la production est verrouillée »
        // (FullTcfExamResponseBuilder), et le poser sur une seule aurait fermé
        // à l'écran une épreuve encore offerte. Le verrou d'une seule épreuve
        // se porte sur SON sous-attempt.
        boolean toutVerrouille = verrouillees.size() == 2;

        Attempt parent = createParent(user, slot, toutVerrouille);

        // CO + CE : QCM avec questions tirées + chrono propre.
        attemptService.startModuleExamSubAttempt(user, QuestionType.CO, parent);
        attemptService.startModuleExamSubAttempt(user, QuestionType.CE, parent);

        // EE + EO : attempts vides — les 3 tâches seront soumises via
        // /api/production-submissions avec attemptId du sous-attempt + parent.
        attemptService.startProductionAttempt(userId, new ProductionAttemptStartRequest(
                Module.TCF, EpreuveType.TCF_EE, parent.getId(), null, null));
        attemptService.startProductionAttempt(userId, new ProductionAttemptStartRequest(
                Module.TCF, EpreuveType.TCF_EO, parent.getId(), null, null));

        // Compte gratuit ayant déjà consommé la gratuité d'une épreuve : on
        // pré-termine SON sous-attempt (aucune soumission possible — le garde
        // finishedAt côté ProductionSubmissionService double le verrou) ; le
        // bilan la laissera SANS niveau (hors plancher), l'examen reste jouable
        // sur les autres épreuves.
        if (!verrouillees.isEmpty()) {
            lockProductionSubAttempts(parent, verrouillees);
        }

        log.info("Full TCF exam created: parentId={} user={} productionVerrouillee={}",
                parent.getId(), userId, verrouillees);
        return responseBuilder.buildResponse(parent);
    }

    /**
     * Pré-termine les sous-attempts EE/EO d'un examen complet verrouillé.
     *
     * <p>🛑 <b>AUCUN BRANCHEMENT DU PARCOURS ICI, ET C'EST EXPLICITE</b> (D-24,
     * point 4). Cette méthode pose {@code TERMINE} <b>sans qu'aucun examen n'ait
     * été passé</b> : le compte est gratuit, son EE/EO offerte est consommée, et
     * les deux épreuves sont fermées avant même que l'examen ne commence. Le
     * signaler aurait <b>inventé une mesure</b>, et clos au passage l'étape
     * « Évaluer mon niveau » d'une épreuve que le candidat n'a jamais ouverte.
     * {@code JourneyProductionBridge} tient la même garde de son côté (aucune
     * tâche corrigée ⇒ aucun signal), parce qu'un jour ces sous-attempts
     * passeront quand même devant lui, à la complétion de l'examen.
     */
    private void lockProductionSubAttempts(Attempt parent, Set<EpreuveType> verrouillees) {
        Instant now = Instant.now();
        for (Attempt sub : attemptManager.findSubAttempts(parent.getId())) {
            if (verrouillees.contains(sub.getEpreuve()) && sub.getFinishedAt() == null) {
                sub.setFinishedAt(now);
                sub.setStatus(AttemptStatus.TERMINE);
                // 🛑 Le drapeau est posé sur le SOUS-ATTEMPT, pas seulement sur
                // le parent : depuis D-17 bis les deux gratuités sont
                // nominatives, et un drapeau porté par le seul parent ne sait
                // pas dire LAQUELLE des deux épreuves est fermée. La colonne
                // existe sur `attempts`, donc sur les sous-attempts aussi — rien
                // à migrer. L'ancienne donnée (drapeau sur le seul parent) reste
                // lue telle quelle par FullTcfExamResponseBuilder.
                sub.setProductionLocked(true);
                attemptManager.save(sub);
            }
        }
    }

    /**
     * Slot de la grille « 20 examens blancs complets » : 1..{@value #EXAM_SLOTS},
     * null → slot 1. Sans cette borne, {@code slotNumber=999} ou {@code -3}
     * étaient persistés tels quels — même verrou que les MOCK_EXAM QCM.
     */
    private static int validateSlot(Integer slotNumber) {
        if (slotNumber == null) return 1;
        if (slotNumber < 1 || slotNumber > EXAM_SLOTS) {
            throw new BusinessException("slotNumber doit être entre 1 et " + EXAM_SLOTS + ".");
        }
        return slotNumber;
    }

    private Attempt createParent(User user, Integer slotNumber, boolean productionLocked) {
        Attempt parent = new Attempt();
        parent.setUser(user);
        parent.setType(AttemptType.MOCK_EXAM);
        parent.setModule(Module.TCF);
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        parent.setStatus(AttemptStatus.EN_COURS);
        // Pas de time_limit_seconds sur le parent : l'enveloppe globale de
        // 90 min a été supprimée (cf. javadoc de classe). Chaque sous-attempt
        // porte la durée de son épreuve.
        parent.setStartedAt(Instant.now());
        // Slot UI (cf. V110) — propage le slot visé par l'utilisateur dans la
        // grille « 20 slots TCF complets ». Les sous-attempts CO/CE/EE/EO
        // restent à slot_number NULL (ils ne sont pas listés en grille).
        if (slotNumber != null) {
            parent.setSlotNumber(slotNumber);
        }
        parent.setProductionLocked(productionLocked);
        // totalQuestions / score / passThreshold restent NULL — le parent
        // n'a pas de questions propres, le résultat est porté par finalCecrlLevel.
        return attemptManager.save(parent);
    }

    // ------------------------------------------------------------------------
    // Lecture
    // ------------------------------------------------------------------------

    /**
     * Détail complet d'un examen blanc (parent + 4 sous-attempts + agrégation
     * CECRL).
     *
     * <p>Clôture d'abord les sous-épreuves dont le délai est écoulé — clôture
     * <b>paresseuse, à la lecture</b>, sans job planifié : quitter ne suspend
     * rien, et le candidat qui revient après l'échéance d'une épreuve la
     * retrouve close avec ce qui avait été enregistré.
     */
    @Transactional(readOnly = true)
    public FullTcfExamResponse get(UUID userId, UUID parentAttemptId) {
        Attempt parent = loadParentAndCheck(userId, parentAttemptId);
        attemptInteractionService.closeExpiredSubAttempts(parent.getId());
        return responseBuilder.buildResponse(parent);
    }

    /** Historique des examens blancs complets d'un user, tri descendant. */
    @Transactional(readOnly = true)
    public List<FullTcfExamSummaryResponse> listMine(UUID userId, int limit) {
        int safeLimit = Math.max(1, Math.min(HISTORY_LIMIT_MAX, limit));
        List<Attempt> parents = attemptManager.findByUserAndEpreuve(
                userId, EpreuveType.TCF_COMPLET, safeLimit);
        // 🛑 Forme de LISTE : sous-épreuves et niveaux QCM en deux requêtes pour
        // la page entière, jamais une par examen affiché.
        return responseBuilder.buildSummaries(parents);
    }

    /**
     * Dernier examen blanc complet TCF du user (parent TCF_COMPLET le plus
     * récent) avec son détail intégral — sub-attempts mappés, niveau CECRL
     * par épreuve, statut. Renvoie {@code null} si l'utilisateur n'en a
     * jamais lancé.
     *
     * <p>Utilisé par {@code MeService.progressionSummary} pour alimenter le
     * hero "Progression" mobile sans dupliquer la logique de calcul CECRL.
     */
    @Transactional(readOnly = true)
    public FullTcfExamResponse findLatestForUser(UUID userId) {
        List<Attempt> parents = attemptManager.findByUserAndEpreuve(
                userId, EpreuveType.TCF_COMPLET, 1);
        if (parents.isEmpty()) return null;
        return responseBuilder.buildResponse(parents.get(0));
    }

    /**
     * Marque explicitement un sous-attempt EE/EO comme terminé, sans attendre
     * que toutes les submissions soient persistées. Appelé par le mobile
     * après la dernière tâche d'une épreuve productive en mode examen blanc
     * complet — le fire-and-forget de la 3ème submission étant encore en
     * cours côté backend, on ne peut pas se reposer sur le hook automatique
     * de {@code ProductionEvaluationService.finishSubAttemptIfFullExam}.
     *
     * <p>Sans cet appel explicite, le hub de progression mobile resterait
     * bloqué sur EE/EO comme étape courante tant que la 3ème évaluation IA
     * n'aurait pas rendu (~15 s).
     */
    @Transactional
    public FullTcfExamResponse markSubAttemptDone(
            UUID userId, UUID parentAttemptId, EpreuveType epreuve) {
        if (epreuve != EpreuveType.TCF_EE && epreuve != EpreuveType.TCF_EO) {
            throw new BusinessException(
                    "Seuls TCF_EE et TCF_EO peuvent être marqués via cet endpoint.");
        }
        Attempt parent = loadParentAndCheck(userId, parentAttemptId);

        List<Attempt> subs = attemptManager.findSubAttempts(parent.getId());
        Attempt sub = subs.stream()
                .filter(a -> a.getEpreuve() == epreuve)
                .findFirst()
                .orElseThrow(() -> new NotFoundException(
                        "Sous-attempt " + epreuve + " introuvable pour le parent " + parentAttemptId));

        if (sub.getFinishedAt() == null) {
            sub.setFinishedAt(Instant.now());
            sub.setStatus(com.sejourfr.app.enums.AttemptStatus.TERMINE);
            attemptManager.save(sub);
            log.info("Sub-attempt {} marked done explicitly (epreuve={}, parent={})",
                    sub.getId(), epreuve, parent.getId());
        }
        return responseBuilder.buildResponse(parent);
    }

    /**
     * Démarre le chrono d'une épreuve au moment où le candidat la lance
     * (« Commencer · … »). Deux ancres, chacune posée une seule fois :
     * <ul>
     *   <li>{@code parent.timer_started_at} — <b>trace du début réel de
     *       l'examen</b>, posée au tout premier lancement (la CO). Ce n'est
     *       plus l'ancre d'un décompte : l'enveloppe globale de 90 min a été
     *       supprimée (cf. javadoc de classe). Elle sert au bilan et au calcul
     *       de {@code ContinuiteSimulation}.</li>
     *   <li>{@code sub.timer_started_at} + {@code sub.started_at} — ancre du
     *       chrono PROPRE de l'épreuve (CO 20 min / CE 35 min / EE 30 min).
     *       C'est la <b>seule</b> ancre opposable d'une sous-épreuve : les 4
     *       sous-attempts étant créés d'un bloc au lancement de l'examen, leur
     *       {@code started_at} ne dit rien du moment où le candidat les ouvre —
     *       tant que {@code timer_started_at} est null, l'épreuve n'a pas
     *       d'échéance (cf. {@code AttemptChrono}). On recale
     *       {@code started_at} sur le lancement réel pour que le runner
     *       reparte à neuf.</li>
     * </ul>
     *
     * <p>Idempotent par ancre : revenir au hub puis reprendre la même épreuve
     * ne remet pas son chrono à zéro (un {@code timer_started_at} déjà posé
     * n'est jamais retouché) — <b>et le temps a continué de courir pendant
     * l'absence</b>. Il n'existe volontairement aucun flux « recommencer une
     * épreuve interrompue ».
     */
    @Transactional
    public FullTcfExamResponse beginEpreuve(UUID userId, UUID parentAttemptId, EpreuveType epreuve) {
        Attempt parent = loadParentAndCheck(userId, parentAttemptId);
        if (parent.getFinishedAt() != null) {
            return responseBuilder.buildResponse(parent);
        }
        Instant now = Instant.now();
        if (parent.getTimerStartedAt() == null) {
            parent.setTimerStartedAt(now);
            attemptManager.save(parent);
        }
        attemptManager.findSubAttempts(parent.getId()).stream()
                .filter(sub -> sub.getEpreuve() == epreuve
                        && sub.getTimerStartedAt() == null
                        && sub.getFinishedAt() == null)
                .findFirst()
                .ifPresent(sub -> {
                    sub.setTimerStartedAt(now);
                    sub.setStartedAt(now);
                    attemptManager.save(sub);
                });
        log.info("Full TCF exam épreuve begun: parentId={} epreuve={} user={}",
                parent.getId(), epreuve, userId);
        return responseBuilder.buildResponse(parent);
    }

    // ------------------------------------------------------------------------
    // Finalisation
    // ------------------------------------------------------------------------

    /**
     * Marque l'examen comme terminé et persiste le niveau CECRL plancher si
     * toutes les évaluations IA EE/EO sont prêtes. Si une eval est encore en
     * cours, on pose seulement {@code finishedAt} — un appel ultérieur à
     * {@link #get} recalculera et persistera le niveau quand prêt.
     *
     * <p>Pré-requis : les 4 sous-attempts QCM/production ont leur
     * {@code finishedAt}. Les 3 submissions par épreuve productive ne sont pas
     * obligatoirement EVALUATED (le mobile attend en polling sur get).
     */
    @Transactional
    public FullTcfExamResponse finish(UUID userId, UUID parentAttemptId) {
        Attempt parent = loadParentAndCheck(userId, parentAttemptId);

        if (parent.getFinishedAt() == null) {
            List<Attempt> subs = attemptManager.findSubAttempts(parent.getId());
            for (Attempt s : subs) {
                if (s.getFinishedAt() == null) {
                    throw new BusinessException(
                            "Sous-attempt " + s.getEpreuve() + " pas encore terminé.");
                }
            }
            parent.setFinishedAt(Instant.now());
            parent.setStatus(AttemptStatus.TERMINE);
            attemptManager.save(parent);
        }

        // Tente de calculer le CECRL plancher dès maintenant (best effort).
        // Si une eval EE/EO n'est pas EVALUATED, finalCecrlLevel restera NULL.
        return buildAndPersistCecrlIfReady(parent);
    }

    // ------------------------------------------------------------------------
    // Internals
    // ------------------------------------------------------------------------

    private Attempt loadParentAndCheck(UUID userId, UUID parentAttemptId) {
        Attempt parent = attemptManager.findById(parentAttemptId)
                .orElseThrow(() -> new NotFoundException("Examen blanc introuvable : " + parentAttemptId));
        if (parent.getUser() == null || !parent.getUser().getId().equals(userId)) {
            // 404 et non 403 : un 403 confirmait l'EXISTENCE de l'id à qui ne
            // le possède pas (énumération). Aligné sur les endpoints voisins
            // (attempts guest, sous-attempts) qui répondent déjà « introuvable ».
            throw new NotFoundException("Examen blanc introuvable : " + parentAttemptId);
        }
        if (parent.getEpreuve() != EpreuveType.TCF_COMPLET) {
            throw new BusinessException("Attempt " + parentAttemptId + " n'est pas un examen TCF complet.");
        }
        return parent;
    }

    /**
     * Construit la réponse + persiste {@code finalCecrlLevel} sur le parent
     * si toutes les conditions sont réunies (terminé + toutes les évals IA
     * EVALUATED). Utilisé par get/finish — la persistance n'a lieu qu'une
     * fois (idempotent).
     */
    private FullTcfExamResponse buildAndPersistCecrlIfReady(Attempt parent) {
        FullTcfExamResponse response = responseBuilder.buildResponse(parent);
        if (parent.getFinishedAt() != null
                && parent.getFinalCecrlLevel() == null
                && response.status() == FullTcfExamResponse.FullTcfExamStatus.COMPLETED) {
            parent.setFinalCecrlLevel(response.finalCecrlLevel());
            attemptManager.save(parent);
            // 🛑 TROISIEME POINT DE BRANCHEMENT DU PARCOURS (D-24, point 3).
            // Le parent TCF_COMPLET ne passe JAMAIS par doFinish : il n'a pas de
            // questions propres, son resultat est agrege a la lecture. Un
            // branchement sur doFinish seul rate donc entierement l'examen
            // complet (B-9). Ce sont ses SOUS-EPREUVES qui sont signalees —
            // TCF_COMPLET n'est pas une epreuve du TCF IRN et ne porte aucun
            // niveau d'epreuve.
            //
            // ⚠️ ICI, et une seule fois : la persistance du niveau final est le
            // moment ou l'examen DEVIENT complet. Le faire a chaque `get()`
            // aurait coute quatre lectures d'idempotence a chaque polling du
            // mobile, pour rien.
            journeyProductionBridge.onFullExamCompleted(
                    attemptManager.findSubAttempts(parent.getId()));
        }
        return response;
    }

}

package com.sejourfr.app.service.diagnostictcf;

import com.sejourfr.app.config.TcfDiagnosticProperties;
import com.sejourfr.app.dto.TcfReassessmentEligibilityDto;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.TcfDiagnosticStatus;
import com.sejourfr.app.enums.TcfReassessmentBlocker;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.TcfDiagnosticSessionManager;
import com.sejourfr.app.service.LearningPlanPriorityResolver;
import com.sejourfr.app.service.SkillMasteryEngine;
import com.sejourfr.app.service.SkillMasteryResolver;
import com.sejourfr.app.service.SubscriptionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * <b>La boucle de reevaluation</b> (lot L7, spec 10_ §4.6 et 30_ §5.6).
 *
 * <h2>Ce que ce lot ajoute, et ce qu'il n'ajoute pas</h2>
 * <p>Le moteur V4.2 fournissait deja les etats et les preuves ; il manquait le
 * <b>declencheur produit</b>. Rien ici ne mesure : c'est le diagnostic
 * (L4) qui mesure, le Plan qui travaille, et cette classe qui dit <b>quand</b>
 * la mesure vaut la peine d'etre refaite.
 *
 * <h2>Une seule autorite</h2>
 * <p>🛑 Cette classe sert l'eligibilite aux ecrans <b>et</b> garde l'ouverture
 * ({@link #assertPeutOuvrirUnNouveau}). Les deux lisent
 * {@link #eligibilite(UUID)} : impossible qu'un ecran affiche un bouton actif
 * que le serveur refusera, ou l'inverse. C'est exactement le defaut le plus
 * cher du depot — deux copies d'une regle qui divergent — evite par
 * construction.
 *
 * <h2>Les trois portes, et leur nature</h2>
 * <ol>
 *   <li><b>Le premier est offert</b>, sans condition (10_ §4.3). Ce n'est pas
 *       une reevaluation : c'est le diagnostic initial.</li>
 *   <li><b>Les suivants exigent l'acces TCF</b> — porte <i>commerciale</i>,
 *       {@code locked}, l'ecran ouvre le paywall. 🛑 Elle ne verrouille jamais
 *       le resultat deja obtenu : le paywall porte sur la nouvelle mesure.</li>
 *   <li><b>Un delai minimal</b> entre deux passations — porte <i>temporelle</i>,
 *       jamais {@code locked} : payer ne l'ouvre pas. Sans elle, une
 *       reevaluation a volonte ne mesurerait plus une progression, juste le
 *       bruit de deux passations rapprochees.</li>
 * </ol>
 *
 * <h2>Le declencheur du Plan</h2>
 * <p>10_ §4.6 : « 1 tous les 14 jours, <b>ou declenchee par le plan quand une
 * priorite est terminee</b> ». Une etape franchie depuis le dernier diagnostic
 * ouvre donc la porte temporelle <b>avant</b> son terme — et seulement
 * celle-la : l'acces TCF reste exige. C'est le sens de la boucle. Le candidat
 * qui a reellement fait progresser une competence n'attend pas quatorze jours
 * pour le verifier ; celui qui n'a rien fait attend.
 *
 * <p>La notion d'« etape franchie » n'est pas redefinie ici : elle est
 * <b>lue</b> chez {@link LearningPlanPriorityResolver#franchies}, la meme que
 * celle qui coche les etapes du Plan. Une seconde definition aurait fini par
 * ouvrir la reevaluation sur un parcours que le Plan considere en cours.
 */
@Service
@RequiredArgsConstructor
public class TcfReassessmentService {

    private final TcfDiagnosticSessionManager sessionManager;
    private final SubscriptionService subscriptionService;
    private final TcfDiagnosticReadService readService;
    private final LearningPlanObservationManager observationManager;
    private final LearningPlanPriorityResolver priorityResolver;
    private final SkillMasteryResolver masteryResolver;
    private final TcfDiagnosticProperties props;

    /**
     * Le message affiche quand le diagnostic offert est consomme et que le
     * candidat n'a pas l'acces TCF. Verbatim de 10_ §4.6.
     */
    static final String MESSAGE_PREMIUM =
            "Votre diagnostic initial a déjà été réalisé. "
                    + "Passez Premium pour réévaluer votre niveau et mesurer votre progression.";

    /**
     * L'eligibilite complete, telle que l'ecran T11 l'affiche.
     *
     * <p>Lecture seule et sans effet de bord : la lire n'ouvre rien, ne
     * consomme rien, ne date rien.
     */
    @Transactional(readOnly = true)
    public TcfReassessmentEligibilityDto eligibilite(UUID userId) {
        return eligibilite(userId, Instant.now());
    }

    /** Meme calcul, horloge injectee — c'est ce qui rend les bornes testables. */
    @Transactional(readOnly = true)
    public TcfReassessmentEligibilityDto eligibilite(UUID userId, Instant now) {
        int intervalDays = Math.toIntExact(props.getReevaluation().toDays());
        Optional<TcfDiagnosticSession> dernier = sessionManager.findLatest(userId);

        // --- Aucun diagnostic : le premier est offert, et ce n'en est pas une
        // reevaluation. Rien d'autre a evaluer.
        if (dernier.isEmpty()) {
            return new TcfReassessmentEligibilityDto(
                    true, null, false, null, true, false,
                    intervalDays, null, null, false,
                    null, null, null);
        }

        TcfDiagnosticSession last = dernier.get();
        boolean inProgress = last.getStatus() == TcfDiagnosticStatus.IN_PROGRESS;
        UUID lastId = last.getId();
        Instant lastCompletedAt = last.getCompletedAt();
        // 🛑 Le palier du dernier diagnostic se RECALCULE : il n'est pas
        // persiste (« derive serveur ⇒ jamais persiste »). null = non evalue.
        NiveauCecrl lastNiveau = inProgress
                ? null
                : readService.niveauGlobal(readService.sections(last)).orElse(null);

        // --- Un diagnostic est ouvert : l'action est « Reprendre ». Ni porte
        // commerciale ni delai — il est deja paye et deja commence.
        if (inProgress) {
            return new TcfReassessmentEligibilityDto(
                    true, null, false, null, false, true,
                    intervalDays, null, null, false,
                    lastId, null, null);
        }

        // --- Porte commerciale. Elle passe AVANT le delai : annoncer « dans 3
        // jours » a qui n'a pas l'acces promettrait une gratuite qui n'existe
        // pas.
        if (!subscriptionService.hasTcf(userId)) {
            return new TcfReassessmentEligibilityDto(
                    false, TcfReassessmentBlocker.PREMIUM_REQUIRED, true, MESSAGE_PREMIUM,
                    false, false, intervalDays, null, null, false,
                    lastId, lastCompletedAt, lastNiveau);
        }

        // --- Porte temporelle, et son unique derogation : une priorite du Plan
        // terminee depuis le dernier diagnostic.
        Instant depuis = lastCompletedAt != null ? lastCompletedAt : last.getStartedAt();
        boolean parLePlan = unePrioriteTermineeDepuis(userId, depuis);
        Instant ouvrableA = last.getStartedAt().plus(props.getReevaluation());

        if (!parLePlan && now.isBefore(ouvrableA)) {
            int jours = joursRestants(now, ouvrableA);
            return new TcfReassessmentEligibilityDto(
                    false, TcfReassessmentBlocker.INTERVAL_NOT_ELAPSED, false,
                    messageDelai(intervalDays, jours),
                    false, false, intervalDays, ouvrableA, jours, false,
                    lastId, lastCompletedAt, lastNiveau);
        }

        return new TcfReassessmentEligibilityDto(
                true, null, false, null, false, false,
                intervalDays,
                // La date reste servie quand le Plan a ouvert la porte en
                // avance : c'est ce qui permet a l'ecran de dire POURQUOI elle
                // est ouverte, au lieu d'un bouton qui apparait sans raison.
                parLePlan && now.isBefore(ouvrableA) ? ouvrableA : null,
                parLePlan && now.isBefore(ouvrableA) ? joursRestants(now, ouvrableA) : null,
                parLePlan,
                lastId, lastCompletedAt, lastNiveau);
    }

    /**
     * Le garde d'ouverture. <b>Meme calcul</b> que l'eligibilite servie, et
     * meme phrase : le refus ne peut pas contredire l'ecran.
     */
    public void assertPeutOuvrirUnNouveau(UUID userId) {
        TcfReassessmentEligibilityDto e = eligibilite(userId);
        if (!e.canStart()) {
            throw new BusinessException(e.message());
        }
    }

    /**
     * Une etape du parcours a-t-elle ete franchie depuis {@code depuis} ?
     *
     * <p>« Priorite terminee » = competence dont le <b>transfert est prouve</b>,
     * exactement la definition du Plan. On ne la reecrit pas : deux lectures du
     * meme historique se sont deja contredites en production (cf. le journal de
     * {@link LearningPlanPriorityResolver#franchies}).
     *
     * <p>Une seule requete — l'historique complet, deja indexe — puis deux
     * fonctions pures. Aucune lecture du Plan complet : le construire pour
     * repondre « oui / non » couterait une quinzaine de resolveurs.
     */
    private boolean unePrioriteTermineeDepuis(UUID userId, Instant depuis) {
        List<LearningPlanObservation> historique =
                observationManager.findAllByUserWithSkill(userId);
        if (historique.isEmpty()) {
            return false;
        }
        Map<UUID, LearningPlanObservation> latest =
                priorityResolver.latestObservedBySkill(historique);
        Map<UUID, SkillMasteryEngine.SkillMastery> mastery =
                masteryResolver.fromObservations(historique, latest.keySet());
        return priorityResolver.franchies(historique, mastery).stream()
                .anyMatch(o -> o.getObservedAt() != null && o.getObservedAt().isAfter(depuis));
    }

    /**
     * Jours restants, arrondis au superieur : il reste « 1 jour » tant qu'il
     * reste une heure. Un arrondi a l'inferieur afficherait « 0 jour » sur un
     * bouton encore refuse.
     */
    private static int joursRestants(Instant now, Instant ouvrableA) {
        long minutes = Duration.between(now, ouvrableA).toMinutes();
        return (int) Math.max(1, (minutes + 60L * 24 - 1) / (60L * 24));
    }

    private static String messageDelai(int intervalDays, int jours) {
        return "Une réévaluation est possible tous les " + intervalDays
                + " jours. Vous pourrez en relancer une dans " + jours + " jour"
                + (jours > 1 ? "s" : "") + ".";
    }
}

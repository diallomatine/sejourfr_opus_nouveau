package com.sejourfr.app.service;

import com.sejourfr.app.dto.FullTcfExamResponse;
import com.sejourfr.app.dto.FullTcfExamSummaryResponse;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.ContinuiteSimulation;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.AnswerManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.service.attempt.AttemptChrono;
import lombok.RequiredArgsConstructor;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import org.springframework.stereotype.Component;

/**
 * Construit le read-model de l'examen blanc TCF complet ({@link FullTcfExamResponse}
 * / {@link FullTcfExamSummaryResponse}) à partir du parent {@code TCF_COMPLET} et
 * de ses 4 sous-attempts : mapping des sous-épreuves, calcul du statut agrégé,
 * scoring CO/CE et plancher CECRL. Sans état ni persistance — la finalisation
 * (pose de {@code finalCecrlLevel}) reste portée par {@link FullTcfExamService}.
 */
@Component
@RequiredArgsConstructor
public class FullTcfExamResponseBuilder {

    /** Nombre de tâches attendues par épreuve productive (3 comme le vrai TCF). */
    private static final int EXPECTED_PRODUCTION_SUBMISSIONS =
            ProductionBilanService.EXPECTED_TASKS_PER_EPREUVE;

    /** Épreuves attendues dans un examen complet : CO + CE + EE + EO. */
    public static final int EXPECTED_EPREUVES = 4;

    private final AttemptManager attemptManager;
    private final AnswerManager answerManager;
    private final ProductionSubmissionManager productionSubmissionManager;
    private final TcfLevelEstimatorService levelEstimator;
    private final ProductionBilanService productionBilanService;

    /** Ordre canonique d'affichage — et de déroulé — des 4 épreuves. */
    private static final List<EpreuveType> ORDRE_EPREUVES = List.of(
            EpreuveType.TCF_CO, EpreuveType.TCF_CE,
            EpreuveType.TCF_EE, EpreuveType.TCF_EO);

    public FullTcfExamResponse buildResponse(Attempt parent) {
        List<Attempt> subs = attemptManager.findSubAttempts(parent.getId());
        Map<EpreuveType, Sous> mapped = new EnumMap<>(EpreuveType.class);
        for (Attempt sub : subs) {
            mapped.put(sub.getEpreuve(), mapSubAttempt(sub, parent.isProductionLocked()));
        }

        // Ordre canonique d'affichage : CO → CE → EE → EO.
        List<FullTcfExamResponse.SubAttempt> ordered = new ArrayList<>();
        Set<EpreuveType> jamaisOuvertes = EnumSet.noneOf(EpreuveType.class);
        for (EpreuveType e : ORDRE_EPREUVES) {
            Sous s = mapped.get(e);
            if (s == null) continue;
            ordered.add(s.dto());
            if (s.jamaisOuverte()) jamaisOuvertes.add(e);
        }

        FullTcfExamResponse.FullTcfExamStatus status = computeStatus(parent, ordered, jamaisOuvertes);
        NiveauCecrl finalCecrl = parent.getFinalCecrlLevel();
        if (finalCecrl == null && status == FullTcfExamResponse.FullTcfExamStatus.COMPLETED) {
            finalCecrl = floorOfCecrls(ordered);
        }
        // Plafond IRN B2, y compris pour un finalCecrlLevel persisté avant le
        // cap (données antérieures où EE/EO pouvait remonter C1/C2).
        finalCecrl = levelEstimator.capB2(finalCecrl);
        int counted = countEpreuvesInFloor(ordered);
        return new FullTcfExamResponse(
                parent.getId(),
                parent.getStartedAt(),
                parent.getTimerStartedAt(),
                parent.getFinishedAt(),
                finalCecrl,
                status,
                continuite(parent, ordered),
                counted,
                EXPECTED_EPREUVES,
                counted < EXPECTED_EPREUVES,
                ordered);
    }

    public FullTcfExamSummaryResponse buildSummary(Attempt parent) {
        FullTcfExamResponse full = buildResponse(parent);
        return new FullTcfExamSummaryResponse(
                full.id(), full.startedAt(), full.finishedAt(),
                full.finalCecrlLevel(), full.status(),
                parent.getSlotNumber(),
                full.finalLevelPartial(),
                full.continuite());
    }

    /**
     * L'examen a-t-il été enchaîné d'une traite ? Dérivé à la lecture, jamais
     * persisté. {@code null} tant que l'examen n'est pas terminé : la question
     * ne se pose qu'au moment de restituer le résultat.
     */
    private static ContinuiteSimulation continuite(
            Attempt parent, List<FullTcfExamResponse.SubAttempt> ordered) {
        if (parent.getFinishedAt() == null) return null;
        return ContinuiteSimulation.of(ordered.stream()
                .map(s -> new ContinuiteSimulation.Etape(s.timerStartedAt(), s.finishedAt()))
                .toList());
    }

    /**
     * Sous-épreuve mappée, plus l'unique information dérivée qui n'a pas sa
     * place dans le DTO : cette épreuve a-t-elle été <b>close sans jamais avoir
     * été ouverte</b> ? Elle ne sert qu'au statut agrégé — pour une CO/CE, un
     * {@code cecrlLevel} null signifie normalement « notation pas encore
     * décidée » (PENDING_EVALUATIONS), et une porte jamais franchie ne doit pas
     * y bloquer l'examen indéfiniment.
     */
    private record Sous(FullTcfExamResponse.SubAttempt dto, boolean jamaisOuverte) {
    }

    /**
     * Épreuve <b>close sans avoir jamais été ouverte</b> : {@code timer_started_at}
     * absent (elle n'a jamais été lancée, cf. {@link AttemptChrono} — pour un
     * sous-attempt c'est la seule ancre) <b>et</b> rien de rendu (aucune
     * réponse en CO/CE, aucune soumission en EE/EO). C'est le cas du candidat
     * qui fait la CO et la CE puis quitte : les fronts clôturent les épreuves
     * restantes pour permettre l'abandon volontaire (cf.
     * {@code FullTcfExamService.markSubAttemptDone}), sans que le candidat ait
     * jamais vu le sujet.
     *
     * <p>Ne s'évalue que sur une épreuve TERMINÉE : tant qu'elle ne l'est pas,
     * l'examen est de toute façon {@code IN_PROGRESS} et aucun niveau n'est
     * calculé — inutile d'aller interroger la base.
     *
     * <p>⚠️ Les deux conditions comptent. Les sous-attempts antérieurs au chrono
     * par épreuve portent tous {@code timer_started_at} null : sans le second
     * critère, on effacerait le niveau d'épreuves réellement passées.
     */
    private boolean jamaisOuverteQcm(Attempt sub) {
        return sub.getFinishedAt() != null
                && sub.getTimerStartedAt() == null
                && !answerManager.hasAnyAnswer(sub.getId());
    }

    private Sous mapSubAttempt(Attempt sub, boolean parentProductionLocked) {
        EpreuveType e = sub.getEpreuve();
        // Le verrou ne concerne que les épreuves productives EE/EO.
        boolean locked = parentProductionLocked
                && (e == EpreuveType.TCF_EE || e == EpreuveType.TCF_EO);
        if (locked) {
            // Épreuve VERROUILLÉE : elle n'a pas été PASSÉE, elle a été fermée
            // par le freemium. Elle n'a donc AUCUN niveau. La compter
            // A1_NON_ATTEINT (ce que faisait bilanEpreuveTerminee sur zéro
            // tâche) restituait un verrou commercial comme un verdict de
            // langue : « ton niveau TCF IRN : A1 non atteint » à côté d'un
            // cadenas « réservé à l'abonnement ». Le verrou lui-même ne bouge
            // pas — seule la restitution change.
            // Épreuve verrouillée : jamais lancée, donc aucune donnée de temps
            // — un chrono sur une porte fermée n'aurait aucun sens.
            return new Sous(new FullTcfExamResponse.SubAttempt(
                    sub.getId(), e, sub.getFinishedAt(), null,
                    null, null, null, 0, List.of(), true,
                    null, null, null), false);
        }
        if (e == EpreuveType.TCF_CO || e == EpreuveType.TCF_CE) {
            // Même raisonnement que le verrou ci-dessus, appliqué à l'autre
            // porte jamais franchie : une épreuve close SANS avoir jamais été
            // ouverte n'a pas été PASSÉE, donc elle n'a AUCUN niveau. La
            // compter A1_NON_ATTEINT (0 réponse → 0 % → borne basse) restituait
            // une absence comme un verdict de langue. Doctrine du dépôt :
            // null = inconnu, jamais mauvais.
            boolean jamaisOuverte = jamaisOuverteQcm(sub);
            // Source de vérité : cecrl_level posé à la finalisation par
            // TcfLevelEstimatorService. Fallback weightedScoreToCecrl pour les
            // sous-attempts finis avant V416 (cecrl_level encore NULL).
            NiveauCecrl level = null;
            if (sub.getFinishedAt() != null && !jamaisOuverte) {
                level = sub.getCecrlLevel() != null
                        ? sub.getCecrlLevel()
                        : weightedScoreToCecrl(sub.getWeightedScore(), sub.getMaxWeightedScore());
                level = levelEstimator.capB2(level);
            }
            return new Sous(new FullTcfExamResponse.SubAttempt(
                    sub.getId(), e, sub.getFinishedAt(), level,
                    sub.getWeightedScore(), sub.getMaxWeightedScore(),
                    calibratedScoreOf(sub),
                    null, List.of(), locked,
                    sub.getTimeLimitSeconds(), sub.getTimerStartedAt(),
                    AttemptChrono.echeance(sub)), jamaisOuverte);
        }
        // EE / EO : on compte les tâches EVALUATED pour le niveau CECRL
        // ET on remonte les ids des FAILED — le mobile propose un bouton
        // "Réessayer cette évaluation" qui appelle
        // POST /api/production-submissions/{id}/retry pour chacune. Tant
        // qu'une submission est FAILED, le bilan affiche un état partiel
        // (pas de tolérance silencieuse — l'utilisateur voit le problème).
        List<ProductionSubmission> submissions = productionSubmissionManager.findByAttemptId(sub.getId());
        List<UUID> failedIds = new ArrayList<>();
        boolean inFlight = false;
        for (ProductionSubmission s : submissions) {
            if (s.getStatut() == SubmissionStatut.FAILED) {
                failedIds.add(s.getId());
            } else if (s.getStatut() != SubmissionStatut.EVALUATED) {
                inFlight = true; // SUBMITTED / TRANSCRIBING / EVALUATING
            }
        }
        // Épreuve close SANS avoir jamais été ouverte : aucun niveau (cf.
        // jamaisOuverteQcm — même règle, mais « rien de rendu » se lit ici sur
        // les soumissions, déjà chargées).
        boolean jamaisOuverte = sub.getFinishedAt() != null
                && sub.getTimerStartedAt() == null
                && submissions.isEmpty();
        Map<Integer, AiEvaluation> evalsByTache = jamaisOuverte
                ? Map.of()
                : productionBilanService.latestEvalsByTache(submissions);
        int evaluatedCount = evalsByTache.size();
        // Niveau d'épreuve = moyenne pondérée des compétences des 3 tâches
        // (cf. ProductionBilanService), plafonné B2. La note brute reste
        // stockée intacte. Épreuve TERMINÉE incomplète (chrono écoulé, abandon)
        // sans pipeline IA en cours ni FAILED à retenter : les tâches non
        // rendues comptent 0 (« le reste noté 0 ») — y compris zéro soumission
        // → A1_NON_ATTEINT. ⚠️ Sauf si elle n'a JAMAIS été ouverte : le
        // candidat n'a pas vu le sujet, ce n'est pas un abandon mais une
        // absence, et une absence n'a pas de niveau.
        NiveauCecrl level;
        if (jamaisOuverte) {
            level = null;
        } else if (evaluatedCount == EXPECTED_PRODUCTION_SUBMISSIONS) {
            level = levelEstimator.capB2(productionBilanService.bilanEpreuve(evalsByTache));
        } else if (sub.getFinishedAt() != null && !inFlight && failedIds.isEmpty()) {
            level = levelEstimator.capB2(productionBilanService.bilanEpreuveTerminee(evalsByTache));
        } else {
            level = null;
        }
        // EE : chrono d'épreuve (30 min) ancré sur son lancement réel.
        // EO : timeLimitSeconds NULL — pas de chrono d'épreuve, le temps se
        // compte par tâche (production_tasks.dureeMaxSec) et ne démarre qu'au
        // lancement de la tâche. `timerStartedAt` reste servi : il dit quand
        // l'épreuve a été ouverte, ce qui sert au statut de continuité.
        return new Sous(new FullTcfExamResponse.SubAttempt(
                sub.getId(), e, sub.getFinishedAt(), level,
                null, null, null, evaluatedCount, failedIds, locked,
                sub.getTimeLimitSeconds(), sub.getTimerStartedAt(),
                AttemptChrono.echeance(sub)), jamaisOuverte);
    }

    /**
     * Score calibré 100-499 d'une sous-épreuve QCM (CO / CE) — l'échelle du
     * relevé TCF, seule lisible par un candidat. Délégué à
     * {@link TcfLevelEstimatorService}, comme {@code AttemptMapper} le fait pour
     * les examens module : la correction du hasard et les bornes n'existent
     * qu'à un seul endroit, deux copies finiraient par diverger.
     *
     * <p>{@code null} tant que le score pondéré n'est pas posé (épreuve en
     * cours, ou finalisée sans score) : le service rendrait alors 100, ce qui
     * afficherait « 100/499 » là où on ne sait rien.
     */
    private Integer calibratedScoreOf(Attempt sub) {
        if (sub.getWeightedScore() == null || sub.getMaxWeightedScore() == null) return null;
        return levelEstimator.calibratedScore(sub.getWeightedScore(), sub.getMaxWeightedScore());
    }

    private FullTcfExamResponse.FullTcfExamStatus computeStatus(
            Attempt parent, List<FullTcfExamResponse.SubAttempt> subs,
            Set<EpreuveType> jamaisOuvertes) {
        // 4 sous-attempts attendus (CO, CE, EE, EO). Si un manque ou n'est
        // pas fini → IN_PROGRESS.
        if (subs.size() < EXPECTED_EPREUVES) return FullTcfExamResponse.FullTcfExamStatus.IN_PROGRESS;
        for (FullTcfExamResponse.SubAttempt s : subs) {
            if (s.finishedAt() == null) {
                return FullTcfExamResponse.FullTcfExamStatus.IN_PROGRESS;
            }
        }
        // Tous les sous-attempts ont `finishedAt`. Pour chaque épreuve productive,
        // on attend que TOUT soit décidé : soit EVALUATED, soit FAILED (qu'on
        // expose via `failedSubmissionIds` pour permettre un retry mobile).
        // PENDING_EVALUATIONS ne reste que pendant la fenêtre où le pipeline IA
        // tourne encore (statuts SUBMITTED / TRANSCRIBING / EVALUATING).
        for (FullTcfExamResponse.SubAttempt s : subs) {
            if (s.epreuve() == EpreuveType.TCF_EE || s.epreuve() == EpreuveType.TCF_EO) {
                // PENDING uniquement s'il reste une submission RÉELLEMENT dans le
                // pipeline IA (SUBMITTED / TRANSCRIBING / EVALUATING). Un examen
                // abandonné avec moins de 3 (voire 0) submissions n'a rien en
                // cours → il est aussi complet qu'il le sera. Les FAILED sont
                // terminales (retry exposé via failedSubmissionIds), pas pending.
                if (hasInFlightProduction(s.attemptId())) {
                    return FullTcfExamResponse.FullTcfExamStatus.PENDING_EVALUATIONS;
                }
            } else if (s.cecrlLevel() == null && !jamaisOuvertes.contains(s.epreuve())) {
                // CO/CE sans niveau calculé : finishedAt présent mais weightedScore manquant.
                // Une épreuve close sans avoir jamais été ouverte est, elle,
                // définitivement décidée : elle n'aura jamais de niveau, et
                // l'attendre laisserait l'examen en PENDING pour toujours.
                return FullTcfExamResponse.FullTcfExamStatus.PENDING_EVALUATIONS;
            }
        }
        return parent.getFinishedAt() != null
                ? FullTcfExamResponse.FullTcfExamStatus.COMPLETED
                : FullTcfExamResponse.FullTcfExamStatus.PENDING_EVALUATIONS;
    }

    /** Vrai s'il existe au moins une submission de cet attempt encore dans le
     *  pipeline IA (non terminale). FAILED et EVALUATED sont terminales. */
    private boolean hasInFlightProduction(UUID attemptId) {
        for (ProductionSubmission s : productionSubmissionManager.findByAttemptId(attemptId)) {
            SubmissionStatut st = s.getStatut();
            if (st == SubmissionStatut.SUBMITTED
                    || st == SubmissionStatut.TRANSCRIBING
                    || st == SubmissionStatut.EVALUATING) {
                return true;
            }
        }
        return false;
    }

    /**
     * Conversion score pondéré CO/CE → niveau CECRL.
     * <ul>
     *   <li>≥ 80 % → B2</li>
     *   <li>≥ 60 % → B1</li>
     *   <li>≥ 40 % → A2</li>
     *   <li>≥ 20 % → A1</li>
     *   <li>&lt; 20 % → A1_NON_ATTEINT</li>
     * </ul>
     * Seuils calibrés sur l'esprit du TCF (60 % = B1 d'usage). Le vrai TCF
     * IRN utilise une grille interne non publique — ces seuils sont
     * volontairement simples pour rester explicables à l'utilisateur.
     */
    private NiveauCecrl weightedScoreToCecrl(Integer score, Integer maxScore) {
        if (score == null || maxScore == null || maxScore <= 0) return null;
        double ratio = (double) score / (double) maxScore;
        if (ratio >= 0.80) return NiveauCecrl.B2;
        if (ratio >= 0.60) return NiveauCecrl.B1;
        if (ratio >= 0.40) return NiveauCecrl.A2;
        if (ratio >= 0.20) return NiveauCecrl.A1;
        return NiveauCecrl.A1_NON_ATTEINT;
    }

    /**
     * Plancher des épreuves RÉELLEMENT passées. Deux exclusions, pour la même
     * raison — on ne planchérie que sur ce qui a été mesuré :
     * <ul>
     *   <li>épreuve {@code locked} : fermée par le freemium, jamais passée ;</li>
     *   <li>niveau {@code null} : inconnu (évaluations IA échouées ou encore en
     *       vol, <b>ou épreuve close sans avoir jamais été ouverte</b>), et
     *       {@code min()} ignore déjà l'inconnu.</li>
     * </ul>
     * Le nombre d'épreuves effectivement comptées est exposé aux fronts
     * ({@code epreuvesCountedInFinalLevel}) pour qu'ils n'affirment pas « le
     * plus bas de tes 4 épreuves » quand il n'y en a que 3.
     */
    private NiveauCecrl floorOfCecrls(List<FullTcfExamResponse.SubAttempt> subs) {
        NiveauCecrl floor = null;
        for (FullTcfExamResponse.SubAttempt s : subs) {
            if (s.locked()) continue;
            floor = levelEstimator.min(floor, s.cecrlLevel());
        }
        return floor;
    }

    /** Épreuves qui portent réellement un niveau et entrent dans le plancher. */
    private static int countEpreuvesInFloor(List<FullTcfExamResponse.SubAttempt> subs) {
        int counted = 0;
        for (FullTcfExamResponse.SubAttempt s : subs) {
            if (!s.locked() && s.cecrlLevel() != null) counted++;
        }
        return counted;
    }
}

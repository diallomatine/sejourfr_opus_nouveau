package com.sejourfr.app.service.journey;

import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyAssessmentKind;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.service.ProductionAccessService;
import com.sejourfr.app.service.ProductionBilanService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;
import java.util.Map;

/**
 * <b>Ce qu'une epreuve de production apprend au parcours a sa CLOTURE</b> —
 * point de branchement n&deg;2 de D-24.
 *
 * <h2>Le trou que ce composant bouche (D-11, dette A16)</h2>
 * <p>{@code AttemptInteractionService.doFinish} a une <b>sortie anticipee</b>
 * pour EE/EO : ces epreuves n'ont ni questions ni score QCM, on pose juste
 * {@code finishedAt} et {@code TERMINE}, et on <b>sort</b> — la suite de
 * {@code doFinish}, donc le branchement du parcours, n'est jamais atteinte. Le
 * parcours n'apprenait donc l'epreuve que par la voie de l'<b>analyse</b>
 * ({@code DiagnosticProductionAnalysisService}), qui exige les <b>trois</b>
 * taches corrigees. Une epreuve <b>abandonnee</b> — une ou deux taches rendues,
 * session close a l'echeance — n'ouvrait aucun lot, et le travail que ses
 * priorites designaient etait perdu.
 *
 * <h2>🛑 Ni doublon, ni course</h2>
 * <p>Deux voies peuvent signaler la meme epreuve. Elles ne se marchent pas sur
 * les pieds pour deux raisons, et il faut les deux :
 * <ul>
 *   <li><b>l'idempotence</b> du parcours ({@code journey_assessment_event}
 *       unique sur {@code (journey_id, source_assessment_id)}) : la seconde
 *       retombe sur la premiere, sans effet ;</li>
 *   <li><b>l'attente des corrections en cours</b> : tant qu'une soumission n'est
 *       ni corrigee ni en echec, cette voie-ci <b>se tait</b>. Sinon un candidat
 *       qui termine sa session pendant que la 3<sup>e</sup> analyse tourne
 *       enregistrerait l'evaluation <b>avant</b> que ses priorites soient
 *       ecrites — l'idempotence ferait alors taire la voie de l'analyse, et les
 *       priorites de l'epreuve seraient perdues pour de bon. C'est exactement
 *       B-13 : on se branche <b>apres</b> l'ecriture des observations.</li>
 * </ul>
 *
 * <h2>🛑 Et surtout : aucune mesure inventee (D-24, point 4)</h2>
 * <p>Une epreuve dont <b>aucune</b> tache n'a ete corrigee ne signale
 * <b>rien</b>. C'est ce qui exclut {@code lockProductionSubAttempts} : il pose
 * {@code TERMINE} sur les EE/EO d'un examen complet gratuit <b>sans qu'aucun
 * examen n'ait ete passe</b>. L'inclure aurait invente une mesure — et clos, au
 * passage, l'etape « Évaluer mon niveau » d'une epreuve que le candidat n'a
 * jamais ouverte.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class JourneyProductionBridge {

    private final ProductionSubmissionManager submissionManager;
    private final ProductionBilanService bilanService;
    private final JourneyService journeyService;

    /**
     * <b>D'ou vient cette evaluation</b> — l'information que
     * {@code source_assessment_id} ne porte pas a lui seul.
     *
     * <p>🛑 <b>Une seule autorite</b> : une section de <b>diagnostic complet</b>
     * et une sous-epreuve d'<b>examen blanc complet</b> sont l'une et l'autre
     * des attempts a part entiere, et c'est ce qui permet a une evaluation de ne
     * mesurer qu'<b>une</b> epreuve. La regle vivait en deux copies (fin de QCM,
     * fin d'analyse de production) ; le troisieme branchement l'a ramenee ici.
     */
    public static JourneyAssessmentKind natureDeLEvaluation(Attempt attempt) {
        if (attempt.getTcfDiagnostic() != null) return JourneyAssessmentKind.FULL_DIAGNOSTIC;
        if (attempt.getParentAttempt() != null) return JourneyAssessmentKind.MOCK_EXAM;
        return JourneyAssessmentKind.SECTION_EXAM;
    }

    /**
     * Une epreuve de production vient d'etre <b>definitivement close</b>.
     *
     * <p><b>Best-effort</b>, comme tout ce qui entoure une cloture : le parcours
     * ecrit dans sa propre transaction et son echec est avale ici. La cloture de
     * la session et la reponse HTTP n'en dependent pas.
     *
     * @param attempt la session EE/EO close. Rien n'est fait si ce n'est pas une
     *                <b>session d'examen</b> (R1, D-6 : un entrainement libre de
     *                production ne cree jamais d'etape), si aucune tache n'a ete
     *                corrigee, ou si une correction est encore en cours.
     */
    public void onProductionAttemptClosed(Attempt attempt) {
        if (attempt == null || attempt.getUser() == null) return;
        EpreuveType epreuve = attempt.getEpreuve();
        if (epreuve != EpreuveType.TCF_EE && epreuve != EpreuveType.TCF_EO) return;
        // 🛑 R1 — seul un EXAMEN alimente la file. Le predicat est celui de
        // ProductionAccessService (slot pose au demarrage, ou parent d'examen
        // complet), jamais une seconde definition.
        if (!ProductionAccessService.isExamSession(attempt)) return;
        try {
            List<ProductionSubmission> soumissions =
                    submissionManager.findByAttemptId(attempt.getId());
            if (enAttenteDeCorrection(soumissions)) {
                log.debug("Parcours : epreuve {} close, correction en cours — la voie de "
                        + "l'analyse signalera (B-13)", attempt.getId());
                return;
            }
            Map<Integer, AiEvaluation> parTache = bilanService.latestEvalsByTache(soumissions);
            if (parTache.isEmpty()) {
                // Aucune tache corrigee : rien n'a ete passe. Une epreuve
                // pre-terminee (examen complet gratuit, EE/EO verrouillees)
                // passe TOUJOURS par ici, et ne doit RIEN declencher.
                return;
            }
            Instant fin = attempt.getFinishedAt() != null
                    ? attempt.getFinishedAt()
                    : Instant.now();
            journeyService.onAssessmentCompleted(
                    attempt.getUser().getId(),
                    new JourneyEvaluation(attempt.getId(), natureDeLEvaluation(attempt),
                            epreuve, fin));
        } catch (RuntimeException echec) {
            log.warn("Parcours TCF non mis a jour a la cloture de l'epreuve {} : {}",
                    attempt.getId(), echec.toString());
        }
    }

    /**
     * <b>Un examen blanc TCF complet vient d'etre complete</b> — point de
     * branchement n&deg;3 de D-24.
     *
     * <h3>🛑 Le parent {@code TCF_COMPLET} ne passe JAMAIS par {@code doFinish}</h3>
     * <p>Il n'a pas de questions propres : son resultat est agrege a la lecture
     * par {@code FullTcfExamResponseBuilder}. Un branchement sur
     * {@code doFinish} seul rate donc entierement l'examen complet — c'est le
     * constat B-9 de l'audit, et c'est pourquoi « un branchement sur doFinish
     * seul est un echec de phase ».
     *
     * <h3>Ce sont les SOUS-EPREUVES qui sont signalees, jamais le parent</h3>
     * <p>{@code TCF_COMPLET} n'est pas une epreuve du TCF IRN : il ne porte
     * aucun niveau d'epreuve, {@code NiveauActuelEpreuveResolver} le dit
     * explicitement, et {@code chk_journey_assessment_exam_type} le refuserait.
     * Chaque sous-attempt, lui, est une evaluation a part entiere — « une
     * evaluation mesure exactement UNE epreuve ».
     *
     * <p>Les sous-epreuves CO/CE sont normalement deja signalees par
     * {@code doFinish} ; ce passage-ci est leur <b>filet</b> : le branchement de
     * {@code doFinish} est best-effort, et rien ne le rejoue. L'idempotence du
     * parcours rend le doublon sans effet.
     *
     * @param sousEpreuves les quatre sous-attempts du parent. Ceux qui ne sont
     *                     pas termines sont ignores ; les EE/EO passent par
     *                     {@link #onProductionAttemptClosed}, qui refuse
     *                     d'inventer une mesure sur une epreuve pre-terminee.
     */
    public void onFullExamCompleted(List<Attempt> sousEpreuves) {
        if (sousEpreuves == null) return;
        for (Attempt sous : sousEpreuves) {
            if (sous == null || sous.getFinishedAt() == null || sous.getUser() == null) continue;
            EpreuveType epreuve = sous.getEpreuve();
            if (epreuve == null) continue;
            switch (epreuve) {
                case TCF_CO, TCF_CE -> signalerLaComprehension(sous);
                case TCF_EE, TCF_EO -> onProductionAttemptClosed(sous);
                default -> { }
            }
        }
    }

    /** Best-effort : l'agregation de l'examen complet ne depend pas du parcours. */
    private void signalerLaComprehension(Attempt sous) {
        try {
            journeyService.onAssessmentCompleted(
                    sous.getUser().getId(),
                    new JourneyEvaluation(sous.getId(), natureDeLEvaluation(sous),
                            sous.getEpreuve(), sous.getFinishedAt()));
        } catch (RuntimeException echec) {
            log.warn("Parcours TCF non mis a jour pour la sous-epreuve {} : {}",
                    sous.getId(), echec.toString());
        }
    }

    /**
     * Une soumission attend-elle encore son correcteur ?
     *
     * <p>{@code FAILED} n'est <b>pas</b> une attente : un echec technique ne
     * livrera jamais rien, et attendre indefiniment ferait perdre les priorites
     * des taches qui, elles, ont ete corrigees.
     */
    private static boolean enAttenteDeCorrection(List<ProductionSubmission> soumissions) {
        for (ProductionSubmission soumission : soumissions) {
            SubmissionStatut statut = soumission.getStatut();
            if (statut == SubmissionStatut.SUBMITTED
                    || statut == SubmissionStatut.TRANSCRIBING
                    || statut == SubmissionStatut.EVALUATING) {
                return true;
            }
        }
        return false;
    }
}

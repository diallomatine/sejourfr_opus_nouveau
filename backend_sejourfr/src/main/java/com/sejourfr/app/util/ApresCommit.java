package com.sejourfr.app.util;

import lombok.extern.slf4j.Slf4j;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

/**
 * <b>Signaler au parcours ce que la transaction courante vient d'écrire —
 * une fois qu'elle l'a VRAIMENT écrit.</b>
 *
 * <h2>Le défaut que cette classe ferme (2026-09-26, mesuré en base)</h2>
 * <p>Les crochets du parcours ({@code JourneyService.onAssessmentCompleted},
 * {@code onTrainingProgress}…) tournent en {@code REQUIRES_NEW}. Appelés
 * <b>depuis</b> la transaction qui clôt l'examen, ils lisaient la base
 * <b>avant son commit</b> : l'attempt y était encore {@code EN_COURS}, sans
 * {@code finished_at}. Conséquence observée : l'examen blanc CO fermait bien
 * l'étape d'examen du bloc, puis R12 ({@code ajouterLesEpreuvesNonMesurees})
 * interrogeait « la CO est-elle mesurée ? », obtenait « non », et recréait
 * aussitôt une étape « Examen à passer » CO — le Plan semblait n'avoir rien
 * vu, pendant que l'Accueil (lu après le commit) était juste. Et comme le
 * journal rend le traitement idempotent, rien ne le rejouait jamais.
 *
 * <h2>La règle</h2>
 * <ul>
 *   <li>une transaction synchronisée est active ⇒ l'action part en
 *       {@code afterCommit} : elle voit tout ce que l'appelant a écrit, et
 *       rien si l'appelant a annulé ;</li>
 *   <li>aucune transaction ⇒ l'action part tout de suite (runner async,
 *       test unitaire).</li>
 * </ul>
 *
 * <p>🛑 <b>Best-effort, sans exception</b> : une exception levée en
 * {@code afterCommit} remonterait à l'appelant d'une transaction <b>déjà
 * validée</b> — la correction du QCM serait faite mais la réponse HTTP en
 * erreur. L'échec est donc journalisé et avalé ici, pour tous les appelants.
 *
 * <p>⚠️ L'action doit ouvrir sa <b>propre</b> transaction
 * ({@code REQUIRES_NEW}) : en {@code afterCommit}, les ressources de la
 * transaction close sont encore liées au fil.
 */
@Slf4j
public final class ApresCommit {

    private ApresCommit() {
    }

    /**
     * @param quoi   libellé court pour le journal en cas d'échec
     * @param action l'effet à produire, dans sa propre transaction
     */
    public static void executer(String quoi, Runnable action) {
        Runnable protegee = () -> {
            try {
                action.run();
            } catch (RuntimeException echec) {
                log.warn("{} : echec apres commit — {}", quoi, echec.toString());
            }
        };
        if (TransactionSynchronizationManager.isSynchronizationActive()
                && TransactionSynchronizationManager.isActualTransactionActive()) {
            TransactionSynchronizationManager.registerSynchronization(
                    new TransactionSynchronization() {
                        @Override
                        public void afterCommit() {
                            protegee.run();
                        }
                    });
            return;
        }
        protegee.run();
    }
}

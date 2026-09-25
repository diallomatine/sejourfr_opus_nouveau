package com.sejourfr.app.service.email;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.manager.CivicDiagnosticSessionManager;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.TcfDiagnosticSessionManager;
import com.sejourfr.app.service.email.event.DiagnosticPlanReadyEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * <b>« Ce diagnostic ouvre-t-il le Plan du module pour la PREMIERE fois ? »</b>
 * — appele par les quatre chemins de cloture, DANS leur transaction.
 *
 * <p>Arbitrage n°7 : le mail part quand le Plan d'un module devient disponible
 * pour la premiere fois — TCF rapide clos, TCF complet clos sans Plan TCF
 * prealable, diagnostic civique clos. Un complet qui <b>affine</b> un Plan
 * existant ne publie rien. La regle d'ouverture du Plan TCF est celle de
 * {@code PlanFoundationResolver} (rapide clos OU complet clos) : « premiere
 * fois » = aucun AUTRE diagnostic clos du module, dans aucune des deux tables.
 *
 * <p>La cle {@code DIAGNOSTIC_PLAN_READY:{userId}:{module}} (complement B) est
 * le second verrou : meme publie deux fois, le mail part une fois.
 *
 * <p>🛑 Doit etre appele dans une transaction active : l'evenement est ecoute
 * en {@code AFTER_COMMIT}, sans {@code fallbackExecution} (complement D).
 */
@Component
@RequiredArgsConstructor
public class DiagnosticPlanReadyNotifier {

    private final DiagnosticSessionManager rapideManager;
    private final TcfDiagnosticSessionManager completManager;
    private final CivicDiagnosticSessionManager civicManager;
    private final ApplicationEventPublisher events;

    /** Cloture d'un diagnostic TCF, rapide ou complet ({@code sessionId} dans sa table). */
    public void tcfClos(User user, UUID sessionId) {
        if (user == null) return;
        boolean planExistait = rapideManager.countCompletedExcluding(user.getId(), sessionId) > 0
                || completManager.countCompletedExcluding(user.getId(), sessionId) > 0;
        if (!planExistait) {
            events.publishEvent(new DiagnosticPlanReadyEvent(
                    user.getId(), user.getEmail(), Module.TCF, sessionId, false));
        }
    }

    /** Cloture d'un diagnostic civique porte par un compte. */
    public void civiqueClos(User user, UUID sessionId) {
        if (user == null) return;
        if (civicManager.countCompletedExcluding(user.getId(), sessionId) == 0) {
            events.publishEvent(new DiagnosticPlanReadyEvent(
                    user.getId(), user.getEmail(), Module.CIVIQUE, sessionId, false));
        }
    }

    /**
     * Adoption d'un diagnostic civique d'invite (complement C) : pas de mail — le
     * candidat est dans l'app, sur son Plan, et recoit deja WELCOME — mais la cle
     * du module est consommee, pour qu'un diagnostic ulterieur ne le declenche pas.
     */
    public void civiqueAdopte(User user, UUID sessionId) {
        if (user == null) return;
        if (civicManager.countCompletedExcluding(user.getId(), sessionId) == 0) {
            events.publishEvent(new DiagnosticPlanReadyEvent(
                    user.getId(), user.getEmail(), Module.CIVIQUE, sessionId, true));
        }
    }
}

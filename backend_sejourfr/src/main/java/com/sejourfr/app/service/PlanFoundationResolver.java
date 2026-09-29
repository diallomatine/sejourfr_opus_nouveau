package com.sejourfr.app.service;

import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.enums.TcfDiagnosticStatus;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.TcfDiagnosticSessionManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.UUID;

/**
 * <b>Sur quelle mesure le Plan TCF se construit-il ?</b> — l'autorité unique.
 *
 * <h2>🛑 UNE SEULE RÈGLE, DEUX LECTEURS</h2>
 * <p>{@link LearningPlanService} décide ici s'il bascule en {@code ACTIVE}, et
 * {@code PreparationService} sert le même fait sous
 * {@code PreparationDto.ModulePreparation.planDisponible}. Ce sont les deux
 * seuls appelants, et ils lisent <b>cette</b> méthode : un écran qui
 * promettrait un plan que le moteur refuse de construire est exactement la
 * contradiction que l'état unique existe pour empêcher. La règle a déjà vécu en
 * deux copies implicites (l'étape servie disait « pas encore prêt » d'un plan
 * que le moteur servait déjà) — c'est ce qui a coûté l'arbitrage du 2026-09-12.
 *
 * <h2>Ce qui fonde un Plan (arbitrage du propriétaire, 2026-09-12)</h2>
 * <ul>
 *   <li><b>Diagnostic RAPIDE clos</b> ⇒ Plan disponible. C'est le chemin normal
 *       et court : une production écrite mesurée, donc des priorités vraies.</li>
 *   <li><b>Diagnostic COMPLET clos</b> ⇒ Plan disponible <b>aussi</b>, même si
 *       le rapide n'a jamais été fait. On ne crée pas une dépendance
 *       artificielle pour quelqu'un qui a terminé directement les 4 épreuves —
 *       et le moteur est déjà nourri par elles : la CO et la CE écrivent leurs
 *       observations par {@code ComprehensionObservationService} (le QCM du
 *       diagnostic est un attempt ordinaire), l'EE et l'EO par
 *       {@code DiagnosticProductionAnalysisService.observeStandardProduction}
 *       (leurs 3 tâches sont des tâches de production <b>standard</b>, soumises
 *       par la route commune, donc observées en {@code MOCK_EXAM_EE/EO}).</li>
 *   <li>🛑 <b>Diagnostic complet seulement COMMENCÉ, sans rapide</b> ⇒ <b>pas</b>
 *       de Plan, même à 3 épreuves sur 4. Règle explicite du propriétaire : le
 *       Plan attend une mesure close, il ne se construit pas sur un diagnostic
 *       qu'on est en train de passer.</li>
 * </ul>
 *
 * <p>🛑 <b>Rien n'est persisté, rien n'est deviné.</b> Ce resolveur ne fait que
 * lire deux lignes indexées ; c'est le moteur qui décide ensuite ce qu'il a le
 * droit de dire, à partir des seules observations réelles.
 */
@Component
@RequiredArgsConstructor
public class PlanFoundationResolver {

    private final DiagnosticSessionManager rapideManager;
    private final TcfDiagnosticSessionManager completManager;

    /**
     * La mesure close sur laquelle le Plan s'appuie.
     *
     * @param rapide  le diagnostic rapide clos, s'il existe
     * @param complet le diagnostic TCF 4 épreuves <b>clos</b>, s'il existe
     */
    public record Foundation(
            DiagnosticSession rapide,
            TcfDiagnosticSession complet) {

        public static final Foundation AUCUNE = new Foundation(null, null);

        /** 🛑 Le fait unique : « le Plan est-il constructible maintenant ? ». */
        public boolean exists() {
            return rapide != null || complet != null;
        }

        /**
         * Le diagnostic que le Plan désigne comme sa base.
         *
         * <p>Le <b>rapide</b> prime quand les deux existent : c'est lui qui a
         * ouvert le parcours, et c'est son rapport que le candidat peut relire.
         * {@code null} = aucune base, donc le Plan n'est pas {@code ACTIVE}.
         */
        public UUID sessionId() {
            if (rapide != null) return rapide.getId();
            return complet == null ? null : complet.getId();
        }

        /** Quand cette base a été close. {@code null} si aucune base. */
        public Instant completedAt() {
            if (rapide != null) return rapide.getCompletedAt();
            return complet == null ? null : complet.getCompletedAt();
        }
    }

    /**
     * <b>Deux lectures indexées</b>, constantes : une par table de diagnostic.
     * Le coût est assumé et ne dépend d'aucune donnée du candidat — c'est ce
     * qui permet aux tests de coût du Plan de rester des égalités.
     */
    public Foundation resolve(UUID userId) {
        DiagnosticSession rapide = rapideManager.findLatestCompleted(userId).orElse(null);
        TcfDiagnosticSession complet = completManager.findLatest(userId)
                .filter(session -> session.getStatus() == TcfDiagnosticStatus.COMPLETED)
                .orElse(null);
        return rapide == null && complet == null
                ? Foundation.AUCUNE
                : new Foundation(rapide, complet);
    }

    /**
     * Pour un appelant qui tient <b>déjà</b> les deux lignes en main —
     * {@code PreparationService} les a lues pour servir l'étape, et les relire
     * ici doublerait le coût de {@code /api/me/preparation}.
     *
     * <p>🛑 {@code completClos} est bien le complet <b>CLOS</b>, jamais le
     * complet courant : c'est à l'appelant de ne passer que ce qui est clos, et
     * la signature le dit.
     */
    public static Foundation of(DiagnosticSession rapide, TcfDiagnosticSession completClos) {
        return rapide == null && completClos == null
                ? Foundation.AUCUNE
                : new Foundation(rapide, completClos);
    }
}

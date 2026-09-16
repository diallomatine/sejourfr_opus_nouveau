package com.sejourfr.app.service.journey;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyAssessmentKind;

import java.time.Instant;
import java.util.UUID;

/**
 * Une <b>evaluation terminee</b>, telle qu'un branchement la presente au
 * parcours.
 *
 * <p>🛑 <b>Une evaluation = un attempt</b> (ou une session de diagnostic
 * rapide), <b>jamais une soumission</b>. C'est la correction A11 de l'audit : les
 * 3 taches d'une epreuve d'expression produisent 3 {@code production_submissions},
 * et traiter chacune comme une evaluation ferait que la tache 2
 * <b>remplacerait</b> (R7) le lot que la tache 1 vient de creer. Le branchement
 * doit donc attendre que l'epreuve soit <b>complete</b> et passer son
 * {@code attempt.id}.
 *
 * @param sourceAssessmentId l'identite de l'evaluation : {@code attempts.id} pour
 *                           un examen ou une section de diagnostic complet,
 *                           {@code diagnostic_sessions.id} pour un diagnostic
 *                           rapide.
 * @param kind               de quelle table vient cet identifiant.
 * @param examType           l'epreuve <b>mesuree</b>. 🛑 {@code null} <b>pour le
 *                           seul diagnostic rapide</b> : il produit des priorites
 *                           sans mesurer (R11). La base le verrouille.
 * @param completedAt        la date de <b>fin</b> de l'evaluation — celle qui
 *                           fait l'ordre des evenements (R14), jamais la date de
 *                           traitement.
 */
public record JourneyEvaluation(
        UUID sourceAssessmentId,
        JourneyAssessmentKind kind,
        EpreuveType examType,
        Instant completedAt
) {

    public JourneyEvaluation {
        if (sourceAssessmentId == null) {
            throw new IllegalArgumentException("Une evaluation porte toujours son identifiant.");
        }
        if (completedAt == null) {
            throw new IllegalArgumentException(
                    "Une evaluation terminee porte toujours sa date de fin (R14).");
        }
        boolean rapide = kind == JourneyAssessmentKind.QUICK_DIAGNOSTIC;
        if (rapide != (examType == null)) {
            throw new IllegalArgumentException(
                    "Seul le diagnostic rapide ne mesure aucune epreuve (R11) : "
                            + kind + " / " + examType);
        }
    }

    /** Le diagnostic rapide ne mesure aucune epreuve, et lui seul (R11). */
    public boolean mesureUneEpreuve() {
        return examType != null;
    }

    public static JourneyEvaluation diagnosticRapide(UUID sessionId, Instant completedAt) {
        return new JourneyEvaluation(
                sessionId, JourneyAssessmentKind.QUICK_DIAGNOSTIC, null, completedAt);
    }
}

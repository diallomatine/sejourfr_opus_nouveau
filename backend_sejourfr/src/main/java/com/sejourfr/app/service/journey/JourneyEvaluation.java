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
        UUID themeId,
        Instant completedAt
) {

    /**
     * 🛑 <b>Le MIROIR EXACT de {@code chk_journey_assessment_mesure}</b> (V071,
     * D-51) : chaque nature porte <b>exactement</b> l'axe qu'elle mesure. Le
     * verifier ici plutot qu'au flush fait echouer l'appel <b>a la ligne
     * fautive</b>, et pas dans un {@code catch} trois couches plus haut — c'est
     * precisement la panne que {@code DETTE-M1} nomme.
     */
    public JourneyEvaluation {
        if (sourceAssessmentId == null) {
            throw new IllegalArgumentException("Une evaluation porte toujours son identifiant.");
        }
        if (completedAt == null) {
            throw new IllegalArgumentException(
                    "Une evaluation terminee porte toujours sa date de fin (R14).");
        }
        boolean axeAttendu = switch (kind) {
            // Les deux diagnostics et l'examen civique COMPLET ne mesurent aucun
            // axe : les premiers produisent des priorites (R11), le dernier est
            // un fait GLOBAL -- il mesure le programme entier.
            case QUICK_DIAGNOSTIC, CIVIC_DIAGNOSTIC, CIVIC_EXAM ->
                    examType == null && themeId == null;
            case CIVIC_THEME_EXAM -> examType == null && themeId != null;
            case FULL_DIAGNOSTIC, SECTION_EXAM, MOCK_EXAM ->
                    examType != null && themeId == null;
        };
        if (!axeAttendu) {
            throw new IllegalArgumentException(
                    "Cette nature ne porte pas l'axe qu'elle mesure : "
                            + kind + " / epreuve=" + examType + " / theme=" + themeId);
        }
    }

    /**
     * Le constructeur <b>TCF</b>, conserve tel quel : ses appelants ne
     * connaissent pas de thematique, et leur faire ecrire {@code null} a chaque
     * fois n'apprendrait rien a personne.
     */
    public JourneyEvaluation(
            UUID sourceAssessmentId, JourneyAssessmentKind kind,
            EpreuveType examType, Instant completedAt) {
        this(sourceAssessmentId, kind, examType, null, completedAt);
    }

    /** Le diagnostic rapide ne mesure aucune epreuve, et lui seul (R11). */
    public boolean mesureUneEpreuve() {
        return examType != null;
    }

    /** Cette evaluation mesure-t-elle UNE thematique civique ? */
    public boolean mesureUneThematique() {
        return themeId != null;
    }

    public static JourneyEvaluation diagnosticRapide(UUID sessionId, Instant completedAt) {
        return new JourneyEvaluation(
                sessionId, JourneyAssessmentKind.QUICK_DIAGNOSTIC, null, completedAt);
    }

    /** Le diagnostic <b>civique</b> : aucun axe, comme son pendant TCF. */
    public static JourneyEvaluation diagnosticCivique(UUID sessionId, Instant completedAt) {
        return new JourneyEvaluation(
                sessionId, JourneyAssessmentKind.CIVIC_DIAGNOSTIC, null, null, completedAt);
    }

    /** Un examen de <b>theme</b> : son axe est sa thematique. */
    public static JourneyEvaluation examenDeTheme(
            UUID attemptId, UUID themeId, Instant completedAt) {
        return new JourneyEvaluation(
                attemptId, JourneyAssessmentKind.CIVIC_THEME_EXAM, null, themeId, completedAt);
    }

    /**
     * L'examen civique <b>complet</b> : un fait GLOBAL, aucun axe. Les clotures
     * de bloc qu'il provoque (R1) sont des {@link #examenDeTheme} distinctes --
     * <b>six lignes pour un seul attempt</b> (D-51).
     */
    public static JourneyEvaluation examenCivique(UUID attemptId, Instant completedAt) {
        return new JourneyEvaluation(
                attemptId, JourneyAssessmentKind.CIVIC_EXAM, null, null, completedAt);
    }
}

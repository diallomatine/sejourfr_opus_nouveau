package com.sejourfr.app.enums;

/**
 * La nature d'une evaluation deja traitee par un parcours.
 *
 * <p><b>Persiste</b> sur {@code journey_assessment_event}, et ce n'est pas une
 * redite : un {@code sourceAssessmentId} seul ne dit pas de quelle table il
 * vient. {@link #QUICK_DIAGNOSTIC} designe une {@code diagnostic_sessions},
 * {@link #FULL_DIAGNOSTIC} une {@code tcf_diagnostic_sessions}, les deux autres
 * un {@code attempts}. Sans cette colonne, tracer « qu'est-ce qui a construit
 * cette file ? » demanderait d'interroger trois tables a l'aveugle.
 */
public enum JourneyAssessmentKind {

    /**
     * Le diagnostic rapide (1 production ecrite + 1 orale facultative). Il
     * produit des priorites mais <b>ne mesure aucune epreuve</b> (R11).
     */
    QUICK_DIAGNOSTIC,

    /** Le diagnostic TCF 4 epreuves. Ses sections <b>mesurent</b> (R10). */
    FULL_DIAGNOSTIC,

    /** Un examen d'epreuve passe seul. */
    SECTION_EXAM,

    /** Un examen blanc TCF complet ; ses 4 sous-epreuves mesurent (R10). */
    MOCK_EXAM
}

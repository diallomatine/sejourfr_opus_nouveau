package com.sejourfr.app.enums;

/**
 * La nature d'une evaluation deja traitee par un parcours.
 *
 * <p><b>Persiste</b> sur {@code journey_assessment_event}, et ce n'est pas une
 * redite : un {@code sourceAssessmentId} seul ne dit pas de quelle table il
 * vient. {@link #QUICK_DIAGNOSTIC} designe une {@code diagnostic_sessions},
 * {@link #FULL_DIAGNOSTIC} une {@code tcf_diagnostic_sessions},
 * {@link #CIVIC_DIAGNOSTIC} une {@code civic_diagnostic_sessions}, les quatre
 * autres un {@code attempts}. Sans cette colonne, tracer « qu'est-ce qui a construit
 * cette file ? » demanderait d'interroger quatre tables a l'aveugle.
 *
 * <p>🛑 <b>Cet enum est le MIROIR de {@code chk_journey_assessment_kind}
 * (V071), jamais son autorite.</b> Ajouter une nature est une MIGRATION : une
 * valeur qui n'existerait qu'ici serait refusee a l'insertion, et une valeur
 * libre ferait qu'une faute de frappe passerait sans que rien ne le signale.
 * Meme discipline que {@code chk_free_entitlement_code} (V067).
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
    MOCK_EXAM,

    /**
     * Le diagnostic <b>civique</b>. Il ne mesure aucune thematique : il produit
     * des priorites, comme {@link #QUICK_DIAGNOSTIC} cote TCF.
     *
     * <p>🛑 <b>Une valeur a part, et non {@code QUICK_DIAGNOSTIC}</b> : son
     * {@code sourceAssessmentId} vient d'une AUTRE table
     * ({@code civic_diagnostic_sessions}), et c'est precisement ce que cette
     * colonne existe pour dire.
     */
    CIVIC_DIAGNOSTIC,

    /** Un examen de theme civique. Son axe est <b>sa</b> thematique. */
    CIVIC_THEME_EXAM,

    /**
     * L'examen blanc civique <b>complet</b> (40 questions, les 5 thematiques).
     *
     * <p>🛑 <b>Aucun axe</b> : c'est un fait GLOBAL, il mesure le programme
     * entier. Les cloture d'examen de bloc qu'il provoque (R1) sont des lignes
     * {@link #CIVIC_THEME_EXAM} distinctes, une par thematique debloquee --
     * <b>six lignes pour un seul attempt</b>.
     */
    CIVIC_EXAM
}

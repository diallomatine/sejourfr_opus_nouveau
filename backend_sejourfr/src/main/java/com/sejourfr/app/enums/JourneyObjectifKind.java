package com.sejourfr.app.enums;

/**
 * La <b>nature</b> de l'objectif d'un cycle, telle qu'elle se sert.
 *
 * <p>🛑 <b>Meme geste que {@link JourneyBlocKind}</b> (D-47) : un front affiche
 * l'objectif d'un cycle <b>sans savoir de quel module il parle</b>. Il lit cette
 * nature pour choisir sa <b>tournure</b> (« vers le B2 » / « — Naturalisation »),
 * jamais pour brancher sur le module.
 *
 * <p>La base impose deja l'exclusivite : {@code chk_journey_objectif} (V069)
 * exige <b>exactement un</b> de {@code target_level} / {@code target_procedure}.
 */
public enum JourneyObjectifKind {

    /** Un palier CECRL vise — le TCF. */
    NIVEAU,

    /** Une demarche administrative visee — le civique. */
    PROCEDURE
}

package com.sejourfr.app.enums;

/**
 * Etat d'un lot de priorites.
 *
 * <p><b>Persiste</b>, comme {@link JourneyStepResolution} et pour la meme
 * raison : {@link #SUPERSEDED} est un evenement date, pas un etat recalculable.
 */
public enum JourneyLotStatus {

    /**
     * En cours. 🛑 <b>Au plus un par epreuve et par parcours</b> (R5), tenu par
     * un index unique partiel en base — le verrou pessimiste serialise deja les
     * traitements, l'index est la ceinture.
     */
    OPEN,

    /**
     * Ses entrainements etaient faits et son examen de reevaluation est passe :
     * le lot a rempli son office.
     */
    CLOSED,

    /**
     * Un examen de l'epreuve est arrive alors que le lot n'etait pas fini : la
     * mesure fait autorite, le lot est remplace (R7).
     */
    SUPERSEDED
}

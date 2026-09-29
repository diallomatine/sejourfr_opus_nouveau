package com.sejourfr.app.enums;

/**
 * Comment un lot choisit ses priorites parmi celles qu'une evaluation a
 * designees (R2).
 *
 * <p>Un enum d'une seule valeur, et c'est volontaire : la limite de
 * {@link #TOP_SEVERITY} est <b>connue</b> — avec trois competences tres faibles,
 * une quatrieme n'apparaitra jamais — et une strategie de rotation devra pouvoir
 * s'ajouter <b>sans changer le modele</b>, par une nouvelle valeur. Un booleen
 * n'aurait pas laisse cette porte ouverte.
 *
 * <p>🛑 Toute valeur non supportee fait <b>echouer le demarrage</b> : jamais de
 * repli muet sur une strategie que personne n'a choisie.
 */
public enum JourneyLotSelectionStrategy {

    /**
     * Les plus graves d'abord, dans l'ordre <b>lu</b> chez
     * {@code LearningPlanPriorityResolver.actionable()} — statut, puis confiance
     * decroissante, puis recence — departage par {@code skillCode} pour rester
     * deterministe a egalite. Seule valeur supportee en V1.
     */
    TOP_SEVERITY
}

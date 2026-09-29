package com.sejourfr.app.progression.domain;

/**
 * Les six etats normalises de la progression (V4.2 §13) et leur libelle FR.
 *
 * <p><b>Le libelle est servi par le serveur</b> (§25 bis.2) : aucun front ne
 * traduit cet enum et aucun front ne le derive d'un nombre. Une UI qui ne
 * gererait que quatre etats est non conforme — {@link #WATCH} et
 * {@link #READY_FOR_REASSESSMENT} sont precisement ceux qui portent la valeur
 * pedagogique du produit (§25 bis.3).
 *
 * <p>Le {@code tone} visuel se derive de cet etat, <b>jamais d'un
 * pourcentage</b> (invariant I42).
 */
public enum ProgressionStatus {

    /** Aucune preuve directe : {@code sumWeightEpoch == 0} (§14.1). */
    NOT_EVALUATED("À évaluer", "neutral"),

    /** Des preuves existent, sous le seuil d'entree en progression (§14.2). */
    FRAGILE("À renforcer", "danger"),

    /** Score et confiance suffisants pour progresser (§14.2). */
    PROGRESSING("En progression", "primary"),

    /** EE/EO uniquement : pret a etre verifie sur une vraie tache (§14.3). */
    READY_FOR_REASSESSMENT("Prêt à vérifier", "accent"),

    /** Palier ou competence confirme, gate satisfait (§14.4, §14.5). */
    SOLID("Acquis", "success"),

    /** Un SOLID contredit une fois : verification ciblee prioritaire (§15). */
    WATCH("À vérifier", "warn");

    private final String label;
    private final String tone;

    ProgressionStatus(String label, String tone) {
        this.label = label;
        this.tone = tone;
    }

    /** Libelle FR servi au front — contrat gele (§25 bis.3). */
    public String getLabel() {
        return label;
    }

    /** Ton visuel servi au front, derive de l'etat et jamais d'un nombre. */
    public String getTone() {
        return tone;
    }
}

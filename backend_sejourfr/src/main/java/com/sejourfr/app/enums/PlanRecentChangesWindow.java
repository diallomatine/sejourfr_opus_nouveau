package com.sejourfr.app.enums;

/**
 * Fenetre sur laquelle le Plan raconte « ce qui a change ».
 *
 * <p><b>C'est le SERVEUR qui la choisit</b>, et il prend la plus courte qui
 * contienne quelque chose de reel : une semaine si la semaine suffit, sinon
 * quinze jours, sinon le mois. Un candidat assidu lit sa semaine, un candidat
 * irregulier lit son mois, et <b>personne ne lit une liste vide sous un titre
 * qui promet du mouvement</b>. Aucune fenetre ne convient a tout le monde, d'ou
 * ce choix a la lecture plutot qu'une constante.
 *
 * <p><b>L'ordre de declaration EST l'ordre d'essai</b>, de la plus courte a la
 * plus longue. Ne pas le reordonner.
 *
 * <p><b>Derive a la lecture, jamais persiste</b> — meme philosophie que
 * {@link SituationNiveauVise} et {@link PlanDomainPriority}. Libelles
 * <b>geles</b> par {@code SkillLabelsTest} et recopies a la main dans les
 * fronts : un libelle qui bouge, ce sont quatre fichiers a changer dans la meme
 * passe.
 */
public enum PlanRecentChangesWindow {

    CETTE_SEMAINE("Cette semaine", 7),

    DEUX_SEMAINES("Ces deux dernières semaines", 14),

    CE_MOIS("Ce mois-ci", 30);

    private final String label;
    private final int days;

    PlanRecentChangesWindow(String label, int days) {
        this.label = label;
        this.days = days;
    }

    /** Libelle FR rendu au candidat, tel quel. */
    public String getLabel() {
        return label;
    }

    /** Profondeur de la fenetre, en jours pleins. */
    public int getDays() {
        return days;
    }
}

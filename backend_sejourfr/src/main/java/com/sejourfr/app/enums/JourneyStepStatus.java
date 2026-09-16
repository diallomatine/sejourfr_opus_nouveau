package com.sejourfr.app.enums;

/**
 * Ou en est une etape du parcours, <b>tel que l'ecran l'affiche</b>.
 *
 * <p>🛑 <b>DERIVE A LA LECTURE, JAMAIS PERSISTE</b> (arbitrage du proprietaire
 * D-7, 2026-09-17). Il n'existe aucune colonne {@code status} sur
 * {@code journey_step} : les cinq valeurs se recalculent depuis
 * {@code closed_at}, {@code resolution}, l'etat du lot et l'<b>ordre de
 * cloture</b>. Deux raisons, et elles sont du meme ordre :
 * <ul>
 *   <li>{@link #CURRENT} depend du <b>verrou</b> du candidat, qui change quand
 *       il s'abonne — le figer obligerait a reecrire la file a chaque paiement ;</li>
 *   <li>persister un statut d'affichage creerait une seconde autorite sur
 *       « ou en est ce candidat ? », qui finirait par contredire la premiere.
 *       C'est le defaut le plus cher du depot.</li>
 * </ul>
 *
 * <p>Meme philosophie que {@link SkillMasteryState}, {@link PlanSkillStepState}
 * et {@link SituationDansNiveau}.
 */
public enum JourneyStepStatus {

    /** A venir. Ouverte, mais ce n'est pas encore son tour. */
    UPCOMING,

    /**
     * A faire maintenant — <b>une seule par parcours</b>, garantie par
     * construction et non par une contrainte d'unicite.
     *
     * <p>C'est la premiere etape ouverte <b>et executable</b> (arbitrage D-1) :
     * une etape que le candidat ne peut pas mener a son terme avec son acces ne
     * prend jamais la main, sinon un compte gratuit verrait son parcours se
     * figer definitivement sur elle.
     */
    CURRENT,

    /** Close dans son tour. */
    COMPLETED,

    /**
     * Close <b>hors de son tour</b> : le candidat l'a resolue par un
     * entrainement libre avant d'y arriver, ou en sautant une etape verrouillee.
     *
     * <p>C'est une <b>nuance de rendu</b> de {@link #COMPLETED} (« Deja
     * maitrisee », « Deja travaillee »), derivee en comparant les dates de
     * cloture : une etape de position <b>inferieure</b> a ete close <b>apres</b>
     * elle, ou ne l'est toujours pas.
     */
    SKIPPED,

    /**
     * Remplacee par une evaluation plus recente (R7). <b>Non affichee</b> : le
     * candidat n'a pas a lire une etape que la mesure a rendue caduque.
     */
    OBSOLETE
}

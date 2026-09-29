package com.sejourfr.app.util;

/**
 * BORNES DE LONGUEUR d'une production ECRITE, resolues une fois pour toutes.
 *
 * <p><b>Source de verite unique : {@code production_tasks.mots_min / mots_max}</b>,
 * croisees avec les garde-fous absolus de la configuration
 * ({@code sejourfr.production-evaluation.min-text-words / max-text-words}). Ces
 * bornes ne se reecrivent nulle part ailleurs — ni dans une rubrique, ni dans un
 * tool-schema, ni dans un texte de front : c'est exactement ce qui a produit une
 * consigne contradictoire au correcteur (bornes T2/T3 figees a 60 jusqu'a V724).
 *
 * <p><b>Pourquoi ce type existe.</b> Deux endroits doivent repondre exactement la
 * meme chose a la question « ce texte est-il d'une longueur recevable ? » :
 * <ul>
 *   <li>{@code ProductionEvaluationService.validateTextWordCount}, qui REFUSE la
 *       soumission d'un candidat hors bornes ;</li>
 *   <li>le second appel « version au niveau vise », qui rend au candidat un texte
 *       MODELE dont il est invite a s'inspirer pour rejouer le sujet.</li>
 * </ul>
 * Tant que le second ne connaissait pas les bornes du premier, on livrait des
 * modeles de 63 et 64 mots sur une tache plafonnee a 60 : un texte que notre
 * propre plateforme refuse de recevoir.
 *
 * @param min nombre de mots minimum accepte (inclus)
 * @param max nombre de mots maximum accepte (inclus)
 */
public record ProductionTextBounds(int min, int max) {

    /**
     * @param motsMin        {@code production_tasks.mots_min} (peut etre null)
     * @param motsMax        {@code production_tasks.mots_max} (peut etre null)
     * @param plancherAbsolu garde-fou de configuration, independant de la tache
     * @param plafondAbsolu  garde-fou anti-payload geant, independant de la tache
     */
    public static ProductionTextBounds of(Integer motsMin, Integer motsMax,
                                          int plancherAbsolu, int plafondAbsolu) {
        int min = Math.max(plancherAbsolu, motsMin == null ? 0 : motsMin);
        int max = Math.min(plafondAbsolu, motsMax == null ? plafondAbsolu : motsMax);
        return new ProductionTextBounds(min, Math.max(min, max));
    }

    /** Vrai si ce nombre de mots serait accepte a la soumission. */
    public boolean accepte(int mots) {
        return mots >= min && mots <= max;
    }

    /** « 40 a 90 mots » — a destination d'un prompt ou d'un log, jamais d'un front. */
    public String libelle() {
        return min + " a " + max + " mots";
    }
}

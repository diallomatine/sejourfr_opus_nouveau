package com.sejourfr.app.enums;

/**
 * Nature d'un événement d'audience sur une landing.
 *
 * <p>Volontairement minimal : on mesure l'entonnoir haut (la page est vue, le
 * CTA est cliqué). La suite du parcours — série démo jouée, inscription — est
 * déjà lisible dans {@code attempts} et {@code users}, inutile de la dupliquer
 * ici.
 */
public enum PageViewEvent {
    /** La page a été affichée. */
    VIEW,
    /** L'appel à l'action principal a été cliqué. */
    CTA
}

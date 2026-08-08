package com.sejourfr.app.dto;

import com.sejourfr.app.enums.NiveauCecrl;

/**
 * Niveau TCF d'un candidat <b>dans le temps</b> : le meilleur résultat de
 * chacune des 4 épreuves (CO / CE / EE / EO), plus le niveau global = plancher
 * des épreuves <b>réellement passées</b>.
 *
 * <p>Un champ null veut dire « épreuve jamais passée », donc <b>inconnu</b> —
 * jamais « mauvais ». C'est ce qui interdit à une épreuve abandonnée sans rien
 * rendre d'écraser l'indicateur.
 *
 * <p>Agrégat interne : aucun endpoint ne le sert tel quel. Il alimente
 * {@code DashboardSummaryResponse.estimatedTcfLevel}, seule surface qui publie
 * ce niveau aux 3 fronts (aucun front ne le recalcule).
 */
public record TcfLevelProfile(
        NiveauCecrl co,
        NiveauCecrl ce,
        NiveauCecrl ee,
        NiveauCecrl eo,
        NiveauCecrl globalLevel
) {
}

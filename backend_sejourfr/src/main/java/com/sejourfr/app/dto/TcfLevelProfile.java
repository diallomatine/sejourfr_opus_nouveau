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

    /** Les 4 épreuves du TCF IRN — le dénominateur de {@link #epreuvesCounted()}. */
    public static final int EPREUVES_EXPECTED = 4;

    /**
     * Nombre d'épreuves qui ont réellement pesé dans {@link #globalLevel()}
     * (0..{@value #EPREUVES_EXPECTED}).
     *
     * <p>C'est l'exact pendant de {@code epreuvesCountedInFinalLevel} sur un
     * examen blanc complet : le plancher se calcule sur les épreuves non nulles,
     * donc leur compte <b>est</b> le périmètre du niveau annoncé. Le dériver ici
     * plutôt que de le recompter ailleurs interdit qu'un jour le périmètre publié
     * cesse de décrire le niveau publié.
     */
    public int epreuvesCounted() {
        int counted = 0;
        for (final NiveauCecrl n : new NiveauCecrl[]{co, ce, ee, eo}) {
            if (n != null) counted++;
        }
        return counted;
    }

    /**
     * {@code true} quand le niveau est établi sur <b>une partie seulement</b> des
     * épreuves. Faux quand il n'y en a aucune : {@link #globalLevel()} vaut alors
     * {@code null} et il n'y a rien à annoter — « — » se suffit.
     */
    public boolean partial() {
        final int counted = epreuvesCounted();
        return counted > 0 && counted < EPREUVES_EXPECTED;
    }
}

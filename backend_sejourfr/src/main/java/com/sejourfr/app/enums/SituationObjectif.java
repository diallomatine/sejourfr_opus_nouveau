package com.sejourfr.app.enums;

import com.sejourfr.app.util.TcfDomaine;

/**
 * <b>Ou se situe le niveau estime par le diagnostic par rapport a l'objectif
 * du candidat</b> — servi sur le rapport du diagnostic rapide
 * ({@code DiagnosticResultDto.situationObjectif}).
 *
 * <p>Le fait appartient au serveur, la phrase aux fronts (comme
 * {@link StatutObjectif}) : cet enum ne porte aucun libelle. 🛑 Il remplace la
 * phrase fixe « Vous avez deja les bases pour viser {objectif} », fausse pour un
 * A1 qui vise B2 comme pour un candidat deja au-dessus de son objectif.
 *
 * <p>🛑 <b>La regle n'est pas ecrite ici</b> : l'ecart se lit chez
 * {@link TcfDomaine#ecartAuNiveauCible}, l'autorite que le parcours utilise
 * deja pour ordonner ses lots (R10 bis).
 */
public enum SituationObjectif {

    /** Le niveau estime est au moins celui de l'objectif. */
    OBJECTIF_ATTEINT,

    /** Exactement un palier CECRL sous l'objectif. */
    UN_PALIER_SOUS_OBJECTIF,

    /** Deux paliers ou plus sous l'objectif ({@code A1_NON_ATTEINT} compris). */
    PLUSIEURS_PALIERS_SOUS_OBJECTIF;

    /**
     * @return {@code null} si le niveau est inconnu (production
     *         {@code NON_EVALUABLE}) ou l'objectif absent — <b>null = inconnu,
     *         jamais mauvais</b> : les fronts se taisent.
     */
    public static SituationObjectif de(NiveauCecrl niveauEstime, TargetLevel objectif) {
        Integer ecart = TcfDomaine.ecartAuNiveauCible(niveauEstime, objectif);
        if (ecart == null) return null;
        if (ecart == 0) return OBJECTIF_ATTEINT;
        return ecart == 1 ? UN_PALIER_SOUS_OBJECTIF : PLUSIEURS_PALIERS_SOUS_OBJECTIF;
    }
}

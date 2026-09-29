package com.sejourfr.app.enums;

/**
 * Registre de la relation entre l'examinateur-personnage de la Tache 2 (EO) et
 * le candidat. Determine le vouvoiement/tutoiement et le niveau de langue que
 * l'agent doit tenir pendant tout le jeu de role.
 *
 * <p>La formulation reellement injectee dans le prompt vit dans le bloc
 * {@code relations} de {@code prompts/realtime-personas-<version>.json} : le
 * code ne porte que la cle.
 */
public enum AgentRelation {

    /** Inconnus, cadre de service ou administratif : vouvoiement. */
    INCONNU_VOUVOIEMENT,

    /** Inconnus dans un cadre tres informel (marche, voisinage jeune) : tutoiement. */
    INCONNU_TUTOIEMENT,

    /** Deja en relation (bailleur, collegue) mais registre soutenu : vouvoiement. */
    CONNU_VOUVOIEMENT,

    /** Proche (ami, famille) : tutoiement. */
    CONNU_TUTOIEMENT
}

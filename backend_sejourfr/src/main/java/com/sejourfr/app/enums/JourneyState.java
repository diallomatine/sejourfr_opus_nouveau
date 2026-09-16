package com.sejourfr.app.enums;

/**
 * L'etat d'ensemble d'un parcours, <b>servi</b> aux fronts.
 *
 * <p>🛑 <b>Derive a la lecture</b>, comme tout le reste de l'etat du parcours
 * (D-7). Les fronts le <b>lisent</b> pour choisir quelle carte montrer ; ils ne
 * le deduisent ni du nombre d'etapes, ni de la nullite de {@code current} — deux
 * fronts qui deduiraient chacun leur version finiraient par afficher deux
 * choses differentes au meme candidat, ce que l'arbitrage du 2026-09-10
 * interdit deja pour {@link PreparationEtape}.
 */
public enum JourneyState {

    /**
     * Le candidat n'a pas declare de demarche, donc <b>aucun niveau cible</b> —
     * et donc <b>aucun parcours n'existe en base</b> (arbitrage D-3). L'ecran
     * propose « Choisir mon objectif ».
     *
     * <p>Ce n'est pas un parcours vide : c'est l'absence de parcours. Le
     * distinguer de {@link #UP_TO_DATE} evite de feliciter un candidat qui n'a
     * rien commence.
     */
    NEEDS_OBJECTIVE,

    /** Des etapes restent a faire, et au moins une est executable. */
    IN_PROGRESS,

    /**
     * Des etapes restent ouvertes mais <b>aucune n'est executable</b> avec
     * l'acces du candidat (R16, D-1) : {@code current} vaut {@code null} et la
     * carte montre la premiere etape verrouillee, avec son paywall.
     *
     * <p>🛑 Ce n'est <b>pas</b> un parcours modifie pour le freemium : la file
     * est la meme pour tout le monde, seule l'election de {@code CURRENT} tient
     * compte du verrou.
     */
    LOCKED,

    /**
     * Plus aucune etape ouverte. L'ecran dit « Votre parcours est a jour » et,
     * si les 4 epreuves sont mesurees, <b>suggere</b> un examen blanc complet —
     * une suggestion, hors file, jamais une etape.
     */
    UP_TO_DATE
}

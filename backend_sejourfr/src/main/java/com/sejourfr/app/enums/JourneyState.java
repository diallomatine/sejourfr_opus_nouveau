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
     * l'acces du candidat (R16, D-1) : la carte montre la premiere etape
     * verrouillee, avec son paywall.
     *
     * <p>🛑 <b>{@code current} n'est PAS nul pour autant</b> (D-60,
     * 2026-09-20) : c'est le serveur qui sert cette etape verrouillee, plutot
     * que de laisser chaque front la deviner — ils repliaient alors sur leur
     * plan derive et nommaient une autre epreuve que le badge. Cet etat reste
     * donc le seul fait a lire pour savoir que <b>rien ne se lance</b> : il ne
     * se deduit ni de la nullite de {@code current}, ni d'un abonnement.
     *
     * <p>🛑 Ce n'est <b>pas</b> un parcours modifie pour le freemium : la file
     * est la meme pour tout le monde, seule l'election de {@code CURRENT} tient
     * compte du verrou.
     */
    LOCKED,

    /**
     * <b>Le cycle est termine</b> : ses quatre blocs le sont, et il reste
     * quelque chose a proposer (spec §6). L'ecran affiche « Prochaine étape » et
     * la carte finale a deux actions, lues dans
     * {@code JourneyDto.nextStep()} — jamais deduites du nombre d'etapes.
     *
     * <p>🛑 <b>Distinct de {@link #UP_TO_DATE}</b>, qui garde son sens : « plus
     * rien a faire du tout ». Un cycle termine n'est pas un parcours fini —
     * c'est un palier franchi, et le suivant attend d'etre ouvert.
     */
    CYCLE_COMPLETED,

    /**
     * Plus aucune etape ouverte, <b>et plus rien a proposer</b> : le cycle en
     * attente est vide et le niveau cible est atteint partout. L'ecran dit
     * « Votre parcours est a jour » et, si les 4 epreuves sont mesurees,
     * <b>suggere</b> un examen blanc complet — une suggestion, hors file, jamais
     * une etape.
     *
     * <p>🛑 <b>Aucun second etat n'a ete invente pour dire la meme chose</b>
     * (spec §6, cas vide) : « Objectif atteint » et le maintien mensuel sont des
     * libelles de front, pas une valeur de plus ici.
     */
    UP_TO_DATE
}

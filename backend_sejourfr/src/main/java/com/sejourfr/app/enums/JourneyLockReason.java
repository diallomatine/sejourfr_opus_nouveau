package com.sejourfr.app.enums;

/**
 * <b>Pourquoi</b> une etape du parcours est verrouillee — servi a cote de
 * {@code JourneyStepDto.locked}, {@code null} quand elle ne l'est pas.
 *
 * <p>🛑 <b>Deux verrous de nature differente, un seul booleen jusqu'ici</b>
 * (2026-09-26). L'examen d'un bloc cumule un verrou <b>pedagogique</b> (D-15 :
 * une competence du meme bloc reste ouverte) et un verrou <b>commercial</b>
 * (D-17 bis : la gratuite d'examen blanc de production est consommee). Un front
 * qui ne lisait que {@code locked} devait deviner lequel s'appliquait, et
 * disait « terminez vos competences » a un candidat qui n'en avait plus aucune.
 * La raison est donc lue a la meme source que le verrou, jamais reconstituee.
 */
public enum JourneyLockReason {

    /** Une etape du <b>meme bloc</b> reste a faire (D-15). Un pass ne la leve pas. */
    PROGRESSION,

    /** L'acces du candidat ne permet pas de mener l'etape a son terme (D-18, D-17 bis, D-33). */
    ACCESS
}

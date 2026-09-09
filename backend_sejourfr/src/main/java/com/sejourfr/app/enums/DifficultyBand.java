package com.sejourfr.app.enums;

/**
 * La bande de difficulté d'une question <b>à l'intérieur de son palier</b>
 * (moteur de progression V4.2 §7).
 *
 * <p>🛑 <b>À ne pas confondre avec {@link Difficulty}</b>, qui porte l'axe
 * « procédure visée ou palier CECRL » ({@code CSP / CR / NAT / A2 / B1 / B2}).
 * Une question B1 peut être facile ou difficile <i>pour du B1</i> : c'est ce que
 * dit cet enum-ci, et rien d'autre.
 *
 * <p>Il existe pour une seule raison : rendre deux séries <b>comparables</b>.
 * Sans lui, une série de 20 questions faciles et une série de 20 questions
 * difficiles du même palier produisent deux scores qu'on additionne comme s'ils
 * mesuraient la même chose. Le blueprint qualifiant de §6.2 —
 * <b>6 EASY / 10 MEDIUM / 4 HARD sur 20</b> — n'a de sens que si chaque question
 * porte sa bande.
 *
 * <p>Une question <b>non taguée</b> ({@code null} en base) est un cas normal du
 * catalogue existant : sa série est alors {@code UNCALIBRATED}, pèse moins et ne
 * verrouille jamais un palier. On ne lui invente pas de bande par défaut —
 * absence de mesure n'est pas « moyen ».
 */
public enum DifficultyBand {
    EASY,
    MEDIUM,
    HARD
}

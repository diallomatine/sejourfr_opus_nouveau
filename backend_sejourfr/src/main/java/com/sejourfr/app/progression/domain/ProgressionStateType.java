package com.sejourfr.app.progression.domain;

/**
 * Le type d'etat mesure — <b>et donc le profil de seuils qui s'applique</b>
 * (moteur de progression V4.2 §4, §14).
 *
 * <p>Les deux echelles ne sont pas comparables par construction : un
 * {@code RECEPTIVE_LEVEL} agrege un {@code result} <b>corrige du hasard</b>
 * (§6.1), un {@code PRODUCTIVE_SKILL} agrege des observations IA {@code 0 /
 * 0.5 / 1} (§6.5). Reutiliser silencieusement le profil de l'un pour l'autre
 * est explicitement interdit (§4, invariant I14) : tout acces aux seuils passe
 * par {@code thresholdProfile(stateType)}, jamais par une constante en dur.
 */
public enum ProgressionStateType {

    /** CO / CE, par palier : {@code CO:A2}, {@code CE:B1}, … */
    RECEPTIVE_LEVEL,

    /** EE / EO, par competence du referentiel. */
    PRODUCTIVE_SKILL
}

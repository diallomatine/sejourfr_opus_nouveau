package com.sejourfr.app.enums;

/**
 * Contexte d'une inscription ({@code users.signup_context}, V074), pose par le
 * serveur <b>dans la transaction d'inscription</b>, jamais reecrit.
 *
 * <p>{@link #AFTER_DIAGNOSTIC} si l'inscription a claime une run de diagnostic
 * <b>soumise</b> (jeton transmis par le client, jamais une recherche par
 * {@code anonymous_id}), {@link #OUTSIDE_DIAGNOSTIC} sinon. {@code null} = compte
 * anterieur a la mesure, affiche « inconnu ».
 */
public enum SignupContext {
    AFTER_DIAGNOSTIC,
    OUTSIDE_DIAGNOSTIC
}

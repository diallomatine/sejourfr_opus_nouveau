package com.sejourfr.app.enums;

/**
 * Nature d'une authentification reussie, vue de la mesure : creation d'un
 * compte ou connexion a un compte existant (local ou social).
 *
 * <p>C'est la valeur que le lot 2 du chantier Suivi recopie dans
 * {@code diagnostic_run.claim_kind} : un claim a l'inscription compte dans
 * « inscrit apres diagnostic », un claim a la connexion dans « connecte apres
 * diagnostic » — jamais comme une inscription.
 */
public enum AuthKind {
    SIGNUP,
    LOGIN
}

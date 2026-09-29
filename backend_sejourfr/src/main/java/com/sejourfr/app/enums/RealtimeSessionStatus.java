package com.sejourfr.app.enums;

/**
 * Cycle de vie d'une session d'expression orale en temps reel (examinateur IA,
 * Tache 1 / Tache 2). Distinct de {@link SubmissionStatut} : ici on suit la
 * CONDUITE de la conversation, pas la notation.
 *
 * <p>PENDING : token ephemere emis, le client n'a pas encore ouvert la session
 * (ne consomme PAS le quota tant que la connexion n'est pas etablie, mais
 * "reserve" un slot pendant la fenetre de validite du token).
 * <br>ACTIVE : au moins un fragment de transcript a ete recu cote serveur — la
 * connexion est reellement etablie, le quota est debite.
 * <br>COMPLETED : la session s'est terminee normalement, transcript final
 * capture (la notation est faite ensuite par le pipeline existant — lot 2).
 * <br>FAILED : connexion jamais etablie ou interrompue avant tout echange utile
 * (ne consomme PAS le quota — pas de penalite sur un echec technique).
 */
public enum RealtimeSessionStatus {
    PENDING,
    ACTIVE,
    COMPLETED,
    FAILED
}

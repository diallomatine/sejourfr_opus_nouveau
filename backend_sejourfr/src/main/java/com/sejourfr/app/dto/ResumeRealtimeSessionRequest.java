package com.sejourfr.app.dto;

/**
 * Demande de REPRISE d'une session temps reel dont le WebSocket est tombe
 * (coupure reseau, appli passee en arriere-plan). Renvoie un NOUVEAU token
 * ephemere qui rouvre la meme conversation, sans re-debiter le slot de
 * simulation : la session, son transcript et son quota sont ceux d'avant.
 *
 * @param resumptionHandle dernier handle reçu du fournisseur avant la coupure.
 *                         {@code null} ou vide = on retombe sur le dernier
 *                         handle connu du serveur (relaye avec les fragments de
 *                         transcript). Si le serveur n'en a aucun non plus, la
 *                         reprise reste accordee mais l'echange repart d'un
 *                         contexte vide — mieux que perdre la session.
 */
public record ResumeRealtimeSessionRequest(
        String resumptionHandle
) {}

package com.sejourfr.app.dto;

import java.util.List;

/**
 * Resultat d'un appel {@code POST /api/admin/campaigns/{code}/send}.
 *
 * @param status          DRY_RUN, TEST_SENT, COMPLETED (vague terminee),
 *                        NOTHING_TO_SEND, IN_PROGRESS (vague encore en cours
 *                        sur l'executor), STOPPED_ON_ERROR (arret au premier echec)
 * @param remaining       comptes encore a servir au moment de la reponse :
 *                        {@code remainingNeverAttempted + remainingRetry}
 * @param remainingNeverAttempted comptes jamais tentes (servis en premier)
 * @param remainingRetry  comptes FAILED encore reprenables (sous le plafond de
 *                        tentatives), servis quand plus aucun jamais-tente ne reste
 * @param servedTotal     comptes SENT de la campagne, toutes vagues confondues
 * @param failedTotal     comptes FAILED de la campagne (reprenables ou non)
 * @param waveRejected    adresses refusees dans la vague (la vague a continue)
 * @param waveFailed      echec systemique (0 ou 1) : la vague s'est arretee
 * @param sample          echantillon masque ({@code a***@domaine}) des prochains destinataires
 * @param error           premiere erreur de la vague, assainie ; {@code null} sinon
 */
public record EmailCampaignRunResponse(
        String campaign,
        String mode,
        String status,
        long remaining,
        long remainingNeverAttempted,
        long remainingRetry,
        long servedTotal,
        long failedTotal,
        int waveSent,
        int waveAlreadyServed,
        int waveSkipped,
        int waveRejected,
        int waveFailed,
        String error,
        List<String> sample,
        int waveSize,
        int pauseSeconds
) {}

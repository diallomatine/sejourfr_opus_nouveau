package com.sejourfr.app.dto;

/**
 * Compte rendu du mailing d'annonce aux acheteurs de l'ancien catalogue
 * (migration V038).
 *
 * @param total        compensations accordées par la migration.
 * @param dejaEnvoyes  compensations dont l'e-mail est déjà parti.
 * @param aEnvoyer     destinataires restants au moment de l'appel (comptes
 *                     supprimés depuis la migration exclus).
 * @param envoyes      messages effectivement partis pendant cet appel — toujours
 *                     0 en {@code dryRun}.
 * @param echecs       destinataires dont l'envoi a échoué : ils restent à
 *                     envoyer, un rappel de l'endpoint les reprendra.
 * @param dryRun       vrai si aucun message n'a été envoyé.
 */
public record LegacyCompensationMailingResponse(
        long total,
        long dejaEnvoyes,
        int aEnvoyer,
        int envoyes,
        int echecs,
        boolean dryRun
) {}

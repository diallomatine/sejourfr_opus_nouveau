package com.sejourfr.app.dto;

/**
 * Apercu d'un message d'admin, rendu par le VRAI gabarit {@code ADMIN_MESSAGE}
 * (layout compris) : ce que le compte recevra, sans rien enregistrer ni envoyer.
 */
public record AdminMessagePreviewDto(
        String recipient,
        String subject,
        String html,
        String text
) {}

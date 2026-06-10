package com.sejourfr.app.dto;

/**
 * Réponse de POST /api/contact. Le {@code ticketId} est une **référence
 * cosmétique** (pas de persistance pour l'instant) : il sert de numéro à citer
 * dans l'échange mail. Si on ajoute un jour une entité {@code ContactMessage},
 * il deviendra une vraie clé de suivi.
 */
public record ContactResponse(String ticketId) {}

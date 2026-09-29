package com.sejourfr.app.dto;

import java.time.Instant;
import java.util.UUID;

/**
 * Intention creee. Le mobile la persiste indexee par {@code productId} avant
 * d'ouvrir le paiement, la renvoie dans {@code verify-receipt}, et la reutilise
 * si l'achat est rejoue au lancement suivant (Q12).
 */
public record PurchaseIntentResponse(UUID purchaseIntentId, Instant expiresAt) {}

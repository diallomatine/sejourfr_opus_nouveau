package com.sejourfr.app.enums;

/**
 * Etat d'une ligne {@code email_deliveries}.
 *
 * <p>{@code PENDING}, {@code SENT} et {@code SKIPPED} occupent la cle
 * anti-doublon (index unique partiel, V073) ; {@code FAILED} la libere pour une
 * nouvelle tentative.
 */
public enum EmailDeliveryStatus {
    PENDING,
    SENT,
    FAILED,
    SKIPPED
}

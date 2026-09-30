package com.sejourfr.app.enums;

/**
 * Pourquoi une ligne {@code email_deliveries} est {@code SKIPPED}.
 *
 * <ul>
 *   <li>{@code PREFERENCE} — mail ENGAGEMENT evenementiel refuse par la preference
 *       du candidat (le scheduler, lui, exclut les desabonnes dans ses requetes et
 *       n'ecrit rien).</li>
 *   <li>{@code ALLOWLIST} — HISTORIQUE, plus jamais ecrit : l'ancienne liste
 *       blanche de dev est supprimee (2026-09-30). Conservee pour relire les
 *       lignes deja tracees.</li>
 *   <li>{@code KEY_CONSUMED} — la cle est consommee sans envoi (adoption d'un
 *       diagnostic civique invite, complement C).</li>
 * </ul>
 */
public enum EmailSkipReason {
    PREFERENCE,
    ALLOWLIST,
    KEY_CONSUMED
}

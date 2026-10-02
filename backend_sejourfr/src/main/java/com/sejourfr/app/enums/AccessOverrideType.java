package com.sejourfr.app.enums;

/**
 * Nature d'une décision admin sur l'accès à un produit (table {@code access_overrides}).
 * <ul>
 *   <li>{@code GRANT} : l'accès est ouvert sur la fenêtre, quels que soient les achats ;</li>
 *   <li>{@code REVOKE} : l'accès est fermé sur la fenêtre, SAUF achat postérieur à la
 *       décision (un REVOKE ne bloque jamais un rachat légitime, spec §2.3).</li>
 * </ul>
 */
public enum AccessOverrideType {
    GRANT,
    REVOKE
}

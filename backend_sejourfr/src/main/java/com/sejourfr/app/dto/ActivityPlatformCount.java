package com.sejourfr.app.dto;

import com.sejourfr.app.enums.ClientPlatform;

/**
 * Un compte par plateforme, libelle servi (D12, N6). Toujours les cinq
 * plateformes, dans l'ordre de {@link ClientPlatform}.
 *
 * @param displayed faux pour {@code UNKNOWN} hors comptes internes (N6) : le
 *                  front n'affiche pas la ligne
 * @param value     {@code null} = non mesure
 */
public record ActivityPlatformCount(ClientPlatform platform, String label, boolean displayed, Long value) {
}

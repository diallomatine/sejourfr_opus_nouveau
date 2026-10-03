package com.sejourfr.app.dto;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * Reponse de {@code GET /api/admin/analytics/activity/live} (D11) : les comptes
 * connectes en ligne maintenant, c'est-a-dire actifs depuis moins de
 * {@code windowSeconds}. 🛑 {@code null} = non mesure (avant la date de debut de
 * mesure {@code ACTIVE_USERS}), jamais 0.
 *
 * @param total              comptes distincts, toutes plateformes (un compte
 *                           compte une fois)
 * @param multiPlatformUsers comptes en ligne sur au moins deux plateformes
 * @param byPlatform         comptes distincts par plateforme (leur somme peut
 *                           depasser {@code total})
 */
public record AdminActivityLiveResponse(Instant at, int windowSeconds, boolean includeInternal,
                                        LocalDate measurementStart, Long total, Long multiPlatformUsers,
                                        List<ActivityPlatformCount> byPlatform) {
}

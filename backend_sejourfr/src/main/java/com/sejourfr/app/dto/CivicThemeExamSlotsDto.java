package com.sejourfr.app.dto;

import java.util.List;
import java.util.UUID;

/**
 * {@code GET /api/themes/{themeId}/exam-slots} (compte) et
 * {@code GET /api/public/themes/{themeId}/exam-slots} (visiteur) — la grille
 * des examens blancs d'un thème civique, créneau par créneau.
 *
 * <p>🛑 <b>Le verrou est SERVI</b> : les fronts lisent {@code locked}, ils ne
 * le déduisent jamais du rang. Autorité : {@code ExamenBlancAccessService.isExamenBlancVerrouille}
 * (arbitrage du 2026-09-24 — le créneau 1 de chaque thème est offert à tous,
 * visiteurs compris ; les suivants sont réservés aux abonnés Civique).
 *
 * @param themeId le thème civique
 * @param slots   les créneaux 1..20, dans l'ordre
 */
public record CivicThemeExamSlotsDto(UUID themeId, List<ExamSlotsDto.Slot> slots) {
}

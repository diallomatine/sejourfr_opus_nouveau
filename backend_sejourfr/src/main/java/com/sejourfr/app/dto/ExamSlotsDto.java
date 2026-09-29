package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;

import java.util.List;

/**
 * {@code GET /api/exam-slots?epreuve=…} (compte) et
 * {@code GET /api/public/exam-slots?epreuve=…} (visiteur) — la grille des
 * examens blancs d'une épreuve, créneau par créneau.
 *
 * <p>🛑 <b>Le verrou est SERVI</b> (arbitrage du 2026-09-24, « c'est le serveur
 * qui décide du verrouillage ») : les fronts lisent {@code locked}, ils ne le
 * déduisent jamais du rang. Chaque grille lit l'autorité que le démarrage
 * oppose en 403 — {@code ExamenBlancAccessService} pour les QCM et l'examen
 * complet, {@code ProductionAccessService.isProductionExamSlotLocked} pour EE / EO.
 *
 * @param epreuve la grille : {@code TCF_CO} / {@code TCF_CE} / {@code TCF_STRUCTURE}
 *                (examens d'épreuve), {@code TCF_EE} / {@code TCF_EO} (examens de
 *                production), {@code TCF_COMPLET} (examens complets ; pour un
 *                visiteur, l'examen de compréhension offert), {@code CIVIQUE}
 *                (examens civiques globaux de 40 questions)
 * @param slots   les créneaux de la grille, dans l'ordre (1..n)
 */
public record ExamSlotsDto(EpreuveType epreuve, List<Slot> slots) {

    /**
     * @param slot   numéro du créneau (1..n)
     * @param locked {@code true} si ce candidat ne peut pas le lancer
     */
    public record Slot(int slot, boolean locked) {
    }
}

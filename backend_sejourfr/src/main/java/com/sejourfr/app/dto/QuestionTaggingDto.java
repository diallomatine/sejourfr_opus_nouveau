package com.sejourfr.app.dto;

import java.util.List;
import java.util.UUID;

/**
 * Une question a taguer, telle que l'ecran de tagging la voit (lot L8).
 *
 * <p>🛑 <b>{@code notionCode} nul = PAS ENCORE TAGUEE</b>, jamais « sans
 * notion ». Une question non taguee attend un humain ; elle n'est pas hors
 * programme, et l'ecran doit le dire ainsi.
 *
 * <p>🛑 Les <b>suggestions</b> sont affichees pour accelerer la decision, pas
 * pour la prendre. Elles arrivent triees par confiance decroissante, et aucune
 * n'est pre-selectionnee : un tag valide est toujours un geste.
 */
public record QuestionTaggingDto(
        UUID questionId,
        String enonce,
        String themeCode,
        /** La mention visee par la question ({@code CSP} / {@code CR} / {@code NAT}). */
        String mention,
        String notionCode,
        String notionLabel,
        List<Suggestion> suggestions
) {
    public record Suggestion(String notionCode, String notionLabel, double confidence) {}
}

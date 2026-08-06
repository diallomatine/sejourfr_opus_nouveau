package com.sejourfr.app.dto;

/**
 * Etat du quota d'analyses IA du candidat.
 *
 * <p>Produire, s'auto-evaluer et lire les references restent gratuits et
 * illimites : seule l'ANALYSE est comptee ici. {@code remaining = -1} signifie
 * « illimite » — les fronts doivent le traiter comme tel et ne jamais afficher
 * la valeur brute.
 */
public record SkillAnalysisQuotaDto(
        /** Acces au module TCF ({@code subscriptionService.hasTcf}). */
        boolean premium,
        boolean unlimited,
        int freeAnalysesTotal,
        int freeAnalysesUsed,
        /** {@code -1} si illimite, sinon le reste, jamais negatif. */
        int remaining
) {
}

package com.sejourfr.app.dto;

import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.enums.ProgressionEtatSource;

import java.util.List;
import java.util.UUID;

/**
 * {@code GET /api/me/progression/civique/themes/{themeId}} — la progression
 * d'<b>un</b> thème civique, sur ses seuls examens de thème (20 questions, D10).
 *
 * @param etat            état du thème <b>d'après le dernier examen de ce thème</b>
 *                        ({@code null} sans examen). 🛑 Ce n'est pas l'état de
 *                        l'Accueil, qui vient du diagnostic (D13)
 * @param etatSource      d'où vient {@code etat}
 * @param etatSourceLabel la phrase à afficher à côté de l'état
 * @param examens         <b>tous</b> les examens du thème (au plus 50), du plus
 *                        récent au plus ancien
 * @param cta             « Nouvel examen blanc » (grille du thème, premium)
 */
public record ProgressionThemeDto(
        UUID themeId,
        String code,
        String label,
        ProgressionEchelleDto echelle,
        ProgressionResumeDto resume,
        CivicThemeState etat,
        ProgressionEtatSource etatSource,
        String etatSourceLabel,
        List<ProgressionMesureDto> examens,
        ProgressionCtaDto cta) {
}

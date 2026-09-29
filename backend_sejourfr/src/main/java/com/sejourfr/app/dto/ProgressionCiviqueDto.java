package com.sejourfr.app.dto;

import java.util.List;
import java.util.UUID;

/**
 * {@code GET /api/me/progression/civique} — la progression <b>globale</b> de
 * l'examen civique.
 *
 * @param echelle l'axe d'un examen global (/40, seuil 32, bandes d'état)
 * @param global  résumé des examens globaux (40 questions)
 * @param themes  les 5 thématiques officielles, <b>toujours</b> servies, dans
 *                l'ordre {@code display_order} ; chacune résumée sur ses seuls
 *                <b>examens de thème</b> (D10)
 * @param examens examens globaux, du plus récent au plus ancien : les 3
 *                derniers, ou tous (au plus 50) avec {@code ?tous=true} ;
 *                {@code global.nombre} donne le total
 * @param cta     « Faire un examen blanc global »
 */
public record ProgressionCiviqueDto(
        ProgressionEchelleDto echelle,
        ProgressionResumeDto global,
        List<ThemeCarte> themes,
        List<ExamenGlobal> examens,
        ProgressionCtaDto cta) {

    /** Carte d'un thème : le même résumé que l'en-tête de son écran. */
    public record ThemeCarte(
            UUID themeId,
            String code,
            String label,
            ProgressionEchelleDto echelle,
            ProgressionResumeDto resume) {
    }

    /**
     * Un examen global et sa répartition par thème.
     *
     * @param mesure    le résultat /40 de l'examen
     * @param parTheme  les 5 thèmes, même ordre que {@code themes} ; 🛑 en
     *                  « x / n posées », jamais « / 20 » (D11), mises en
     *                  situation incluses, <b>sans état</b> (à 4 questions, un
     *                  état basculerait sur une seule réponse)
     */
    public record ExamenGlobal(ProgressionMesureDto mesure, List<PartTheme> parTheme) {
    }

    /**
     * @param bonnes bonnes réponses sur ce thème dans cet examen
     * @param posees questions de ce thème posées dans cet examen ; 0 = thème
     *               non posé (inconnu, jamais « 0 / 0 raté »)
     */
    public record PartTheme(UUID themeId, String code, String label, int bonnes, int posees) {
    }
}

package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;

import java.util.List;

/**
 * {@code GET /api/me/progression/tcf/{epreuve}} — la progression d'<b>une</b>
 * épreuve du TCF IRN, sur ses examens blancs (épreuve seule + sous-épreuve
 * d'examen complet, aucun diagnostic : D1).
 *
 * @param epreuve      TCF_CO | TCF_CE | TCF_EE | TCF_EO
 * @param echelle      l'axe de la courbe
 * @param resume       carte de tête et encarts
 * @param niveauActuel le <b>niveau actuel estimé</b> de l'épreuve, le chiffre de
 *                     l'Accueil (moyenne des 3 derniers examens qualifiants,
 *                     {@code TcfProfileService.levelProfileAccueil}) — la ligne
 *                     secondaire de D4. {@code null} = à évaluer
 * @param examens      <b>tous</b> les examens (au plus 50), du plus récent au
 *                     plus ancien — la courbe et la liste montrent les mêmes
 * @param cta          le bouton « Nouvel examen blanc »
 */
public record ProgressionEpreuveDto(
        EpreuveType epreuve,
        ProgressionEchelleDto echelle,
        ProgressionResumeDto resume,
        NiveauCecrl niveauActuel,
        List<ProgressionMesureDto> examens,
        ProgressionCtaDto cta) {
}

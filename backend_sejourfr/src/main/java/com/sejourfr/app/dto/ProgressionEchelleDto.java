package com.sejourfr.app.dto;

import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ProgressionUnite;

import java.util.List;

/**
 * L'axe d'une courbe de progression, <b>servi</b> : le front place des points
 * entre {@code min} et {@code max}, il ne classe rien.
 *
 * @param unite   ce que mesure l'axe (cf. {@link ProgressionUnite})
 * @param min     borne basse de l'axe (100 en CO/CE, 0 ailleurs)
 * @param max     borne haute (499, 20 ou 40)
 * @param seuil   civique seulement : bonnes réponses exigées (16 / 20, 32 / 40) ;
 *                {@code null} en TCF
 * @param bandes  les zones colorées de l'axe, de la plus basse à la plus haute.
 *                🛑 <b>Vide en CO/CE</b> (aucun palier ne dérive du score de
 *                progression, arbitrage D2). EE/EO : bandes officielles
 *                {@code BandeNoteTcf}. Civique : bandes d'état dérivées des seuils
 *                du {@code CivicDiagnosticThemeResolver}
 * @param reperes lignes neutres de l'axe, sans libellé de palier
 */
public record ProgressionEchelleDto(
        ProgressionUnite unite,
        int min,
        int max,
        Integer seuil,
        List<Bande> bandes,
        List<Integer> reperes) {

    /**
     * Une zone de l'axe, bornes incluses.
     *
     * @param niveau palier officiel (EE/EO), sinon {@code null}
     * @param etat   état civique (civique), sinon {@code null}
     */
    public record Bande(NiveauCecrl niveau, CivicThemeState etat, int min, int max) {
    }
}

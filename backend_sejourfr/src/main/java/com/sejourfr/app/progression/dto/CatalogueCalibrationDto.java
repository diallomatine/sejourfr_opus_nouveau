package com.sejourfr.app.progression.dto;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;

import java.util.List;

/**
 * <b>L'indicateur d'avancement du tagging du catalogue</b> (V4.2 §7, phase 4).
 *
 * <p>Il répond à une seule question, celle qui décide de tout le reste :
 * <i>combien de séries qualifiantes ce couple domaine + palier peut-il produire
 * aujourd'hui ?</i> Tant que la réponse est zéro, aucun candidat ne peut faire
 * avancer ce palier par l'entraînement — seuls les examens blancs le font — et
 * les métriques shadow ne seront alimentées que par un échantillon minuscule et
 * biaisé.
 *
 * @param seriesConstructibles {@code min(easy/6, medium/10, hard/4)}. C'est un
 *        <b>minimum</b>, pas une moyenne : la bande la plus pauvre décide seule,
 *        et 200 questions MEDIUM ne servent à rien s'il n'y a que 3 HARD.
 * @param bandeLimitante la bande qui plafonne — ce qu'il faut produire en
 *        priorité, plutôt qu'« il manque des questions ».
 */
public record CatalogueCalibrationDto(
        SkillSection section,
        TargetLevel level,
        long taguees,
        long nonTaguees,
        long easy,
        long medium,
        long hard,
        int seriesConstructibles,
        String bandeLimitante
) {

    /** Le total du couple, tagué ou non. */
    public long total() {
        return taguees + nonTaguees;
    }

    /** Le rapport complet, un couple par ligne. */
    public record Inventaire(
            List<CatalogueCalibrationDto> couples,
            long totalTaguees,
            long totalNonTaguees,
            int couplesAvecAuMoinsUneSerie
    ) {}
}

package com.sejourfr.app.progression.dto;

import com.sejourfr.app.progression.config.ProgressionEngineMode;

import java.util.List;

/**
 * <b>Le rapport qui rend la bascule décidable</b> (V4.2 §47.4).
 *
 * <p>Il ne dit pas « on peut passer en ACTIVE ». Il donne les chiffres, et
 * surtout leur base : une précision de 100 % sur deux prédictions ne veut rien
 * dire, et masquer la taille de l'échantillon derrière un pourcentage est la
 * façon la plus simple de prendre une mauvaise décision en toute confiance.
 *
 * @param precisionSolid      {@code null} tant qu'aucune prédiction n'a reçu de
 *                            résultat — <b>absence de mesure, pas 0 %</b>.
 * @param predictionsAvecResultat la base réelle de {@code precisionSolid}.
 * @param objectifPrecision   le seuil de §47.4, servi pour que la console n'en
 *                            recopie pas la valeur.
 * @param recommandation      une phrase, en clair, sur ce que ces chiffres
 *                            permettent — ou ne permettent pas — de décider.
 */
public record ProgressionShadowReportDto(
        ProgressionEngineMode mode,
        int engineVersion,
        Double precisionSolid,
        long predictionsAvecResultat,
        long predictionsEnAttente,
        long predictionsTotal,
        double objectifPrecision,
        List<RepartitionEtat> repartitionEtats,
        String recommandation
) {

    /** Combien d'états dans chaque statut, tous candidats confondus. */
    public record RepartitionEtat(String status, long combien) {}
}

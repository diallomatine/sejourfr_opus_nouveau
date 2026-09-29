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
 * @param precisionSolid      🛑 {@code null} tant que {@code minOutcomeCount}
 *                            n'est pas atteint — <b>y compris quand la
 *                            précision serait calculable</b>. Un pourcentage
 *                            servi sur quatre issues finit toujours par être lu
 *                            comme une mesure ; le seul moyen sûr de l'empêcher
 *                            est de ne pas le rendre.
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
        int minOutcomeCount,
        Verdict verdict,
        List<RepartitionEtat> repartitionEtats,
        String recommandation
) {

    /**
     * Ce que ces chiffres permettent — <b>ou ne permettent pas</b> — de décider.
     *
     * <p>Trois états distincts, jamais confondus : ne rien avoir, ne pas en
     * avoir assez, et en avoir assez. Les deux premiers se ressemblent sur un
     * écran mais n'appellent pas la même chose — l'un veut dire « attendez que
     * des candidats passent des examens », l'autre « il en faut encore N ».
     */
    public enum Verdict {
        /** Aucune prédiction n'a de résultat. Absence de mesure, pas 0 %. */
        AUCUNE_DONNEE,
        /** Des résultats existent, mais sous {@code minOutcomeCount}. */
        ECHANTILLON_INSUFFISANT,
        /** Effectif atteint, précision sous l'objectif. */
        PRECISION_INSUFFISANTE,
        /** Effectif atteint et objectif tenu. La bascule reste une décision. */
        OBJECTIF_ATTEINT
    }

    /** Combien d'états dans chaque statut, tous candidats confondus. */
    public record RepartitionEtat(String status, long combien) {}
}

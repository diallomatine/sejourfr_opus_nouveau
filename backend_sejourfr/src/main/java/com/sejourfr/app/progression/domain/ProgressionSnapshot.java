package com.sejourfr.app.progression.domain;

/**
 * L'etat calcule d'un {@link ProgressionStateKey} a un instant donne — ce que le
 * moteur projette, jamais ce qu'il persiste comme verite definitive.
 *
 * <p>🛑 <b>Trois de ces champs ne sortent jamais vers un front</b> :
 * {@link #masteryScore}, {@link #confidence} et les accumulateurs epoch. Ils
 * n'existent que pour la console admin et {@code progression_prediction_log}
 * (§25 bis.2). Le front recoit {@link #status}, {@link #visibleProgress} et les
 * booleens derives — rien de quoi reconstituer un seuil.
 *
 * @param masteryScore    {@code null} quand aucune preuve n'existe.
 *                        <b>{@code null} veut dire inconnu, jamais mauvais</b> :
 *                        une absence de mesure ne devient pas le verdict le plus
 *                        bas.
 * @param visibleProgress {@code null} pour un palier sans la moindre preuve
 *                        directe (§18.6, invariant I41) — <b>jamais 0</b>. Le
 *                        candidat n'a pas regresse, il n'a jamais ete mesure.
 * @param practicePoints  points de parcours (§26) : ils alimentent la seule
 *                        progression visible, n'ajoutent aucune masse de
 *                        confiance et ne satisfont aucun gate.
 * @param microSumWeightedResultEpoch    la moitié manquante de l'agrégat de
 *                        famille (§27.3) : sans le résultat pondéré, la table
 *                        ne porterait qu'une masse et ne permettrait pas de
 *                        rejouer le cap micro ni d'auditer ce qui l'a rempli.
 */
public record ProgressionSnapshot(
        ProgressionStateKey stateKey,
        Double masteryScore,
        double confidence,
        ProgressionStatus status,
        boolean qualificationGate,
        boolean transferGate,
        boolean directQualification,
        Integer visibleProgress,
        double practicePoints,
        double sumWeightEpoch,
        double sumWeightedResultEpoch,
        double microSumWeightEpoch,
        double nonMicroSumWeightEpoch,
        double microSumWeightedResultEpoch,
        double nonMicroSumWeightedResultEpoch,
        int qualifyingEvidenceCount,
        int recentStrongNegativeCount,
        String levelCycleId
) {

    /** Aucune preuve directe n'a jamais alimente cet etat (§14.1). */
    public boolean hasNoDirectEvidence() {
        return sumWeightEpoch == 0.0d;
    }
}

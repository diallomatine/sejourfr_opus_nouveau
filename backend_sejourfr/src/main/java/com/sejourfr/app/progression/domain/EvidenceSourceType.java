package com.sejourfr.app.progression.domain;

/**
 * <b>La valeur pedagogique de ce que le candidat a reellement fait</b> — a ne
 * jamais confondre avec {@link EvidenceEntryPoint}, qui dit seulement d'ou il
 * est parti (V4.2 §5).
 *
 * <p>C'est cet axe, et lui seul, qui porte le {@code sourceWeight} de la
 * configuration versionnee (§4) et les {@code practicePoints} (§26). Le point
 * d'entree n'entre dans aucun calcul : {@code startedFromPlan == true} comme
 * condition d'admission d'une preuve est explicitement interdit (§1, T24).
 */
public enum EvidenceSourceType {

    /** Examen blanc complet, 4 domaines. Poids maximal (§24). */
    FULL_MOCK_EXAM,

    /** Examen blanc d'une seule epreuve (§23.5). */
    DOMAIN_MOCK,

    /** Vraie tache EE/EO complete — preuve de transfert (§17). */
    FULL_TASK,

    /** Re-verification d'une competence declaree prete (§14.3). */
    REASSESSMENT,

    /** Diagnostic initial. Ne verrouille jamais seul un palier (§16, T08). */
    DIAGNOSTIC,

    /** Serie CO/CE de 20 questions respectant le blueprint 6/10/4 (§6.2). */
    CO_CE_20_SERIES,

    /** Serie CO/CE hors blueprint : compte, mais ne qualifie jamais (§6.3). */
    CO_CE_20_SERIES_UNCALIBRATED,

    /** Micro-sujet du module Competences. Plafonne en confiance (§11.1). */
    MICRO_SKILL;

    /**
     * La famille de sources, pour le cap micro de {@code
     * eligibleEvidenceMassNow} en {@code PRODUCTIVE_SKILL} (§11.1).
     *
     * <p>Ce cap ne s'applique <b>jamais</b> a un {@code RECEPTIVE_LEVEL}
     * (§11.0) : CO/CE est protege par ses {@code sourceWeights}, son
     * {@code qualificationGate} et son {@code independenceClass}.
     */
    public EvidenceSourceFamily family() {
        return this == MICRO_SKILL
                ? EvidenceSourceFamily.MICRO
                : EvidenceSourceFamily.NON_MICRO;
    }
}

package com.sejourfr.app.progression.config;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.sejourfr.app.progression.domain.AssistanceLevel;
import com.sejourfr.app.progression.domain.EvidenceSourceType;
import com.sejourfr.app.progression.domain.IndependenceClass;
import com.sejourfr.app.progression.domain.ProgressionStateType;

import java.time.Instant;
import java.util.Map;

/**
 * <b>La configuration unique et versionnee du moteur de progression</b>
 * (V4.2 §4) — image en memoire de {@code progression-config-vN.json}.
 *
 * <p>🛑 <b>Aucune valeur metier n'est ecrite dans ce fichier Java.</b> Il n'y a
 * pas de valeur par defaut, pas de constante de repli, pas de {@code ?:} : une
 * cle absente du JSON est une erreur de demarrage, pas un zero silencieux.
 * C'est la seule facon de tenir l'invariant I32 — <i>tous les seuils viennent
 * d'une config versionnee unique</i> — et l'invariant I33 — <i>le fichier n'est
 * jamais auto-ajuste par le code</i>.
 *
 * <p>Changer une valeur metier n'est donc pas une edition : c'est un
 * {@code progression-config-v(N+1).json}, un {@code engineVersion} de plus et
 * un replay controle (§29). Un retour arriere est un changement de version
 * active, pas une migration.
 */
@JsonIgnoreProperties(ignoreUnknown = false)
public record ProgressionConfig(
        int engineVersion,
        @JsonProperty("weightEpoch") String weightEpochIso,
        double recencyHalfLifeDays,
        Map<EvidenceSourceType, Double> sourceWeights,
        Map<AssistanceLevel, Double> assistanceFactors,
        Map<IndependenceClass, Double> independenceFactors,
        Independence independence,
        Map<ProgressionStateType, Double> confidenceK,
        Thresholds thresholds,
        Map<ProgressionStateType, StrongEvidence> strongEvidence,
        QualificationGates qualificationGates,
        MicroEvidenceCaps microEvidenceCaps,
        VisibleProgress visibleProgress,
        ReceptiveSeriesBlueprint receptiveSeriesBlueprint,
        ShadowValidation shadowValidation,
        Maintenance maintenance
) {

    /**
     * L'origine du referentiel de poids (§10) — <b>lue en texte, exposee en
     * {@link Instant}</b>.
     *
     * <p>Le champ reste une chaine ISO-8601 dans le record parce que la config
     * se lit avec un {@code ObjectMapper} nu, sans module temps : une date qui
     * se deserialise « toute seule » est une dependance de plus sur le chemin du
     * demarrage, pour une valeur qu'on relit une fois par version.
     */
    public Instant weightEpoch() {
        return Instant.parse(weightEpochIso);
    }

    /** {@code lambda = ln(2) / recencyHalfLifeDays} (§8.1). */
    public double lambda() {
        return Math.log(2.0d) / recencyHalfLifeDays;
    }

    /** Le profil de seuils du type d'etat — jamais une constante en dur (§14). */
    public ThresholdProfile thresholdProfile(ProgressionStateType stateType) {
        return switch (stateType) {
            case RECEPTIVE_LEVEL -> thresholds.receptiveLevel();
            case PRODUCTIVE_SKILL -> thresholds.productiveSkill();
        };
    }

    /** La fenetre de recouvrement et son seuil (§12 bis.2, §12 bis.3). */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record Independence(
            int overlapWindowDays,
            double independenceOverlapThreshold
    ) {}

    /**
     * Les deux profils de seuils, nommes par leur {@link ProgressionStateType}.
     *
     * <p>Ils sont volontairement separes plutot que ranges dans une {@code Map} :
     * ils n'ont pas les memes champs — {@code readyForReassessment} n'existe
     * qu'en production — et le typage rend impossible de lire l'un pour l'autre.
     */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record Thresholds(
            @JsonProperty("RECEPTIVE_LEVEL") ReceptiveThresholds receptiveLevel,
            @JsonProperty("PRODUCTIVE_SKILL") ProductiveThresholds productiveSkill
    ) {}

    /** Ce que tout profil de seuils expose, quel que soit son type d'etat. */
    public sealed interface ThresholdProfile
            permits ReceptiveThresholds, ProductiveThresholds {
        double fragileMax();
        double progressIn();
        double progressOut();
        double solidIn();
        double solidOut();
        double minConfidenceForProgress();
        double minConfidenceForSolid();
    }

    /** Seuils CO/CE — echelle {@code result} corrigee du hasard (§4). */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record ReceptiveThresholds(
            double fragileMax,
            double progressIn,
            double progressOut,
            double solidIn,
            double solidOut,
            double minConfidenceForProgress,
            double minConfidenceForSolid
    ) implements ThresholdProfile {}

    /** Seuils EE/EO — echelle des observations IA {@code 0 / 0.5 / 1} (§4). */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record ProductiveThresholds(
            double fragileMax,
            double progressIn,
            double progressOut,
            double readyForReassessment,
            double solidIn,
            double solidOut,
            double minConfidenceForProgress,
            double minConfidenceForReady,
            double minConfidenceForSolid
    ) implements ThresholdProfile {}

    /** Ce qui fait une preuve « forte », positive ou negative (§15). */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record StrongEvidence(
            double positiveResult,
            double negativeResult,
            int windowDays,
            int negativeCountToDowngradeSolid
    ) {}

    /** Les seuils des gates de qualification (§16, §17). */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record QualificationGates(
            @JsonProperty("RECEPTIVE_LEVEL") ReceptiveGate receptiveLevel,
            @JsonProperty("PRODUCTIVE_SKILL") ProductiveGate productiveSkill
    ) {}

    /** Cas A / B / C du {@code qualificationGate} CO/CE (§16). */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record ReceptiveGate(
            double mockStrongResult,
            double seriesPositiveResult,
            double diagnosticPositiveResult,
            double confirmationPositiveResult
    ) {}

    /** Le {@code transferGate} EE/EO (§17). */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record ProductiveGate(double transferResult) {}

    /** Le plafond de masse de confiance apportee par les micro-sujets (§11.1). */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record MicroEvidenceCaps(double maxConfidenceMass) {}

    /** La progression <i>visible</i>, distincte de la maitrise (§9, §25, §26). */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record VisibleProgress(
            double coverageWeight,
            double masteryWeight,
            int unconfirmedCap,
            double practicePointsRequired,
            Map<EvidenceSourceType, Double> practicePoints
    ) {}

    /** Le blueprint d'une serie receptive qualifiante (§6.2, §7). */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record ReceptiveSeriesBlueprint(
            int questionCount,
            int easy,
            int medium,
            int hard
    ) {}

    /** Les criteres de validation du shadow mode (§47.4). */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record ShadowValidation(
            int predictionWindowDays,
            double minSolidPrecision
    ) {}

    /** L'age maximal d'un epoch avant replay de re-basage (§27.2.2). */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record Maintenance(int maxEpochAgeDays) {}
}

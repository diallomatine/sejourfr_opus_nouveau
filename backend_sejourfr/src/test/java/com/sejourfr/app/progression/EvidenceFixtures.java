package com.sejourfr.app.progression;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.domain.AssistanceLevel;
import com.sejourfr.app.progression.domain.CalibrationStatus;
import com.sejourfr.app.progression.domain.EvidenceEntryPoint;
import com.sejourfr.app.progression.domain.EvidenceSourceType;
import com.sejourfr.app.progression.domain.IndependenceClass;
import com.sejourfr.app.progression.domain.LearningEvidence;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Les preuves des tests d'acceptation, ecrites comme la spec les enonce :
 * « une serie calibree 16/20 a 4 options, sans assistance, contenu neuf ».
 *
 * <p>Les fabriques calculent le {@code result} <b>a la main</b>, avec la formule
 * de §6.1 recopiee ici. C'est volontaire : si le moteur se trompe de formule, un
 * fixture qui l'appellerait se tromperait avec lui et le test verdirait sur une
 * erreur commune.
 */
final class EvidenceFixtures {

    /** L'instant de reference des tests dont la spec dit « meme date ». */
    static final Instant T0 = Instant.parse("2026-03-01T09:00:00Z");

    static final UUID USER = UUID.fromString("00000000-0000-4000-8000-000000000001");

    private EvidenceFixtures() {
    }

    /** §6.1, recopie a la main — le denominateur est toujours totalQuestions. */
    static double chanceAdjusted(int correct, int total, int optionsPerQuestion) {
        double accuracy = (double) correct / total;
        double guessRate = 1.0d / optionsPerQuestion;
        return Math.clamp((accuracy - guessRate) / (1 - guessRate), 0.0d, 1.0d);
    }

    /** Une serie CO/CE calibree, contenu neuf, sans assistance. */
    static LearningEvidence serie(SkillSection section, TargetLevel level,
                                  int correct, int total, int options,
                                  String contentId, Instant occurredAt) {
        return base(section, level, EvidenceSourceType.CO_CE_20_SERIES, contentId, occurredAt)
                .result(chanceAdjusted(correct, total, options))
                .calibrationStatus(CalibrationStatus.CALIBRATED)
                .build();
    }

    /** La meme serie, mais hors blueprint : poids 0.50, jamais qualifiante. */
    static LearningEvidence serieNonCalibree(SkillSection section, TargetLevel level,
                                             int correct, int total, int options,
                                             String contentId, Instant occurredAt) {
        return base(section, level, EvidenceSourceType.CO_CE_20_SERIES_UNCALIBRATED,
                contentId, occurredAt)
                .result(chanceAdjusted(correct, total, options))
                .calibrationStatus(CalibrationStatus.UNCALIBRATED)
                .build();
    }

    /** Un examen blanc d'epreuve, mesure directe d'un palier. */
    static LearningEvidence examenEpreuve(SkillSection section, TargetLevel level,
                                          double result, String contentId, Instant occurredAt) {
        return base(section, level, EvidenceSourceType.DOMAIN_MOCK, contentId, occurredAt)
                .result(result)
                .calibrationStatus(CalibrationStatus.CALIBRATED)
                .build();
    }

    /** Un diagnostic : mesure directe, mais qui ne verrouille jamais seule. */
    static LearningEvidence diagnostic(SkillSection section, TargetLevel level,
                                       double result, Instant occurredAt) {
        return base(section, level, EvidenceSourceType.DIAGNOSTIC, "diag-" + level, occurredAt)
                .result(result)
                .calibrationStatus(CalibrationStatus.CALIBRATED)
                .build();
    }

    /** Un micro-sujet du module Competences, sur une competence EE/EO. */
    static LearningEvidence microSujet(SkillSection section, String skillId,
                                       double result, double scoringConfidence,
                                       String contentId, Instant occurredAt) {
        return competence(section, skillId, EvidenceSourceType.MICRO_SKILL,
                result, scoringConfidence, contentId, occurredAt);
    }

    /** Une vraie tache EE/EO complete — la preuve de transfert de §17. */
    static LearningEvidence vraieTache(SkillSection section, String skillId,
                                       double result, double scoringConfidence,
                                       String contentId, Instant occurredAt) {
        return competence(section, skillId, EvidenceSourceType.FULL_TASK,
                result, scoringConfidence, contentId, occurredAt);
    }

    private static LearningEvidence competence(SkillSection section, String skillId,
                                               EvidenceSourceType sourceType, double result,
                                               double scoringConfidence, String contentId,
                                               Instant occurredAt) {
        return LearningEvidence.builder()
                .id(UUID.randomUUID())
                .userId(USER)
                .attemptId(UUID.randomUUID())
                .occurredAt(occurredAt)
                .ingestedAt(occurredAt)
                .entryPoint(EvidenceEntryPoint.PLAN)
                .sourceType(sourceType)
                .section(section)
                .skillId(skillId)
                .result(result)
                .scoringConfidence(scoringConfidence)
                .assistanceLevel(AssistanceLevel.NONE)
                .contentId(contentId)
                .calibrationStatus(CalibrationStatus.CALIBRATED)
                .independenceClass(IndependenceClass.NEW_CONTENT)
                .engineVersionAtCreation(1)
                .metadata(Map.of())
                .build();
    }

    private static LearningEvidence.LearningEvidenceBuilder base(
            SkillSection section, TargetLevel level, EvidenceSourceType sourceType,
            String contentId, Instant occurredAt) {
        return LearningEvidence.builder()
                .id(UUID.randomUUID())
                .userId(USER)
                .attemptId(UUID.randomUUID())
                .occurredAt(occurredAt)
                .ingestedAt(occurredAt)
                .entryPoint(EvidenceEntryPoint.PLAN)
                .sourceType(sourceType)
                .section(section)
                .level(level)
                .scoringConfidence(1.0d)
                .assistanceLevel(AssistanceLevel.NONE)
                .contentId(contentId)
                .independenceClass(IndependenceClass.NEW_CONTENT)
                .engineVersionAtCreation(1)
                .metadata(Map.of());
    }

    /** Le {@code contentId} d'une serie : §12 bis.1, ordre des items indifferent. */
    static String contentIdDeSerie(List<String> questionIds) {
        return String.join("|", questionIds.stream().sorted().toList());
    }
}

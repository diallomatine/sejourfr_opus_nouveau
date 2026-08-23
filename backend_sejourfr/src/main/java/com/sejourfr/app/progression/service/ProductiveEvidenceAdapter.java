package com.sejourfr.app.progression.service;

import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.progression.config.ProgressionProperties;
import com.sejourfr.app.progression.domain.AssistanceLevel;
import com.sejourfr.app.progression.domain.CalibrationStatus;
import com.sejourfr.app.progression.domain.EvidenceEntryPoint;
import com.sejourfr.app.progression.domain.EvidenceSourceType;
import com.sejourfr.app.progression.domain.IndependenceClass;
import com.sejourfr.app.progression.domain.LearningEvidence;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * <b>Ce qui transforme une évaluation IA d'expression en preuves</b>
 * (V4.2 §6.5, §11.1, §17).
 *
 * <p>Trois choses portent ce fichier.
 *
 * <h2>1. Non observé n'est pas raté</h2>
 *
 * <p>🛑 Une compétence que l'IA n'a <b>pas observée</b> ne produit
 * <b>aucune preuve</b> — surtout pas un {@code result = 0}. Le candidat n'a pas
 * échoué sur cette compétence : elle n'était simplement pas mesurable dans ce
 * qu'il a écrit ou dit. C'est exactement la confusion {@code null}/{@code 0} qui
 * a produit les faux {@code A1_NON_ATTEINT} de V040–V042.
 *
 * <h2>2. Les micro-sujets ne prouvent pas le transfert</h2>
 *
 * <p>Ils entrent en {@code MICRO_SKILL} : poids 0,35, et surtout masse de
 * confiance <b>plafonnée à 0,80</b> (§11.1). Cinquante micro-sujets parfaits ne
 * peuvent donc jamais, à eux seuls, rendre une compétence {@code SOLID}. Il faut
 * une vraie tâche — c'est le {@code transferGate} de §17, et c'est toute la
 * différence entre « sait appliquer une consigne isolée » et « sait produire ».
 *
 * <p>L'inverse est vrai aussi : deux vraies tâches réussies suffisent, et on
 * n'impose pas les cinq micro-sujets à qui a déjà prouvé le transfert
 * (invariant I28).
 *
 * <h2>3. Le sujet fait l'identité, pas la tentative</h2>
 *
 * <p>Reprendre le même petit sujet après avoir lu sa correction n'est pas une
 * preuve neuve (§12). Le {@code contentId} porte donc l'identifiant du sujet.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ProductiveEvidenceAdapter {

    /**
     * L'échelle de confiance de l'évaluateur IA, traduite en {@code [0,1]}.
     *
     * <p>Le contrat de sortie de l'IA porte un <b>enum</b>
     * ({@code LOW | MEDIUM | HIGH}), pas un nombre — c'est une contrainte dure
     * de tool-schema, et on ne réécrit pas un contrat livré. La traduction doit
     * donc bien vivre quelque part, et c'est ici.
     *
     * <p>⚠️ <b>Ces trois valeurs sont un choix d'implémentation, pas une règle
     * validée.</b> Elles sont candidates à passer dans
     * {@code progression-config-v2.json} le jour où on recalibre — et d'ici là
     * elles restent volontairement prudentes : {@code HIGH} ne vaut pas 1,00,
     * parce qu'une évaluation IA n'est jamais une certitude.
     */
    private static final Map<ObservationConfidence, Double> CONFIANCE_IA = Map.of(
            ObservationConfidence.LOW, 0.50d,
            ObservationConfidence.MEDIUM, 0.75d,
            ObservationConfidence.HIGH, 0.95d);

    private final ProgressionProperties properties;
    private final ProgressionIngestionService ingestionService;
    private final ContentIdentityService contentIdentityService;

    /**
     * Une observation de compétence issue d'une production complète.
     *
     * <p><b>Valeurs, pas entités</b> : rien de détaché ne traverse la frontière
     * de transaction.
     */
    public record ObservationCompetence(
            String skillCode,
            boolean observed,
            LearningPlanSkillStatus status,
            ObservationConfidence confidence
    ) {}

    /**
     * Enregistre ce qu'une production EE/EO complète prouve, compétence par
     * compétence.
     *
     * <p><b>Best-effort, jamais bloquant</b>, dans sa propre transaction : la
     * livraison d'une évaluation au candidat ne doit pas dépendre de ce que le
     * moteur en fait.
     *
     * @return le nombre de preuves écrites
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public int ingererProduction(UUID userId, UUID attemptId, UUID sujetId, SkillSection section,
                                 EvidenceSourceType sourceType, EvidenceEntryPoint entryPoint,
                                 Instant occurredAt, List<ObservationCompetence> observations) {
        if (userId == null || sujetId == null || observations.isEmpty()) {
            return 0;
        }
        String contentId = contentIdentityService.contentIdDeSujet(sujetId);
        int ecrites = 0;

        for (ObservationCompetence observation : observations) {
            // 🛑 Non observé = pas de preuve. Pas un zéro.
            if (!observation.observed() || observation.skillCode() == null) {
                continue;
            }
            Double result = resultDe(observation.status());
            if (result == null) {
                continue;
            }
            if (ingerer(userId, attemptId, section, observation.skillCode(), sourceType,
                    entryPoint, occurredAt, result,
                    CONFIANCE_IA.getOrDefault(observation.confidence(), 0.50d),
                    AssistanceLevel.NONE, contentId,
                    Map.of("status", observation.status().name()))) {
                ecrites++;
            }
        }
        return ecrites;
    }

    /**
     * Enregistre ce qu'un micro-sujet du module Compétences prouve.
     *
     * @param guide le sujet affichait-il une aide (checklist, amorce, astuce) ?
     *              Les micro-sujets en portent par conception : c'est leur
     *              raison d'être pédagogique, et c'est aussi une assistance
     *              réelle, donc un poids réduit (§8.2). Une preuve assistée doit
     *              peser moins — sans plancher artificiel.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public boolean ingererMicroSujet(UUID userId, UUID attemptId, UUID sujetId,
                                     SkillSection section, String skillCode,
                                     SkillCriterionStatus criterion, boolean guide,
                                     Instant occurredAt) {
        if (userId == null || sujetId == null || skillCode == null || criterion == null) {
            return false;
        }
        return ingerer(userId, attemptId, section, skillCode, EvidenceSourceType.MICRO_SKILL,
                EvidenceEntryPoint.COMPETENCES, occurredAt, resultDe(criterion),
                // Un critère unique évalué par l'IA sur une production courte :
                // moins de matière qu'une tâche complète, donc moins de
                // certitude. On le dit plutôt que de faire comme si.
                CONFIANCE_IA.get(ObservationConfidence.MEDIUM),
                guide ? AssistanceLevel.LIGHT : AssistanceLevel.NONE,
                contentIdentityService.contentIdDeSujet(sujetId),
                Map.of("criterion", criterion.name()));
    }

    private boolean ingerer(UUID userId, UUID attemptId, SkillSection section, String skillCode,
                            EvidenceSourceType sourceType, EvidenceEntryPoint entryPoint,
                            Instant occurredAt, double result, double scoringConfidence,
                            AssistanceLevel assistance, String contentId,
                            Map<String, Object> metadata) {
        IndependenceClass independance = contentIdentityService.classerSujet(
                userId, section, skillCode, contentId, occurredAt);

        LearningEvidence preuve = LearningEvidence.builder()
                .userId(userId)
                .attemptId(attemptId)
                .occurredAt(occurredAt)
                .ingestedAt(Instant.now())
                .entryPoint(entryPoint)
                .sourceType(sourceType)
                .section(section)
                .skillId(skillCode)
                .result(result)
                .scoringConfidence(scoringConfidence)
                .assistanceLevel(assistance)
                .contentId(contentId)
                // Le blueprint 6/10/4 est une notion de série QCM. Une production
                // n'en a pas : elle est calibrée par la rubrique qui la note.
                .calibrationStatus(CalibrationStatus.CALIBRATED)
                .independenceClass(independance)
                .engineVersionAtCreation(properties.getEngineVersion())
                .metadata(new LinkedHashMap<>(metadata))
                .build();

        return ingestionService.ingerer(preuve).isPresent();
    }

    /**
     * §6.5 — le mapping normatif des observations IA.
     *
     * <p>🛑 Aucune correction du hasard ici : on ne coche pas une production, on
     * la juge. Et {@code NOT_OBSERVED} rend {@code null} — <b>absence de mesure,
     * jamais verdict le plus bas</b>.
     */
    private static Double resultDe(LearningPlanSkillStatus status) {
        return switch (status) {
            case SOLID -> 1.00d;
            case TO_REINFORCE -> 0.50d;
            case PRIORITY -> 0.00d;
            case NOT_OBSERVED -> null;
        };
    }

    /** §6.5 — le critère unique d'un micro-sujet, sur la même échelle. */
    private static double resultDe(SkillCriterionStatus criterion) {
        return switch (criterion) {
            case VALIDATED -> 1.00d;
            case PARTIAL -> 0.50d;
            case NOT_VALIDATED -> 0.00d;
        };
    }
}

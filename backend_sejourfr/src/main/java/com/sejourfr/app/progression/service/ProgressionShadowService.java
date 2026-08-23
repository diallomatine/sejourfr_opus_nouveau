package com.sejourfr.app.progression.service;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.config.ProgressionConfig;
import com.sejourfr.app.progression.config.ProgressionProperties;
import com.sejourfr.app.progression.domain.ProgressionSnapshot;
import com.sejourfr.app.progression.domain.ProgressionStatus;
import com.sejourfr.app.progression.entity.LearningEvidenceRecord;
import com.sejourfr.app.progression.entity.ProgressionPredictionRecord;
import com.sejourfr.app.progression.manager.LearningEvidenceManager;
import com.sejourfr.app.progression.manager.ProgressionPredictionManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * <b>Le shadow mode</b> : le moteur dit ce qu'il croit, on note, et on regarde
 * plus tard s'il avait raison (V4.2 §47).
 *
 * <p>C'est ce qui sépare un moteur calibré d'un moteur qui pilote le parcours de
 * vrais candidats sur des seuils encore hypothétiques. Les valeurs de
 * {@code progression-config-v1.json} sont des <b>hypothèses produit</b> ; le
 * shadow mode sert à les confronter aux vrais candidats SejourFR avant de leur
 * donner le volant.
 *
 * <p>🛑 <b>Une prédiction est figée à {@code predictedAt}</b> (invariant I35).
 * On ne la recalcule jamais avec l'état d'aujourd'hui : elle aurait toujours
 * raison, et ne mesurerait plus rien.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ProgressionShadowService {

    /** §47.2 — les transitions qui valent la peine d'être notées. */
    private static final Set<ProgressionStatus> TRANSITIONS_NOTABLES = Set.of(
            ProgressionStatus.SOLID,
            ProgressionStatus.READY_FOR_REASSESSMENT,
            ProgressionStatus.WATCH);

    private final ProgressionConfig config;
    private final ProgressionProperties properties;
    private final ProgressionPredictionManager predictionManager;
    private final LearningEvidenceManager evidenceManager;

    /**
     * Consigne une prédiction si l'état vient d'atteindre une transition notable.
     *
     * <p>Une seule par cycle et par statut (§47.2) : un candidat qui repasse
     * plusieurs fois par {@code SOLID} compterait sinon dix fois et écraserait
     * la métrique.
     */
    @Transactional
    public Optional<ProgressionPredictionRecord> consignerSiTransitionNotable(
            UUID userId, ProgressionSnapshot etat, SkillSection section) {
        if (!TRANSITIONS_NOTABLES.contains(etat.status())) {
            return Optional.empty();
        }
        String stateKey = etat.stateKey().asText();
        if (predictionManager.dejaPreditPourCeCycle(
                userId, stateKey, etat.levelCycleId(), etat.status())) {
            return Optional.empty();
        }

        ProgressionPredictionRecord prediction = new ProgressionPredictionRecord();
        prediction.setUserId(userId);
        prediction.setStateKey(stateKey);
        prediction.setStateType(etat.stateKey().stateType());
        prediction.setEngineVersion(properties.getEngineVersion());
        prediction.setPredictedAt(Instant.now());
        prediction.setLevelCycleId(etat.levelCycleId());
        prediction.setMasteryScore(etat.masteryScore());
        prediction.setConfidence(etat.confidence());
        prediction.setStatus(etat.status());
        prediction.setReadyForMock(etat.status() == ProgressionStatus.SOLID
                || etat.status() == ProgressionStatus.READY_FOR_REASSESSMENT);
        prediction.setDirectQualification(etat.directQualification());
        prediction.setPrerequisiteSatisfied(false);
        prediction.setPredictionReason(etat.status().name());
        return Optional.of(predictionManager.enregistrer(prediction));
    }

    /**
     * §47.3 — rattache à chaque prédiction en attente le <b>premier</b> examen
     * qualifiant du même {@code stateKey} survenu dans la fenêtre.
     *
     * <p>« Premier » et « dans la fenêtre » sont tous deux normatifs : prendre
     * le meilleur examen des six mois suivants mesurerait la persévérance du
     * candidat, pas la justesse de la prédiction.
     */
    @Transactional
    public int rattacherResultats(Instant now) {
        int fenetre = config.shadowValidation().predictionWindowDays();
        int rattaches = 0;

        for (ProgressionPredictionRecord prediction
                : predictionManager.enAttenteDeResultat(properties.getEngineVersion())) {
            Optional<Cle> cle = Cle.depuis(prediction.getStateKey());
            if (cle.isEmpty()) {
                continue;
            }
            Instant limite = prediction.getPredictedAt().plus(Duration.ofDays(fenetre));
            if (now.isBefore(prediction.getPredictedAt())) {
                continue;
            }
            List<LearningEvidenceRecord> examens = evidenceManager.examensQualifiants(
                    prediction.getUserId(), cle.get().section(), cle.get().level(),
                    prediction.getPredictedAt(), limite);
            if (examens.isEmpty()) {
                continue;
            }
            LearningEvidenceRecord premier = examens.getFirst();
            prediction.setOutcomeAttemptId(premier.getAttemptId());
            prediction.setOutcomeResult(premier.getResult());
            prediction.setOutcomeAt(premier.getOccurredAt());
            predictionManager.enregistrer(prediction);
            rattaches++;
        }
        return rattaches;
    }

    /**
     * §47.4 — la métrique primaire : parmi les prédictions {@code SOLID} qui ont
     * reçu un résultat, quelle proportion a été confirmée par l'examen suivant ?
     *
     * <p>Objectif initial : 70 %. 🛑 <b>Sous ce seuil, on ne bricole pas
     * {@code progression-config-v1.json}</b> : on analyse les données, on crée
     * une v2, on incrémente {@code engineVersion}, on rejoue. Un ajustement
     * sur place effacerait la trace de ce qu'on croyait avant.
     *
     * @return la précision, ou vide si aucune prédiction n'a encore de résultat
     */
    public Optional<Double> precisionSolid() {
        List<ProgressionPredictionRecord> avecResultat = predictionManager.avecResultat(
                ProgressionStatus.SOLID, properties.getEngineVersion());
        if (avecResultat.isEmpty()) {
            return Optional.empty();
        }
        double seuil = config.qualificationGates().receptiveLevel().seriesPositiveResult();
        long confirmees = avecResultat.stream()
                .filter(p -> p.getOutcomeResult() != null && p.getOutcomeResult() >= seuil)
                .count();
        return Optional.of((double) confirmees / avecResultat.size());
    }

    /** Le moteur a-t-il le droit de piloter le Plan ? (§47) */
    public boolean piloteLePlan() {
        return properties.isActive();
    }

    /** {@code CO:A2} — relu depuis sa forme textuelle. */
    private record Cle(SkillSection section, TargetLevel level) {

        static Optional<Cle> depuis(String stateKey) {
            String[] parts = stateKey.split(":", 2);
            if (parts.length != 2) {
                return Optional.empty();
            }
            try {
                return Optional.of(new Cle(
                        SkillSection.valueOf(parts[0]), TargetLevel.valueOf(parts[1])));
            } catch (IllegalArgumentException e) {
                // Une compétence productive : pas de palier à rattacher.
                return Optional.empty();
            }
        }
    }
}

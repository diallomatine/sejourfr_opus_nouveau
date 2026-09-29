package com.sejourfr.app.progression.manager;

import com.sejourfr.app.progression.domain.ProgressionStatus;
import com.sejourfr.app.progression.entity.ProgressionPredictionRecord;
import com.sejourfr.app.progression.repository.ProgressionPredictionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

/** Le seul accès au journal de prédictions du shadow mode. */
@Component
@RequiredArgsConstructor
public class ProgressionPredictionManager {

    private final ProgressionPredictionRepository repository;

    public ProgressionPredictionRecord enregistrer(ProgressionPredictionRecord prediction) {
        return repository.save(prediction);
    }

    public List<ProgressionPredictionRecord> enAttenteDeResultat(int engineVersion) {
        return repository.findEnAttenteDeResultat(engineVersion);
    }

    /**
     * §47.2 — pour la métrique primaire, on ne garde que la <b>première</b>
     * transition vers SOLID d'un cycle. Sans ça, un candidat qui repasse
     * plusieurs fois par SOLID compterait dix fois et écraserait la mesure.
     */
    public boolean dejaPreditPourCeCycle(UUID userId, String stateKey, String levelCycleId,
                                         ProgressionStatus status) {
        return repository.existsByUserIdAndStateKeyAndLevelCycleIdAndStatus(
                userId, stateKey, levelCycleId, status);
    }

    public List<ProgressionPredictionRecord> avecResultat(ProgressionStatus status,
                                                          int engineVersion) {
        return repository.findAvecResultat(status, engineVersion);
    }

    public List<ProgressionPredictionRecord> pourUtilisateur(UUID userId) {
        return repository.findByUserIdOrderByPredictedAtAsc(userId);
    }
}

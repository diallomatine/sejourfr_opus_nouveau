package com.sejourfr.app.progression.manager;

import com.sejourfr.app.progression.domain.ProgressionSnapshot;
import com.sejourfr.app.progression.entity.ProgressionStateRecord;
import com.sejourfr.app.progression.repository.ProgressionStateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Le seul accès à la projection matérialisée des états. */
@Component
@RequiredArgsConstructor
public class ProgressionStateManager {

    private final ProgressionStateRepository repository;

    public Optional<ProgressionStateRecord> trouver(UUID userId, String stateKey,
                                                    int engineVersion) {
        return repository.findByUserIdAndStateKeyAndEngineVersion(userId, stateKey, engineVersion);
    }

    public List<ProgressionStateRecord> tousLesEtats(UUID userId, int engineVersion) {
        return repository.findByUserIdAndEngineVersion(userId, engineVersion);
    }

    /**
     * Écrit la projection, en créant la ligne au besoin.
     *
     * <p>Le {@code visibleProgress} servi ne redescend pas dans un cycle (§25) :
     * il prend le maximum entre ce qui était affiché et ce que le moteur vient
     * de calculer. Un {@code null} calculé — palier sans preuve directe (§18.6)
     * — <b>écrase</b> quand même l'ancien : c'est le cas de la révocation de
     * prérequis, où le palier redevient « jamais mesuré » et ne doit surtout pas
     * réafficher un pourcentage hérité.
     */
    public ProgressionStateRecord enregistrer(UUID userId, int engineVersion,
                                              ProgressionSnapshot snapshot,
                                              Instant lastEvidenceAt) {
        String stateKey = snapshot.stateKey().asText();
        ProgressionStateRecord record = repository
                .findByUserIdAndStateKeyAndEngineVersion(userId, stateKey, engineVersion)
                .orElseGet(() -> {
                    ProgressionStateRecord neuf = new ProgressionStateRecord();
                    neuf.setUserId(userId);
                    neuf.setStateKey(stateKey);
                    neuf.setEngineVersion(engineVersion);
                    return neuf;
                });

        Integer visibleAvant = record.getVisibleProgress();
        record.setStateType(snapshot.stateKey().stateType());
        record.setMasteryScore(snapshot.masteryScore());
        record.setConfidence(snapshot.confidence());
        record.setStatus(snapshot.status());
        record.setSumWeightEpoch(snapshot.sumWeightEpoch());
        record.setSumWeightedResultEpoch(snapshot.sumWeightedResultEpoch());
        record.setMicroSumWeightEpoch(snapshot.microSumWeightEpoch());
        record.setNonMicroSumWeightEpoch(snapshot.nonMicroSumWeightEpoch());
        record.setQualifyingEvidenceCount(snapshot.qualifyingEvidenceCount());
        record.setRecentStrongNegativeCount(snapshot.recentStrongNegativeCount());
        record.setQualificationGate(snapshot.qualificationGate());
        record.setTransferGate(snapshot.transferGate());
        record.setDirectQualification(snapshot.directQualification());
        record.setPracticePoints(snapshot.practicePoints());
        record.setLevelCycleId(snapshot.levelCycleId());
        record.setLastEvidenceAt(lastEvidenceAt);
        record.setUpdatedAt(Instant.now());

        // Écrit en deux branches et non en ternaire : `Math.max(int, int)` rend
        // un `int`, ce qui force Java à déballer l'autre branche — et un
        // `visibleProgress` nul, qui est le cas NORMAL d'un palier jamais
        // mesuré (§18.6), partait alors en NullPointerException.
        Integer visibleCalcule = snapshot.visibleProgress();
        if (visibleCalcule == null || visibleAvant == null) {
            record.setVisibleProgress(visibleCalcule);
        } else {
            record.setVisibleProgress(Math.max(visibleAvant, visibleCalcule));
        }

        return repository.save(record);
    }

    /** Un replay repart d'une projection vide pour cette version du moteur (§29). */
    public void purgerVersion(UUID userId, int engineVersion) {
        repository.deleteByUserIdAndEngineVersion(userId, engineVersion);
    }
}

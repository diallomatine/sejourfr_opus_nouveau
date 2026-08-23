package com.sejourfr.app.progression.manager;

import com.sejourfr.app.progression.domain.EvidenceSourceFamily;
import com.sejourfr.app.progression.domain.ProgressionSnapshot;
import com.sejourfr.app.progression.entity.ProgressionFamilyAggregateRecord;
import com.sejourfr.app.progression.repository.ProgressionFamilyAggregateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** Le seul accès aux agrégats par famille de sources (§27.3). */
@Component
@RequiredArgsConstructor
public class ProgressionFamilyAggregateManager {

    private final ProgressionFamilyAggregateRepository repository;

    /**
     * Écrit les deux lignes — {@code MICRO} et {@code NON_MICRO} — d'une clé.
     *
     * <p>Les deux, <b>toujours</b>, même à zéro. Une famille absente serait
     * indiscernable d'une famille jamais calculée, et c'est exactement le genre
     * de trou qui fait qu'on ne peut plus auditer le cap micro six mois plus
     * tard.
     */
    public void enregistrer(UUID userId, int engineVersion, ProgressionSnapshot snapshot) {
        String stateKey = snapshot.stateKey().asText();
        ecrire(userId, engineVersion, stateKey, EvidenceSourceFamily.MICRO,
                snapshot.microSumWeightEpoch(), snapshot.microSumWeightedResultEpoch());
        ecrire(userId, engineVersion, stateKey, EvidenceSourceFamily.NON_MICRO,
                snapshot.nonMicroSumWeightEpoch(), snapshot.nonMicroSumWeightedResultEpoch());
    }

    public List<ProgressionFamilyAggregateRecord> tous(UUID userId, int engineVersion) {
        return repository.findByUserIdAndEngineVersion(userId, engineVersion);
    }

    /** Un replay repart d'une ventilation vide pour cette version (§29). */
    public void purgerVersion(UUID userId, int engineVersion) {
        repository.deleteByUserIdAndEngineVersion(userId, engineVersion);
    }

    private void ecrire(UUID userId, int engineVersion, String stateKey,
                        EvidenceSourceFamily famille, double masse, double resultatPondere) {
        ProgressionFamilyAggregateRecord record = repository
                .findByUserIdAndStateKeyAndSourceFamilyAndEngineVersion(
                        userId, stateKey, famille, engineVersion)
                .orElseGet(() -> {
                    ProgressionFamilyAggregateRecord neuf = new ProgressionFamilyAggregateRecord();
                    neuf.setUserId(userId);
                    neuf.setStateKey(stateKey);
                    neuf.setSourceFamily(famille);
                    neuf.setEngineVersion(engineVersion);
                    return neuf;
                });
        record.setSumWeightEpoch(masse);
        record.setSumWeightedResultEpoch(resultatPondere);
        record.setUpdatedAt(Instant.now());
        repository.save(record);
    }
}

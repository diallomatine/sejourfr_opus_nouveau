package com.sejourfr.app.manager;

import com.sejourfr.app.repository.AdminUserReadRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Lectures sans effet de bord de la console admin « Utilisateurs ». */
@Component
@RequiredArgsConstructor
public class AdminUserReadManager {

    private final AdminUserReadRepository repository;

    public List<UUID> findUserIdsWithOpenPurchase(Instant now) {
        return repository.findUserIdsWithOpenPurchase(now);
    }

    /** Dernière activité d'entraînement par compte ; un compte sans activité est absent de la map. */
    public Map<UUID, Instant> findLastActivity(Collection<UUID> userIds) {
        Map<UUID, Instant> out = new HashMap<>();
        if (userIds.isEmpty()) return out;
        for (AdminUserReadRepository.LastActivity a : repository.findLastActivity(userIds)) {
            out.put(a.getUserId(), a.getAt());
        }
        return out;
    }

    public List<AdminUserReadRepository.CurrentCycle> findCurrentCycles(UUID userId) {
        return repository.findCurrentCycles(userId);
    }

    public List<AdminUserReadRepository.ModuleCount> countHistorisedCycles(UUID userId) {
        return repository.countHistorisedCycles(userId);
    }

    public List<AdminUserReadRepository.ModuleDate> findLastCompletedDiagnostics(UUID userId) {
        return repository.findLastCompletedDiagnostics(userId);
    }
}

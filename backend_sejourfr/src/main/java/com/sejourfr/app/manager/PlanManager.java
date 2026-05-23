package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.repository.PlanRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

/**
 * Couche d'acces aux donnees pour {@link Plan}.
 */
@Component
@RequiredArgsConstructor
public class PlanManager {

    private final PlanRepository repository;

    public List<Plan> findAll() {
        return repository.findAll();
    }

    public Optional<Plan> findByCode(String code) {
        return repository.findByCode(code);
    }

    /**
     * Retrouve un Plan à partir d'un SKU Apple App Store. Utilisé après
     * validation d'un reçu IAP : le store nous donne le productId, on remonte
     * au Plan pour savoir quel {@code ModuleAccess} ouvrir (CIVIQUE / INTEGRAL).
     */
    public Optional<Plan> findByAppleProductId(String appleProductId) {
        return repository.findByAppleProductId(appleProductId);
    }

    public Optional<Plan> findByGoogleProductId(String googleProductId) {
        return repository.findByGoogleProductId(googleProductId);
    }
}

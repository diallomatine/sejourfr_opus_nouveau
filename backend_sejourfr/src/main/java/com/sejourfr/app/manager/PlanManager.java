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
}

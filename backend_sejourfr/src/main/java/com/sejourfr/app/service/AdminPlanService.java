package com.sejourfr.app.service;

import com.sejourfr.app.dto.AdminPlanDto;
import com.sejourfr.app.dto.AdminPlanUpdateRequest;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.mapper.PlanMapper;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * Service admin pour la gestion des Plans : listing complet (actifs + inactifs)
 * et mise à jour partielle des champs éditables (prix, store IDs, activation).
 *
 * <p>Les Plans sont créés en migration Flyway, pas via UI — pas de
 * {@code create} ni {@code delete} ici, juste {@code update}.
 */
@Service
@RequiredArgsConstructor
public class AdminPlanService {

    private final PlanManager planManager;
    private final PlanMapper planMapper;

    /**
     * Tous les plans triés par module (NONE → CIVIQUE → INTEGRAL) puis par
     * prix croissant. Inclut les inactifs (FREE et anciens plans dépréciés)
     * pour permettre la réactivation depuis l'admin.
     */
    @Transactional(readOnly = true)
    public List<AdminPlanDto> listAll() {
        return planManager.findAll().stream()
                .sorted(Comparator
                        .comparing((Plan p) -> p.getModuleAccess().ordinal())
                        .thenComparing(Plan::getPrice))
                .map(planMapper::toAdminDto)
                .toList();
    }

    @Transactional
    public AdminPlanDto update(UUID id, AdminPlanUpdateRequest req) {
        Plan plan = planManager.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Plan introuvable: " + id));

        if (req.price() != null) {
            plan.setPrice(req.price());
        }
        if (req.originalPrice() != null) {
            // Convention : 0 ou négatif → on retire le prix barré.
            plan.setOriginalPrice(req.originalPrice().compareTo(BigDecimal.ZERO) > 0
                    ? req.originalPrice() : null);
        }
        if (req.active() != null) {
            plan.setActive(req.active());
        }
        if (req.stripePriceId() != null) {
            plan.setStripePriceId(normalizeStoreId(req.stripePriceId()));
        }
        if (req.appleProductId() != null) {
            plan.setAppleProductId(normalizeStoreId(req.appleProductId()));
        }
        if (req.googleProductId() != null) {
            plan.setGoogleProductId(normalizeStoreId(req.googleProductId()));
        }

        validateConsistency(plan);
        Plan saved = planManager.save(plan);
        return planMapper.toAdminDto(saved);
    }

    /**
     * Convertit une chaîne vide/whitespace en null (= effacer le SKU côté DB,
     * désactive l'index unique partiel). Toute autre valeur est trim().
     */
    private String normalizeStoreId(String raw) {
        String trimmed = raw.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    /**
     * Garde anti-incohérence : un Plan actif et payant doit avoir au moins
     * UN store ID renseigné pour être vendable. Empêche un admin d'activer
     * par erreur un Plan sans canal de vente.
     */
    private void validateConsistency(Plan plan) {
        if (!plan.isActive()) return;
        if (plan.getPrice() == null || plan.getPrice().compareTo(BigDecimal.ZERO) <= 0) {
            return;
        }
        boolean hasAnyStoreId = (plan.getStripePriceId() != null && !plan.getStripePriceId().isBlank())
                || (plan.getAppleProductId() != null && !plan.getAppleProductId().isBlank())
                || (plan.getGoogleProductId() != null && !plan.getGoogleProductId().isBlank());
        if (!hasAnyStoreId) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Un plan payant actif doit avoir au moins un Stripe Price ID, Apple Product ID ou Google Product ID renseigné."
            );
        }
    }
}

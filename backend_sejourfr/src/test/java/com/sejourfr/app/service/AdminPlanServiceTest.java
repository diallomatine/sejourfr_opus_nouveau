package com.sejourfr.app.service;

import com.sejourfr.app.dto.AdminPlanDto;
import com.sejourfr.app.dto.AdminPlanUpdateRequest;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.enums.BillingCycle;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PlanPurchaseType;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.mapper.PlanMapper;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Couvre le PATCH partiel d'un Plan et la garde anti-incohérence : un plan
 * payant actif doit avoir au moins un store ID. Plus la normalisation des SKU
 * (vide → null), l'effacement du prix barré et le tri du listing. Test
 * unitaire pur.
 */
class AdminPlanServiceTest {

    private PlanManager planManager;
    private PlanMapper planMapper;
    private AdminPlanService service;

    @BeforeEach
    void setUp() {
        planManager = mock(PlanManager.class);
        planMapper = mock(PlanMapper.class);
        service = new AdminPlanService(planManager, planMapper);
        when(planManager.save(any(Plan.class))).thenAnswer(inv -> inv.getArgument(0));
        // Le mapper renvoie un DTO qui écho le code + module pour les assertions d'ordre.
        when(planMapper.toAdminDto(any(Plan.class))).thenAnswer(inv -> {
            Plan p = inv.getArgument(0);
            return new AdminPlanDto(
                    p.getId(), p.getCode(), p.getName(), BillingCycle.MONTHLY,
                    p.getPrice(), p.getOriginalPrice(), p.getModuleAccess(),
                    p.getDurationDays(), PlanPurchaseType.ONE_TIME, p.isActive(),
                    p.getStripePriceId(), p.getAppleProductId(), p.getGoogleProductId());
        });
    }

    private static Plan plan(String code, ModuleAccess access, String price) {
        Plan p = new Plan();
        p.setId(UUID.randomUUID());
        p.setCode(code);
        p.setName(code);
        p.setModuleAccess(access);
        p.setPrice(new BigDecimal(price));
        p.setActive(true);
        return p;
    }

    @Test
    void listAll_trieParModulePuisPrix() {
        Plan integral = plan("INTEGRAL", ModuleAccess.INTEGRAL, "79.99");
        Plan civiqueCher = plan("CIVIQUE_1AN", ModuleAccess.CIVIQUE, "29.99");
        Plan civiquePasCher = plan("CIVIQUE_3MOIS", ModuleAccess.CIVIQUE, "9.99");
        Plan free = plan("FREE", ModuleAccess.NONE, "0.00");
        when(planManager.findAll()).thenReturn(List.of(integral, civiqueCher, civiquePasCher, free));

        List<AdminPlanDto> result = service.listAll();

        assertThat(result).extracting(AdminPlanDto::code)
                .containsExactly("FREE", "CIVIQUE_3MOIS", "CIVIQUE_1AN", "INTEGRAL");
    }

    @Test
    void update_introuvable_leveEntityNotFound() {
        UUID id = UUID.randomUUID();
        when(planManager.findById(id)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.update(id,
                new AdminPlanUpdateRequest(null, null, null, null, null, null)))
                .isInstanceOf(EntityNotFoundException.class);
    }

    @Test
    void update_appliqueChampsNonNuls_seulement() {
        UUID id = UUID.randomUUID();
        Plan p = plan("CIVIQUE_3MOIS", ModuleAccess.CIVIQUE, "9.99");
        p.setStripePriceId("price_existing");
        when(planManager.findById(id)).thenReturn(Optional.of(p));

        service.update(id, new AdminPlanUpdateRequest(
                new BigDecimal("12.99"), null, null, null, null, null));

        assertThat(p.getPrice()).isEqualByComparingTo("12.99");
        // Champs non fournis inchangés.
        assertThat(p.getStripePriceId()).isEqualTo("price_existing");
        verify(planManager).save(p);
    }

    @Test
    void update_originalPriceZero_effaceLePrixBarre() {
        UUID id = UUID.randomUUID();
        Plan p = plan("CIVIQUE_3MOIS", ModuleAccess.CIVIQUE, "9.99");
        p.setStripePriceId("price_x");
        p.setOriginalPrice(new BigDecimal("19.99"));
        when(planManager.findById(id)).thenReturn(Optional.of(p));

        service.update(id, new AdminPlanUpdateRequest(
                null, BigDecimal.ZERO, null, null, null, null));

        assertThat(p.getOriginalPrice()).isNull();
    }

    @Test
    void update_storeIdVide_normaliseEnNull() {
        UUID id = UUID.randomUUID();
        Plan p = plan("CIVIQUE_3MOIS", ModuleAccess.CIVIQUE, "9.99");
        p.setStripePriceId("price_x");
        p.setAppleProductId("apple.old");
        when(planManager.findById(id)).thenReturn(Optional.of(p));

        service.update(id, new AdminPlanUpdateRequest(
                null, null, null, null, "   ", null));

        // Chaîne blanche → null (efface le SKU, désactive l'index unique partiel).
        assertThat(p.getAppleProductId()).isNull();
        // Toujours un store ID (stripe) → plan payant actif reste cohérent.
        assertThat(p.getStripePriceId()).isEqualTo("price_x");
    }

    @Test
    void update_planActifPayantSansStoreId_rejete400() {
        UUID id = UUID.randomUUID();
        Plan p = plan("CIVIQUE_3MOIS", ModuleAccess.CIVIQUE, "9.99");
        // active + payant + aucun store ID → incohérent.
        when(planManager.findById(id)).thenReturn(Optional.of(p));

        assertThatThrownBy(() -> service.update(id, new AdminPlanUpdateRequest(
                null, null, true, null, null, null)))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(400);
        verify(planManager, never()).save(any());
    }

    @Test
    void update_planActifPayantAvecStoreId_ok() {
        UUID id = UUID.randomUUID();
        Plan p = plan("CIVIQUE_3MOIS", ModuleAccess.CIVIQUE, "9.99");
        when(planManager.findById(id)).thenReturn(Optional.of(p));

        AdminPlanDto dto = service.update(id, new AdminPlanUpdateRequest(
                null, null, true, "price_new", null, null));

        assertThat(p.isActive()).isTrue();
        assertThat(p.getStripePriceId()).isEqualTo("price_new");
        assertThat(dto.code()).isEqualTo("CIVIQUE_3MOIS");
    }

    @Test
    void update_planInactif_pasDeGardeStoreId() {
        UUID id = UUID.randomUUID();
        Plan p = plan("OLD_PLAN", ModuleAccess.CIVIQUE, "9.99");
        when(planManager.findById(id)).thenReturn(Optional.of(p));

        // Désactivation d'un plan payant sans store ID : autorisé.
        service.update(id, new AdminPlanUpdateRequest(
                null, null, false, null, null, null));

        assertThat(p.isActive()).isFalse();
        verify(planManager).save(p);
    }
}

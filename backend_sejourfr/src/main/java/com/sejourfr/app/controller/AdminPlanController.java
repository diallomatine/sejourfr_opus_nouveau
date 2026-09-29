package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AdminPlanDto;
import com.sejourfr.app.dto.AdminPlanUpdateRequest;
import com.sejourfr.app.service.AdminPlanService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Console admin Plans : listing (actifs + inactifs) et édition partielle des
 * champs commerciaux (prix, store IDs, activation). Les Plans sont créés en
 * migration Flyway — pas de POST ni DELETE ici.
 *
 * <p>Sécurité : whitelist {@code /api/admin/**} → ROLE_ADMIN dans
 * {@code SecurityConfig}.
 */
@RestController
@RequestMapping("/api/admin/plans")
@RequiredArgsConstructor
public class AdminPlanController {

    private final AdminPlanService adminPlanService;

    @GetMapping
    public List<AdminPlanDto> list() {
        return adminPlanService.listAll();
    }

    @PatchMapping("/{id}")
    public AdminPlanDto update(
            @PathVariable UUID id,
            @Valid @RequestBody AdminPlanUpdateRequest req) {
        return adminPlanService.update(id, req);
    }
}

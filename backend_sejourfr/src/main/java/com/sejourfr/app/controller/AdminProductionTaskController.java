package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AdminProductionTaskDto;
import com.sejourfr.app.dto.AdminProductionTaskTitreRequest;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.service.AdminProductionTaskService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Console admin : intitules editoriaux des sujets EO/EE.
 *
 * <p>Securite : {@code /api/admin/**} → ROLE_ADMIN (cf. {@code SecurityConfig}),
 * aucune regle a ajouter ici.
 *
 * <p>Deux routes seulement, et c'est voulu : cette surface porte le
 * <b>titre</b> des cartes de sujet, pas un CRUD du catalogue.
 */
@RestController
@RequestMapping("/api/admin/production-tasks")
@RequiredArgsConstructor
public class AdminProductionTaskController {

    private final AdminProductionTaskService adminProductionTaskService;

    @GetMapping
    public List<AdminProductionTaskDto> list(
            @RequestParam EpreuveType epreuve,
            @RequestParam(required = false) Short tacheNumero) {
        return adminProductionTaskService.list(epreuve, tacheNumero);
    }

    /** Corps {@code {"titre": null}} ou blanc = retirer le titre. */
    @PatchMapping("/{id}/titre")
    public AdminProductionTaskDto updateTitre(
            @PathVariable UUID id,
            @Valid @RequestBody AdminProductionTaskTitreRequest req) {
        return adminProductionTaskService.updateTitre(id, req.titre());
    }
}

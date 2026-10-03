package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AdminProductionDetailDto;
import com.sejourfr.app.dto.AdminProductionFlagDto;
import com.sejourfr.app.dto.AdminProductionFlagRequest;
import com.sejourfr.app.dto.AdminProductionListItemDto;
import com.sejourfr.app.dto.PageResponse;
import com.sejourfr.app.enums.AdminProductionAnnotationFiltre;
import com.sejourfr.app.enums.AdminProductionNiveauFiltre;
import com.sejourfr.app.enums.AdminProductionPeriode;
import com.sejourfr.app.enums.AdminProductionSignalementFiltre;
import com.sejourfr.app.enums.AdminProductionStatutIa;
import com.sejourfr.app.enums.AdminProductionTri;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.adminproduction.AdminProductionFlagService;
import com.sejourfr.app.service.adminproduction.AdminProductionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Console admin « Productions IA » : liste, fiche et signalement des
 * productions TCF EE/EO corrigées par IA. {@code /api/admin/**} → ROLE_ADMIN
 * (SecurityConfig), plus {@code @PreAuthorize} en défense en profondeur.
 * Contrat : {@code docs/api-endpoints.md} § « Admin — Productions IA ».
 */
@RestController
@RequestMapping("/api/admin/productions")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminProductionController {

    private final AdminProductionService productionService;
    private final AdminProductionFlagService flagService;
    private final CurrentUser currentUser;

    @GetMapping
    public PageResponse<AdminProductionListItemDto> list(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) EpreuveType epreuve,
            @RequestParam(required = false) Integer tache,
            @RequestParam(required = false) AdminProductionNiveauFiltre niveau,
            @RequestParam(required = false) AdminProductionStatutIa statut,
            @RequestParam(required = false) AdminProductionSignalementFiltre signalement,
            @RequestParam(required = false) AdminProductionAnnotationFiltre annotation,
            @RequestParam(required = false) AdminProductionPeriode periode,
            @RequestParam(required = false) String from,
            @RequestParam(required = false) String to,
            @RequestParam(defaultValue = "false") boolean includeInternal,
            @RequestParam(defaultValue = "DATE_DESC") AdminProductionTri sort,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        return productionService.list(
                new AdminProductionService.Filtres(q, epreuve, tache, niveau, statut, signalement, annotation,
                        periode, from, to, includeInternal),
                sort, page, size);
    }

    @GetMapping("/{submissionId}")
    public AdminProductionDetailDto detail(@PathVariable UUID submissionId) {
        return productionService.detail(submissionId);
    }

    @PostMapping("/{submissionId}/flags")
    @ResponseStatus(HttpStatus.CREATED)
    public AdminProductionFlagDto flag(@PathVariable UUID submissionId,
                                       @Valid @RequestBody AdminProductionFlagRequest body) {
        return flagService.signaler(submissionId, currentUser.getId(), body);
    }

    @PostMapping("/flags/{flagId}/verify")
    public AdminProductionFlagDto verify(@PathVariable UUID flagId) {
        return flagService.verifier(flagId, currentUser.getId());
    }

    @PostMapping("/flags/{flagId}/remove")
    public AdminProductionFlagDto remove(@PathVariable UUID flagId) {
        return flagService.retirer(flagId, currentUser.getId());
    }
}

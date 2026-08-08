package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AdminSkillCreateRequest;
import com.sejourfr.app.dto.AdminSkillDetailDto;
import com.sejourfr.app.dto.AdminSkillDto;
import com.sejourfr.app.dto.AdminSkillStatsDto;
import com.sejourfr.app.dto.AdminSkillUpdateRequest;
import com.sejourfr.app.dto.PageResponse;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.service.AdminSkillService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Console admin : catalogue des micro-competences TCF.
 *
 * <p>Securite : {@code /api/admin/**} → ROLE_ADMIN (cf. {@code SecurityConfig}),
 * aucune regle a ajouter ici.
 *
 * <p>{@code /stats} est declare avant {@code /{id}} par le routage de Spring
 * (un segment litteral l'emporte sur une variable), il n'y a donc pas de
 * collision entre les deux.
 */
@RestController
@RequestMapping("/api/admin/skills")
@RequiredArgsConstructor
public class AdminSkillController {

    private final AdminSkillService adminSkillService;

    @GetMapping
    public PageResponse<AdminSkillDto> list(
            @RequestParam(required = false) SkillSection section,
            @RequestParam(required = false) SkillTaskCode taskCode,
            @RequestParam(required = false) Boolean active,
            @RequestParam(required = false) String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return adminSkillService.list(section, taskCode, active, q, page, size);
    }

    /** Usage reel du catalogue. {@code section} absent = les deux epreuves. */
    @GetMapping("/stats")
    public List<AdminSkillStatsDto> stats(@RequestParam(required = false) SkillSection section) {
        return adminSkillService.stats(section);
    }

    @GetMapping("/{id}")
    public AdminSkillDetailDto getById(@PathVariable UUID id) {
        return adminSkillService.getSkill(id);
    }

    @PostMapping
    public AdminSkillDto create(@Valid @RequestBody AdminSkillCreateRequest req) {
        return adminSkillService.createSkill(req);
    }

    @PatchMapping("/{id}")
    public AdminSkillDto update(@PathVariable UUID id,
                                @Valid @RequestBody AdminSkillUpdateRequest req) {
        return adminSkillService.updateSkill(id, req);
    }

    /**
     * 204, ou 409 des qu'un candidat a produit sur l'un de ses sujets — on ne
     * detruit jamais d'historique candidat, on desactive.
     */
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) {
        adminSkillService.deleteSkill(id);
    }
}

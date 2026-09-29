package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AdminSkillPromptCreateRequest;
import com.sejourfr.app.dto.AdminSkillPromptDto;
import com.sejourfr.app.dto.AdminSkillPromptUpdateRequest;
import com.sejourfr.app.dto.AdminSkillReferencesRequest;
import com.sejourfr.app.service.AdminSkillService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Console admin : les petits sujets et leurs productions de reference.
 *
 * <p>Chemin de premier niveau et non imbrique sous la competence : un sujet ne
 * change jamais de parent, son identifiant suffit donc a le designer, et les
 * modals d'edition n'ont pas a transporter l'id de la competence.
 *
 * <p>Securite : {@code /api/admin/**} → ROLE_ADMIN (cf. {@code SecurityConfig}).
 */
@RestController
@RequestMapping("/api/admin/skill-prompts")
@RequiredArgsConstructor
public class AdminSkillPromptController {

    private final AdminSkillService adminSkillService;

    /** Sujet complet, references comprises : la source des modals d'edition. */
    @GetMapping("/{id}")
    public AdminSkillPromptDto getById(@PathVariable UUID id) {
        return adminSkillService.getPrompt(id);
    }

    @PostMapping
    public AdminSkillPromptDto create(@Valid @RequestBody AdminSkillPromptCreateRequest req) {
        return adminSkillService.createPrompt(req);
    }

    /**
     * ⚠ Semantique de REMPLACEMENT sur les bornes de longueur : un nul efface.
     * Detail et justification dans {@code AdminSkillPromptUpdateRequest}.
     */
    @PatchMapping("/{id}")
    public AdminSkillPromptDto update(@PathVariable UUID id,
                                      @Valid @RequestBody AdminSkillPromptUpdateRequest req) {
        return adminSkillService.updatePrompt(id, req);
    }

    /**
     * 204, ou 409 des qu'un candidat a produit sur ce sujet — on ne detruit
     * jamais d'historique candidat, on desactive.
     */
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) {
        adminSkillService.deletePrompt(id);
    }

    /** Remplacement atomique des trois references. Renvoie le sujet a jour. */
    @PutMapping("/{id}/references")
    public AdminSkillPromptDto replaceReferences(@PathVariable UUID id,
                                                 @Valid @RequestBody AdminSkillReferencesRequest req) {
        return adminSkillService.replaceReferences(id, req);
    }
}

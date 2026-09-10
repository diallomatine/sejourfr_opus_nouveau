package com.sejourfr.app.controller;

import com.sejourfr.app.dto.CivicNotionDto;
import com.sejourfr.app.service.CivicNotionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * <b>Le referentiel de notions civiques et son tagging</b> (lot L8).
 *
 * <p>C'est l'outil qui rend possible le chantier <b>editorial</b> du chemin
 * critique : 1 016 questions a rattacher a une notion. Le code ne fait pas ce
 * travail — il l'outille, et il garde la trace de qui a decide.
 *
 * <p>🛑 <b>Aucune de ces routes n'appelle un LLM.</b> La table de suggestions
 * existe et reste vide : la remplir coute de l'argent, et c'est une decision du
 * proprietaire (regle du depot).
 */
@RestController
@RequestMapping("/api/admin/civic-notions")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminCivicNotionController {

    private final CivicNotionService service;

    /**
     * Le referentiel, avec la couverture <b>mesuree</b> par notion et par
     * mention. C'est ce tableau qui alimente la porte de revue de
     * {@code 50_} §6.1.3.
     */
    @GetMapping
    public List<CivicNotionDto> referentiel() {
        return service.referentiel();
    }

    /**
     * La file de tagging. {@code tagged=false} (defaut) = ce qu'il reste a
     * faire ; {@code theme} restreint a un theme.
     *
     * <p>{@code 50_} §6.1.2 recommande de commencer par les themes les mieux
     * dotes — {@code CIV_HISTOIRE_GEO} puis {@code CIV_INSTITUTIONS} — pour
     * calibrer la methode avant {@code CIV_PRINCIPES}, plus petit et plus
     * sujet aux recouvrements. Le filtre est la pour ca.
     */
    @GetMapping("/questions")
    public CivicNotionService.FileDeTagging file(
            @RequestParam(required = false) String theme,
            @RequestParam(required = false, defaultValue = "false") Boolean tagged,
            @RequestParam(defaultValue = "25") int limit,
            @RequestParam(defaultValue = "0") int offset) {
        return service.fileDeTagging(theme, tagged, Math.min(Math.max(limit, 1), 100),
                Math.max(offset, 0));
    }

    /**
     * Pose ou efface le tag <b>valide</b> d'une question.
     *
     * <p>{@code notionCode} nul efface : se tromper doit rester rattrapable
     * depuis l'ecran. Effacer ne dit pas « cette question n'a pas de notion »,
     * mais « elle attend a nouveau ».
     */
    @PutMapping("/questions/{questionId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void taguer(@PathVariable UUID questionId, @RequestBody TagRequest body) {
        service.taguer(questionId, body.notionCode());
    }

    /** @param notionCode code de la notion, ou {@code null} pour effacer le tag */
    public record TagRequest(String notionCode) {}
}

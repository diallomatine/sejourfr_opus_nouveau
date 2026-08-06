package com.sejourfr.app.controller;

import com.sejourfr.app.dto.SkillAttemptDto;
import com.sejourfr.app.dto.SubmitSkillTextRequest;
import com.sejourfr.app.enums.SkillSelfEvaluation;
import com.sejourfr.app.service.SkillAttemptService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

/**
 * Productions des candidats sur les petits sujets. Toute la logique vit dans
 * {@link SkillAttemptService}.
 *
 * <p>Les deux routes de soumission partagent le meme chemin et se distinguent
 * par leur {@code Content-Type} — meme mecanique que
 * {@code ProductionSubmissionController} : le front n'a qu'une URL a connaitre,
 * la modalite est portee par la requete.
 */
@RestController
@RequiredArgsConstructor
public class SkillAttemptController {

    private final SkillAttemptService skillAttemptService;

    /** Production ECRITE (section EE) : payload JSON. */
    @PostMapping(value = "/api/skill-attempts", consumes = MediaType.APPLICATION_JSON_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public SkillAttemptDto submitText(@Valid @RequestBody SubmitSkillTextRequest req) {
        return skillAttemptService.submitText(req);
    }

    /** Production ORALE (section EO) : upload multipart de l'enregistrement. */
    @PostMapping(value = "/api/skill-attempts", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public SkillAttemptDto submitAudio(
            @RequestPart("audio") MultipartFile audio,
            @RequestParam("skillPromptId") UUID skillPromptId,
            @RequestParam("durationSec") int durationSec,
            @RequestParam(value = "selfEvaluation", required = false) SkillSelfEvaluation selfEvaluation,
            @RequestParam("requestAnalysis") boolean requestAnalysis) {
        return skillAttemptService.submitAudio(
                skillPromptId, audio, durationSec, selfEvaluation, requestAnalysis);
    }

    /**
     * Polling du resultat d'une analyse. Reserve au proprietaire : une
     * tentative d'autrui renvoie 404, pas 403 — un 403 confirmerait son
     * existence.
     */
    @GetMapping("/api/skill-attempts/{id}")
    public SkillAttemptDto detail(@PathVariable UUID id) {
        return skillAttemptService.detail(id);
    }

    /**
     * Demande l'analyse IA d'une production deja enregistree sans elle. Sert le
     * candidat qui a produit gratuitement puis s'est abonne : sans cette route,
     * il devait refaire le sujet et perdait sa production. Consomme le quota.
     */
    @PostMapping("/api/skill-attempts/{id}/analyse")
    public SkillAttemptDto analyse(@PathVariable UUID id) {
        return skillAttemptService.analyse(id);
    }

    /**
     * Relance une analyse en echec. Ne reconsomme pas le quota gratuit :
     * l'analyse a deja ete decomptee a son acceptation. Plafonnee a 3.
     */
    @PostMapping("/api/skill-attempts/{id}/retry")
    public SkillAttemptDto retry(@PathVariable UUID id) {
        return skillAttemptService.retry(id);
    }

    /** Historique du candidat sur un sujet, plus recente d'abord. */
    @GetMapping("/api/skill-prompts/{promptId}/attempts")
    public List<SkillAttemptDto> history(
            @PathVariable UUID promptId,
            @RequestParam(defaultValue = "5") int limit) {
        return skillAttemptService.history(promptId, limit);
    }
}

package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ProductionSubmissionDto;
import com.sejourfr.app.dto.SubmitProductionTextRequest;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.service.ProductionSubmissionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

/**
 * Surface utilisateur des epreuves productives TCF EO/EE.
 * Toute la logique vit dans {@link ProductionSubmissionService}.
 * Les endpoints admin sont dans {@code AdminCalibrationController}.
 */
@RestController
@RequiredArgsConstructor
public class ProductionSubmissionController {

    private final ProductionSubmissionService productionSubmissionService;

    /** EO : upload multipart de l'audio. */
    @PostMapping(value = "/api/production-submissions", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ProductionSubmissionDto submitAudio(
            @RequestPart("audio") MultipartFile audio,
            @RequestParam("productionTaskId") UUID productionTaskId,
            @RequestParam("attemptId") UUID attemptId,
            @RequestParam(value = "situationId", required = false) UUID situationId) {
        return productionSubmissionService.submitAudio(productionTaskId, attemptId, audio, situationId);
    }

    /** EE : texte JSON. */
    @PostMapping(value = "/api/production-submissions", consumes = MediaType.APPLICATION_JSON_VALUE)
    public ProductionSubmissionDto submitText(@Valid @RequestBody SubmitProductionTextRequest req) {
        return productionSubmissionService.submitText(req);
    }

    /** Relancer une submission FAILED (max 3 retries, controle dans le service). */
    @PostMapping("/api/production-submissions/{id}/retry")
    public ProductionSubmissionDto retry(@PathVariable UUID id) {
        return productionSubmissionService.retry(id);
    }

    /** Detail d'une submission : reserve au proprietaire (l'admin a sa propre route). */
    @GetMapping("/api/production-submissions/{id}")
    public ProductionSubmissionDto detail(@PathVariable UUID id) {
        return productionSubmissionService.getOwnDetail(id);
    }

    /** Historique de l'utilisateur, optionnellement filtre par epreuve. */
    @GetMapping("/api/users/me/production-submissions")
    public List<ProductionSubmissionDto> mine(
            @RequestParam(required = false) EpreuveType epreuve,
            @RequestParam(defaultValue = "20") int limit) {
        return productionSubmissionService.listMine(epreuve, limit);
    }

    /**
     * Derniere submission de l'utilisateur par numero de tache pour un (epreuve, niveau).
     * Sert au hub d'entrainement pour afficher la derniere note sur chaque card (T1, T2, T3).
     */
    @GetMapping("/api/users/me/production-submissions/last-per-task")
    public List<ProductionSubmissionDto> lastPerTask(
            @RequestParam EpreuveType epreuve,
            @RequestParam String niveau) {
        return productionSubmissionService.lastPerTask(epreuve, niveau);
    }
}

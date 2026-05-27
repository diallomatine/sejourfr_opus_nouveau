package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ExampleAudioBatchResultDto;
import com.sejourfr.app.dto.ExampleAudioDto;
import com.sejourfr.app.dto.RegenerateExampleAudioRequest;
import com.sejourfr.app.service.ProductionExampleAudioService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Admin : génération batch + validation des audios des exemples EO.
 * Sécurité : couverte par le matcher global {@code /api/admin/**} (ROLE_ADMIN).
 */
@RestController
@RequestMapping("/api/admin/production/examples/audio")
@RequiredArgsConstructor
public class ProductionExampleAudioController {

    private final ProductionExampleAudioService service;

    /** Génère les audios manquants (1 par 1, résilient). */
    @PostMapping("/batch-generate")
    public ExampleAudioBatchResultDto batchGenerate(@RequestParam(defaultValue = "10") int size) {
        return service.generateBatchAudio(size);
    }

    /** Nombre d'exemples EO sans audio (badge du bouton). */
    @GetMapping("/pending/count")
    public Map<String, Long> pendingCount() {
        return Map.of("count", service.countPendingAudio());
    }

    /** Exemples EO dont l'audio est généré mais pas encore publié. */
    @GetMapping("/to-review")
    public List<ExampleAudioDto> toReview() {
        return service.listGeneratedForReview();
    }

    /** Publie l'audio (devient audible côté app). */
    @PostMapping("/{id}/publish")
    public ExampleAudioDto publish(@PathVariable UUID id) {
        return service.publishExampleAudio(id);
    }

    /** Régénère l'audio (voix optionnelle). */
    @PostMapping("/{id}/regenerate")
    public ExampleAudioDto regenerate(
            @PathVariable UUID id,
            @RequestBody(required = false) RegenerateExampleAudioRequest req) {
        return service.regenerateExampleAudio(id, req == null ? null : req.voice());
    }
}

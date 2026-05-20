package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AnswerResultResponse;
import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.ProductionAttemptStartRequest;
import com.sejourfr.app.dto.StartAttemptRequest;
import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.AttemptService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/attempts")
public class AttemptController {

    private final AttemptService service;
    private final CurrentUser currentUser;

    public AttemptController(AttemptService service, CurrentUser currentUser) {
        this.service = service;
        this.currentUser = currentUser;
    }

    @PostMapping
    public ResponseEntity<AttemptResponse> start(@Valid @RequestBody StartAttemptRequest req) {
        return ResponseEntity.ok(service.start(currentUser.getId(), req));
    }

    /**
     * Cree un attempt vide pour les epreuves productives (TCF_EO / TCF_EE / TCF_COMPLET).
     * Distinct de POST /api/attempts qui pioche des questions QCM : ici aucune question
     * n'est tiree, les productions sont rattachees ensuite via /api/production-submissions.
     */
    @PostMapping("/production")
    public ResponseEntity<AttemptResponse> startProduction(
            @Valid @RequestBody ProductionAttemptStartRequest req) {
        return ResponseEntity.ok(service.startProductionAttempt(currentUser.getId(), req));
    }

    @GetMapping("/{id}")
    public AttemptResponse get(@PathVariable UUID id) {
        return service.getById(currentUser.getId(), id);
    }

    @PostMapping("/{id}/answers")
    public AnswerResultResponse submit(
            @PathVariable UUID id,
            @Valid @RequestBody SubmitAnswerRequest req
    ) {
        return service.submitAnswer(currentUser.getId(), id, req);
    }

    @PostMapping("/{id}/finish")
    public AttemptResponse finish(@PathVariable UUID id) {
        return service.finish(currentUser.getId(), id);
    }
}

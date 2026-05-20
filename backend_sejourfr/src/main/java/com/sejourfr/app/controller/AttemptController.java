package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AnswerResultResponse;
import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.ProductionAttemptStartRequest;
import com.sejourfr.app.dto.StartAttemptRequest;
import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.AttemptService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/attempts")
@RequiredArgsConstructor
public class AttemptController {

    private final AttemptService attemptService;
    private final CurrentUser currentUser;

    @PostMapping
    public AttemptResponse start(@Valid @RequestBody StartAttemptRequest req) {
        return attemptService.start(currentUser.getId(), req);
    }

    /**
     * Cree un attempt vide pour les epreuves productives (TCF_EO / TCF_EE / TCF_COMPLET).
     * Distinct de POST /api/attempts qui pioche des questions QCM : ici aucune question
     * n'est tiree, les productions sont rattachees ensuite via /api/production-submissions.
     */
    @PostMapping("/production")
    public AttemptResponse startProduction(@Valid @RequestBody ProductionAttemptStartRequest req) {
        return attemptService.startProductionAttempt(currentUser.getId(), req);
    }

    @GetMapping("/{id}")
    public AttemptResponse get(@PathVariable UUID id) {
        return attemptService.getById(currentUser.getId(), id);
    }

    @PostMapping("/{id}/answers")
    public AnswerResultResponse submit(@PathVariable UUID id, @Valid @RequestBody SubmitAnswerRequest req) {
        return attemptService.submitAnswer(currentUser.getId(), id, req);
    }

    @PostMapping("/{id}/finish")
    public AttemptResponse finish(@PathVariable UUID id) {
        return attemptService.finish(currentUser.getId(), id);
    }
}

package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AnswerResultResponse;
import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.StartAttemptRequest;
import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.service.PublicAttemptService;
import com.sejourfr.app.util.ClientIpExtractor;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Endpoints d'attempts pour visiteurs non authentifiés (démo guest).
 * Quota géré côté service via l'IP cliente.
 */
@RestController
@RequestMapping("/api/public/attempts")
public class PublicAttemptController {

    private final PublicAttemptService service;

    public PublicAttemptController(PublicAttemptService service) {
        this.service = service;
    }

    @PostMapping("/demo")
    public ResponseEntity<AttemptResponse> startDemo(
            @Valid @RequestBody StartAttemptRequest req,
            HttpServletRequest httpReq
    ) {
        String ip = ClientIpExtractor.extract(httpReq);
        AttemptResponse response = service.startDemo(req, ip);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{id}")
    public AttemptResponse get(@PathVariable UUID id, HttpServletRequest httpReq) {
        String ip = ClientIpExtractor.extract(httpReq);
        return service.getDemoById(id, ip);
    }

    @PostMapping("/{id}/answers")
    public AnswerResultResponse submit(
            @PathVariable UUID id,
            @Valid @RequestBody SubmitAnswerRequest req,
            HttpServletRequest httpReq
    ) {
        String ip = ClientIpExtractor.extract(httpReq);
        return service.submitDemoAnswer(id, ip, req);
    }

    @PostMapping("/{id}/finish")
    public AttemptResponse finish(@PathVariable UUID id, HttpServletRequest httpReq) {
        String ip = ClientIpExtractor.extract(httpReq);
        return service.finishDemo(id, ip);
    }
}

package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AnswerResultResponse;
import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.StartAttemptRequest;
import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.service.PublicAttemptService;
import com.sejourfr.app.util.ClientIpExtractor;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Endpoints d'attempts pour visiteurs non authentifies (demo guest).
 * L'IP cliente est extraite ici (concern HTTP) puis passee au service qui
 * porte les invariants guest (user IS NULL + meme IP).
 */
@RestController
@RequestMapping("/api/public/attempts")
@RequiredArgsConstructor
public class PublicAttemptController {

    private final PublicAttemptService publicAttemptService;

    @PostMapping("/demo")
    @ResponseStatus(HttpStatus.CREATED)
    public AttemptResponse startDemo(@Valid @RequestBody StartAttemptRequest req, HttpServletRequest httpReq) {
        return publicAttemptService.startDemo(req, ClientIpExtractor.extract(httpReq));
    }

    @GetMapping("/{id}")
    public AttemptResponse get(@PathVariable UUID id, HttpServletRequest httpReq) {
        return publicAttemptService.getDemoById(id, ClientIpExtractor.extract(httpReq));
    }

    @PostMapping("/{id}/answers")
    public AnswerResultResponse submit(
            @PathVariable UUID id,
            @Valid @RequestBody SubmitAnswerRequest req,
            HttpServletRequest httpReq) {
        return publicAttemptService.submitDemoAnswer(id, ClientIpExtractor.extract(httpReq), req);
    }

    @PostMapping("/{id}/finish")
    public AttemptResponse finish(@PathVariable UUID id, HttpServletRequest httpReq) {
        return publicAttemptService.finishDemo(id, ClientIpExtractor.extract(httpReq));
    }
}

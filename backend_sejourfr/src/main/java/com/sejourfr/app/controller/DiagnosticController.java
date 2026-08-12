package com.sejourfr.app.controller;

import com.sejourfr.app.dto.DiagnosticResponse;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.diagnostic.DiagnosticService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/diagnostics")
@RequiredArgsConstructor
public class DiagnosticController {

    private final DiagnosticService diagnosticService;
    private final CurrentUser currentUser;

    @GetMapping("/current")
    public DiagnosticResponse current() {
        return diagnosticService.current(currentUser.getId());
    }

    /** Idempotent : crée la version active ou renvoie la session déjà commencée. */
    @PostMapping
    public DiagnosticResponse startOrResume() {
        return diagnosticService.startOrResume(currentUser.getId());
    }

    @GetMapping("/{sessionId}")
    public DiagnosticResponse detail(@PathVariable UUID sessionId) {
        return diagnosticService.detail(currentUser.getId(), sessionId);
    }

    @PostMapping("/{sessionId}/retry-analysis")
    public DiagnosticResponse retryAnalysis(@PathVariable UUID sessionId) {
        return diagnosticService.retryAnalysis(currentUser.getId(), sessionId);
    }
}

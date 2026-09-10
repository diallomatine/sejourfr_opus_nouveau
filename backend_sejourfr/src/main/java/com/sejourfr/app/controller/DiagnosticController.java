package com.sejourfr.app.controller;

import com.sejourfr.app.dto.DiagnosticResponse;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.diagnostic.DiagnosticService;
import com.sejourfr.app.util.ClientContextResolver;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/diagnostics")
@RequiredArgsConstructor
public class DiagnosticController {

    private final DiagnosticService diagnosticService;
    private final ClientContextResolver clientContextResolver;
    private final CurrentUser currentUser;

    @GetMapping("/current")
    public DiagnosticResponse current() {
        return diagnosticService.current(currentUser.getId());
    }

    /**
     * Idempotent : crée la version active ou renvoie la session déjà commencée.
     *
     * <p>{@code writtenTaskId} est le sujet que le candidat a réellement lu et
     * traité, quand le diagnostic tire dans un pool (L3). Il est <b>facultatif</b>
     * — un client ancien continue de marcher — et <b>vérifié serveur</b> contre
     * le pool actif : un identifiant arbitraire ne peut pas ouvrir le diagnostic
     * sur une tâche officielle du TCF.
     */
    @PostMapping
    public DiagnosticResponse startOrResume(
            HttpServletRequest http,
            @RequestParam(required = false) UUID writtenTaskId) {
        return diagnosticService.startOrResume(currentUser.getId(),
                clientContextResolver.resolve(http).platform(), writtenTaskId);
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

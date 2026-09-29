package com.sejourfr.app.controller;

import com.sejourfr.app.dto.DiagnosticRunCreateRequest;
import com.sejourfr.app.dto.DiagnosticRunCreatedResponse;
import com.sejourfr.app.dto.DiagnosticRunSubmitRequest;
import com.sejourfr.app.ratelimit.DiagnosticRunRateLimit;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.diagnosticrun.DiagnosticRunService;
import com.sejourfr.app.util.ClientContext;
import com.sejourfr.app.util.ClientContextResolver;
import com.sejourfr.app.util.ClientIpResolver;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Le cycle de vie public d'une {@code diagnostic_run} (chantier Suivi, lot 2a) :
 * la creation a l'affichage du sujet, et le « soumis » du TCF rapide.
 *
 * <p>Routes publiques : un visiteur sans compte est le cas normal, mais un jeton
 * JWT valide, s'il accompagne la requete, fait de l'appelant le porteur. Les
 * en-tetes {@code X-Sejourfr-Client}, {@code X-Sejourfr-Anonymous-Id} et
 * {@code X-Sejourfr-App-Version} sont lus par {@link ClientContextResolver}.
 * Rate-limitees par IP et par identifiant de mesure ({@link DiagnosticRunRateLimit}).
 * L'IP n'est jamais persistee ici : elle ne sert qu'a prouver l'appartenance
 * d'une session civique invitee.
 */
@RestController
@RequestMapping("/api/public/diagnostic-runs")
@RequiredArgsConstructor
public class PublicDiagnosticRunController {

    private final DiagnosticRunService service;
    private final DiagnosticRunRateLimit rateLimit;
    private final ClientIpResolver clientIpResolver;
    private final ClientContextResolver clientContextResolver;
    private final CurrentUser currentUser;

    /** Idempotent sur {@code (X-Sejourfr-Anonymous-Id, clientKey)} et sur la session. */
    @PostMapping
    public DiagnosticRunCreatedResponse create(@Valid @RequestBody DiagnosticRunCreateRequest request,
                                               HttpServletRequest http) {
        String ip = clientIpResolver.resolve(http);
        ClientContext client = clientContextResolver.resolve(http);
        rateLimit.checkCreate(ip, client.anonymousId());
        return service.create(request, client, ip, currentUser.optionalId().orElse(null));
    }

    /** « Soumis » d'une run {@code QUICK_TCF}, une seule fois. 409 pour les autres types. */
    @PostMapping("/{id}/submit")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void submit(@PathVariable UUID id,
                       @RequestBody(required = false) DiagnosticRunSubmitRequest request,
                       HttpServletRequest http) {
        String ip = clientIpResolver.resolve(http);
        ClientContext client = clientContextResolver.resolve(http);
        rateLimit.checkSubmit(ip, client.anonymousId());
        service.submit(id, request, currentUser.optionalId().orElse(null), client.anonymousId());
    }
}

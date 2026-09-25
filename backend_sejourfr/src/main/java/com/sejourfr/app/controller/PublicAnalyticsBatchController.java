package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AnalyticsBatchRequest;
import com.sejourfr.app.dto.AnalyticsBatchResponse;
import com.sejourfr.app.enums.AnalyticsDeviceType;
import com.sejourfr.app.ratelimit.AnalyticsBatchRateLimit;
import com.sejourfr.app.service.analytics.AnalyticsBatchIngestionService;
import com.sejourfr.app.util.ClientContext;
import com.sejourfr.app.util.ClientContextResolver;
import com.sejourfr.app.util.ClientIpResolver;
import com.sejourfr.app.util.DeviceTypeResolver;
import com.sejourfr.app.util.GeoIpCountryResolver;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Ingestion d'evenements d'analytics <b>en lot</b>, sans authentification
 * (chantier Suivi, arbitrage Q17).
 *
 * <p>Repond <b>202</b> avec un compte rendu : acceptes, doublons, rejets
 * individuels. Le client purge de sa file tout ce qui n'est pas une erreur de
 * transport (acceptes, doublons ET rejets — un rejet renvoye tel quel serait
 * rejete de nouveau). Une enveloppe invalide repond 400, un depassement de
 * garde-fou 429 : dans ces deux cas le lot est a renvoyer plus tard.
 *
 * <p>Rate-limite par IP et par identifiant de mesure
 * ({@link AnalyticsBatchRateLimit}). Pays et type d'appareil sont resolus ici,
 * en bord d'entree, jamais recus du client ; l'IP n'est <b>jamais
 * persistee</b>.
 */
@RestController
@RequestMapping("/api/public/analytics")
@RequiredArgsConstructor
public class PublicAnalyticsBatchController {

    private final AnalyticsBatchIngestionService batchService;
    private final AnalyticsBatchRateLimit rateLimit;
    private final ClientIpResolver clientIpResolver;
    private final ClientContextResolver clientContextResolver;
    private final GeoIpCountryResolver geoIpCountryResolver;
    private final DeviceTypeResolver deviceTypeResolver;

    /**
     * JSON, ou {@code text/plain} pour le {@code sendBeacon} du web (controle
     * N7 : pas de pre-verification CORS) — meme corps, lu par
     * {@code AnalyticsBatchTextPlainConverter}, memes validations.
     */
    @PostMapping(value = "/events/batch", consumes = {MediaType.APPLICATION_JSON_VALUE, MediaType.TEXT_PLAIN_VALUE})
    @ResponseStatus(HttpStatus.ACCEPTED)
    public AnalyticsBatchResponse ingest(@Valid @RequestBody AnalyticsBatchRequest request,
                                         HttpServletRequest http) {
        String ip = clientIpResolver.resolve(http);
        rateLimit.check(ip, request.anonymousId());

        ClientContext client = clientContextResolver.resolve(http, request.client(), request.appVersion());
        String country = geoIpCountryResolver.resolve(ip);
        AnalyticsDeviceType device =
                deviceTypeResolver.resolve(http.getHeader("User-Agent"), client.platform());

        return batchService.ingest(request, client, country, device, principalOrNull());
    }

    /**
     * Adresse du compte appelant s'il est connecte. La route est publique — un
     * visiteur anonyme est le cas normal — mais le filtre JWT a deja pose une
     * authentification si un jeton valide accompagnait la requete.
     */
    private static String principalOrNull() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || auth.getName() == null) return null;
        return auth.getName();
    }
}

package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AnalyticsEventRequest;
import com.sejourfr.app.enums.AnalyticsDeviceType;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.ratelimit.RateLimitGuard;
import com.sejourfr.app.service.analytics.AnalyticsIngestionService;
import com.sejourfr.app.util.ClientContext;
import com.sejourfr.app.util.ClientContextResolver;
import com.sejourfr.app.util.ClientIpResolver;
import com.sejourfr.app.util.DeviceTypeResolver;
import com.sejourfr.app.util.GeoIpCountryResolver;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Reception des evenements d'analytics, sans authentification.
 *
 * <p>Repond <b>204</b> : les fronts emettent en {@code sendBeacon} et ne lisent
 * jamais la reponse — renvoyer un corps serait du gaspillage. Un rejeu
 * dedoublonne repond 204 lui aussi : de son point de vue, rien ne s'est mal
 * passe.
 *
 * <p><b>Rate-limite par IP</b>, contrairement a {@code /api/public/page-views}
 * qui ne l'est pas — et c'est un trou connu, ecrit noir sur blanc dans le
 * CLAUDE.md racine. Ici la table n'est pas un agregat borne par construction :
 * chaque appel ecrit une ligne. On ne reproduit donc pas l'omission.
 *
 * <p><b>Le pays et le type d'appareil sont resolus ici</b>, en bord d'entree,
 * et jamais recus du client : ils seraient falsifiables. 🛑 L'IP sert le temps
 * d'en tirer deux lettres et n'est <b>jamais persistee</b> ; le user-agent sert
 * le temps d'en tirer un type d'appareil et n'est pas conserve non plus.
 */
@RestController
@RequestMapping("/api/public/analytics")
@RequiredArgsConstructor
public class PublicAnalyticsController {

    private final AnalyticsIngestionService ingestionService;
    private final RateLimitGuard rateLimitGuard;
    private final ClientIpResolver clientIpResolver;
    private final ClientContextResolver clientContextResolver;
    private final GeoIpCountryResolver geoIpCountryResolver;
    private final DeviceTypeResolver deviceTypeResolver;
    private final UserManager userManager;

    @PostMapping("/events")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void track(@Valid @RequestBody AnalyticsEventRequest request, HttpServletRequest http) {
        String ip = clientIpResolver.resolve(http);
        rateLimitGuard.checkAnalytics(ip);

        ClientContext client = clientContextResolver.resolve(http);
        String country = geoIpCountryResolver.resolve(ip);
        AnalyticsDeviceType device =
                deviceTypeResolver.resolve(http.getHeader("User-Agent"), client.platform());

        ingestionService.track(request, client, country, device, currentUserIdOrNull());
    }

    /**
     * Compte de l'appelant s'il se trouve qu'il est connecte.
     *
     * <p>La route est publique — un visiteur anonyme est le cas normal — mais
     * le filtre JWT a deja pose une authentification si un jeton valide
     * accompagnait la requete. La reconnaitre ici evite de rattacher apres coup
     * des gestes qu'on savait deja nominatifs.
     */
    private UUID currentUserIdOrNull() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || auth.getName() == null) return null;
        return userManager.findByEmail(auth.getName())
                .map(user -> user.getId())
                .orElse(null);
    }
}

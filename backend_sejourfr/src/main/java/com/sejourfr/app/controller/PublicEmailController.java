package com.sejourfr.app.controller;

import com.sejourfr.app.ratelimit.RateLimitGuard;
import com.sejourfr.app.service.email.EmailUnsubscribeService;
import com.sejourfr.app.util.ClientIpResolver;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.nio.charset.StandardCharsets;

/**
 * Desabonnement des mails ENGAGEMENT, <b>sans authentification</b> (le lien du
 * mail porte un jeton signe). Sous {@code /api/public/**}, deja {@code permitAll}.
 *
 * <ul>
 *   <li>{@code GET /unsubscribe?token=} — page de confirmation, ne modifie rien ;</li>
 *   <li>{@code POST /unsubscribe} (formulaire, {@code token}) — desabonne ;</li>
 *   <li>{@code POST /unsubscribe/one-click?token=} — cible de {@code List-Unsubscribe}
 *       (RFC 8058) ; {@code GET} sur la meme URL rend la page de confirmation, pour
 *       un client qui suivrait le lien au lieu de le poster.</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/public/email")
@RequiredArgsConstructor
public class PublicEmailController {

    private static final MediaType HTML_UTF8 = new MediaType(MediaType.TEXT_HTML, StandardCharsets.UTF_8);

    private final EmailUnsubscribeService unsubscribeService;
    private final RateLimitGuard rateLimitGuard;
    private final ClientIpResolver clientIpResolver;

    @GetMapping(value = {"/unsubscribe", "/unsubscribe/one-click"}, produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> confirmation(@RequestParam(value = "token", required = false) String token,
                                               HttpServletRequest http) {
        rateLimitGuard.checkEmailUnsubscribe(clientIpResolver.resolve(http));
        return page(unsubscribeService.confirmation(token));
    }

    @PostMapping(value = "/unsubscribe", produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> unsubscribe(@RequestParam(value = "token", required = false) String token,
                                              HttpServletRequest http) {
        rateLimitGuard.checkEmailUnsubscribe(clientIpResolver.resolve(http));
        return page(unsubscribeService.unsubscribe(token));
    }

    @PostMapping("/unsubscribe/one-click")
    public ResponseEntity<Void> oneClick(@RequestParam(value = "token", required = false) String token,
                                         HttpServletRequest http) {
        rateLimitGuard.checkEmailUnsubscribe(clientIpResolver.resolve(http));
        return unsubscribeService.oneClick(token)
                ? ResponseEntity.ok().build()
                : ResponseEntity.badRequest().build();
    }

    private static ResponseEntity<String> page(EmailUnsubscribeService.Page page) {
        return ResponseEntity.status(page.status()).contentType(HTML_UTF8).body(page.html());
    }
}

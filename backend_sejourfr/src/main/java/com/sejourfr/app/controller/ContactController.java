package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ContactRequest;
import com.sejourfr.app.dto.ContactResponse;
import com.sejourfr.app.ratelimit.RateLimitGuard;
import com.sejourfr.app.service.ContactService;
import com.sejourfr.app.util.ClientIpExtractor;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Formulaire de contact (web + mobile). Endpoint **public** — un utilisateur
 * non connecté peut nous écrire (ex: question sur l'inscription).
 *
 * <p>Protege par un rate-limit IP (cf. {@link RateLimitGuard}) contre le
 * flood d'emails. Un captcha cote front reste envisageable si l'abus persiste.
 */
@RestController
@RequestMapping("/api/contact")
@RequiredArgsConstructor
public class ContactController {

    private final ContactService contactService;
    private final RateLimitGuard rateLimitGuard;

    @PostMapping
    public ContactResponse submit(@Valid @RequestBody ContactRequest req, HttpServletRequest http) {
        rateLimitGuard.checkContact(ClientIpExtractor.extract(http));
        return contactService.submit(req);
    }
}

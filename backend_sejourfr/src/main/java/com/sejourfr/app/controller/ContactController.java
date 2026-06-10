package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ContactRequest;
import com.sejourfr.app.dto.ContactResponse;
import com.sejourfr.app.service.ContactService;
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
 * <p>La protection contre les abus repose pour l'instant sur le pattern
 * standard SecurityConfig (CSRF off, CORS strict). Si le volume devient
 * problématique, ajouter rate-limit IP ici (Bucket4j) et/ou un captcha
 * côté front.
 */
@RestController
@RequestMapping("/api/contact")
@RequiredArgsConstructor
public class ContactController {

    private final ContactService contactService;

    @PostMapping
    public ContactResponse submit(@Valid @RequestBody ContactRequest req) {
        return contactService.submit(req);
    }
}

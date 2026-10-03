package com.sejourfr.app.controller;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Heartbeat de premier plan (D2) : {@code POST /api/me/presence} → 204.
 *
 * <p>Volontairement vide : la presence est enregistree par
 * {@code UserActivityInterceptor}, comme pour toute requete authentifiee. Un
 * seul point d'ecriture ; cet endpoint ne sert qu'a couvrir les phases sans
 * requete (lecture, chrono d'examen). Authentifie par la regle
 * {@code anyRequest().authenticated()}.
 */
@RestController
public class MePresenceController {

    @PostMapping("/api/me/presence")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void presence() {
        // La presence est ecrite par l'intercepteur d'activite.
    }
}

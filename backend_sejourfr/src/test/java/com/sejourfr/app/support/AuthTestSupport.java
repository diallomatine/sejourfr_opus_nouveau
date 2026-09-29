package com.sejourfr.app.support;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.security.JwtService;
import lombok.RequiredArgsConstructor;

/**
 * Fournit de vrais access tokens JWT pour les tests de controllers : on signe
 * avec le même {@link JwtService} que la prod, donc le filtre
 * {@code JwtAuthenticationFilter} + les règles de {@code SecurityConfig} sont
 * exercés de bout en bout (test fidèle des droits).
 */
@RequiredArgsConstructor
public class AuthTestSupport {

    private final JwtService jwtService;

    /** Valeur prête pour l'en-tête {@code Authorization}. */
    public String bearer(User user) {
        return "Bearer " + jwtService.generateAccessToken(user);
    }
}

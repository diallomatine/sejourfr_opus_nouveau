package com.sejourfr.app.security;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.manager.UserManager;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Helper pour recuperer l'utilisateur courant dans les controllers.
 * <p>
 * Hypothese : le {@link JwtAuthenticationFilter} pose dans le SecurityContext
 * une Authentication dont le 'name' est l'email de l'utilisateur.
 */
@Component
@RequiredArgsConstructor
public class CurrentUser {

    private final UserManager userManager;

    public User get() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            throw new AccessDeniedException("Non authentifié");
        }
        String email = auth.getName();
        return userManager.findByEmail(email)
                .orElseThrow(() -> new AccessDeniedException("Utilisateur introuvable"));
    }

    public UUID getId() {
        return get().getId();
    }
}

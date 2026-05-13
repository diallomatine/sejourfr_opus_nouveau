package com.sejourfr.app.security;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.repository.UserRepository;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Helper pour récupérer l'utilisateur courant dans les controllers.
 * <p>
 * Hypothèse : le {@link JwtAuthenticationFilter} pose dans le SecurityContext
 * une Authentication dont le 'name' est l'email de l'utilisateur (ou un
 * principal de type AppUserDetails contenant l'email).
 * <p>
 * Si ta config met l'UUID directement comme principal, simplifie le code.
 */
@Component
public class CurrentUser {

    private final UserRepository userRepository;

    public CurrentUser(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User get() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            throw new AccessDeniedException("Non authentifié");
        }
        String email = auth.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new AccessDeniedException("Utilisateur introuvable"));
    }

    public UUID getId() {
        return get().getId();
    }
}

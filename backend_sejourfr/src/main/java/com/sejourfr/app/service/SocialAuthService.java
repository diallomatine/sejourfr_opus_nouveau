package com.sejourfr.app.service;

import com.sejourfr.app.dto.AppleSignInRequest;
import com.sejourfr.app.dto.AuthenticatedUser;
import com.sejourfr.app.dto.GoogleSignInRequest;
import com.sejourfr.app.dto.TokenResponse;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AuthProvider;
import com.sejourfr.app.enums.Role;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.security.JwtService;
import com.sejourfr.app.service.social.AppleTokenVerifier;
import com.sejourfr.app.service.social.GoogleTokenVerifier;
import com.sejourfr.app.service.social.SocialIdentity;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;

/**
 * Orchestre la connexion via providers externes (Google, Apple) :
 * <ol>
 *   <li>Valide l'ID token via le verifier dedie (signature JWKS + claims).</li>
 *   <li>Find-or-create l'utilisateur local :
 *     <ul>
 *       <li>match prioritaire par (provider, providerUserId)</li>
 *       <li>fallback par email (on lie au compte LOCAL existant sans toucher
 *           a son {@code auth_provider} : la colonne reste un marqueur du
 *           moyen de creation initial)</li>
 *       <li>sinon, creation d'un nouveau compte USER avec provider = X</li>
 *     </ul>
 *   </li>
 *   <li>Retourne les memes TokenResponse que /api/auth/login.</li>
 * </ol>
 */
@Service
@Transactional
@RequiredArgsConstructor
@Slf4j
public class SocialAuthService {

    private final UserManager userManager;
    private final JwtService jwtService;
    private final SubscriptionService subscriptionService;
    private final GoogleTokenVerifier googleVerifier;
    private final AppleTokenVerifier appleVerifier;

    public TokenResponse loginWithGoogle(GoogleSignInRequest req) {
        SocialIdentity identity = googleVerifier.verify(req.idToken());
        User user = findOrCreate(identity, null, null);
        return buildTokenResponse(user);
    }

    public TokenResponse loginWithApple(AppleSignInRequest req) {
        SocialIdentity identity = appleVerifier.verify(req.identityToken());
        User user = findOrCreate(identity, trim(req.firstName()), trim(req.lastName()));
        return buildTokenResponse(user);
    }

    public boolean isGoogleConfigured() {
        return googleVerifier.isConfigured();
    }

    public boolean isAppleConfigured() {
        return appleVerifier.isConfigured();
    }

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------

    private User findOrCreate(SocialIdentity identity, String firstNameOverride, String lastNameOverride) {
        // 1) lookup par (provider, sub) — match exact deja vu
        Optional<User> byProvider = userManager.findByProvider(identity.provider(), identity.providerUserId());
        if (byProvider.isPresent()) {
            User user = byProvider.get();
            user.setLastLoginAt(Instant.now());
            return userManager.save(user);
        }

        // 2) lookup par email — compte LOCAL existant ou compte cree avec un
        // autre provider (rare). On le ramene comme login sans muter
        // auth_provider (= moyen de creation initial, immutable).
        Optional<User> byEmail = userManager.findByEmail(identity.email());
        if (byEmail.isPresent()) {
            User user = byEmail.get();
            user.setLastLoginAt(Instant.now());
            return userManager.save(user);
        }

        // 3) creation
        User user = new User();
        user.setEmail(identity.email());
        user.setPasswordHash(null); // pas de mot de passe pour les comptes sociaux
        String firstName = firstChoice(firstNameOverride, identity.firstName());
        String lastName = firstChoice(lastNameOverride, identity.lastName());
        user.setFirstName(firstName);
        user.setLastName(lastName);
        user.setRole(Role.USER);
        user.setAuthProvider(identity.provider());
        user.setProviderUserId(identity.providerUserId());
        user.setLastLoginAt(Instant.now());
        log.info("Creation compte via {} : email={}", identity.provider(), identity.email());
        return userManager.save(user);
    }

    private TokenResponse buildTokenResponse(User u) {
        String access = jwtService.generateAccessToken(u);
        String refresh = jwtService.generateRefreshToken(u);
        SubscriptionService.CurrentAccess current = subscriptionService.currentAccess(u.getId());
        return TokenResponse.of(access, refresh, jwtService.accessTokenTtlSeconds(),
                AuthenticatedUser.from(u, current.module(), current.endsAt()));
    }

    private static String trim(String s) {
        if (s == null) return null;
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }

    private static String firstChoice(String a, String b) {
        if (a != null && !a.isBlank()) return a;
        if (b != null && !b.isBlank()) return b;
        return null;
    }
}

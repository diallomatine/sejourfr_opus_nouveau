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
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.Optional;

/**
 * Orchestre la connexion via providers externes (Google, Apple) :
 * <ol>
 *   <li>Valide l'ID token via le verifier dedie (signature JWKS + claims).</li>
 *   <li>Find-or-create l'utilisateur local :
 *     <ul>
 *       <li>match prioritaire par {@code (provider, providerUserId)}</li>
 *       <li>sinon, si l'email pointe sur un compte existant <strong>quel que
 *           soit son auth_provider</strong>, on refuse (409). Le linking
 *           explicite d'un provider à un compte existant doit toujours
 *           partir d'une session authentifiée préalable — sinon n'importe
 *           qui qui contrôle un Apple ID / Workspace Google avec une adresse
 *           non-vérifiée peut prendre le contrôle d'un compte existant.
 *           Cf. audit Vuln 1.</li>
 *       <li>sinon, création d'un nouveau compte USER avec provider = X</li>
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
    private final SessionService sessionService;
    private final SubscriptionService subscriptionService;
    private final GoogleTokenVerifier googleVerifier;
    private final AppleTokenVerifier appleVerifier;

    public TokenResponse loginWithGoogle(GoogleSignInRequest req, String userAgent, String ipAddress) {
        SocialIdentity identity = googleVerifier.verify(req.idToken());
        User user = findOrCreate(identity, null, null);
        return buildTokenResponse(user, userAgent, ipAddress);
    }

    public TokenResponse loginWithApple(AppleSignInRequest req, String userAgent, String ipAddress) {
        SocialIdentity identity = appleVerifier.verify(req.identityToken());
        User user = findOrCreate(identity, trim(req.firstName()), trim(req.lastName()));
        return buildTokenResponse(user, userAgent, ipAddress);
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

        // 2) Si un compte existe déjà avec cet email (peu importe son
        // auth_provider), on REFUSE. Sans cette garde, n'importe qui qui
        // peut signer un token social pour une adresse arbitraire (Apple
        // sans email_verified, Workspace Google avec un sous-domaine
        // mal-configuré...) pourrait prendre le contrôle d'un compte
        // existant — l'audit Vuln 1 décrit le scénario en détail.
        //
        // Le linking explicite d'un provider social à un compte existant
        // devra passer par un endpoint authentifié dédié (POST
        // /api/me/social-link, à implémenter quand on en aura besoin),
        // qui suppose d'être déjà connecté avec la méthode initiale.
        Optional<User> byEmail = userManager.findByEmail(identity.email());
        if (byEmail.isPresent()) {
            User existing = byEmail.get();
            log.warn("Refus de social sign-in : email {} déjà associé à un compte (provider initial: {}, tentative: {})",
                    identity.email(), existing.getAuthProvider(), identity.provider());
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Un compte existe déjà avec cette adresse email. Connectez-vous avec votre méthode initiale puis liez "
                            + identity.provider() + " depuis vos paramètres.");
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

    private TokenResponse buildTokenResponse(User u, String userAgent, String ipAddress) {
        SessionService.IssuedTokens tokens = sessionService.openSession(u, userAgent, ipAddress);
        SubscriptionService.CurrentAccess current = subscriptionService.currentAccess(u.getId());
        return TokenResponse.of(tokens.accessToken(), tokens.refreshToken(),
                jwtService.accessTokenTtlSeconds(),
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

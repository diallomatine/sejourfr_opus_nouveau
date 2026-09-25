package com.sejourfr.app.service;

import com.sejourfr.app.util.LogMask;
import com.sejourfr.app.dto.AppleSignInRequest;
import com.sejourfr.app.dto.AuthenticatedUser;
import com.sejourfr.app.dto.GoogleSignInRequest;
import com.sejourfr.app.dto.TokenResponse;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AuthKind;
import com.sejourfr.app.enums.AuthProvider;
import com.sejourfr.app.enums.DiagnosticRunClaimVia;
import com.sejourfr.app.enums.Role;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.security.JwtService;
import com.sejourfr.app.service.social.AppleTokenVerifier;
import com.sejourfr.app.service.social.GoogleTokenVerifier;
import com.sejourfr.app.service.social.SocialIdentity;
import com.sejourfr.app.service.analytics.AnalyticsIdentityService;
import com.sejourfr.app.service.diagnosticrun.DiagnosticRunClaimService;
import com.sejourfr.app.util.ClientContext;
import com.sejourfr.app.util.SignupAttribution;
import com.sejourfr.app.service.email.event.AccountCreatedEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;

/**
 * Orchestre la connexion via providers externes (Google, Apple) :
 * <ol>
 *   <li>Valide l'ID token via le verifier dedie (signature JWKS + claims).</li>
 *   <li>Find-or-create l'utilisateur local (sign-in et sign-up se comportent
 *       de façon identique — un seul flux "upsert") :
 *     <ul>
 *       <li>match prioritaire par {@code (provider, providerUserId)} →
 *           connexion.</li>
 *       <li>sinon, si l'email pointe sur un compte existant <strong>quel que
 *           soit son auth_provider</strong> → connexion sur ce compte. C'est
 *           sûr car l'email est <strong>garanti vérifié par le provider</strong>
 *           ({@code GoogleTokenVerifier}/{@code AppleTokenVerifier} rejettent
 *           tout token dont {@code email_verified} n'est pas vrai), donc le
 *           porteur du token contrôle réellement l'adresse — le scénario de
 *           prise de contrôle de l'audit Vuln 1/2 est bloqué en amont. On NE
 *           mute PAS {@code auth_provider} (il reste le mode de création
 *           initial) ; le prochain sign-in social re-matchera simplement par
 *           email.</li>
 *       <li>sinon, création d'un nouveau compte USER avec provider = X →
 *           connexion.</li>
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
    private final AnalyticsIdentityService analyticsIdentityService;
    private final DiagnosticRunClaimService diagnosticRunClaimService;
    private final ApplicationEventPublisher eventPublisher;

    public TokenResponse loginWithGoogle(GoogleSignInRequest req, String userAgent,
                                         String ipAddress, ClientContext client) {
        SocialIdentity identity = googleVerifier.verify(req.idToken());
        Resolution r = findOrCreate(identity, null, null, client, req.anonymousId());
        // Même geste qu'en connexion locale : le parcours anonyme de cet
        // appareil rejoint le compte. Idempotent et best-effort.
        onAuthenticated(r, client, req.anonymousId(), req.diagnosticRunId(), req.claimToken());
        return buildTokenResponse(r.user(), userAgent, ipAddress);
    }

    public TokenResponse loginWithApple(AppleSignInRequest req, String userAgent,
                                        String ipAddress, ClientContext client) {
        SocialIdentity identity = appleVerifier.verify(req.identityToken());
        Resolution r = findOrCreate(identity, trim(req.firstName()), trim(req.lastName()), client,
                req.anonymousId());
        onAuthenticated(r, client, req.anonymousId(), req.diagnosticRunId(), req.claimToken());
        return buildTokenResponse(r.user(), userAgent, ipAddress);
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

    /**
     * <p><b>La provenance n'est posée que sur la branche de CRÉATION</b> : un
     * sign-in social est le même flux pour se connecter et pour s'inscrire, et
     * la stamper sur les deux premières branches réécrirait la provenance de
     * l'acquisition à chaque reconnexion.
     */
    /** Le compte retrouve ou cree, et lequel des deux : c'est la nature du claim (lot 2). */
    private record Resolution(User user, boolean created) {
    }

    private void onAuthenticated(Resolution r, ClientContext client, String declaredAnonymousId,
                                 String diagnosticRunId, String claimToken) {
        ClientContext ctx = client == null ? ClientContext.unknown() : client;
        AuthKind kind = r.created() ? AuthKind.SIGNUP : AuthKind.LOGIN;
        analyticsIdentityService.onAuthenticated(r.user().getId(), kind,
                ctx.anonymousIdPreferring(declaredAnonymousId));
        // Meme geste qu'en auth locale : claim dans cette transaction, contexte
        // d'inscription pose au meme instant sur la branche de creation.
        diagnosticRunClaimService.onAuthenticated(r.user(), kind, diagnosticRunId, claimToken,
                DiagnosticRunClaimVia.SAME_DEVICE);
    }

    private Resolution findOrCreate(SocialIdentity identity, String firstNameOverride,
                                    String lastNameOverride, ClientContext client,
                                    String declaredAnonymousId) {
        // 1) lookup par (provider, sub) — match exact deja vu
        Optional<User> byProvider = userManager.findByProvider(identity.provider(), identity.providerUserId());
        if (byProvider.isPresent()) {
            User user = byProvider.get();
            user.setLastLoginAt(Instant.now());
            return new Resolution(userManager.save(user), false);
        }

        // 2) Compte existant pour cet email (quel que soit son auth_provider)
        // → connexion directe. L'email est garanti vérifié par le provider
        // (les verifiers rejettent tout token dont email_verified n'est pas
        // vrai), donc l'utilisateur contrôle réellement l'adresse : le scénario
        // de prise de contrôle (audit Vuln 1/2) est bloqué en amont. On ne mute
        // pas auth_provider — il reste le mode de création initial, et le
        // prochain sign-in social re-matchera ici par email.
        Optional<User> byEmail = userManager.findByEmail(identity.email());
        if (byEmail.isPresent()) {
            User existing = byEmail.get();
            existing.setLastLoginAt(Instant.now());
            log.info("Social sign-in sur compte existant : email={} (provider d'origine={}, via={})",
                    LogMask.email(identity.email()), existing.getAuthProvider(), identity.provider());
            return new Resolution(userManager.save(existing), false);
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
        SignupAttribution.stamp(user, client, declaredAnonymousId);
        log.info("Creation compte via {} : email={}", identity.provider(), LogMask.email(identity.email()));
        User saved = userManager.save(user);
        eventPublisher.publishEvent(new AccountCreatedEvent(saved.getId(), saved.getEmail()));
        return new Resolution(saved, true);
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

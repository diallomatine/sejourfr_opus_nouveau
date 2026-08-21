package com.sejourfr.app.service;

import com.sejourfr.app.dto.AppleSignInRequest;
import com.sejourfr.app.dto.GoogleSignInRequest;
import com.sejourfr.app.dto.TokenResponse;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AuthProvider;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.Role;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.security.JwtService;
import com.sejourfr.app.service.social.AppleTokenVerifier;
import com.sejourfr.app.service.social.GoogleTokenVerifier;
import com.sejourfr.app.service.social.SocialIdentity;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.util.ClientContext;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Test unitaire pur du find-or-create social : match prioritaire par
 * (provider, sub), fallback par email vérifié sans muter {@code auth_provider},
 * sinon création. Aucun appel réseau (verifiers mockés).
 */
class SocialAuthServiceTest {

    private static final ClientContext CTX = new ClientContext(ClientPlatform.MOBILE, "tiktok");

    private UserManager userManager;
    private SessionService sessionService;
    private SubscriptionService subscriptionService;
    private GoogleTokenVerifier googleVerifier;
    private AppleTokenVerifier appleVerifier;
    private MailService mailService;
    private SocialAuthService service;

    @BeforeEach
    void setUp() {
        userManager = mock(UserManager.class);
        JwtService jwtService = mock(JwtService.class);
        sessionService = mock(SessionService.class);
        subscriptionService = mock(SubscriptionService.class);
        googleVerifier = mock(GoogleTokenVerifier.class);
        appleVerifier = mock(AppleTokenVerifier.class);
        mailService = mock(MailService.class);

        service = new SocialAuthService(userManager, jwtService, sessionService,
                subscriptionService, googleVerifier, appleVerifier, mailService);

        when(jwtService.accessTokenTtlSeconds()).thenReturn(3600L);
        when(subscriptionService.currentAccess(any()))
                .thenReturn(new SubscriptionService.CurrentAccess(ModuleAccess.NONE, null));
        when(userManager.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(sessionService.openSession(any(), any(), any())).thenAnswer(inv ->
                new SessionService.IssuedTokens("acc", "ref", UUID.randomUUID(), inv.getArgument(0)));
    }

    private static SocialIdentity google(String email, String sub) {
        return new SocialIdentity(AuthProvider.GOOGLE, sub, email, "Given", "Family");
    }

    private static User existing(String email, AuthProvider provider) {
        User u = new User();
        u.setId(UUID.randomUUID());
        u.setEmail(email);
        u.setRole(Role.USER);
        u.setActive(true);
        u.setAuthProvider(provider);
        return u;
    }

    @Test
    void loginWithGoogle_existingByProvider_login_noCreate_noWelcome() {
        SocialIdentity id = google("known@test.fr", "sub-1");
        when(googleVerifier.verify("tok")).thenReturn(id);
        User user = existing("known@test.fr", AuthProvider.GOOGLE);
        when(userManager.findByProvider(AuthProvider.GOOGLE, "sub-1")).thenReturn(Optional.of(user));

        TokenResponse resp = service.loginWithGoogle(new GoogleSignInRequest("tok"), "ua", "ip", CTX);

        assertThat(resp.accessToken()).isEqualTo("acc");
        assertThat(user.getLastLoginAt()).isNotNull();
        verify(userManager, never()).findByEmail(any());
        verify(mailService, never()).sendWelcomeEmail(any(), any());
    }

    @Test
    void loginWithGoogle_existingByEmail_matchesWithoutMutatingProvider() {
        SocialIdentity id = google("local@test.fr", "sub-2");
        when(googleVerifier.verify("tok")).thenReturn(id);
        when(userManager.findByProvider(AuthProvider.GOOGLE, "sub-2")).thenReturn(Optional.empty());
        User local = existing("local@test.fr", AuthProvider.LOCAL);
        when(userManager.findByEmail("local@test.fr")).thenReturn(Optional.of(local));

        service.loginWithGoogle(new GoogleSignInRequest("tok"), "ua", "ip", CTX);

        // auth_provider reste celui de la création initiale (immutable ici).
        assertThat(local.getAuthProvider()).isEqualTo(AuthProvider.LOCAL);
        assertThat(local.getLastLoginAt()).isNotNull();
        verify(mailService, never()).sendWelcomeEmail(any(), any());
    }

    @Test
    void loginWithGoogle_newUser_createsWithProviderAndSendsWelcome() {
        SocialIdentity id = google("new@test.fr", "sub-3");
        when(googleVerifier.verify("tok")).thenReturn(id);
        when(userManager.findByProvider(AuthProvider.GOOGLE, "sub-3")).thenReturn(Optional.empty());
        when(userManager.findByEmail("new@test.fr")).thenReturn(Optional.empty());

        service.loginWithGoogle(new GoogleSignInRequest("tok"), "ua", "ip", CTX);

        org.mockito.ArgumentCaptor<User> captor = org.mockito.ArgumentCaptor.forClass(User.class);
        verify(userManager).save(captor.capture());
        User created = captor.getValue();
        assertThat(created.getEmail()).isEqualTo("new@test.fr");
        assertThat(created.getAuthProvider()).isEqualTo(AuthProvider.GOOGLE);
        assertThat(created.getProviderUserId()).isEqualTo("sub-3");
        assertThat(created.getPasswordHash()).isNull();
        assertThat(created.getRole()).isEqualTo(Role.USER);
        // Provenance du premier jour, posée sur la branche de CRÉATION seulement.
        assertThat(created.getSignupSource()).isEqualTo("tiktok");
        assertThat(created.getSignupPlatform()).isEqualTo(ClientPlatform.MOBILE);
        verify(mailService).sendWelcomeEmail("new@test.fr", created.getFirstName());
    }

    /**
     * Un sign-in social est le même flux pour se connecter et pour s'inscrire :
     * stamper la provenance sur la branche de connexion réécrirait l'acquisition
     * à chaque reconnexion, et attribuerait tout au dernier canal utilisé.
     */
    @Test
    void loginWithGoogle_existingUser_neverRewritesTheSignupOrigin() {
        User existing = new User();
        existing.setId(UUID.randomUUID());
        existing.setEmail("deja@test.fr");
        existing.setAuthProvider(AuthProvider.GOOGLE);
        existing.setSignupSource("instagram");
        existing.setSignupPlatform(ClientPlatform.WEB);
        SocialIdentity id = google("deja@test.fr", "sub-9");
        when(googleVerifier.verify("tok")).thenReturn(id);
        when(userManager.findByProvider(AuthProvider.GOOGLE, "sub-9"))
                .thenReturn(Optional.of(existing));

        service.loginWithGoogle(new GoogleSignInRequest("tok"), "ua", "ip", CTX);

        assertThat(existing.getSignupSource()).isEqualTo("instagram");
        assertThat(existing.getSignupPlatform()).isEqualTo(ClientPlatform.WEB);
    }

    @Test
    void loginWithApple_newUser_usesClientNameOverrides() {
        SocialIdentity id = new SocialIdentity(AuthProvider.APPLE, "apple-sub", "apple@test.fr", null, null);
        when(appleVerifier.verify("idtok")).thenReturn(id);
        when(userManager.findByProvider(AuthProvider.APPLE, "apple-sub")).thenReturn(Optional.empty());
        when(userManager.findByEmail("apple@test.fr")).thenReturn(Optional.empty());

        service.loginWithApple(new AppleSignInRequest("idtok", " Jean ", " Dupont "), "ua", "ip", CTX);

        org.mockito.ArgumentCaptor<User> captor = org.mockito.ArgumentCaptor.forClass(User.class);
        verify(userManager).save(captor.capture());
        User created = captor.getValue();
        assertThat(created.getAuthProvider()).isEqualTo(AuthProvider.APPLE);
        assertThat(created.getFirstName()).isEqualTo("Jean");
        assertThat(created.getLastName()).isEqualTo("Dupont");
    }

    @Test
    void configuredFlags_delegateToVerifiers() {
        when(googleVerifier.isConfigured()).thenReturn(true);
        when(appleVerifier.isConfigured()).thenReturn(false);

        assertThat(service.isGoogleConfigured()).isTrue();
        assertThat(service.isAppleConfigured()).isFalse();
    }
}

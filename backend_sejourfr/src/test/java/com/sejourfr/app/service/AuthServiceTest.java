package com.sejourfr.app.service;

import com.sejourfr.app.dto.AuthenticatedUser;
import com.sejourfr.app.dto.LoginRequest;
import com.sejourfr.app.dto.RefreshRequest;
import com.sejourfr.app.dto.RegisterRequest;
import com.sejourfr.app.dto.TokenResponse;
import com.sejourfr.app.entity.PasswordResetToken;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.Role;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.PasswordResetTokenManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.security.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.Authentication;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Test unitaire pur (Mockito) du facade d'authentification : register
 * (rejet doublon), login (mauvais mot de passe / user introuvable), me,
 * password reset (request silencieux + apply). Aucun accès réseau / DB.
 */
class AuthServiceTest {

    private AuthenticationManager authenticationManager;
    private UserManager userManager;
    private PasswordResetTokenManager passwordResetTokenManager;
    private JwtService jwtService;
    private SessionService sessionService;
    private SubscriptionService subscriptionService;
    private MailService mailService;
    private MeService meService;
    private org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;
    private AuthService service;

    @BeforeEach
    void setUp() {
        authenticationManager = mock(AuthenticationManager.class);
        userManager = mock(UserManager.class);
        passwordResetTokenManager = mock(PasswordResetTokenManager.class);
        jwtService = mock(JwtService.class);
        sessionService = mock(SessionService.class);
        subscriptionService = mock(SubscriptionService.class);
        mailService = mock(MailService.class);
        meService = mock(MeService.class);
        passwordEncoder = mock(org.springframework.security.crypto.password.PasswordEncoder.class);

        service = new AuthService(authenticationManager, userManager, passwordResetTokenManager,
                jwtService, sessionService, subscriptionService, mailService, meService,
                passwordEncoder);

        when(jwtService.accessTokenTtlSeconds()).thenReturn(3600L);
        when(subscriptionService.currentAccess(any()))
                .thenReturn(new SubscriptionService.CurrentAccess(ModuleAccess.NONE, null));
    }

    private static User userWith(String email) {
        User u = new User();
        u.setId(UUID.randomUUID());
        u.setEmail(email);
        u.setRole(Role.USER);
        u.setActive(true);
        return u;
    }

    private void stubSessionFor(User u) {
        when(sessionService.openSession(any(), any(), any()))
                .thenReturn(new SessionService.IssuedTokens("acc", "ref", UUID.randomUUID(), u));
    }

    // ------------------------------------------------------------------ register

    @Test
    void register_duplicateEmail_throws_andSavesNothing() {
        when(userManager.existsByEmail("dup@test.fr")).thenReturn(true);

        assertThatThrownBy(() -> service.register(
                new RegisterRequest("dup@test.fr", "password1", "A", "B", null), "ua", "ip"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("existe déjà");

        verify(userManager, never()).save(any());
        verify(mailService, never()).sendWelcomeEmail(any(), any());
    }

    @Test
    void register_success_lowercasesEmail_savesUser_sendsWelcome_returnsTokens() {
        when(userManager.existsByEmail("user@test.fr")).thenReturn(false);
        when(passwordEncoder.encode("password1")).thenReturn("hashed");
        when(userManager.save(any())).thenAnswer(inv -> inv.getArgument(0));
        User logged = userWith("user@test.fr");
        when(authenticationManager.authenticate(any())).thenReturn(mock(Authentication.class));
        when(userManager.findByEmail("user@test.fr")).thenReturn(Optional.of(logged));
        stubSessionFor(logged);

        TokenResponse resp = service.register(
                new RegisterRequest("User@Test.fr", "password1", " Alice ", " Martin ", null),
                "ua", "ip");

        assertThat(resp.accessToken()).isEqualTo("acc");
        assertThat(resp.refreshToken()).isEqualTo("ref");
        org.mockito.ArgumentCaptor<User> captor = org.mockito.ArgumentCaptor.forClass(User.class);
        verify(userManager).save(captor.capture());
        User saved = captor.getValue();
        assertThat(saved.getEmail()).isEqualTo("user@test.fr");
        assertThat(saved.getFirstName()).isEqualTo("Alice");
        assertThat(saved.getLastName()).isEqualTo("Martin");
        assertThat(saved.getRole()).isEqualTo(Role.USER);
        assertThat(saved.getPasswordHash()).isEqualTo("hashed");
        verify(mailService).sendWelcomeEmail("user@test.fr", "Alice");
    }

    // -------------------------------------------------- register + démarche visée

    /**
     * Prépare une inscription qui aboutit, et rend l'id que le serveur posera
     * sur le compte créé (le vrai id vient de {@code @UuidGenerator} au persist).
     */
    private UUID stubSuccessfulRegistration(String email) {
        UUID id = UUID.randomUUID();
        when(userManager.existsByEmail(email)).thenReturn(false);
        when(passwordEncoder.encode(any())).thenReturn("hashed");
        when(userManager.save(any())).thenAnswer(inv -> {
            User u = inv.getArgument(0);
            if (u.getId() == null) u.setId(id);
            return u;
        });
        User logged = userWith(email);
        logged.setId(id);
        when(authenticationManager.authenticate(any())).thenReturn(mock(Authentication.class));
        when(userManager.findByEmail(email)).thenReturn(Optional.of(logged));
        stubSessionFor(logged);
        return id;
    }

    /**
     * La démarche choisie sur l'écran de compte du diagnostic passe par
     * l'UNIQUE point d'écriture ({@code MeService.updateTargetProcedure}), qui
     * pose lui-même {@code target_level}. Le service d'inscription ne doit
     * jamais écrire le palier : ce serait une seconde copie de la table
     * démarche → niveau.
     */
    @Test
    void register_withTargetProcedure_delegatesToTheSingleWritePoint() {
        for (TargetProcedure procedure : TargetProcedure.values()) {
            setUp(); // repart d'un jeu de mocks neuf pour chaque démarche
            String email = procedure.name().toLowerCase() + "@test.fr";
            UUID id = stubSuccessfulRegistration(email);

            service.register(new RegisterRequest(email, "password1", "A", "B", procedure),
                    "ua", "ip");

            verify(meService).updateTargetProcedure(id, procedure);
            org.mockito.ArgumentCaptor<User> captor = org.mockito.ArgumentCaptor.forClass(User.class);
            verify(userManager).save(captor.capture());
            // Le palier n'est PAS posé par l'inscription : c'est le point
            // d'écriture délégué (ici mocké) qui s'en charge.
            assertThat(captor.getValue().getTargetLevel()).isNull();
        }
    }

    /** Sans démarche (cas du mobile, qui a son écran de parcours dédié) : rien n'est touché. */
    @Test
    void register_withoutTargetProcedure_neverTouchesTheTargetColumns() {
        String email = "sans@test.fr";
        stubSuccessfulRegistration(email);

        service.register(new RegisterRequest(email, "password1", "A", "B", null), "ua", "ip");

        verify(meService, never()).updateTargetProcedure(any(), any());
        org.mockito.ArgumentCaptor<User> captor = org.mockito.ArgumentCaptor.forClass(User.class);
        verify(userManager).save(captor.capture());
        assertThat(captor.getValue().getTargetProcedure()).isNull();
        assertThat(captor.getValue().getTargetLevel()).isNull();
    }

    // ------------------------------------------------------------------ login

    @Test
    void login_badPassword_throwsBadCredentials() {
        when(authenticationManager.authenticate(any()))
                .thenThrow(new BadCredentialsException("nope"));

        assertThatThrownBy(() -> service.login(
                new LoginRequest("x@test.fr", "bad"), "ua", "ip"))
                .isInstanceOf(BadCredentialsException.class)
                .hasMessageContaining("Identifiants invalides");
    }

    @Test
    void login_userNotFoundAfterAuth_throwsBadCredentials() {
        when(authenticationManager.authenticate(any())).thenReturn(mock(Authentication.class));
        when(userManager.findByEmail("ghost@test.fr")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.login(
                new LoginRequest("ghost@test.fr", "pw"), "ua", "ip"))
                .isInstanceOf(BadCredentialsException.class);
    }

    @Test
    void login_success_setsLastLogin_returnsTokens() {
        User u = userWith("ok@test.fr");
        when(authenticationManager.authenticate(any())).thenReturn(mock(Authentication.class));
        when(userManager.findByEmail("ok@test.fr")).thenReturn(Optional.of(u));
        stubSessionFor(u);

        TokenResponse resp = service.login(new LoginRequest("ok@test.fr", "pw"), "ua", "ip");

        assertThat(u.getLastLoginAt()).isNotNull();
        assertThat(resp.tokenType()).isEqualTo("Bearer");
        assertThat(resp.expiresInSeconds()).isEqualTo(3600L);
        assertThat(resp.user().email()).isEqualTo("ok@test.fr");
    }

    // ------------------------------------------------------------------ me

    @Test
    void me_unknownEmail_throwsNotFound() {
        when(userManager.findByEmail("none@test.fr")).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.me("none@test.fr"))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void me_returnsAuthenticatedUser_withPremiumFromAccess() {
        User u = userWith("me@test.fr");
        when(userManager.findByEmail("me@test.fr")).thenReturn(Optional.of(u));
        when(subscriptionService.currentAccess(u.getId()))
                .thenReturn(new SubscriptionService.CurrentAccess(ModuleAccess.INTEGRAL, Instant.now()));

        AuthenticatedUser au = service.me("me@test.fr");

        assertThat(au.isPremium()).isTrue();
        assertThat(au.hasTcf()).isTrue();
        assertThat(au.hasCivique()).isTrue();
    }

    // ------------------------------------------------------------------ password reset

    @Test
    void requestPasswordReset_unknownEmail_silent_noTokenNoMail() {
        when(userManager.findByEmail("ghost@test.fr")).thenReturn(Optional.empty());

        service.requestPasswordReset("Ghost@Test.fr");

        verify(passwordResetTokenManager, never()).save(any());
        verify(mailService, never()).sendPasswordResetEmail(any(), any());
    }

    @Test
    void requestPasswordReset_known_invalidatesSavesAndSendsMail() {
        User u = userWith("reset@test.fr");
        when(userManager.findByEmail("reset@test.fr")).thenReturn(Optional.of(u));

        service.requestPasswordReset("reset@test.fr");

        verify(passwordResetTokenManager).invalidateAllForUser(eq(u.getId()), any());
        verify(passwordResetTokenManager).save(any(PasswordResetToken.class));
        verify(mailService).sendPasswordResetEmail(eq("reset@test.fr"), any());
    }

    @Test
    void resetPassword_invalidToken_throws() {
        when(passwordResetTokenManager.findByTokenHash(any())).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.resetPassword("raw", "newPw"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("invalide");
    }

    @Test
    void resetPassword_expiredToken_throws() {
        PasswordResetToken token = new PasswordResetToken();
        token.setUser(userWith("u@test.fr"));
        token.setExpiresAt(Instant.now().minus(1, ChronoUnit.HOURS));
        when(passwordResetTokenManager.findByTokenHash(any())).thenReturn(Optional.of(token));

        assertThatThrownBy(() -> service.resetPassword("raw", "newPw"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("expiré");
    }

    @Test
    void resetPassword_success_updatesPassword_marksUsed_revokesSessions() {
        User u = userWith("u@test.fr");
        PasswordResetToken token = new PasswordResetToken();
        token.setUser(u);
        token.setExpiresAt(Instant.now().plus(1, ChronoUnit.HOURS));
        when(passwordResetTokenManager.findByTokenHash(any())).thenReturn(Optional.of(token));
        when(passwordEncoder.encode("newPw")).thenReturn("newHash");

        service.resetPassword("raw", "newPw");

        assertThat(u.getPasswordHash()).isEqualTo("newHash");
        assertThat(token.getUsedAt()).isNotNull();
        verify(userManager).save(u);
        verify(sessionService).revokeAllForUser(u.getId());
    }

    // ------------------------------------------------------------------ refresh / logout

    @Test
    void refresh_delegatesToSessionRotate() {
        User u = userWith("r@test.fr");
        when(sessionService.rotate("rt", "ua", "ip"))
                .thenReturn(new SessionService.IssuedTokens("a2", "r2", UUID.randomUUID(), u));

        TokenResponse resp = service.refresh(new RefreshRequest("rt"), "ua", "ip");

        assertThat(resp.accessToken()).isEqualTo("a2");
        assertThat(resp.refreshToken()).isEqualTo("r2");
    }

    @Test
    void logout_delegatesToCloseSession() {
        service.logout("rt");
        verify(sessionService).closeSession("rt");
    }
}

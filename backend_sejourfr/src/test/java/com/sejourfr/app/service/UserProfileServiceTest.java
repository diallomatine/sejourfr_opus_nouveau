package com.sejourfr.app.service;

import com.sejourfr.app.entity.EmailChangeToken;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AuthProvider;
import com.sejourfr.app.manager.EmailChangeTokenManager;
import com.sejourfr.app.manager.UserManager;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Map;
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
 * Test unitaire pur du profil compte : update prénom/nom, changePassword
 * (refus social / mauvais mdp / mdp identique + cascade révocation),
 * changement d'email (validations + confirmation + race). Collaborateurs
 * mockés ; aucune DB / mail réel.
 */
class UserProfileServiceTest {

    private UserManager userManager;
    private EmailChangeTokenManager emailChangeTokenManager;
    private PasswordEncoder passwordEncoder;
    private MailService mailService;
    private MailTemplateRenderer templateRenderer;
    private SessionService sessionService;
    private UserProfileService service;

    @BeforeEach
    void setUp() {
        userManager = mock(UserManager.class);
        emailChangeTokenManager = mock(EmailChangeTokenManager.class);
        passwordEncoder = mock(PasswordEncoder.class);
        mailService = mock(MailService.class);
        templateRenderer = mock(MailTemplateRenderer.class);
        sessionService = mock(SessionService.class);
        service = new UserProfileService(userManager, emailChangeTokenManager, passwordEncoder,
                mailService, templateRenderer, sessionService);
    }

    private static User localUser(String email) {
        User u = new User();
        u.setId(UUID.randomUUID());
        u.setEmail(email);
        u.setAuthProvider(AuthProvider.LOCAL);
        u.setPasswordHash("currentHash");
        return u;
    }

    // ------------------------------------------------------------------ updateProfile

    @Test
    void updateProfile_trimsAndSaves() {
        User u = localUser("u@test.fr");
        when(userManager.findById(u.getId())).thenReturn(Optional.of(u));

        service.updateProfile(u.getId(), "  Jean ", " Dupont ");

        assertThat(u.getFirstName()).isEqualTo("Jean");
        assertThat(u.getLastName()).isEqualTo("Dupont");
        verify(userManager).save(u);
    }

    @Test
    void updateProfile_userNotFound_throws() {
        UUID id = UUID.randomUUID();
        when(userManager.findById(id)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.updateProfile(id, "A", "B"))
                .isInstanceOf(EntityNotFoundException.class);
    }

    // ------------------------------------------------------------------ changePassword

    @Test
    void changePassword_socialAccount_throwsBadRequest() {
        User u = localUser("g@test.fr");
        u.setAuthProvider(AuthProvider.GOOGLE);
        when(userManager.findById(u.getId())).thenReturn(Optional.of(u));

        assertThatThrownBy(() -> service.changePassword(u.getId(), "old", "new"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.BAD_REQUEST);
        verify(sessionService, never()).revokeAllForUser(any());
    }

    @Test
    void changePassword_wrongCurrent_throwsBadRequest() {
        User u = localUser("u@test.fr");
        when(userManager.findById(u.getId())).thenReturn(Optional.of(u));
        when(passwordEncoder.matches("old", "currentHash")).thenReturn(false);

        assertThatThrownBy(() -> service.changePassword(u.getId(), "old", "new"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void changePassword_newSameAsCurrent_throwsBadRequest() {
        User u = localUser("u@test.fr");
        when(userManager.findById(u.getId())).thenReturn(Optional.of(u));
        when(passwordEncoder.matches("old", "currentHash")).thenReturn(true);
        when(passwordEncoder.matches("new", "currentHash")).thenReturn(true);

        assertThatThrownBy(() -> service.changePassword(u.getId(), "old", "new"))
                .isInstanceOf(ResponseStatusException.class);
        verify(userManager, never()).save(any());
    }

    @Test
    void changePassword_success_encodesAndRevokesSessions() {
        User u = localUser("u@test.fr");
        when(userManager.findById(u.getId())).thenReturn(Optional.of(u));
        when(passwordEncoder.matches("old", "currentHash")).thenReturn(true);
        when(passwordEncoder.matches("new", "currentHash")).thenReturn(false);
        when(passwordEncoder.encode("new")).thenReturn("newHash");

        service.changePassword(u.getId(), "old", "new");

        assertThat(u.getPasswordHash()).isEqualTo("newHash");
        verify(userManager).save(u);
        verify(sessionService).revokeAllForUser(u.getId());
    }

    // ------------------------------------------------------------------ requestEmailChange

    @Test
    void requestEmailChange_social_throwsBadRequest() {
        User u = localUser("g@test.fr");
        u.setAuthProvider(AuthProvider.APPLE);
        when(userManager.findById(u.getId())).thenReturn(Optional.of(u));

        assertThatThrownBy(() -> service.requestEmailChange(u.getId(), "x@test.fr", "pw"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void requestEmailChange_wrongPassword_throwsBadRequest() {
        User u = localUser("u@test.fr");
        when(userManager.findById(u.getId())).thenReturn(Optional.of(u));
        when(passwordEncoder.matches("pw", "currentHash")).thenReturn(false);

        assertThatThrownBy(() -> service.requestEmailChange(u.getId(), "x@test.fr", "pw"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void requestEmailChange_sameEmail_throwsBadRequest() {
        User u = localUser("u@test.fr");
        when(userManager.findById(u.getId())).thenReturn(Optional.of(u));
        when(passwordEncoder.matches("pw", "currentHash")).thenReturn(true);

        assertThatThrownBy(() -> service.requestEmailChange(u.getId(), "U@Test.fr", "pw"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void requestEmailChange_emailTaken_throwsConflict() {
        User u = localUser("u@test.fr");
        when(userManager.findById(u.getId())).thenReturn(Optional.of(u));
        when(passwordEncoder.matches("pw", "currentHash")).thenReturn(true);
        when(userManager.existsByEmail("taken@test.fr")).thenReturn(true);

        assertThatThrownBy(() -> service.requestEmailChange(u.getId(), "Taken@Test.fr", "pw"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.CONFLICT);
    }

    @Test
    void requestEmailChange_success_invalidatesSavesTokenSendsMail() {
        User u = localUser("u@test.fr");
        when(userManager.findById(u.getId())).thenReturn(Optional.of(u));
        when(passwordEncoder.matches("pw", "currentHash")).thenReturn(true);
        when(userManager.existsByEmail("new@test.fr")).thenReturn(false);

        service.requestEmailChange(u.getId(), "New@Test.fr", "pw");

        verify(emailChangeTokenManager).invalidateAllForUser(eq(u.getId()), any());
        org.mockito.ArgumentCaptor<EmailChangeToken> captor =
                org.mockito.ArgumentCaptor.forClass(EmailChangeToken.class);
        verify(emailChangeTokenManager).save(captor.capture());
        assertThat(captor.getValue().getNewEmail()).isEqualTo("new@test.fr");
        verify(mailService).sendEmailChangeConfirmation(eq("new@test.fr"), any());
    }

    // ------------------------------------------------------------------ confirmEmailChange

    @Test
    void confirmEmailChange_invalidToken_throwsBadRequest() {
        when(emailChangeTokenManager.findByTokenHash(any())).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.confirmEmailChange("raw"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void confirmEmailChange_usedOrExpiredToken_throwsBadRequest() {
        EmailChangeToken token = new EmailChangeToken();
        token.setUser(localUser("u@test.fr"));
        token.setNewEmail("new@test.fr");
        token.setExpiresAt(Instant.now().minus(1, ChronoUnit.HOURS));
        when(emailChangeTokenManager.findByTokenHash(any())).thenReturn(Optional.of(token));

        assertThatThrownBy(() -> service.confirmEmailChange("raw"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.BAD_REQUEST);
    }

    @Test
    void confirmEmailChange_emailTakenByOther_throwsConflict() {
        User u = localUser("old@test.fr");
        EmailChangeToken token = new EmailChangeToken();
        token.setUser(u);
        token.setNewEmail("taken@test.fr");
        token.setExpiresAt(Instant.now().plus(1, ChronoUnit.HOURS));
        when(emailChangeTokenManager.findByTokenHash(any())).thenReturn(Optional.of(token));
        when(userManager.existsByEmail("taken@test.fr")).thenReturn(true);

        assertThatThrownBy(() -> service.confirmEmailChange("raw"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode())
                .isEqualTo(HttpStatus.CONFLICT);
    }

    @Test
    void confirmEmailChange_success_setsEmail_marksUsed_revokesSessions() {
        User u = localUser("old@test.fr");
        EmailChangeToken token = new EmailChangeToken();
        token.setUser(u);
        token.setNewEmail("new@test.fr");
        token.setExpiresAt(Instant.now().plus(1, ChronoUnit.HOURS));
        when(emailChangeTokenManager.findByTokenHash(any())).thenReturn(Optional.of(token));
        when(userManager.existsByEmail("new@test.fr")).thenReturn(false);

        String result = service.confirmEmailChange("raw");

        assertThat(result).isEqualTo("new@test.fr");
        assertThat(u.getEmail()).isEqualTo("new@test.fr");
        assertThat(token.getUsedAt()).isNotNull();
        verify(userManager).save(u);
        verify(sessionService).revokeAllForUser(u.getId());
    }

    @Test
    void renderEmailChangeConfirmationPage_delegatesToRenderer() {
        when(templateRenderer.render(eq("email-change-confirmed.html"), any())).thenReturn("<html/>");

        String html = service.renderEmailChangeConfirmationPage(true, "ok");

        assertThat(html).isEqualTo("<html/>");
        org.mockito.ArgumentCaptor<Map<String, String>> captor =
                org.mockito.ArgumentCaptor.forClass(Map.class);
        verify(templateRenderer).render(eq("email-change-confirmed.html"), captor.capture());
        assertThat(captor.getValue()).containsEntry("message", "ok");
    }
}

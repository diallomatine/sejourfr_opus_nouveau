package com.sejourfr.app.service.email.compose;

import com.sejourfr.app.entity.EmailChangeToken;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.manager.EmailChangeTokenManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.email.EmailLinks;
import com.sejourfr.app.service.email.EmailRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class SecurityEmailComposerTest {

    private final UUID userId = UUID.randomUUID();
    private final UUID requestId = UUID.randomUUID();
    private EmailChangeTokenManager tokens;
    private SecurityEmailComposer composer;

    @BeforeEach
    void setUp() {
        UserManager users = mock(UserManager.class);
        tokens = mock(EmailChangeTokenManager.class);
        EmailLinks links = new EmailLinks("https://sejourfr.fr", "https://api.sejourfr.fr");
        composer = new SecurityEmailComposer(new AccountEmailComposer(users, links), tokens, links);
        User u = new User();
        u.setId(userId);
        u.setEmail("alice@example.com");
        u.setFirstName("Alice");
        when(users.findById(userId)).thenReturn(Optional.of(u));
    }

    @Test
    void reinitialisationPorteLeLienEtLaDureeServie() {
        EmailRequest r = composer.passwordReset(userId, requestId, "JETON", 60).orElseThrow();

        assertThat(r.type()).isEqualTo(EmailType.PASSWORD_RESET);
        assertThat(r.deduplicationKey()).isEqualTo("PASSWORD_RESET:" + requestId);
        assertThat(r.variables()).containsEntry("resetUrl", "https://sejourfr.fr/reinitialiser-mot-de-passe?token=JETON")
                .containsEntry("expiresInMinutes", "60");
        assertThat(r.toString()).doesNotContain("JETON");
    }

    @Test
    void motDePasseChangePorteLInstantDuFait() {
        Instant at = Instant.parse("2026-09-25T12:05:00Z");
        UUID eventId = UUID.randomUUID();

        EmailRequest r = composer.passwordChanged(userId, eventId, at, EmailRequest.Origin.EVENT).orElseThrow();

        assertThat(r.occurredAt()).isEqualTo(at);
        assertThat(r.deduplicationKey()).isEqualTo("PASSWORD_CHANGED:" + eventId);
        assertThat(r.variables()).containsEntry("changedAt", "25 septembre 2026 à 14 h 05")
                .containsEntry("supportUrl", "https://sejourfr.fr/contact");
    }

    @Test
    void confirmationVersLaNouvelleAdresse() {
        EmailRequest r = composer.emailChangeConfirmation(userId, "new@example.com", requestId, "TOK", 60).orElseThrow();

        assertThat(r.recipient()).isEqualTo("new@example.com");
        assertThat(r.variables()).containsEntry("confirmUrl",
                "https://api.sejourfr.fr/api/auth/confirm-email-change?token=TOK");
    }

    @Test
    void lAncienneAdresseRecoitLaNouvelleMasquee() {
        EmailChangeToken token = new EmailChangeToken();
        token.setNewEmail("nouvelle.adresse@example.com");
        when(tokens.findById(requestId)).thenReturn(Optional.of(token));

        EmailRequest r = composer.emailChanged(userId, "ancienne@example.com", requestId, Instant.now(),
                EmailRequest.Origin.DEFERRED_RETRY).orElseThrow();

        assertThat(r.recipient()).isEqualTo("ancienne@example.com");
        assertThat(r.variables()).containsEntry("newEmailMasked", "n***@example.com");
        assertThat(r.variables().values()).doesNotContain("nouvelle.adresse@example.com");
    }
}

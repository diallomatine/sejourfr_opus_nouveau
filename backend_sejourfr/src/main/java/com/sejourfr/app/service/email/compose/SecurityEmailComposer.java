package com.sejourfr.app.service.email.compose;

import com.sejourfr.app.entity.EmailChangeToken;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.manager.EmailChangeTokenManager;
import com.sejourfr.app.service.email.EmailFormats;
import com.sejourfr.app.service.email.EmailKeys;
import com.sejourfr.app.service.email.EmailLinks;
import com.sejourfr.app.service.email.EmailRequest;
import com.sejourfr.app.util.LogMask;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Les mails de SECURITE du compte : reinitialisation, mot de passe change,
 * confirmation d'une nouvelle adresse, adresse changee (vers l'ancienne).
 *
 * <p>🛑 Deux d'entre eux portent un jeton brut ({@code PASSWORD_RESET},
 * {@code EMAIL_CHANGE_CONFIRMATION}) : ils ne se relancent jamais en differe —
 * le jeton n'est stocke que hache. Le candidat refait sa demande.
 */
@Component
@RequiredArgsConstructor
public class SecurityEmailComposer {

    private final AccountEmailComposer accounts;
    private final EmailChangeTokenManager emailChangeTokenManager;
    private final EmailLinks links;

    @Transactional(readOnly = true)
    public Optional<EmailRequest> passwordReset(UUID userId, UUID resetRequestId, String rawToken,
                                                long expiresInMinutes) {
        return accounts.activeUser(userId).map(user -> new EmailRequest(
                EmailType.PASSWORD_RESET, user.getId(), user.getEmail(),
                Map.of("firstName", EmailFormats.firstName(user.getFirstName()),
                        "greeting", EmailFormats.greeting(user.getFirstName()),
                        "resetUrl", links.passwordReset(rawToken),
                        "expiresInMinutes", String.valueOf(expiresInMinutes)),
                EmailKeys.byReference(EmailType.PASSWORD_RESET, resetRequestId), resetRequestId, null,
                EmailRequest.Origin.EVENT));
    }

    /** Envoi initial et relance differee : {@code changedAt} vient de l'evenement puis d'{@code occurred_at}. */
    @Transactional(readOnly = true)
    public Optional<EmailRequest> passwordChanged(UUID userId, UUID eventId, Instant changedAt,
                                                  EmailRequest.Origin origin) {
        return accounts.activeUser(userId).map(user -> new EmailRequest(
                EmailType.PASSWORD_CHANGED, user.getId(), user.getEmail(),
                Map.of("firstName", EmailFormats.firstName(user.getFirstName()),
                        "greeting", EmailFormats.greeting(user.getFirstName()),
                        "changedAt", EmailFormats.dateTime(changedAt),
                        "supportUrl", links.contact()),
                EmailKeys.byReference(EmailType.PASSWORD_CHANGED, eventId), eventId, changedAt, origin));
    }

    /** Vers la NOUVELLE adresse, qui n'est pas encore celle du compte. */
    @Transactional(readOnly = true)
    public Optional<EmailRequest> emailChangeConfirmation(UUID userId, String newEmail, UUID requestId,
                                                          String rawToken, long expiresInMinutes) {
        return accounts.activeUser(userId).map(user -> new EmailRequest(
                EmailType.EMAIL_CHANGE_CONFIRMATION, user.getId(), newEmail,
                Map.of("firstName", EmailFormats.firstName(user.getFirstName()),
                        "greeting", EmailFormats.greeting(user.getFirstName()),
                        "confirmUrl", links.emailChangeConfirmation(rawToken),
                        "expiresInMinutes", String.valueOf(expiresInMinutes)),
                EmailKeys.byReference(EmailType.EMAIL_CHANGE_CONFIRMATION, requestId), requestId, null,
                EmailRequest.Origin.EVENT));
    }

    /**
     * Vers l'ANCIENNE adresse. La nouvelle n'y figure que masquee. A la relance
     * differee, l'ancienne adresse se relit sur la ligne du journal (elle n'est
     * plus nulle part ailleurs) et la nouvelle sur la demande de changement.
     */
    @Transactional(readOnly = true)
    public Optional<EmailRequest> emailChanged(UUID userId, String oldEmail, UUID requestId,
                                               Instant changedAt, EmailRequest.Origin origin) {
        Optional<String> newEmail = emailChangeTokenManager.findById(requestId).map(EmailChangeToken::getNewEmail);
        return accounts.activeUser(userId).map(user -> new EmailRequest(
                EmailType.EMAIL_CHANGED, user.getId(), oldEmail,
                Map.of("firstName", EmailFormats.firstName(user.getFirstName()),
                        "greeting", EmailFormats.greeting(user.getFirstName()),
                        "changedAt", EmailFormats.dateTime(changedAt),
                        "newEmailMasked", newEmail.map(LogMask::email).orElse(""),
                        "supportUrl", links.contact()),
                EmailKeys.byReference(EmailType.EMAIL_CHANGED, requestId), requestId, changedAt, origin));
    }
}

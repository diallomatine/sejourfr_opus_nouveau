package com.sejourfr.app.service.email.event;

import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.service.email.EmailDispatcher;
import com.sejourfr.app.service.email.EmailIntent;
import com.sejourfr.app.service.email.EmailKeys;
import com.sejourfr.app.service.email.EmailRequest;
import com.sejourfr.app.service.email.EmailService;
import com.sejourfr.app.service.email.compose.AccountEmailComposer;
import com.sejourfr.app.service.email.compose.DiagnosticEmailComposer;
import com.sejourfr.app.service.email.compose.PremiumEmailComposer;
import com.sejourfr.app.service.email.compose.SecurityEmailComposer;
import com.sejourfr.app.service.email.compose.SupportEmailComposer;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * <b>Les mails evenementiels partent APRES LE COMMIT</b> (brief §5, S3/S4).
 *
 * <p>Jamais dans la transaction metier : un rollback de l'inscription n'envoie
 * pas de bienvenue, et un SMTP lent ne retient ni la transaction ni la requete
 * (la composition et l'envoi partent sur l'executor email, via
 * {@link EmailDispatcher}).
 *
 * <p>🛑 {@code fallbackExecution} reste a {@code false} (complement D) : un
 * evenement publie HORS transaction serait perdu en silence, d'ou un test IT
 * par point de publication qui prouve qu'il y a bien une transaction.
 */
@Component
@RequiredArgsConstructor
public class EmailEventListener {

    private final EmailDispatcher dispatcher;
    private final EmailService emailService;
    private final AccountEmailComposer accounts;
    private final DiagnosticEmailComposer diagnostics;
    private final PremiumEmailComposer premium;
    private final SecurityEmailComposer security;
    private final SupportEmailComposer support;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onAccountCreated(AccountCreatedEvent event) {
        EmailIntent intent = new EmailIntent(EmailType.WELCOME, event.userId(), event.email(),
                EmailKeys.welcome(event.userId()), event.userId(), null);
        dispatcher.dispatch(intent, () -> accounts.welcome(event.userId(), EmailRequest.Origin.EVENT));
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onDiagnosticPlanReady(DiagnosticPlanReadyEvent event) {
        EmailIntent intent = new EmailIntent(EmailType.DIAGNOSTIC_PLAN_READY, event.userId(), event.email(),
                EmailKeys.diagnosticPlanReady(event.userId(), event.module()), event.diagnosticId(), null);
        if (event.adoption()) {
            dispatcher.run(intent, () -> emailService.consumeKey(intent));
            return;
        }
        dispatcher.dispatch(intent, () -> diagnostics.planReady(
                event.userId(), event.module(), event.diagnosticId(), EmailRequest.Origin.EVENT));
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onPremiumAccessGranted(PremiumAccessGrantedEvent event) {
        EmailType type = event.extension() ? EmailType.PREMIUM_ACCESS_EXTENDED : EmailType.PREMIUM_ACCESS_STARTED;
        EmailIntent intent = new EmailIntent(type, event.userId(), event.email(),
                EmailKeys.byReference(type, event.accessId()), event.accessId(), null);
        dispatcher.dispatch(intent, () -> premium.accessGranted(type, event.accessId(), EmailRequest.Origin.EVENT));
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onPremiumSubscriptionCanceled(PremiumSubscriptionCanceledEvent event) {
        EmailType type = EmailType.PREMIUM_SUBSCRIPTION_CANCELED;
        EmailIntent intent = new EmailIntent(type, event.userId(), event.email(),
                EmailKeys.byReference(type, event.accessId()), event.accessId(), null);
        dispatcher.dispatch(intent, () -> premium.subscriptionCanceled(event.accessId(), EmailRequest.Origin.EVENT));
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onPasswordResetRequested(PasswordResetRequestedEvent event) {
        EmailType type = EmailType.PASSWORD_RESET;
        EmailIntent intent = new EmailIntent(type, event.userId(), event.email(),
                EmailKeys.byReference(type, event.resetRequestId()), event.resetRequestId(), null);
        dispatcher.dispatch(intent, () -> security.passwordReset(
                event.userId(), event.resetRequestId(), event.rawToken(), event.expiresInMinutes()));
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onPasswordChanged(PasswordChangedEvent event) {
        EmailType type = EmailType.PASSWORD_CHANGED;
        EmailIntent intent = new EmailIntent(type, event.userId(), event.email(),
                EmailKeys.byReference(type, event.eventId()), event.eventId(), event.changedAt());
        dispatcher.dispatch(intent, () -> security.passwordChanged(
                event.userId(), event.eventId(), event.changedAt(), EmailRequest.Origin.EVENT));
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onEmailChangeRequested(EmailChangeRequestedEvent event) {
        EmailType type = EmailType.EMAIL_CHANGE_CONFIRMATION;
        EmailIntent intent = new EmailIntent(type, event.userId(), event.newEmail(),
                EmailKeys.byReference(type, event.requestId()), event.requestId(), null);
        dispatcher.dispatch(intent, () -> security.emailChangeConfirmation(
                event.userId(), event.newEmail(), event.requestId(), event.rawToken(), event.expiresInMinutes()));
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onEmailChanged(EmailChangedEvent event) {
        EmailType type = EmailType.EMAIL_CHANGED;
        EmailIntent intent = new EmailIntent(type, event.userId(), event.oldEmail(),
                EmailKeys.byReference(type, event.requestId()), event.requestId(), event.changedAt());
        dispatcher.dispatch(intent, () -> security.emailChanged(
                event.userId(), event.oldEmail(), event.requestId(), event.changedAt(), EmailRequest.Origin.EVENT));
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onContactReceived(ContactReceivedEvent event) {
        EmailType type = EmailType.CONTACT_RECEIVED;
        EmailIntent intent = new EmailIntent(type, null, event.email(),
                EmailKeys.byReference(type, event.conversationId()), event.conversationId(), null);
        dispatcher.dispatch(intent, () -> support.contactReceived(event));
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onSupportReply(SupportReplyEvent event) {
        EmailType type = EmailType.SUPPORT_REPLY;
        EmailIntent intent = new EmailIntent(type, null, event.email(),
                EmailKeys.byReference(type, event.messageId()), event.messageId(), null);
        dispatcher.dispatch(intent, () -> support.supportReply(event.messageId(), EmailRequest.Origin.EVENT));
    }
}

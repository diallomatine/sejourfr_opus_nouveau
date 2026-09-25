package com.sejourfr.app.service.email.event;

import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.service.email.EmailDispatcher;
import com.sejourfr.app.service.email.EmailIntent;
import com.sejourfr.app.service.email.EmailKeys;
import com.sejourfr.app.service.email.EmailRequest;
import com.sejourfr.app.service.email.EmailService;
import com.sejourfr.app.service.email.compose.AccountEmailComposer;
import com.sejourfr.app.service.email.compose.DiagnosticEmailComposer;
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
}

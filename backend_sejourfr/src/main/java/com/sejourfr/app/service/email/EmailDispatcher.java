package com.sejourfr.app.service.email;

import com.sejourfr.app.config.EmailAsyncConfig;
import com.sejourfr.app.util.LogMask;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.task.TaskExecutor;
import org.springframework.core.task.TaskRejectedException;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.function.Supplier;

/**
 * Le passage d'un evenement metier COMMITE a l'executor email.
 *
 * <p>La composition (lecture du compte, du Plan, de l'acces...) ET l'envoi
 * tournent sur {@code emailTaskExecutor}, jamais dans le thread de la requete
 * qui a commite. Soumission explicite plutot qu'un {@code @Async} : un rejet de
 * l'executor doit devenir une ligne FAILED (complement E), et un {@code @Async}
 * le laisserait remonter dans la synchronisation de fin de transaction.
 *
 * <p>🛑 Aucune exception ne sort d'ici.
 */
@Component
@Slf4j
public class EmailDispatcher {

    private final TaskExecutor executor;
    private final EmailService emailService;

    public EmailDispatcher(@Qualifier(EmailAsyncConfig.EMAIL_TASK_EXECUTOR) TaskExecutor executor,
                           EmailService emailService) {
        this.executor = executor;
        this.emailService = emailService;
    }

    /** Compose puis envoie, sur l'executor email. */
    public void dispatch(EmailIntent intent, Supplier<Optional<EmailRequest>> composer) {
        submit(intent, () -> composer.get().ifPresent(emailService::send));
    }

    /** Execute une action d'ecriture (consommer une cle) sur l'executor email. */
    public void run(EmailIntent intent, Runnable action) {
        submit(intent, action);
    }

    private void submit(EmailIntent intent, Runnable action) {
        try {
            executor.execute(() -> {
                try {
                    action.run();
                } catch (RuntimeException e) {
                    log.warn("Email {} vers {} : composition ou envoi en echec : {}", intent.type(),
                            LogMask.email(intent.recipient()), EmailErrors.sanitize(e));
                    recordFailure(intent, EmailErrors.sanitize(e));
                }
            });
        } catch (TaskRejectedException e) {
            recordFailure(intent, "rejected: email executor saturated");
        } catch (RuntimeException e) {
            log.warn("Email {} : soumission impossible : {}", intent.type(), EmailErrors.sanitize(e));
        }
    }

    private void recordFailure(EmailIntent intent, String reason) {
        try {
            emailService.recordFailure(intent, reason);
        } catch (RuntimeException e) {
            log.warn("Email {} : echec non trace : {}", intent.type(), EmailErrors.sanitize(e));
        }
    }
}

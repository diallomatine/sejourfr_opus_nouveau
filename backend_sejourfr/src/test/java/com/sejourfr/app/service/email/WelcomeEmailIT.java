package com.sejourfr.app.service.email;

import com.sejourfr.app.dto.RegisterRequest;
import com.sejourfr.app.entity.EmailDelivery;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EmailDeliveryStatus;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.AuthService;
import com.sejourfr.app.support.AbstractEmailIT;
import com.sejourfr.app.support.EmailTestSupport;
import com.sejourfr.app.util.ClientContext;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * WELCOME de bout en bout : evenement publie dans la transaction d'inscription,
 * mail compose et envoye APRES COMMIT sur l'executor email (brief §10 :
 * « Transaction »).
 */
class WelcomeEmailIT extends AbstractEmailIT {

    @Autowired private AuthService authService;
    @Autowired private UserManager userManager;
    @Autowired private PlatformTransactionManager txManager;

    private RegisterRequest inscription(String email) {
        return new RegisterRequest(email, "password1", "Alice", "Martin", null, null, null, null, null);
    }

    private User inscrire(String email) {
        authService.register(inscription(email), "ua", "127.0.0.1", ClientContext.unknown());
        return track(userManager.findByEmail(email).orElseThrow());
    }

    private static String email() {
        return "welcome-" + UUID.randomUUID() + "@test.sejourfr";
    }

    @Test
    @DisplayName("Inscription commitee : WELCOME part une fois, ligne SENT sur la cle WELCOME:{userId}")
    void inscriptionEnvoieBienvenue() {
        User u = inscrire(email());

        EmailTestSupport.await("WELCOME envoye", () -> hasStatus(u, EmailType.WELCOME, EmailDeliveryStatus.SENT));
        assertThat(mails.sentTo(u.getEmail())).singleElement().satisfies(m -> {
            assertThat(m.type()).isEqualTo(EmailType.WELCOME);
            assertThat(m.variables()).containsEntry("firstName", "Alice").containsEntry("greeting", "Bonjour Alice");
            assertThat(m.unsubscribeUrl()).isNull();
        });
        List<EmailDelivery> rows = rowsOf(u, EmailType.WELCOME);
        assertThat(rows).singleElement().satisfies(d -> {
            assertThat(d.getDeduplicationKey()).isEqualTo("WELCOME:" + u.getId());
            assertThat(d.getAttemptCount()).isEqualTo((short) 1);
            assertThat(d.getSentAt()).isNotNull();
        });
    }

    @Test
    @DisplayName("Rollback de l'inscription : aucun WELCOME, aucune ligne")
    void rollbackPasDeBienvenue() {
        String email = email();
        TransactionTemplate tx = new TransactionTemplate(txManager);

        tx.executeWithoutResult(status -> {
            authService.register(inscription(email), "ua", "127.0.0.1", ClientContext.unknown());
            status.setRollbackOnly();
        });
        EmailTestSupport.settle();
        awaitEmailExecutorIdle();

        assertThat(userManager.findByEmail(email)).isEmpty();
        assertThat(mails.sentTo(email)).isEmpty();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM email_deliveries WHERE recipient = ?",
                Long.class, email)).isZero();
    }

    @Test
    @DisplayName("SMTP en panne : l'inscription reussit quand meme, la ligne finit FAILED")
    void smtpEnPanneInscriptionReussit() {
        mails.failNext(100);

        User u = inscrire(email());

        assertThat(u.getId()).isNotNull();
        EmailTestSupport.await("WELCOME en echec", () -> hasStatus(u, EmailType.WELCOME, EmailDeliveryStatus.FAILED));
        EmailDelivery row = rowsOf(u, EmailType.WELCOME).getFirst();
        assertThat(row.getAttemptCount()).isEqualTo((short) 4);
        assertThat(row.getErrorMessage()).contains("SMTP indisponible");
        assertThat(mails.sentTo(u.getEmail())).isEmpty();
    }

    @Test
    @DisplayName("Coupure SMTP courte : la relance immediate fait partir le mail, sur la meme ligne")
    void relanceImmediate() {
        mails.failNext(2);

        User u = inscrire(email());

        EmailTestSupport.await("WELCOME envoye", () -> hasStatus(u, EmailType.WELCOME, EmailDeliveryStatus.SENT));
        assertThat(rowsOf(u, EmailType.WELCOME)).singleElement()
                .satisfies(d -> assertThat(d.getAttemptCount()).isEqualTo((short) 3));
    }
}

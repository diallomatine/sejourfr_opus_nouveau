package com.sejourfr.app.support;

import com.sejourfr.app.config.EmailAsyncConfig;
import com.sejourfr.app.entity.EmailDelivery;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EmailDeliveryStatus;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.manager.EmailDeliveryManager;
import com.sejourfr.app.service.email.EmailMessage;
import com.sejourfr.app.service.email.SpringMailEmailSender;
import org.junit.jupiter.api.AfterEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Base des tests d'integration du systeme d'emails.
 *
 * <p>🛑 <b>Hors transaction de test</b> ({@code NOT_SUPPORTED}) : les mails
 * evenementiels partent en {@code AFTER_COMMIT}, et le journal s'ecrit en
 * {@code REQUIRES_NEW}. Dans la transaction de rollback habituelle, aucun
 * evenement ne partirait jamais — et une ligne {@code REQUIRES_NEW} attendrait
 * un compte non commite. Chaque test COMMITE donc, et nettoie ses comptes.
 */
@Transactional(propagation = Propagation.NOT_SUPPORTED)
public abstract class AbstractEmailIT extends AbstractIntegrationTest {

    @Autowired protected TestData data;
    @Autowired protected JdbcTemplate jdbc;
    @Autowired protected RecordingEmailSender mails;
    @Autowired protected MutableClock clock;
    @Autowired protected EmailDeliveryManager deliveries;
    @Autowired @Qualifier(EmailAsyncConfig.EMAIL_TASK_EXECUTOR)
    protected ThreadPoolTaskExecutor emailExecutor;

    private final List<UUID> createdUsers = new ArrayList<>();
    private final List<String> trackedRecipients = new ArrayList<>();
    private final List<UUID> trackedPlans = new ArrayList<>();

    /** Un compte USER commite, nettoye apres le test. */
    protected User user() {
        return track(data.user());
    }

    protected User user(String email) {
        return track(data.user(email));
    }

    protected User track(User user) {
        createdUsers.add(user.getId());
        return user;
    }

    /**
     * Un plan cree pour le test, supprime apres ses acheteurs : un plan actif
     * laisse en base fausserait le controle du catalogue (PlanCatalogueSeedIT).
     */
    protected com.sejourfr.app.entity.Plan trackPlan(com.sejourfr.app.entity.Plan plan) {
        trackedPlans.add(plan.getId());
        return plan;
    }

    /** Une adresse sans compte (contact, support) dont les lignes seront nettoyees. */
    protected String trackRecipient(String email) {
        trackedRecipients.add(email);
        return email;
    }

    protected List<EmailDelivery> rowsTo(String recipient) {
        return jdbc.query("SELECT id FROM email_deliveries WHERE lower(recipient) = lower(?) ORDER BY created_at",
                (rs, i) -> rs.getObject(1, UUID.class), recipient).stream()
                .map(id -> deliveries.findById(id).orElseThrow()).toList();
    }

    protected List<EmailDelivery> rows(String key) {
        return deliveries.findByKey(key);
    }

    protected List<EmailDelivery> rowsOf(User user) {
        return deliveries.findByUserId(user.getId());
    }

    protected List<EmailDelivery> rowsOf(User user, EmailType type) {
        return rowsOf(user).stream().filter(d -> d.getEmailType() == type).toList();
    }

    protected boolean hasStatus(User user, EmailType type, EmailDeliveryStatus status) {
        return rowsOf(user, type).stream().anyMatch(d -> d.getStatus() == status);
    }

    /** Attend que l'executor email n'ait plus rien en cours ni en file. */
    protected void awaitEmailExecutorIdle() {
        // taskCount compte tout ce qui a ete soumis ; completedTaskCount ce qui est
        // fini. getActiveCount() seul laisse passer la fenetre ou une tache a
        // quitte la file sans etre encore marquee active.
        var pool = emailExecutor.getThreadPoolExecutor();
        EmailTestSupport.await("executor email au repos", () ->
                pool.getTaskCount() == pool.getCompletedTaskCount());
    }

    @Autowired private SpringMailEmailSender springMailRenderer;

    /**
     * 🛑 Chaque mail compose par un test d'integration est aussi RENDU par le vrai
     * provider local : un gabarit qui attend une variable que son composeur ne
     * fournit pas laisserait un {@code {{placeholder}}} chez le candidat.
     */
    private void assertEverySentMailRendersCleanly() {
        for (EmailMessage m : mails.sent()) {
            SpringMailEmailSender.Rendered r = springMailRenderer.render(m);
            assertThat(r.subject() + r.html() + r.text())
                    .as("gabarit %s rendu sans placeholder", m.type())
                    .doesNotContain("{{");
        }
    }

    @AfterEach
    void cleanUpEmails() {
        try {
            awaitEmailExecutorIdle();
            assertEverySentMailRendersCleanly();
        } finally {
            mails.reset();
            clock.reset();
            for (String email : trackedRecipients) {
                jdbc.update("DELETE FROM email_deliveries WHERE lower(recipient) = lower(?)", email);
                jdbc.update("DELETE FROM messages WHERE conversation_id IN "
                        + "(SELECT id FROM conversations WHERE lower(contact_email) = lower(?))", email);
                jdbc.update("DELETE FROM conversations WHERE lower(contact_email) = lower(?)", email);
            }
            trackedRecipients.clear();
            for (UUID id : createdUsers) {
                jdbc.update("DELETE FROM email_deliveries WHERE user_id = ?", id);
                jdbc.update("DELETE FROM answers WHERE user_id = ?", id);
                jdbc.update("DELETE FROM users WHERE id = ?", id);
            }
            createdUsers.clear();
            for (UUID id : trackedPlans) {
                jdbc.update("DELETE FROM user_subscriptions WHERE plan_id = ?", id);
                jdbc.update("DELETE FROM plans WHERE id = ?", id);
            }
            trackedPlans.clear();
        }
    }
}

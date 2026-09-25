package com.sejourfr.app.support;

import com.sejourfr.app.config.EmailAsyncConfig;
import com.sejourfr.app.entity.EmailDelivery;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EmailDeliveryStatus;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.manager.EmailDeliveryManager;
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
        EmailTestSupport.await("executor email au repos", () ->
                emailExecutor.getActiveCount() == 0
                        && emailExecutor.getThreadPoolExecutor().getQueue().isEmpty());
    }

    @AfterEach
    void cleanUpEmails() {
        try {
            awaitEmailExecutorIdle();
        } finally {
            mails.reset();
            clock.reset();
            for (UUID id : createdUsers) {
                jdbc.update("DELETE FROM email_deliveries WHERE user_id = ?", id);
                jdbc.update("DELETE FROM answers WHERE user_id = ?", id);
                jdbc.update("DELETE FROM users WHERE id = ?", id);
            }
            createdUsers.clear();
        }
    }
}

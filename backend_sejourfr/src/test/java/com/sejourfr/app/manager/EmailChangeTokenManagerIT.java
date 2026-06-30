package com.sejourfr.app.manager;

import com.sejourfr.app.entity.EmailChangeToken;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.repository.EmailChangeTokenRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Intégration réelle (Postgres embarqué) du {@link EmailChangeTokenManager} :
 * lookup par hash, unicité du hash, et invalidation en masse des tokens en
 * attente d'un user.
 */
class EmailChangeTokenManagerIT extends AbstractIntegrationTest {

    @Autowired
    private EmailChangeTokenManager manager;

    @Autowired
    private EmailChangeTokenRepository repository;

    @Autowired
    private TestData testData;

    @PersistenceContext
    private EntityManager em;

    @Test
    void findByTokenHashReturnsMatchAndEmptyWhenAbsent() {
        EmailChangeToken token = testData.emailChangeToken();

        Optional<EmailChangeToken> found = manager.findByTokenHash(token.getTokenHash());
        assertThat(found).isPresent();
        assertThat(found.get().getId()).isEqualTo(token.getId());
        assertThat(found.get().getNewEmail()).isEqualTo(token.getNewEmail());
        assertThat(manager.findByTokenHash("absent-hash")).isEmpty();
    }

    @Test
    void saveAssignsIdAndPersists() {
        User user = testData.user();
        EmailChangeToken token = new EmailChangeToken();
        token.setUser(user);
        token.setTokenHash("email-save-" + System.nanoTime());
        token.setNewEmail("cible" + System.nanoTime() + "@test.sejourfr");
        token.setExpiresAt(Instant.now().plus(1, ChronoUnit.HOURS));

        EmailChangeToken saved = manager.save(token);

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(manager.findByTokenHash(token.getTokenHash())).isPresent();
    }

    @Test
    void invalidateAllForUserMarksOnlyActiveTokensUsed() {
        User user = testData.user();
        EmailChangeToken active1 = testData.emailChangeToken(user);
        EmailChangeToken active2 = testData.emailChangeToken(user);
        EmailChangeToken alreadyUsed = testData.emailChangeToken(user);
        Instant usedAt = Instant.now().minusSeconds(120).truncatedTo(ChronoUnit.MILLIS);
        alreadyUsed.setUsedAt(usedAt);
        manager.save(alreadyUsed);
        EmailChangeToken otherUser = testData.emailChangeToken();

        Instant now = Instant.now();
        em.flush();
        manager.invalidateAllForUser(user.getId(), now);
        em.clear();

        assertThat(manager.findByTokenHash(active1.getTokenHash())).get()
                .extracting(EmailChangeToken::getUsedAt).isNotNull();
        assertThat(manager.findByTokenHash(active2.getTokenHash())).get()
                .extracting(EmailChangeToken::getUsedAt).isNotNull();
        assertThat(manager.findByTokenHash(alreadyUsed.getTokenHash())).get()
                .extracting(EmailChangeToken::getUsedAt).isEqualTo(usedAt);
        assertThat(manager.findByTokenHash(otherUser.getTokenHash())).get()
                .extracting(EmailChangeToken::getUsedAt).isNull();
    }

    @Test
    void duplicateTokenHashViolatesUniqueConstraint() {
        EmailChangeToken first = testData.emailChangeToken();

        EmailChangeToken dup = new EmailChangeToken();
        dup.setUser(first.getUser());
        dup.setTokenHash(first.getTokenHash());
        dup.setNewEmail("autre" + System.nanoTime() + "@test.sejourfr");
        dup.setExpiresAt(Instant.now().plus(1, ChronoUnit.HOURS));

        assertThatThrownBy(() -> repository.saveAndFlush(dup))
                .isInstanceOf(DataIntegrityViolationException.class);
    }
}

package com.sejourfr.app.manager;

import com.sejourfr.app.entity.PasswordResetToken;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.repository.PasswordResetTokenRepository;
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
 * Intégration réelle (Postgres embarqué) du {@link PasswordResetTokenManager} :
 * lookup par hash, unicité du hash, et invalidation en masse (bulk update sur
 * les tokens encore actifs d'un user).
 */
class PasswordResetTokenManagerIT extends AbstractIntegrationTest {

    @Autowired
    private PasswordResetTokenManager manager;

    @Autowired
    private PasswordResetTokenRepository repository;

    @Autowired
    private TestData testData;

    @PersistenceContext
    private EntityManager em;

    @Test
    void findByTokenHashReturnsMatchAndEmptyWhenAbsent() {
        PasswordResetToken token = testData.passwordResetToken();

        Optional<PasswordResetToken> found = manager.findByTokenHash(token.getTokenHash());
        assertThat(found).isPresent();
        assertThat(found.get().getId()).isEqualTo(token.getId());
        assertThat(manager.findByTokenHash("absent-hash")).isEmpty();
    }

    @Test
    void saveAssignsIdAndPersists() {
        User user = testData.user();
        PasswordResetToken token = new PasswordResetToken();
        token.setUser(user);
        token.setTokenHash("reset-save-" + System.nanoTime());
        token.setExpiresAt(Instant.now().plus(1, ChronoUnit.HOURS));

        PasswordResetToken saved = manager.save(token);

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(manager.findByTokenHash(token.getTokenHash())).isPresent();
    }

    @Test
    void invalidateAllForUserMarksOnlyActiveTokensUsed() {
        User user = testData.user();
        PasswordResetToken active1 = testData.passwordResetToken(user);
        PasswordResetToken active2 = testData.passwordResetToken(user);
        PasswordResetToken alreadyUsed = testData.passwordResetToken(user);
        Instant usedAt = Instant.now().minusSeconds(120).truncatedTo(ChronoUnit.MILLIS);
        alreadyUsed.setUsedAt(usedAt);
        manager.save(alreadyUsed);
        PasswordResetToken otherUser = testData.passwordResetToken();

        Instant now = Instant.now();
        em.flush();
        manager.invalidateAllForUser(user.getId(), now);
        em.clear();

        assertThat(manager.findByTokenHash(active1.getTokenHash())).get()
                .extracting(PasswordResetToken::getUsedAt).isNotNull();
        assertThat(manager.findByTokenHash(active2.getTokenHash())).get()
                .extracting(PasswordResetToken::getUsedAt).isNotNull();
        // Le token déjà consommé garde son horodatage initial (exclu du WHERE).
        assertThat(manager.findByTokenHash(alreadyUsed.getTokenHash())).get()
                .extracting(PasswordResetToken::getUsedAt).isEqualTo(usedAt);
        // Token d'un autre user → intact.
        assertThat(manager.findByTokenHash(otherUser.getTokenHash())).get()
                .extracting(PasswordResetToken::getUsedAt).isNull();
    }

    @Test
    void duplicateTokenHashViolatesUniqueConstraint() {
        PasswordResetToken first = testData.passwordResetToken();

        PasswordResetToken dup = new PasswordResetToken();
        dup.setUser(first.getUser());
        dup.setTokenHash(first.getTokenHash());
        dup.setExpiresAt(Instant.now().plus(1, ChronoUnit.HOURS));

        assertThatThrownBy(() -> repository.saveAndFlush(dup))
                .isInstanceOf(DataIntegrityViolationException.class);
    }
}

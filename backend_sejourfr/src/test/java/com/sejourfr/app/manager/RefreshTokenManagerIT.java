package com.sejourfr.app.manager;

import com.sejourfr.app.entity.RefreshToken;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Intégration réelle (Postgres embarqué) du {@link RefreshTokenManager} :
 * lookup par {@code jti} et révocation en masse (bulk update filtré sur les
 * sessions encore actives).
 */
class RefreshTokenManagerIT extends AbstractIntegrationTest {

    @Autowired
    private RefreshTokenManager manager;

    @Autowired
    private TestData testData;

    @PersistenceContext
    private EntityManager em;

    @Test
    void findByJtiReturnsMatchAndEmptyWhenAbsent() {
        RefreshToken token = testData.refreshToken();

        Optional<RefreshToken> found = manager.findByJti(token.getJti());
        assertThat(found).isPresent();
        assertThat(found.get().getJti()).isEqualTo(token.getJti());
        assertThat(manager.findByJti(UUID.randomUUID())).isEmpty();
    }

    @Test
    void saveAssignsTimestampAndPersists() {
        User user = testData.user();
        RefreshToken token = new RefreshToken();
        token.setJti(UUID.randomUUID());
        token.setUser(user);
        token.setExpiresAt(Instant.now().plusSeconds(3600));

        RefreshToken saved = manager.save(token);

        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(manager.findByJti(token.getJti())).isPresent();
    }

    @Test
    void revokeAllForUserRevokesOnlyActiveTokensOfThatUser() {
        User user = testData.user();
        RefreshToken active1 = testData.refreshToken(user);
        RefreshToken active2 = testData.refreshToken(user);
        RefreshToken alreadyRevoked = testData.refreshToken(user);
        Instant past = Instant.now().minusSeconds(60).truncatedTo(ChronoUnit.MILLIS);
        alreadyRevoked.setRevokedAt(past);
        manager.save(alreadyRevoked);
        RefreshToken otherUser = testData.refreshToken();

        em.flush();
        int revoked = manager.revokeAllForUser(user.getId());
        em.clear();

        // Seules les 2 sessions encore actives sont touchées (la révoquée est exclue par le WHERE).
        assertThat(revoked).isEqualTo(2);
        assertThat(manager.findByJti(active1.getJti())).get()
                .extracting(RefreshToken::getRevokedAt).isNotNull();
        assertThat(manager.findByJti(active2.getJti())).get()
                .extracting(RefreshToken::getRevokedAt).isNotNull();
        // La déjà-révoquée garde son horodatage d'origine.
        assertThat(manager.findByJti(alreadyRevoked.getJti())).get()
                .extracting(RefreshToken::getRevokedAt).isEqualTo(past);
        // L'autre user n'est pas affecté.
        assertThat(manager.findByJti(otherUser.getJti())).get()
                .extracting(RefreshToken::getRevokedAt).isNull();
    }
}

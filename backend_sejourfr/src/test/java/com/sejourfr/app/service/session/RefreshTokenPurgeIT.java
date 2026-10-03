package com.sejourfr.app.service.session;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.RefreshTokenManager;
import com.sejourfr.app.security.JwtProperties;
import com.sejourfr.app.security.JwtService;
import com.sejourfr.app.service.SessionService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Purge de {@code refresh_tokens} (lot 1, V086) : 7 j apres l'echeance,
 * revoquees ou non ; une revoquee non expiree reste (detection de
 * reutilisation) ; une chaine {@code replaced_by} coupee entre deux lots passe.
 */
class RefreshTokenPurgeIT extends AbstractIntegrationTest {

    private static final Instant MAINTENANT = Instant.parse("2026-10-03T02:25:00Z");

    @Autowired private RefreshTokenPurgeService purge;
    @Autowired private RefreshTokenManager manager;
    @Autowired private JwtProperties properties;
    @Autowired private JwtService jwtService;
    @Autowired private SessionService sessionService;
    @Autowired private TestData data;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private EntityManager em;

    private int batchInitial;

    @AfterEach
    void restaurer() {
        if (batchInitial > 0) properties.setRefreshTokenPurgeBatchSize(batchInitial);
    }

    private UUID jeton(User user, Instant expiresAt, Instant revokedAt, UUID replacedBy) {
        em.flush();
        UUID jti = UUID.randomUUID();
        jdbc.update("INSERT INTO refresh_tokens (jti, user_id, expires_at, revoked_at, replaced_by, created_at) "
                        + "VALUES (?, ?, ?, ?, ?, ?)", jti, user.getId(), Timestamp.from(expiresAt),
                revokedAt == null ? null : Timestamp.from(revokedAt), replacedBy,
                Timestamp.from(expiresAt.minus(Duration.ofDays(30))));
        return jti;
    }

    private boolean existe(UUID jti) {
        return jdbc.queryForObject("SELECT count(*) FROM refresh_tokens WHERE jti = ?", Long.class, jti) == 1;
    }

    @Test
    @DisplayName("Expirée depuis plus de 7 j : purgée, révoquée ou non ; récente, vivante ou révoquée non expirée : gardée")
    void purgeApresLaMarge() {
        User user = data.user();
        UUID vieilleRevoquee = jeton(user, MAINTENANT.minus(Duration.ofDays(8)), MAINTENANT.minus(Duration.ofDays(20)),
                null);
        UUID vieilleNonRevoquee = jeton(user, MAINTENANT.minus(Duration.ofDays(8)), null, null);
        UUID dansLaMarge = jeton(user, MAINTENANT.minus(Duration.ofDays(6)), null, null);
        UUID revoqueeNonExpiree = jeton(user, MAINTENANT.plus(Duration.ofDays(10)), MAINTENANT.minus(Duration.ofDays(1)),
                null);
        UUID vivante = jeton(user, MAINTENANT.plus(Duration.ofDays(29)), null, null);

        int supprimees = purge.purge(MAINTENANT);

        assertThat(supprimees).isEqualTo(2);
        assertThat(existe(vieilleRevoquee)).isFalse();
        assertThat(existe(vieilleNonRevoquee)).isFalse();
        assertThat(existe(dansLaMarge)).isTrue();
        assertThat(existe(revoqueeNonExpiree)).isTrue();
        assertThat(existe(vivante)).isTrue();
    }

    @Test
    @DisplayName("Chaîne replaced_by coupée en deux lots : la FK passe à NULL (V086), rien n'échoue")
    void chaineCoupeeEntreDeuxLots() {
        User user = data.user();
        // A -> B -> C (C vivant). B expire avant A : le premier lot (taille 1)
        // emporte B, que A reference encore.
        UUID c = jeton(user, MAINTENANT.plus(Duration.ofDays(20)), null, null);
        UUID b = jeton(user, MAINTENANT.minus(Duration.ofDays(30)), MAINTENANT.minus(Duration.ofDays(40)), c);
        UUID a = jeton(user, MAINTENANT.minus(Duration.ofDays(9)), MAINTENANT.minus(Duration.ofDays(39)), b);

        assertThat(manager.deleteExpiredBefore(MAINTENANT.minus(Duration.ofDays(7)), 1)).isEqualTo(1);
        assertThat(existe(b)).isFalse();
        assertThat(jdbc.queryForObject("SELECT replaced_by FROM refresh_tokens WHERE jti = ?", UUID.class, a))
                .isNull();

        assertThat(manager.deleteExpiredBefore(MAINTENANT.minus(Duration.ofDays(7)), 1)).isEqualTo(1);
        assertThat(existe(a)).isFalse();
        assertThat(existe(c)).isTrue();
    }

    @Test
    @DisplayName("La passe boucle tant qu'un lot est plein")
    void boucleParLots() {
        batchInitial = properties.getRefreshTokenPurgeBatchSize();
        properties.setRefreshTokenPurgeBatchSize(2);
        User user = data.user();
        for (int i = 0; i < 5; i++) jeton(user, MAINTENANT.minus(Duration.ofDays(10 + i)), null, null);

        assertThat(purge.purge(MAINTENANT)).isEqualTo(5);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM refresh_tokens WHERE user_id = ?", Long.class,
                user.getId())).isZero();
    }

    @Test
    @DisplayName("Un jeton dont la ligne a été purgée est refusé au refresh")
    void jetonPurgeRefuse() {
        User user = data.user();
        UUID jti = jeton(user, MAINTENANT.minus(Duration.ofDays(10)), null, null);
        String refresh = jwtService.generateRefreshToken(user, jti);
        purge.purge(MAINTENANT);

        assertThatThrownBy(() -> sessionService.rotate(refresh, "ua", "ip"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("inconnue");
    }

    @Test
    @DisplayName("V086 : la FK replaced_by est en ON DELETE SET NULL, et expires_at est indexée")
    void schema() {
        assertThat(jdbc.queryForObject("""
                SELECT confdeltype FROM pg_constraint WHERE conname = 'refresh_tokens_replaced_by_fkey'""",
                String.class)).isEqualTo("n");
        assertThat(jdbc.queryForObject(
                "SELECT count(*) FROM pg_indexes WHERE indexname = 'idx_refresh_tokens_expires_at'", Long.class))
                .isEqualTo(1);
    }
}

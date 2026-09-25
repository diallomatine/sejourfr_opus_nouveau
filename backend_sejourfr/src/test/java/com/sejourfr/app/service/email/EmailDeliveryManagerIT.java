package com.sejourfr.app.service.email;

import com.sejourfr.app.entity.EmailDelivery;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EmailDeliveryStatus;
import com.sejourfr.app.enums.EmailProvider;
import com.sejourfr.app.enums.EmailSkipReason;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.manager.EmailDeliveryManager.NewDelivery;
import com.sejourfr.app.support.AbstractEmailIT;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import static org.assertj.core.api.Assertions.assertThat;

/** L'anti-doublon, le plafond et les purges, contre la vraie base (index partiel de V073). */
class EmailDeliveryManagerIT extends AbstractEmailIT {

    private NewDelivery delivery(User user, EmailType type, String key, Instant createdAt) {
        return new NewDelivery(user.getId(), type, user.getEmail(), EmailProvider.SPRING_MAIL,
                key, null, null, createdAt);
    }

    private static String key() {
        return "TEST:" + UUID.randomUUID();
    }

    @Test
    @DisplayName("Meme cle : une seule ligne PENDING, le second INSERT rend vide sans erreur")
    void memeCleUneSeuleLigne() {
        User u = user();
        String k = key();

        Optional<UUID> premier = deliveries.insertPending(delivery(u, EmailType.WELCOME, k, Instant.now()));
        Optional<UUID> second = deliveries.insertPending(delivery(u, EmailType.WELCOME, k, Instant.now()));

        assertThat(premier).isPresent();
        assertThat(second).isEmpty();
        assertThat(rows(k)).hasSize(1);
    }

    @Test
    @DisplayName("Deux appels concurrents sur la meme cle : une seule ligne")
    void deuxAppelsConcurrents() throws Exception {
        User u = user();
        String k = key();
        CountDownLatch go = new CountDownLatch(1);
        ExecutorService pool = Executors.newFixedThreadPool(2);
        try {
            Future<Optional<UUID>> a = pool.submit(() -> {
                go.await();
                return deliveries.insertPending(delivery(u, EmailType.WELCOME, k, Instant.now()));
            });
            Future<Optional<UUID>> b = pool.submit(() -> {
                go.await();
                return deliveries.insertPending(delivery(u, EmailType.WELCOME, k, Instant.now()));
            });
            go.countDown();

            assertThat(List.of(a.get(), b.get())).filteredOn(Optional::isPresent).hasSize(1);
            assertThat(rows(k)).hasSize(1);
        } finally {
            pool.shutdownNow();
        }
    }

    @Test
    @DisplayName("Une ligne FAILED ne bloque pas une nouvelle tentative ; SENT la bloque")
    void failedLibereLaCle() {
        User u = user();
        String k = key();
        UUID id = deliveries.insertPending(delivery(u, EmailType.WELCOME, k, Instant.now())).orElseThrow();
        deliveries.markFailed(id, Instant.now(), "SMTP down", 4);

        UUID retry = deliveries.insertPending(delivery(u, EmailType.WELCOME, k, Instant.now())).orElseThrow();
        deliveries.markSent(retry, Instant.now(), null, 1);

        assertThat(deliveries.insertPending(delivery(u, EmailType.WELCOME, k, Instant.now()))).isEmpty();
        assertThat(rows(k)).extracting(EmailDelivery::getStatus)
                .containsExactlyInAnyOrder(EmailDeliveryStatus.FAILED, EmailDeliveryStatus.SENT);
        assertThat(deliveries.countFailedByKey(k)).isEqualTo(1);
    }

    @Test
    @DisplayName("SKIPPED occupe la cle : c'est ce qui permet de la CONSOMMER sans envoyer (complement C)")
    void skippedOccupeLaCle() {
        User u = user();
        String k = key();

        assertThat(deliveries.insertSkipped(delivery(u, EmailType.DIAGNOSTIC_PLAN_READY, k, Instant.now()),
                EmailSkipReason.KEY_CONSUMED)).isPresent();

        assertThat(deliveries.insertPending(delivery(u, EmailType.DIAGNOSTIC_PLAN_READY, k, Instant.now()))).isEmpty();
        EmailDelivery row = rows(k).getFirst();
        assertThat(row.getStatus()).isEqualTo(EmailDeliveryStatus.SKIPPED);
        assertThat(row.getSkipReason()).isEqualTo(EmailSkipReason.KEY_CONSUMED);
    }

    @Test
    @DisplayName("Le plafond compte les ENGAGEMENT PENDING et SENT du jour, pas les FAILED ni les SKIPPED")
    void plafondCompteCeQuiEstParti() {
        User u = user();
        Instant now = Instant.now();
        UUID sent = deliveries.insertPending(delivery(u, EmailType.NO_TRAINING_7_DAYS, key(), now)).orElseThrow();
        deliveries.markSent(sent, now, null, 1);
        deliveries.insertPending(delivery(u, EmailType.DIAGNOSTIC_PLAN_READY, key(), now));
        UUID failed = deliveries.insertPending(delivery(u, EmailType.PREMIUM_ENDED, key(), now)).orElseThrow();
        deliveries.markFailed(failed, now, "x", 1);
        deliveries.insertSkipped(delivery(u, EmailType.NO_PREMIUM_AFTER_7_DAYS, key(), now), EmailSkipReason.PREFERENCE);
        deliveries.insertPending(delivery(u, EmailType.WELCOME, key(), now));
        deliveries.insertPending(delivery(u, EmailType.NO_TRAINING_7_DAYS, key(), now.minus(2, ChronoUnit.DAYS)));

        assertThat(deliveries.countEngagementSince(u.getId(), now.minus(1, ChronoUnit.HOURS))).isEqualTo(2);
    }

    @Test
    @DisplayName("Un PENDING de plus d'une heure passe FAILED « stale » ; un PENDING recent ne bouge pas")
    void pendingBloque() {
        User u = user();
        Instant now = Instant.now();
        String vieux = key();
        String recent = key();
        deliveries.insertPending(delivery(u, EmailType.WELCOME, vieux, now.minus(2, ChronoUnit.HOURS)));
        deliveries.insertPending(delivery(u, EmailType.WELCOME, recent, now.minus(10, ChronoUnit.MINUTES)));

        deliveries.markStalePending(now.minus(1, ChronoUnit.HOURS), now);

        assertThat(rows(vieux).getFirst().getStatus()).isEqualTo(EmailDeliveryStatus.FAILED);
        assertThat(rows(vieux).getFirst().getErrorMessage()).isEqualTo("stale");
        assertThat(rows(recent).getFirst().getStatus()).isEqualTo(EmailDeliveryStatus.PENDING);
    }

    @Test
    @DisplayName("Suppression du compte : ses lignes ET celles envoyees a son adresse sans compte")
    void suppressionDuCompte() {
        User u = user();
        User autre = user();
        deliveries.insertPending(delivery(u, EmailType.WELCOME, key(), Instant.now()));
        deliveries.insertPending(new NewDelivery(null, EmailType.CONTACT_RECEIVED, u.getEmail().toUpperCase(),
                EmailProvider.SPRING_MAIL, key(), null, null, Instant.now()));
        String keyAutre = key();
        deliveries.insertPending(delivery(autre, EmailType.WELCOME, keyAutre, Instant.now()));

        int deleted = deliveries.deleteForAccount(u.getId(), u.getEmail());

        assertThat(deleted).isEqualTo(2);
        assertThat(rows(keyAutre)).hasSize(1);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM email_deliveries WHERE lower(recipient) = lower(?)",
                Long.class, u.getEmail())).isZero();
    }

    @Test
    @DisplayName("Retention : seules les lignes plus vieilles que la borne partent, par lots bornes")
    void purgeDeRetention() {
        User u = user();
        Instant now = Instant.now();
        String vieille = key();
        String recente = key();
        deliveries.insertPending(delivery(u, EmailType.WELCOME, vieille, now.minus(400, ChronoUnit.DAYS)));
        deliveries.insertPending(delivery(u, EmailType.WELCOME, recente, now.minus(300, ChronoUnit.DAYS)));

        int purged = deliveries.deleteOlderThan(now.minus(365, ChronoUnit.DAYS), 1000);

        assertThat(purged).isGreaterThanOrEqualTo(1);
        assertThat(rows(vieille)).isEmpty();
        assertThat(rows(recente)).hasSize(1);
    }
}

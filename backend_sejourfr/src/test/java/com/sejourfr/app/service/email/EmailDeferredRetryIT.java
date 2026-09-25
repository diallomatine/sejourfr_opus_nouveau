package com.sejourfr.app.service.email;

import com.sejourfr.app.entity.EmailDelivery;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EmailDeliveryStatus;
import com.sejourfr.app.enums.EmailProvider;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.manager.EmailDeliveryManager.NewDelivery;
import com.sejourfr.app.service.email.automation.EmailDeferredRetryService;
import com.sejourfr.app.service.email.automation.EmailRetentionService;
import com.sejourfr.app.support.AbstractEmailIT;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * La relance DIFFEREE (brief §5 et §10) et la retention (arbitrage n°16).
 * Instant de reference calcule sur l'horloge d'execution, decale d'un an : les
 * lignes des autres tests sont hors de la fenetre de 24 h.
 */
class EmailDeferredRetryIT extends AbstractEmailIT {

    private static final Instant T = java.time.LocalDate.now(java.time.ZoneOffset.UTC).plusDays(365)
            .atTime(8, 0).toInstant(java.time.ZoneOffset.UTC);

    @Autowired private EmailDeferredRetryService retryService;
    @Autowired private EmailRetentionService retentionService;

    private String echec(User u, EmailType type, String key, UUID ref, Instant occurred, Instant at) {
        UUID id = deliveries.insertPending(new NewDelivery(u.getId(), type, u.getEmail(), EmailProvider.SPRING_MAIL,
                key, ref, occurred, at)).orElseThrow();
        deliveries.markFailed(id, at, "SMTP down", 4);
        return key;
    }

    private void relance(Instant at) {
        clock.set(at);
        retryService.retry(at);
        awaitEmailExecutorIdle();
    }

    @Test
    @DisplayName("PASSWORD_CHANGED en echec : relance dans les 24 h, variables reconstruites")
    void passwordChangedRelanceDansLes24h() {
        User u = user();
        UUID event = UUID.randomUUID();
        Instant changedAt = T.minus(Duration.ofHours(3));
        String key = echec(u, EmailType.PASSWORD_CHANGED, "PASSWORD_CHANGED:" + event, event, changedAt, changedAt);

        relance(T);
        // L'envoi est asynchrone : l'executor peut sembler au repos avant que la
        // ligne relancee ait quitte PENDING (test intermittent). On attend l'etat
        // final, borne par le delai d'EmailTestSupport.await.
        com.sejourfr.app.support.EmailTestSupport.await("relance hors PENDING", () ->
                rows(key).stream().noneMatch(d -> d.getStatus() == EmailDeliveryStatus.PENDING));

        assertThat(rows(key)).extracting(EmailDelivery::getStatus)
                .containsExactlyInAnyOrder(EmailDeliveryStatus.FAILED, EmailDeliveryStatus.SENT);
        EmailMessage m = mails.sentTo(u.getEmail()).getFirst();
        assertThat(m.type()).isEqualTo(EmailType.PASSWORD_CHANGED);
        assertThat(m.variables().get("changedAt")).isEqualTo(EmailFormats.dateTime(changedAt));
    }

    @Test
    @DisplayName("PASSWORD_CHANGED en echec depuis plus de 24 h : jamais relance")
    void passwordChangedAuDelaDe24h() {
        User u = user();
        UUID event = UUID.randomUUID();
        Instant at = T.minus(Duration.ofHours(30));
        String key = echec(u, EmailType.PASSWORD_CHANGED, "PASSWORD_CHANGED:" + event, event, at, at);

        relance(T);

        assertThat(rows(key)).singleElement().extracting(EmailDelivery::getStatus).isEqualTo(EmailDeliveryStatus.FAILED);
    }

    @Test
    @DisplayName("🛑 PASSWORD_RESET en echec : jamais relance (jeton stocke seulement hache)")
    void passwordResetJamaisRelance() {
        User u = user();
        UUID req = UUID.randomUUID();
        String key = echec(u, EmailType.PASSWORD_RESET, "PASSWORD_RESET:" + req, req, null, T.minus(Duration.ofHours(1)));

        relance(T);

        assertThat(rows(key)).hasSize(1);
        assertThat(mails.sentTo(u.getEmail())).isEmpty();
    }

    @Test
    @DisplayName("FAILED puis nouvelle tentative autorisee, 3 au maximum")
    void troisRelancesAuMaximum() {
        User u = user();
        String key = "WELCOME:" + u.getId();
        echec(u, EmailType.WELCOME, key, u.getId(), null, T.minus(Duration.ofHours(4)));
        mails.failNext(1000);

        relance(T.minus(Duration.ofHours(3)));
        relance(T.minus(Duration.ofHours(2)));
        relance(T.minus(Duration.ofHours(1)));
        relance(T);
        mails.failNext(0);
        relance(T.plus(Duration.ofHours(1)));

        assertThat(rows(key)).hasSize(4)
                .allSatisfy(d -> assertThat(d.getStatus()).isEqualTo(EmailDeliveryStatus.FAILED));
        assertThat(mails.sentTo(u.getEmail())).isEmpty();
    }

    @Test
    @DisplayName("WELCOME en echec : la relance differee le fait partir")
    void welcomeRelance() {
        User u = user();
        String key = "WELCOME:" + u.getId();
        echec(u, EmailType.WELCOME, key, u.getId(), null, T.minus(Duration.ofHours(2)));

        relance(T);

        assertThat(rows(key)).anyMatch(d -> d.getStatus() == EmailDeliveryStatus.SENT);
        assertThat(mails.sentTo(u.getEmail())).singleElement()
                .satisfies(m -> assertThat(m.type()).isEqualTo(EmailType.WELCOME));
    }

    @Test
    @DisplayName("Retention : plus de 12 mois purges, 11 mois conserves")
    void retention() {
        User u = user();
        String vieux = "TEST_RET_OLD:" + UUID.randomUUID();
        String recent = "TEST_RET_NEW:" + UUID.randomUUID();
        deliveries.insertPending(new NewDelivery(u.getId(), EmailType.WELCOME, u.getEmail(), EmailProvider.SPRING_MAIL,
                vieux, null, null, T.minus(Duration.ofDays(400))));
        deliveries.insertPending(new NewDelivery(u.getId(), EmailType.WELCOME, u.getEmail(), EmailProvider.SPRING_MAIL,
                recent, null, null, T.minus(Duration.ofDays(330))));

        retentionService.purge(T);

        assertThat(rows(vieux)).isEmpty();
        assertThat(rows(recent)).hasSize(1);
    }
}

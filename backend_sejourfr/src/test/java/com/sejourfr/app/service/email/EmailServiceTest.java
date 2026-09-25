package com.sejourfr.app.service.email;

import com.sejourfr.app.entity.UserEmailPreference;
import com.sejourfr.app.enums.EmailProvider;
import com.sejourfr.app.enums.EmailSkipReason;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.manager.EmailDeliveryManager;
import com.sejourfr.app.manager.UserEmailPreferenceManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.core.task.SyncTaskExecutor;
import org.springframework.core.task.TaskExecutor;
import org.springframework.core.task.TaskRejectedException;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Les regles d'envoi du brief §5, dans l'ordre, avec un {@link EmailSender} mocke.
 */
class EmailServiceTest {

    /** 2026-09-25 08:00 UTC = 10:00 a Paris. */
    private static final Instant NOW = Instant.parse("2026-09-25T08:00:00Z");
    private static final Instant MINUIT_PARIS = Instant.parse("2026-09-24T22:00:00Z");

    private EmailDeliveryManager deliveries;
    private UserEmailPreferenceManager preferences;
    private EmailSender sender;
    private EmailAllowlist allowlist;
    private final List<Duration> sleeps = new ArrayList<>();
    private TaskExecutor executor;
    private EmailService service;
    private final UUID userId = UUID.randomUUID();
    private final UUID deliveryId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        deliveries = mock(EmailDeliveryManager.class);
        preferences = mock(UserEmailPreferenceManager.class);
        sender = mock(EmailSender.class);
        when(sender.provider()).thenReturn(EmailProvider.SPRING_MAIL);
        allowlist = mock(EmailAllowlist.class);
        when(allowlist.allows(anyString())).thenReturn(true);
        when(preferences.find(any())).thenReturn(Optional.empty());
        when(deliveries.insertPending(any())).thenReturn(Optional.of(deliveryId));
        executor = new SyncTaskExecutor();
        build(EmailTestFixtures.config(1, List.of(30, 120, 300), 3));
    }

    private void build(EmailAutomationConfig config) {
        service = new EmailService(deliveries, preferences, sender, config, allowlist,
                new UnsubscribeTokenService(EmailTestFixtures.properties()),
                new EmailLinks("https://sejourfr.fr", "https://api.sejourfr.fr"),
                sleeps::add, Clock.fixed(NOW, ZoneOffset.UTC), executor);
    }

    private EmailRequest request(EmailType type, EmailRequest.Origin origin) {
        return new EmailRequest(type, userId, "alice@example.com", Map.of("firstName", "Alice"),
                EmailKeys.of(type, userId), userId, null, origin);
    }

    private void engagementDisabled() {
        UserEmailPreference p = new UserEmailPreference();
        p.setUserId(userId);
        p.setEngagementEnabled(false);
        when(preferences.find(userId)).thenReturn(Optional.of(p));
    }

    // ------------------------------------------------------------ categories

    @Test
    @DisplayName("REQUIRED part meme quand l'engagement est desactive")
    void requiredIgnoreLesPreferences() {
        engagementDisabled();

        EmailOutcome outcome = service.send(request(EmailType.WELCOME, EmailRequest.Origin.EVENT));

        assertThat(outcome).isEqualTo(EmailOutcome.SENT);
        verify(sender).send(any());
        verify(deliveries).markSent(eq(deliveryId), eq(NOW), isNull(), eq(1));
    }

    @Test
    @DisplayName("ENGAGEMENT active : envoye, avec lien de desabonnement et one-click")
    void engagementActiveEstEnvoyeAvecDesabonnement() {
        EmailOutcome outcome = service.send(request(EmailType.DIAGNOSTIC_PLAN_READY, EmailRequest.Origin.EVENT));

        assertThat(outcome).isEqualTo(EmailOutcome.SENT);
        ArgumentCaptor<EmailMessage> msg = ArgumentCaptor.forClass(EmailMessage.class);
        verify(sender).send(msg.capture());
        assertThat(msg.getValue().unsubscribeUrl())
                .startsWith("https://api.sejourfr.fr/api/public/email/unsubscribe?token=");
        assertThat(msg.getValue().oneClickUnsubscribeUrl())
                .startsWith("https://api.sejourfr.fr/api/public/email/unsubscribe/one-click?token=");
    }

    @Test
    @DisplayName("Un mail REQUIRED ne porte AUCUN lien de desabonnement")
    void requiredSansDesabonnement() {
        service.send(request(EmailType.WELCOME, EmailRequest.Origin.EVENT));

        ArgumentCaptor<EmailMessage> msg = ArgumentCaptor.forClass(EmailMessage.class);
        verify(sender).send(msg.capture());
        assertThat(msg.getValue().unsubscribeUrl()).isNull();
        assertThat(msg.getValue().oneClickUnsubscribeUrl()).isNull();
    }

    @Test
    @DisplayName("ENGAGEMENT desactive, mail evenementiel : SKIPPED trace, rien n'est envoye")
    void engagementDesactiveEvenementEstTrace() {
        engagementDisabled();

        EmailOutcome outcome = service.send(request(EmailType.DIAGNOSTIC_PLAN_READY, EmailRequest.Origin.EVENT));

        assertThat(outcome).isEqualTo(EmailOutcome.SKIPPED_PREFERENCE);
        verify(deliveries).insertSkipped(any(), eq(EmailSkipReason.PREFERENCE));
        verify(deliveries, never()).insertPending(any());
        verify(sender, never()).send(any());
    }

    @Test
    @DisplayName("ENGAGEMENT desactive, scheduler : rien n'est ecrit (brief §4)")
    void engagementDesactiveSchedulerNeTraceRien() {
        engagementDisabled();

        EmailOutcome outcome = service.sendAsync(request(EmailType.NO_TRAINING_7_DAYS, EmailRequest.Origin.SCHEDULER));

        assertThat(outcome).isEqualTo(EmailOutcome.SKIPPED_PREFERENCE);
        verify(deliveries, never()).insertSkipped(any(), any());
        verify(deliveries, never()).insertPending(any());
    }

    // ------------------------------------------------------------- plafond

    @Test
    @DisplayName("Plafond atteint : le rappel automatique n'est pas envoye ni trace")
    void plafondAtteint() {
        when(deliveries.countEngagementSince(userId, MINUIT_PARIS)).thenReturn(1L);

        EmailOutcome outcome = service.sendAsync(request(EmailType.NO_TRAINING_7_DAYS, EmailRequest.Origin.SCHEDULER));

        assertThat(outcome).isEqualTo(EmailOutcome.CAPPED);
        verify(deliveries, never()).insertPending(any());
    }

    @Test
    @DisplayName("Le plafond se compte depuis MINUIT A PARIS, pas sur 24 h glissantes")
    void plafondDepuisMinuitParis() {
        service.sendAsync(request(EmailType.NO_TRAINING_7_DAYS, EmailRequest.Origin.SCHEDULER));

        verify(deliveries).countEngagementSince(userId, MINUIT_PARIS);
    }

    @Test
    @DisplayName("DIAGNOSTIC_PLAN_READY n'est jamais bloque par le plafond (arbitrage n°18)")
    void planReadyIgnoreLePlafond() {
        when(deliveries.countEngagementSince(any(), any())).thenReturn(5L);

        EmailOutcome outcome = service.send(request(EmailType.DIAGNOSTIC_PLAN_READY, EmailRequest.Origin.EVENT));

        assertThat(outcome).isEqualTo(EmailOutcome.SENT);
    }

    // -------------------------------------------------- anti-doublon, tentatives

    @Test
    @DisplayName("Cle deja occupee : DUPLICATE, aucun envoi")
    void cleOccupee() {
        when(deliveries.insertPending(any())).thenReturn(Optional.empty());

        EmailOutcome outcome = service.send(request(EmailType.WELCOME, EmailRequest.Origin.EVENT));

        assertThat(outcome).isEqualTo(EmailOutcome.DUPLICATE);
        verify(sender, never()).send(any());
    }

    @Test
    @DisplayName("Une cle qui a deja echoue 1 + 3 fois n'est plus tentee")
    void tentativesEpuisees() {
        when(deliveries.countFailedByKey(anyString())).thenReturn(4L);

        EmailOutcome outcome = service.send(request(EmailType.WELCOME, EmailRequest.Origin.DEFERRED_RETRY));

        assertThat(outcome).isEqualTo(EmailOutcome.EXHAUSTED);
        verify(deliveries, never()).insertPending(any());
    }

    @Test
    @DisplayName("Une cle qui a echoue 3 fois peut encore etre tentee")
    void encoreUneTentative() {
        when(deliveries.countFailedByKey(anyString())).thenReturn(3L);

        assertThat(service.send(request(EmailType.WELCOME, EmailRequest.Origin.DEFERRED_RETRY)))
                .isEqualTo(EmailOutcome.SENT);
    }

    // ------------------------------------------------------------- allowlist

    @Test
    @DisplayName("Hors liste blanche de dev : SKIPPED / ALLOWLIST, rien ne part (complement G)")
    void horsListeBlanche() {
        when(allowlist.allows("alice@example.com")).thenReturn(false);

        EmailOutcome outcome = service.send(request(EmailType.WELCOME, EmailRequest.Origin.EVENT));

        assertThat(outcome).isEqualTo(EmailOutcome.SKIPPED_ALLOWLIST);
        verify(deliveries).insertSkipped(any(), eq(EmailSkipReason.ALLOWLIST));
        verify(sender, never()).send(any());
    }

    // ------------------------------------------------------ relance immediate

    @Test
    @DisplayName("SMTP en echec puis retabli : le mail part par la relance immediate, sur la meme ligne")
    void relanceImmediateReussit() {
        when(sender.send(any())).thenThrow(new EmailSendException("SMTP down"))
                .thenThrow(new EmailSendException("SMTP down")).thenReturn(null);

        EmailOutcome outcome = service.send(request(EmailType.WELCOME, EmailRequest.Origin.EVENT));

        assertThat(outcome).isEqualTo(EmailOutcome.SENT);
        verify(sender, times(3)).send(any());
        verify(deliveries).markSent(eq(deliveryId), any(), isNull(), eq(3));
        verify(deliveries, times(1)).insertPending(any());
        assertThat(sleeps).containsExactly(Duration.ofSeconds(30), Duration.ofSeconds(120));
    }

    @Test
    @DisplayName("Toutes les tentatives echouent : FAILED, erreur assainie, 4 tentatives")
    void relanceImmediateEchoue() {
        doThrow(new EmailSendException("550 refused for bob@victime.fr token=abc123"))
                .when(sender).send(any());

        EmailOutcome outcome = service.send(request(EmailType.WELCOME, EmailRequest.Origin.EVENT));

        assertThat(outcome).isEqualTo(EmailOutcome.FAILED);
        ArgumentCaptor<String> error = ArgumentCaptor.forClass(String.class);
        verify(deliveries).markFailed(eq(deliveryId), any(), error.capture(), eq(4));
        assertThat(error.getValue()).doesNotContain("bob@victime.fr").doesNotContain("abc123");
        assertThat(sleeps).hasSize(3);
    }

    @Test
    @DisplayName("Un echec d'envoi ne propage jamais d'exception")
    void aucuneExceptionNeSort() {
        doThrow(new RuntimeException("boom")).when(sender).send(any());

        EmailOutcome outcome = service.send(request(EmailType.WELCOME, EmailRequest.Origin.EVENT));

        assertThat(outcome).isEqualTo(EmailOutcome.FAILED);
    }

    // -------------------------------------------------------------- executor

    @Test
    @DisplayName("Executor sature : ligne FAILED, jamais d'execution dans le thread appelant")
    void executorSature() {
        executor = task -> {
            throw new TaskRejectedException("plein");
        };
        build(EmailTestFixtures.config(1, List.of(30), 3));

        EmailOutcome outcome = service.sendAsync(request(EmailType.NO_TRAINING_7_DAYS, EmailRequest.Origin.SCHEDULER));

        assertThat(outcome).isEqualTo(EmailOutcome.REJECTED);
        verify(sender, never()).send(any());
        verify(deliveries).markFailed(eq(deliveryId), any(), anyString(), anyInt());
    }

    @Test
    @DisplayName("Sans destinataire : rien n'est ecrit")
    void sansDestinataire() {
        EmailRequest r = new EmailRequest(EmailType.WELCOME, userId, " ", Map.of(), "k", null, null,
                EmailRequest.Origin.EVENT);

        assertThat(service.send(r)).isEqualTo(EmailOutcome.NO_RECIPIENT);
        verify(deliveries, never()).insertPending(any());
    }

    @Test
    @DisplayName("Consommer une cle ecrit une ligne SKIPPED / KEY_CONSUMED, sans envoi")
    void consommerUneCle() {
        when(deliveries.insertSkipped(any(), eq(EmailSkipReason.KEY_CONSUMED)))
                .thenReturn(Optional.of(UUID.randomUUID()));

        boolean consumed = service.consumeKey(new EmailIntent(EmailType.DIAGNOSTIC_PLAN_READY, userId,
                "alice@example.com", "k", null, null));

        assertThat(consumed).isTrue();
        verify(sender, never()).send(any());
    }
}

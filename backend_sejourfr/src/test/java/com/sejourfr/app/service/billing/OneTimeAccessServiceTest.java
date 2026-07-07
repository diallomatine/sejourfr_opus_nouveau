package com.sejourfr.app.service.billing;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.MailService;
import com.sejourfr.app.service.SubscriptionService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.springframework.web.server.ResponseStatusException;

/**
 * Couvre l'octroi d'un pass one-time (lot 5) : création vs prolongation
 * cumulative, idempotence sur la clé {@code (source, originalTransactionId)},
 * et anti-account-stealing (409). Test unitaire pur (mocks Mockito).
 */
class OneTimeAccessServiceTest {

    private UserManager userManager;
    private UserSubscriptionManager userSubscriptionManager;
    private SubscriptionService subscriptionService;
    private MailService mailService;
    private OneTimeAccessService service;

    private final UUID userId = UUID.randomUUID();
    private User user;
    private Plan civiquePass;

    @BeforeEach
    void setUp() {
        userManager = mock(UserManager.class);
        userSubscriptionManager = mock(UserSubscriptionManager.class);
        subscriptionService = mock(SubscriptionService.class);
        mailService = mock(MailService.class);
        service = new OneTimeAccessService(
                userManager, userSubscriptionManager, subscriptionService, mailService);

        user = new User();
        user.setId(userId);
        user.setEmail("u@sejourfr.fr");
        user.setFirstName("Lea");

        civiquePass = new Plan();
        civiquePass.setCode("CIVIQUE_3MOIS");
        civiquePass.setName("Civique 3 mois");
        civiquePass.setModuleAccess(ModuleAccess.CIVIQUE);
        civiquePass.setDurationDays(90);

        when(userManager.findById(userId)).thenReturn(Optional.of(user));
        when(userSubscriptionManager.save(any(UserSubscription.class)))
                .thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    void premierAchat_creeAccesActif_nonRenouvelable_dureeBackend() {
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.STRIPE, "pi_1")).thenReturn(Optional.empty());
        when(subscriptionService.currentEndForAtLeast(userId, ModuleAccess.CIVIQUE)).thenReturn(null);

        Instant before = Instant.now();
        UserSubscription sub = service.grantOneTimeAccess(
                userId, civiquePass, SubscriptionSource.STRIPE, "pi_1", "pi_1");

        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
        assertThat(sub.isAutoRenew()).isFalse();
        assertThat(sub.getOriginalTransactionId()).isEqualTo("pi_1");
        // endsAt = now + durationDays (durée posée par le backend, pas le store).
        assertThat(sub.getEndsAt()).isAfterOrEqualTo(before.plus(90, ChronoUnit.DAYS));
        // Premier achat → mail de bienvenue (autoRenew=false), pas « accès prolongé ».
        verify(mailService).sendSubscriptionActivatedEmail(
                eq("u@sejourfr.fr"), eq("Lea"), eq("Civique 3 mois"), any(Instant.class), eq(false));
        verify(mailService, never()).sendAccessExtendedEmail(
                any(), any(), any(), any());
    }

    @Test
    void prolongation_cumuleDepuisLaFinCourante_mailAccesProlonge() {
        Instant currentEnd = Instant.now().plus(20, ChronoUnit.DAYS);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.STRIPE, "pi_2")).thenReturn(Optional.empty());
        when(subscriptionService.currentEndForAtLeast(userId, ModuleAccess.CIVIQUE))
                .thenReturn(currentEnd);

        UserSubscription sub = service.grantOneTimeAccess(
                userId, civiquePass, SubscriptionSource.STRIPE, "pi_2", "pi_2");

        // Cumul : base = fin courante, pas « maintenant ».
        assertThat(sub.getEndsAt()).isEqualTo(currentEnd.plus(90, ChronoUnit.DAYS));
        verify(mailService).sendAccessExtendedEmail(
                eq("u@sejourfr.fr"), eq("Lea"), eq("Civique 3 mois"), eq(currentEnd.plus(90, ChronoUnit.DAYS)));
        verify(mailService, never()).sendSubscriptionActivatedEmail(
                any(), any(), any(), any(), org.mockito.ArgumentMatchers.anyBoolean());
    }

    @Test
    void replay_memeAchatMemeUser_idempotent_aucuneNouvellePeriode() {
        UserSubscription existing = new UserSubscription();
        existing.setUser(user);
        existing.setEndsAt(Instant.now().plus(50, ChronoUnit.DAYS));
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.STRIPE, "pi_3")).thenReturn(Optional.of(existing));

        UserSubscription sub = service.grantOneTimeAccess(
                userId, civiquePass, SubscriptionSource.STRIPE, "pi_3", "pi_3");

        assertThat(sub).isSameAs(existing);
        verify(userSubscriptionManager, never()).save(any());
        verify(mailService, never()).sendSubscriptionActivatedEmail(
                any(), any(), any(), any(), org.mockito.ArgumentMatchers.anyBoolean());
    }

    @Test
    void recuRattacheAUnAutreCompte_renvoie409() {
        User other = new User();
        other.setId(UUID.randomUUID());
        UserSubscription existing = new UserSubscription();
        existing.setUser(other);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.APPLE, "tx_x")).thenReturn(Optional.of(existing));

        assertThatThrownBy(() -> service.grantOneTimeAccess(
                userId, civiquePass, SubscriptionSource.APPLE, "tx_x", "tx_x"))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("déjà rattaché à un autre compte")
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(409);
        verify(userSubscriptionManager, never()).save(any());
    }

    @Test
    void userIntrouvable_renvoie404() {
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                any(), any())).thenReturn(Optional.empty());
        when(userManager.findById(userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.grantOneTimeAccess(
                userId, civiquePass, SubscriptionSource.STRIPE, "pi_4", "pi_4"))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(404);
    }

    private Plan integralPass(int realtimeSessions) {
        Plan p = new Plan();
        p.setCode("INTEGRAL_ANNUEL");
        p.setName("Intégral 1 an");
        p.setModuleAccess(ModuleAccess.INTEGRAL);
        p.setDurationDays(365);
        p.setRealtimeEoSessions(realtimeSessions);
        return p;
    }

    @Test
    void premierAchatIntegral_octroieLesSessionsRealtimeDuPass() {
        Plan integral = integralPass(10);
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.STRIPE, "pi_rt1")).thenReturn(Optional.empty());
        when(subscriptionService.currentEndForAtLeast(userId, ModuleAccess.INTEGRAL)).thenReturn(null);

        UserSubscription sub = service.grantOneTimeAccess(
                userId, integral, SubscriptionSource.STRIPE, "pi_rt1", "pi_rt1");

        // Premier achat : solde = allocation du pass.
        assertThat(sub.getRealtimeEoSessionsRemaining()).isEqualTo(10);
    }

    @Test
    void prolongationIntegral_cumuleLesSessionsRealtimeAvecLeReste() {
        Plan integral = integralPass(10);
        Instant currentEnd = Instant.now().plus(20, ChronoUnit.DAYS);
        UserSubscription covering = new UserSubscription();
        covering.setRealtimeEoSessionsRemaining(3); // reste avant la prolongation
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                SubscriptionSource.STRIPE, "pi_rt2")).thenReturn(Optional.empty());
        when(subscriptionService.currentEndForAtLeast(userId, ModuleAccess.INTEGRAL))
                .thenReturn(currentEnd);
        when(subscriptionService.currentSubscription(userId)).thenReturn(Optional.of(covering));

        UserSubscription sub = service.grantOneTimeAccess(
                userId, integral, SubscriptionSource.STRIPE, "pi_rt2", "pi_rt2");

        // Cumul : report du reste (3) + allocation du nouveau pass (10).
        assertThat(sub.getRealtimeEoSessionsRemaining()).isEqualTo(13);
    }

    @Test
    void prolongation_finPassee_repartDeMaintenant_mailBienvenue() {
        // currentEndForAtLeast renvoie une date déjà passée → pas une extension.
        when(userSubscriptionManager.findBySourceAndOriginalTransactionId(
                any(), any())).thenReturn(Optional.empty());
        when(subscriptionService.currentEndForAtLeast(userId, ModuleAccess.CIVIQUE))
                .thenReturn(Instant.now().minus(1, ChronoUnit.DAYS));

        Instant before = Instant.now();
        UserSubscription sub = service.grantOneTimeAccess(
                userId, civiquePass, SubscriptionSource.STRIPE, "pi_5", "pi_5");

        ArgumentCaptor<Instant> endsCaptor = ArgumentCaptor.forClass(Instant.class);
        assertThat(sub.getEndsAt()).isAfterOrEqualTo(before.plus(90, ChronoUnit.DAYS));
        verify(mailService).sendSubscriptionActivatedEmail(
                eq("u@sejourfr.fr"), eq("Lea"), eq("Civique 3 mois"), endsCaptor.capture(), eq(false));
        assertThat(endsCaptor.getValue()).isAfterOrEqualTo(before.plus(90, ChronoUnit.DAYS));
        // pas de mail « prolongé », pas de date nulle
        verify(mailService, never()).sendAccessExtendedEmail(any(), any(), any(), isNull());
    }
}

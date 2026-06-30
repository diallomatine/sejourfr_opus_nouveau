package com.sejourfr.app.service.billing;

import com.sejourfr.app.config.BillingProperties;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.BillingMode;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.MailService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ExpiryReminderJobTest {

    @Mock
    private UserSubscriptionManager userSubscriptionManager;
    @Mock
    private MailService mailService;

    private BillingProperties billingProperties;
    private ExpiryReminderJob job;

    @BeforeEach
    void setUp() {
        billingProperties = new BillingProperties();
        billingProperties.setMode(BillingMode.ONE_TIME);
        job = new ExpiryReminderJob(userSubscriptionManager, mailService, billingProperties);
    }

    private UserSubscription sub(String email, String firstName, String planName) {
        UserSubscription s = new UserSubscription();
        s.setId(UUID.randomUUID());
        s.setEndsAt(Instant.now().plus(3, ChronoUnit.DAYS));
        if (email != null) {
            User u = new User();
            u.setEmail(email);
            u.setFirstName(firstName);
            s.setUser(u);
        }
        if (planName != null) {
            Plan p = new Plan();
            p.setName(planName);
            s.setPlan(p);
        }
        return s;
    }

    @Test
    void subscriptionMode_doesNothing() {
        billingProperties.setMode(BillingMode.SUBSCRIPTION);

        job.sendExpiryReminders();

        verifyNoInteractions(userSubscriptionManager, mailService);
    }

    @Test
    void oneTimeMode_sendsAndMarksReminded() {
        UserSubscription s = sub("karim@sejourfr.fr", "Karim", "Civique");
        when(userSubscriptionManager.findOneTimeExpiringSoon(any(), any())).thenReturn(List.of(s));

        job.sendExpiryReminders();

        verify(mailService).sendAccessExpiringSoonEmail(
                eq("karim@sejourfr.fr"), eq("Karim"), eq("Civique"), any());
        assertThat(s.getExpiryRemindedAt()).isNotNull();
        verify(userSubscriptionManager).save(s);
    }

    @Test
    void nullPlan_usesPremiumFallback() {
        UserSubscription s = sub("a@b.fr", "Ana", null);
        when(userSubscriptionManager.findOneTimeExpiringSoon(any(), any())).thenReturn(List.of(s));

        job.sendExpiryReminders();

        verify(mailService).sendAccessExpiringSoonEmail(eq("a@b.fr"), eq("Ana"), eq("Premium"), any());
    }

    @Test
    void skipsSubscriptionsWithoutUsableEmail() {
        UserSubscription noUser = sub(null, null, "Civique");
        UserSubscription blankEmail = sub("   ", "X", "Civique");
        when(userSubscriptionManager.findOneTimeExpiringSoon(any(), any()))
                .thenReturn(List.of(noUser, blankEmail));

        job.sendExpiryReminders();

        verify(mailService, never()).sendAccessExpiringSoonEmail(anyString(), any(), anyString(), any());
        verify(userSubscriptionManager, never()).save(any());
    }

    @Test
    void oneFailure_doesNotBlockOthers() {
        UserSubscription failing = sub("boom@sejourfr.fr", "Boom", "Civique");
        UserSubscription ok = sub("ok@sejourfr.fr", "Ok", "Civique");
        when(userSubscriptionManager.findOneTimeExpiringSoon(any(), any()))
                .thenReturn(List.of(failing, ok));
        doThrow(new RuntimeException("smtp down")).when(mailService).sendAccessExpiringSoonEmail(
                eq("boom@sejourfr.fr"), any(), any(), any());

        job.sendExpiryReminders();

        verify(mailService, times(2)).sendAccessExpiringSoonEmail(anyString(), any(), anyString(), any());
        assertThat(failing.getExpiryRemindedAt()).isNull();
        assertThat(ok.getExpiryRemindedAt()).isNotNull();
        verify(userSubscriptionManager).save(ok);
        verify(userSubscriptionManager, never()).save(failing);
    }
}

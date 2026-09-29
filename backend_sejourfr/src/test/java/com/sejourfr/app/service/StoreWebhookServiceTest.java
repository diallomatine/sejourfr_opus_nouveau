package com.sejourfr.app.service;

import com.sejourfr.app.service.billing.AppleSubscriptionService;
import com.sejourfr.app.service.billing.GoogleSubscriptionService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

/**
 * Dispatcher fin : vérifie que les notifications store sont routées vers le bon
 * service spécialisé sans transformation. Test unitaire pur.
 */
class StoreWebhookServiceTest {

    private AppleSubscriptionService appleSubscriptionService;
    private GoogleSubscriptionService googleSubscriptionService;
    private StoreWebhookService service;

    @BeforeEach
    void setUp() {
        appleSubscriptionService = mock(AppleSubscriptionService.class);
        googleSubscriptionService = mock(GoogleSubscriptionService.class);
        service = new StoreWebhookService(appleSubscriptionService, googleSubscriptionService);
    }

    @Test
    void appleNotification_delegueeAAppleService() {
        service.handleAppleNotification("signed-payload");
        verify(appleSubscriptionService).handleNotification("signed-payload");
        verifyNoInteractions(googleSubscriptionService);
    }

    @Test
    void googleNotification_delegueeAGoogleService_avecAuthHeader() {
        service.handleGoogleNotification("Bearer jwt", "pubsub-payload");
        verify(googleSubscriptionService).handleNotification("Bearer jwt", "pubsub-payload");
        verifyNoInteractions(appleSubscriptionService);
    }
}

package com.sejourfr.app.service;

import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.FunnelEvent;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.UserFunnelEventManager;
import com.sejourfr.app.util.ClientContext;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class FunnelEventServiceTest {

    private static final UUID USER = UUID.randomUUID();
    private static final ClientContext CTX =
            new ClientContext(ClientPlatform.MOBILE, "tiktok");

    @Mock
    private UserFunnelEventManager manager;

    @InjectMocks
    private FunnelEventService service;

    @Test
    void uneEtapeDeclareeEstPoseeAvecSonContexte() {
        service.recordFromClient(USER, FunnelEvent.PAYWALL_VIEWED, CTX);

        verify(manager).recordFirstOccurrence(
                eq(USER), eq(FunnelEvent.PAYWALL_VIEWED), eq(ClientPlatform.MOBILE), eq("tiktok"));
    }

    /**
     * CHECKOUT_STARTED dit « une session de paiement a réellement été créée ».
     * L'accepter d'un client en ferait une intention, et la dernière marche du
     * funnel cesserait d'être un vrai chiffre.
     */
    @Test
    void unClientNePeutPasDeclarerLeDepartDePaiement() {
        assertThatThrownBy(() ->
                service.recordFromClient(USER, FunnelEvent.CHECKOUT_STARTED, CTX))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("serveur");

        verify(manager, never()).recordFirstOccurrence(any(), any(), any(), any());
    }

    /** Le serveur, lui, la pose : c'est lui qui constate le fait. */
    @Test
    void leServeurPoseLeDepartDePaiement() {
        service.record(USER, FunnelEvent.CHECKOUT_STARTED, CTX);

        verify(manager).recordFirstOccurrence(
                eq(USER), eq(FunnelEvent.CHECKOUT_STARTED), any(), any());
    }

    @Test
    void sansContexteDeclareOnPoseUnInconnu_jamaisNull() {
        service.record(USER, FunnelEvent.PAYWALL_VIEWED, null);

        verify(manager).recordFirstOccurrence(
                eq(USER), eq(FunnelEvent.PAYWALL_VIEWED),
                eq(ClientPlatform.UNKNOWN), eq("direct"));
    }

    /**
     * Perdre une ligne de statistique est sans commune mesure avec empêcher
     * quelqu'un de payer : la variante best-effort avale tout.
     */
    @Test
    void laVarianteBestEffortNeRemonteJamaisUneErreur() {
        doThrow(new IllegalStateException("base injoignable"))
                .when(manager).recordFirstOccurrence(any(), any(), any(), any());

        assertThatCode(() ->
                service.recordQuietly(USER, FunnelEvent.CHECKOUT_STARTED, CTX))
                .doesNotThrowAnyException();
    }

    /** Le contrat est fermé : trois étapes, pas une de plus. */
    @Test
    void leContratNePorteQueLesTroisEtapesNonDeductibles() {
        assertThat(FunnelEvent.values()).containsExactly(
                FunnelEvent.PAYWALL_VIEWED,
                FunnelEvent.SUBSCRIBE_CLICKED,
                FunnelEvent.CHECKOUT_STARTED);
    }
}

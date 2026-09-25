package com.sejourfr.app.service;

import com.sejourfr.app.config.BillingProperties;
import com.sejourfr.app.config.StripeProperties;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.manager.ProcessedExternalEventManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.mapper.PlanMapper;
import com.sejourfr.app.service.billing.PurchaseIntentService;
import com.sejourfr.app.service.billing.StripeSubscriptionService;
import com.stripe.exception.SignatureVerificationException;
import com.stripe.model.Event;
import com.stripe.net.Webhook;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.MockedStatic;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Couvre la surface fine de {@link BillingService} sans toucher le réseau
 * Stripe : gardes de {@code getPaymentLink} (503 non configuré / 404 plan
 * inconnu / 503 sans stripe_price_id) et le pipeline {@code handleWebhook}
 * (no-op secret manquant, signature invalide → 400, anti-replay → 400,
 * idempotence → pas de dispatch, happy path → dispatch). Les appels statiques
 * Stripe ({@code Webhook.constructEvent}) sont mockés via {@code mockStatic}.
 */
class BillingServiceTest {

    private StripeProperties stripeProperties;
    private BillingProperties billingProperties;
    private UserManager userManager;
    private PlanManager planManager;
    private ProcessedExternalEventManager processedEventManager;
    private StripeSubscriptionService stripeSubscriptionService;
    private PurchaseIntentService purchaseIntentService;
    private BillingService service;

    private static final com.sejourfr.app.util.ClientContext CTX =
            new com.sejourfr.app.util.ClientContext(
                    com.sejourfr.app.enums.ClientPlatform.WEB, "direct");

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        stripeProperties = mock(StripeProperties.class);
        billingProperties = mock(BillingProperties.class);
        userManager = mock(UserManager.class);
        planManager = mock(PlanManager.class);
        processedEventManager = mock(ProcessedExternalEventManager.class);
        PlanMapper planMapper = mock(PlanMapper.class);
        stripeSubscriptionService = mock(StripeSubscriptionService.class);
        SubscriptionService subscriptionService = mock(SubscriptionService.class);
        FunnelEventService funnelEventService = mock(FunnelEventService.class);
        purchaseIntentService = mock(PurchaseIntentService.class);
        service = new BillingService(
                stripeProperties, billingProperties, userManager, planManager,
                processedEventManager, planMapper, stripeSubscriptionService, subscriptionService,
                funnelEventService, purchaseIntentService);

        User user = new User();
        user.setId(userId);
        user.setEmail("u@sejourfr.fr");
        when(userManager.findById(userId)).thenReturn(Optional.of(user));
    }

    private static Plan plan(ModuleAccess access, String priceId) {
        Plan p = new Plan();
        p.setCode("CIVIQUE_3MOIS");
        p.setName("Civique");
        p.setModuleAccess(access);
        p.setPrice(new BigDecimal("9.99"));
        p.setActive(true);
        p.setStripePriceId(priceId);
        return p;
    }

    @Test
    void getPaymentLink_stripeNonConfigure_renvoie503() {
        when(stripeProperties.isConfigured()).thenReturn(false);
        assertThatThrownBy(() -> service.getPaymentLink(userId, "CIVIQUE_3MOIS", null, CTX))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(503);
    }

    @Test
    void getPaymentLink_planInconnu_renvoie404() {
        when(stripeProperties.isConfigured()).thenReturn(true);
        when(billingProperties.isOneTime()).thenReturn(false);
        when(planManager.findByCode("CIVIQUE_3MOIS")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getPaymentLink(userId, "CIVIQUE_3MOIS", null, CTX))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(404);
    }

    @Test
    void getPaymentLink_subscriptionSansStripePriceId_renvoie503() {
        when(stripeProperties.isConfigured()).thenReturn(true);
        when(billingProperties.isOneTime()).thenReturn(false);
        when(planManager.findByCode("CIVIQUE_3MOIS"))
                .thenReturn(Optional.of(plan(ModuleAccess.CIVIQUE, null)));

        assertThatThrownBy(() -> service.getPaymentLink(userId, "CIVIQUE_3MOIS", null, CTX))
                .isInstanceOf(ResponseStatusException.class)
                .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                .isEqualTo(503);
    }

    @Test
    void handleWebhook_secretManquant_noop_pasDeDispatch() {
        when(stripeProperties.getWebhookSecret()).thenReturn("");
        service.handleWebhook("payload", "sig");
        verify(processedEventManager, never()).tryMarkProcessed(anyString(), anyString());
        verify(stripeSubscriptionService, never()).dispatch(any());
    }

    @Test
    void handleWebhook_signatureInvalide_renvoie400() {
        when(stripeProperties.getWebhookSecret()).thenReturn("whsec_x");
        try (MockedStatic<Webhook> mocked = mockStatic(Webhook.class)) {
            mocked.when(() -> Webhook.constructEvent("payload", "bad-sig", "whsec_x"))
                    .thenThrow(new SignatureVerificationException("bad", "bad-sig"));

            assertThatThrownBy(() -> service.handleWebhook("payload", "bad-sig"))
                    .isInstanceOf(ResponseStatusException.class)
                    .extracting(e -> ((ResponseStatusException) e).getStatusCode().value())
                    .isEqualTo(400);
            verify(stripeSubscriptionService, never()).dispatch(any());
        }
    }

    /**
     * Bug Q11 : Stripe garde le {@code created} d'origine sur ses relances (jusqu'à
     * 3 jours). L'ancienne garde de 300 s rejetait définitivement toute relance
     * légitime au-delà de 5 min — l'achat n'était jamais crédité. Un évènement
     * signé, même vieux d'un jour, est traité ; seule l'idempotence sur son id
     * écarte un rejeu.
     */
    @Test
    void handleWebhook_relanceStripeVieilleDUnJour_estTraitee() {
        when(stripeProperties.getWebhookSecret()).thenReturn("whsec_x");
        Event event = mock(Event.class);
        when(event.getCreated()).thenReturn(Instant.now().getEpochSecond() - 86_400);
        when(event.getId()).thenReturn("evt_old");
        when(processedEventManager.tryMarkProcessed("stripe", "evt_old")).thenReturn(true);
        try (MockedStatic<Webhook> mocked = mockStatic(Webhook.class)) {
            mocked.when(() -> Webhook.constructEvent("p", "s", "whsec_x")).thenReturn(event);

            service.handleWebhook("p", "s");

            verify(processedEventManager).tryMarkProcessed("stripe", "evt_old");
            verify(stripeSubscriptionService).dispatch(event);
        }
    }

    /** La même relance, déjà traitée : l'idempotence sur l'id l'écarte. */
    @Test
    void handleWebhook_relanceDejaTraitee_nEstPasRedispatchee() {
        when(stripeProperties.getWebhookSecret()).thenReturn("whsec_x");
        Event event = mock(Event.class);
        when(event.getCreated()).thenReturn(Instant.now().getEpochSecond() - 86_400);
        when(event.getId()).thenReturn("evt_old");
        when(processedEventManager.tryMarkProcessed("stripe", "evt_old")).thenReturn(false);
        try (MockedStatic<Webhook> mocked = mockStatic(Webhook.class)) {
            mocked.when(() -> Webhook.constructEvent("p", "s", "whsec_x")).thenReturn(event);

            service.handleWebhook("p", "s");

            verify(stripeSubscriptionService, never()).dispatch(any());
        }
    }

    /**
     * Q12 : le checkout Stripe crée l'intention AVANT la session et la
     * transporte par {@code metadata.intentId}.
     */
    @Test
    void getPaymentLink_avecCta_creeLIntentionEtLaPoseEnMetadata() {
        when(stripeProperties.isConfigured()).thenReturn(true);
        when(stripeProperties.getAppBaseUrl()).thenReturn("https://sejourfr.fr");
        when(billingProperties.isOneTime()).thenReturn(true);
        Plan pass = plan(ModuleAccess.CIVIQUE, null);
        pass.setDurationDays(90);
        when(planManager.findByCode("CIVIQUE_3MOIS")).thenReturn(Optional.of(pass));
        UUID intentId = UUID.randomUUID();
        when(purchaseIntentService.creerPourCheckout(userId, pass, "LOCKED_PLAN", "j-1", CTX))
                .thenReturn(Optional.of(intentId));

        try (MockedStatic<com.stripe.model.checkout.Session> sessions =
                     mockStatic(com.stripe.model.checkout.Session.class)) {
            com.stripe.model.checkout.Session created =
                    mock(com.stripe.model.checkout.Session.class);
            when(created.getUrl()).thenReturn("https://checkout.stripe.com/x");
            ArgumentCaptor<com.stripe.param.checkout.SessionCreateParams> captor =
                    ArgumentCaptor.forClass(com.stripe.param.checkout.SessionCreateParams.class);
            sessions.when(() -> com.stripe.model.checkout.Session.create(captor.capture()))
                    .thenReturn(created);

            service.getPaymentLink(userId, "CIVIQUE_3MOIS", null, "LOCKED_PLAN", "j-1", CTX);

            assertThat(captor.getValue().getMetadata())
                    .containsEntry("intentId", intentId.toString())
                    .containsEntry("planCode", "CIVIQUE_3MOIS");
        }
    }

    /** Sans CTA (client antérieur) : aucune intention, le paiement part quand même. */
    @Test
    void getPaymentLink_sansIntention_pasDeMetadataIntentId() {
        when(stripeProperties.isConfigured()).thenReturn(true);
        when(stripeProperties.getAppBaseUrl()).thenReturn("https://sejourfr.fr");
        when(billingProperties.isOneTime()).thenReturn(true);
        Plan pass = plan(ModuleAccess.CIVIQUE, null);
        pass.setDurationDays(90);
        when(planManager.findByCode("CIVIQUE_3MOIS")).thenReturn(Optional.of(pass));
        when(purchaseIntentService.creerPourCheckout(any(), any(), any(), any(), any()))
                .thenReturn(Optional.empty());

        try (MockedStatic<com.stripe.model.checkout.Session> sessions =
                     mockStatic(com.stripe.model.checkout.Session.class)) {
            com.stripe.model.checkout.Session created =
                    mock(com.stripe.model.checkout.Session.class);
            when(created.getUrl()).thenReturn("https://checkout.stripe.com/x");
            ArgumentCaptor<com.stripe.param.checkout.SessionCreateParams> captor =
                    ArgumentCaptor.forClass(com.stripe.param.checkout.SessionCreateParams.class);
            sessions.when(() -> com.stripe.model.checkout.Session.create(captor.capture()))
                    .thenReturn(created);

            service.getPaymentLink(userId, "CIVIQUE_3MOIS", null, CTX);

            assertThat(captor.getValue().getMetadata()).doesNotContainKey("intentId");
        }
    }

    @Test
    void handleWebhook_dejaTraite_skip_sansDispatch() {
        when(stripeProperties.getWebhookSecret()).thenReturn("whsec_x");
        Event event = mock(Event.class);
        when(event.getCreated()).thenReturn(Instant.now().getEpochSecond());
        when(event.getId()).thenReturn("evt_dup");
        when(processedEventManager.tryMarkProcessed("stripe", "evt_dup")).thenReturn(false);
        try (MockedStatic<Webhook> mocked = mockStatic(Webhook.class)) {
            mocked.when(() -> Webhook.constructEvent("p", "s", "whsec_x")).thenReturn(event);

            service.handleWebhook("p", "s");

            verify(stripeSubscriptionService, never()).dispatch(any());
        }
    }

    @Test
    void handleWebhook_nouveau_dispatchAppele() {
        when(stripeProperties.getWebhookSecret()).thenReturn("whsec_x");
        Event event = mock(Event.class);
        when(event.getCreated()).thenReturn(Instant.now().getEpochSecond());
        when(event.getId()).thenReturn("evt_new");
        when(processedEventManager.tryMarkProcessed("stripe", "evt_new")).thenReturn(true);
        try (MockedStatic<Webhook> mocked = mockStatic(Webhook.class)) {
            mocked.when(() -> Webhook.constructEvent("p", "s", "whsec_x")).thenReturn(event);

            service.handleWebhook("p", "s");

            verify(stripeSubscriptionService).dispatch(event);
        }
    }

    /**
     * Un demi-tour sur Stripe ramène le candidat sur le RÉCAPITULATIF de son
     * pass, pas sur la grille des formules. Le {@code cancel_url} pointait sur
     * {@code /paiement}, donc sur un écran où il fallait re-choisir — au moment
     * précis où l'on hésite. L'URL est bâtie côté serveur à partir de
     * {@code appBaseUrl} et du code de plan déjà validé : aucun chemin de retour
     * ne vient du client.
     */
    @Test
    void getPaymentLink_demiTourSurStripe_ramenAuRecapitulatifDuPassChoisi() {
        when(stripeProperties.isConfigured()).thenReturn(true);
        when(stripeProperties.getAppBaseUrl()).thenReturn("https://sejourfr.fr");
        when(billingProperties.isOneTime()).thenReturn(true);
        Plan pass = plan(ModuleAccess.CIVIQUE, null);
        pass.setDurationDays(90);
        when(planManager.findByCode("CIVIQUE_3MOIS")).thenReturn(Optional.of(pass));

        try (MockedStatic<com.stripe.model.checkout.Session> sessions =
                     mockStatic(com.stripe.model.checkout.Session.class)) {
            com.stripe.model.checkout.Session created =
                    mock(com.stripe.model.checkout.Session.class);
            when(created.getUrl()).thenReturn("https://checkout.stripe.com/x");
            ArgumentCaptor<com.stripe.param.checkout.SessionCreateParams> captor =
                    ArgumentCaptor.forClass(com.stripe.param.checkout.SessionCreateParams.class);
            sessions.when(() -> com.stripe.model.checkout.Session.create(captor.capture()))
                    .thenReturn(created);

            service.getPaymentLink(userId, "CIVIQUE_3MOIS", null, CTX);

            assertThat(captor.getValue().getCancelUrl())
                    .isEqualTo("https://sejourfr.fr/paiement/recapitulatif"
                            + "?plan=CIVIQUE_3MOIS&canceled=1");
        }
    }

    // ------------------------------------------------------------------------
    // `retour` — le chemin d'où le candidat est parti, rendu après le paiement
    // ------------------------------------------------------------------------

    /**
     * Monte un checkout one-time avec le {@code retour} donné et rend la
     * {@code success_url} réellement passée à Stripe.
     */
    private String successUrlAvecRetour(String retour) {
        when(stripeProperties.isConfigured()).thenReturn(true);
        when(stripeProperties.getAppBaseUrl()).thenReturn("https://sejourfr.fr");
        when(billingProperties.isOneTime()).thenReturn(true);
        Plan pass = plan(ModuleAccess.CIVIQUE, null);
        pass.setDurationDays(90);
        when(planManager.findByCode("CIVIQUE_3MOIS")).thenReturn(Optional.of(pass));

        try (MockedStatic<com.stripe.model.checkout.Session> sessions =
                     mockStatic(com.stripe.model.checkout.Session.class)) {
            com.stripe.model.checkout.Session created =
                    mock(com.stripe.model.checkout.Session.class);
            when(created.getUrl()).thenReturn("https://checkout.stripe.com/x");
            ArgumentCaptor<com.stripe.param.checkout.SessionCreateParams> captor =
                    ArgumentCaptor.forClass(com.stripe.param.checkout.SessionCreateParams.class);
            sessions.when(() -> com.stripe.model.checkout.Session.create(captor.capture()))
                    .thenReturn(created);

            service.getPaymentLink(userId, "CIVIQUE_3MOIS", retour, CTX);

            return captor.getValue().getSuccessUrl();
        }
    }

    /** Le chemin nominal : le candidat retrouve l'écran d'où il est parti. */
    @Test
    void retour_cheminInterne_estPoseSurLaSuccessUrl() {
        assertThat(successUrlAvecRetour("/plan?module=CIVIQUE"))
                .isEqualTo("https://sejourfr.fr/paiement/succes"
                        + "?session_id={CHECKOUT_SESSION_ID}&plan=CIVIQUE_3MOIS"
                        + "&retour=%2Fplan%3Fmodule%3DCIVIQUE");
    }

    /**
     * 🛑 Le marqueur de Stripe n'est PAS encodé : c'est Stripe qui le substitue
     * avant la redirection, et l'encoder rendrait la référence de transaction
     * illisible sur la page de succès. Seule la valeur de {@code retour} l'est.
     */
    @Test
    void retour_leMarqueurStripeResteLitteral() {
        assertThat(successUrlAvecRetour("/plan"))
                .contains("session_id={CHECKOUT_SESSION_ID}")
                .doesNotContain("%7BCHECKOUT_SESSION_ID%7D");
    }

    /**
     * 🛑 L'open-redirect classique : {@code //evil.com} est une URL ABSOLUE pour
     * un navigateur. Refusé, et refusé <b>en silence</b> — un lien malformé ne
     * doit pas empêcher quelqu'un de payer.
     */
    @Test
    void retour_protocolRelative_estIgnoreEnSilence() {
        assertThat(successUrlAvecRetour("//evil.com"))
                .isEqualTo("https://sejourfr.fr/paiement/succes"
                        + "?session_id={CHECKOUT_SESSION_ID}&plan=CIVIQUE_3MOIS");
    }

    /** La même attaque avec un antislash, que certains navigateurs normalisent. */
    @Test
    void retour_antislashProtocolRelative_estIgnoreEnSilence() {
        assertThat(successUrlAvecRetour("/\\evil.com"))
                .doesNotContain("retour=")
                .doesNotContain("evil.com");
    }

    /** Ni hôte ni schéma : ce qui ne commence pas par `/` n'est pas un chemin. */
    @Test
    void retour_urlAbsolue_estIgnoreeEnSilence() {
        assertThat(successUrlAvecRetour("https://evil.com/x"))
                .doesNotContain("retour=")
                .doesNotContain("evil.com");
    }

    /**
     * Sans {@code retour} — le cas de loin le plus fréquent (lien partagé,
     * achat depuis les tarifs, client antérieur au paramètre) : la
     * {@code success_url} est EXACTEMENT celle d'avant.
     */
    @Test
    void retour_absent_gardeLaSuccessUrlDavant() {
        assertThat(successUrlAvecRetour(null))
                .isEqualTo("https://sejourfr.fr/paiement/succes"
                        + "?session_id={CHECKOUT_SESSION_ID}&plan=CIVIQUE_3MOIS");
    }
}

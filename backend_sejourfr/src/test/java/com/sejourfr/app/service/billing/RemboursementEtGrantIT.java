package com.sejourfr.app.service.billing;

import com.apple.itunes.storekit.model.Data;
import com.apple.itunes.storekit.model.JWSTransactionDecodedPayload;
import com.apple.itunes.storekit.model.NotificationTypeV2;
import com.apple.itunes.storekit.model.ResponseBodyV2DecodedPayload;
import com.apple.itunes.storekit.model.Type;
import com.sejourfr.app.dto.AppendTranscriptRequest;
import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.AdminAccessOperationType;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PaymentStatus;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.service.SubscriptionService;
import com.sejourfr.app.service.realtime.RealtimeQuotaService;
import com.sejourfr.app.service.realtime.RealtimeSessionService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AccesAdminFixtures;
import com.sejourfr.app.support.TestData;
import com.stripe.model.Charge;
import com.stripe.model.Event;
import com.stripe.model.EventDataObjectDeserializer;
import com.stripe.model.StripeObject;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * 🛑 Remboursements × sessions EO temps réel d'un GRANT INTEGRAL admin
 * (arbitrages n°3 et n°4 du 2026-10-02, OBLIGATOIRES) — par le VRAI chemin de
 * traitement de chaque fournisseur, jamais par une écriture SQL directe :
 * <ul>
 *   <li>Stripe : {@code charge.refunded} → {@link StripeSubscriptionService#dispatch} ;</li>
 *   <li>Apple : notification ASSN V2 {@code REFUND} → {@link AppleSubscriptionService#handleNotification}
 *       (seule la vérification JWS est simulée) ;</li>
 *   <li>Google : RTDN {@code voidedPurchaseNotification} → {@link GoogleSubscriptionService#handleNotification}
 *       (seule la vérification du jeton Pub/Sub est simulée).</li>
 * </ul>
 * Compte de départ : un achat Intégral (7 sessions restantes) et un GRANT
 * INTEGRAL indépendant (5 sessions offertes). Après un remboursement TOTAL :
 * <ol>
 *   <li>(a) le quota ne compte plus que les 5 sessions du GRANT, l'achat n'est
 *       plus l'achat qui compte ;</li>
 *   <li>(b) les décisions admin et le journal sont identiques colonne par
 *       colonne, solde compris ;</li>
 *   <li>(d) le rejeu de la notification n'écrit rien ;</li>
 *   <li>(c) une connexion temps réel ensuite débite le GRANT, jamais l'achat.</li>
 * </ol>
 * Variantes : remboursement total SANS GRANT (plus de temps réel) et
 * remboursement PARTIEL (comportement actuel conservé : l'achat reste
 * consommable — Stripe et Apple ; Google n'a pas de partiel).
 */
class RemboursementEtGrantIT extends AbstractIntegrationTest {

    private static final int SESSIONS_ACHAT = 7;
    private static final int SESSIONS_GRANT = 5;

    @MockitoBean private AppleStoreClient appleStoreClient;
    @MockitoBean private GoogleStoreClient googleStoreClient;

    @Autowired private StripeSubscriptionService stripe;
    @Autowired private AppleSubscriptionService apple;
    @Autowired private GoogleSubscriptionService google;
    @Autowired private RealtimeQuotaService quota;
    @Autowired private RealtimeSessionService realtimeSessions;
    @Autowired private SubscriptionService subscriptions;
    @Autowired private TestData data;
    @Autowired private AccesAdminFixtures fx;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private EntityManager em;

    private User admin;

    @BeforeEach
    void setUp() {
        admin = data.admin();
    }

    // ================================================================ chemins réels

    /** Une notification de remboursement d'un fournisseur, livrée par son vrai traitement. */
    private interface Fournisseur {
        SubscriptionSource source();

        /** Livre un remboursement TOTAL de l'achat de clé {@code cle} (rejouable à l'identique). */
        void rembourserTotal(String cle) throws Exception;
    }

    private final Fournisseur viaStripe = new Fournisseur() {
        public SubscriptionSource source() { return SubscriptionSource.STRIPE; }
        public void rembourserTotal(String cle) { stripe.dispatch(chargeRefunded(cle, 999)); }
    };

    private final Fournisseur viaApple = new Fournisseur() {
        public SubscriptionSource source() { return SubscriptionSource.APPLE; }
        public void rembourserTotal(String cle) throws Exception { notificationApple(cle, null); }
    };

    private final Fournisseur viaGoogle = new Fournisseur() {
        public SubscriptionSource source() { return SubscriptionSource.GOOGLE; }
        public void rembourserTotal(String cle) { rtdnGoogleVoided(cle); }
    };

    private static Event chargeRefunded(String paymentIntent, long cumul) {
        Charge charge = mock(Charge.class);
        when(charge.getId()).thenReturn("ch_" + paymentIntent);
        when(charge.getInvoice()).thenReturn(null);
        when(charge.getPaymentIntent()).thenReturn(paymentIntent);
        when(charge.getAmount()).thenReturn(999L);
        when(charge.getAmountRefunded()).thenReturn(cumul);
        when(charge.getCurrency()).thenReturn("eur");
        Event event = mock(Event.class);
        when(event.getType()).thenReturn("charge.refunded");
        when(event.getCreated()).thenReturn(Instant.now().getEpochSecond());
        EventDataObjectDeserializer deserializer = mock(EventDataObjectDeserializer.class);
        when(deserializer.getObject()).thenReturn(Optional.<StripeObject>of(charge));
        when(event.getDataObjectDeserializer()).thenReturn(deserializer);
        return event;
    }

    /**
     * Notification Apple {@code REFUND} signée (vérification JWS simulée) pour le
     * pass de transaction {@code txId}. Même {@code notificationUUID} à chaque
     * livraison : un rejeu est un rejeu. {@code pourcentage} : partiel en
     * millièmes de pourcent, {@code null} = total.
     */
    private void notificationApple(String txId, Integer pourcentage) throws Exception {
        JWSTransactionDecodedPayload tx = mock(JWSTransactionDecodedPayload.class);
        when(tx.getTransactionId()).thenReturn(txId);
        when(tx.getOriginalTransactionId()).thenReturn(txId);
        when(tx.getProductId()).thenReturn("integral_pass");
        when(tx.getType()).thenReturn(Type.CONSUMABLE);
        when(tx.getRevocationPercentage()).thenReturn(pourcentage);
        when(tx.getRevocationDate()).thenReturn(Instant.now().toEpochMilli());
        Data dataNotif = mock(Data.class);
        when(dataNotif.getSignedTransactionInfo()).thenReturn("stx-" + txId);
        ResponseBodyV2DecodedPayload notif = mock(ResponseBodyV2DecodedPayload.class);
        when(notif.getNotificationUUID()).thenReturn("uuid-" + txId + "-" + pourcentage);
        when(notif.getNotificationType()).thenReturn(NotificationTypeV2.REFUND);
        when(notif.getData()).thenReturn(dataNotif);
        when(appleStoreClient.verifyNotification("payload-" + txId)).thenReturn(notif);
        when(appleStoreClient.verifyTransaction("stx-" + txId)).thenReturn(tx);
        apple.handleNotification("payload-" + txId);
    }

    /** RTDN Google one-time {@code voidedPurchaseNotification} (jeton Pub/Sub simulé). Même messageId à chaque livraison. */
    private void rtdnGoogleVoided(String purchaseToken) {
        String data = "{\"voidedPurchaseNotification\":{\"purchaseToken\":\"" + purchaseToken
                + "\",\"orderId\":\"GPA." + purchaseToken + "\",\"refundType\":1}}";
        String payload = "{\"message\":{\"messageId\":\"msg-" + purchaseToken + "\",\"publishTime\":\""
                + Instant.now() + "\",\"data\":\""
                + Base64.getEncoder().encodeToString(data.getBytes(StandardCharsets.UTF_8)) + "\"}}";
        google.handleNotification("Bearer test", payload);
    }

    // ================================================================ état

    private String cle(SubscriptionSource source) {
        return switch (source) {
            case STRIPE -> "pi_" + UUID.randomUUID();
            case APPLE -> "apple_tx_" + UUID.randomUUID();
            case GOOGLE -> "google_tok_" + UUID.randomUUID();
        };
    }

    private int lignesDeRemboursement(UUID subId) {
        return jdbc.queryForObject("SELECT count(*) FROM payment_refunds WHERE subscription_id = ?",
                Integer.class, subId);
    }

    /** Relit tout depuis la base (le traitement a écrit hors des entités déjà chargées). */
    private RealtimeQuotaService.Quota quotaRelu(User u) {
        em.flush();
        em.clear();
        return quota.evaluate(u.getId());
    }

    /** Achat Intégral à 7 sessions + GRANT Intégral indépendant à 5 sessions, comme en production. */
    private UserSubscription achatEtGrant(User u, SubscriptionSource source, String cle) {
        UserSubscription achat = fx.achatIntegral(u, source, cle, 15, SESSIONS_ACHAT);
        em.flush();
        fx.agir(u, admin, AdminAccessOperationType.GRANT, ModuleAccess.INTEGRAL, null, null,
                AccesAdminFixtures.jour(60), SESSIONS_GRANT);
        RealtimeQuotaService.Quota avant = quotaRelu(u);
        assertThat(avant.remaining()).isEqualTo(SESSIONS_ACHAT + SESSIONS_GRANT);
        assertThat(avant.grantRemaining()).isEqualTo(SESSIONS_GRANT);
        assertThat(avant.achat()).map(UserSubscription::getId).contains(achat.getId());
        return achat;
    }

    /** Le scénario complet a → d, identique pour les trois fournisseurs. */
    private void remboursementTotalSousGrant(Fournisseur f) throws Exception {
        User u = data.user();
        String cle = cle(f.source());
        UserSubscription achat = achatEtGrant(u, f.source(), cle);
        List<Map<String, Object>> decisionsAvant = fx.lignesDecisions(u.getId());
        List<Map<String, Object>> journalAvant = fx.lignesJournal(u.getId());

        f.rembourserTotal(cle);
        em.flush();

        // L'achat est bien sorti par le traitement du fournisseur.
        Map<String, Object> ligneAchat = fx.ligneAchat(achat.getId());
        assertThat(ligneAchat.get("status")).isEqualTo(SubscriptionStatus.REFUNDED.name());
        assertThat(ligneAchat.get("payment_status")).isEqualTo(PaymentStatus.REFUNDED.name());
        // Le solde de l'achat n'est pas réécrit : il devient simplement illisible pour le quota.
        assertThat(ligneAchat.get("realtime_eo_sessions_remaining")).isEqualTo(SESSIONS_ACHAT);

        // (a) Seul le GRANT compte encore ; l'accès Intégral tient par lui.
        RealtimeQuotaService.Quota apres = quotaRelu(u);
        assertThat(apres.achat()).isEmpty();
        assertThat(subscriptions.effectiveAccess(u.getId()).achat()).isEmpty();
        assertThat(apres.remaining()).isEqualTo(SESSIONS_GRANT);
        assertThat(apres.cap()).isEqualTo(SESSIONS_GRANT);
        assertThat(apres.grantRemaining()).isEqualTo(SESSIONS_GRANT);
        assertThat(subscriptions.hasTcf(u.getId())).isTrue();

        // (b) Décisions admin et journal identiques colonne par colonne, solde compris.
        assertThat(fx.lignesDecisions(u.getId())).isEqualTo(decisionsAvant);
        assertThat(fx.lignesJournal(u.getId())).isEqualTo(journalAvant);

        // (d) Rejeu de la notification : aucune écriture, nulle part.
        Map<String, Object> achatApresRemboursement = fx.ligneAchat(achat.getId());
        int remboursements = lignesDeRemboursement(achat.getId());
        f.rembourserTotal(cle);
        em.flush();
        assertThat(fx.ligneAchat(achat.getId())).isEqualTo(achatApresRemboursement);
        assertThat(lignesDeRemboursement(achat.getId())).isEqualTo(remboursements);
        assertThat(fx.lignesDecisions(u.getId())).isEqualTo(decisionsAvant);
        assertThat(fx.lignesJournal(u.getId())).isEqualTo(journalAvant);

        // (c) Une connexion temps réel après le remboursement débite le GRANT, jamais l'achat.
        RealtimeSession session = fx.sessionReservee(u, apres);
        assertThat(session.getSubscription()).isNull();
        assertThat(session.getAccessOverrideId()).isNotNull();
        realtimeSessions.appendTranscript(u, session.getId(), new AppendTranscriptRequest("CANDIDATE", "Bonjour", 0, null));
        em.flush();
        assertThat(fx.soldeGrantCourant(u.getId())).isEqualTo(SESSIONS_GRANT - 1);
        assertThat(jdbc.queryForObject("SELECT access_override_id FROM realtime_sessions WHERE id = ?",
                UUID.class, session.getId())).isEqualTo(apres.grant().orElseThrow().getId());
        assertThat(fx.ligneAchat(achat.getId())).isEqualTo(achatApresRemboursement);
        assertThat(quotaRelu(u).remaining()).isEqualTo(SESSIONS_GRANT - 1);
    }

    /** Variante : aucun GRANT. Le remboursement total coupe le temps réel (cap 0, paywall). */
    private void remboursementTotalSansGrant(Fournisseur f) throws Exception {
        User u = data.user();
        String cle = cle(f.source());
        fx.achatIntegral(u, f.source(), cle, 15, SESSIONS_ACHAT);
        assertThat(quotaRelu(u).canStartRealtime()).isTrue();

        f.rembourserTotal(cle);

        RealtimeQuotaService.Quota apres = quotaRelu(u);
        assertThat(apres.canStartRealtime()).isFalse();
        assertThat(apres.cap()).isZero();
        assertThat(apres.remaining()).isZero();
        assertThat(subscriptions.hasTcf(u.getId())).isFalse();
        assertThat(fx.lignesDecisions(u.getId())).isEmpty();
    }

    // ================================================================ tests

    @Test
    @DisplayName("Total Stripe charge.refunded sous GRANT : GRANT et solde intacts, l'achat sort de l'accès et du quota, rejeu sans écriture")
    void totalSousGrantStripe() throws Exception {
        remboursementTotalSousGrant(viaStripe);
    }

    @Test
    @DisplayName("Total Apple REFUND sous GRANT : GRANT et solde intacts, l'achat sort de l'accès et du quota, rejeu sans écriture")
    void totalSousGrantApple() throws Exception {
        remboursementTotalSousGrant(viaApple);
    }

    @Test
    @DisplayName("Total Google voidedPurchase sous GRANT : GRANT et solde intacts, l'achat sort de l'accès et du quota, rejeu sans écriture")
    void totalSousGrantGoogle() throws Exception {
        remboursementTotalSousGrant(viaGoogle);
    }

    @Test
    @DisplayName("Total Stripe sans GRANT : plus de temps réel (cap 0)")
    void totalSansGrantStripe() throws Exception {
        remboursementTotalSansGrant(viaStripe);
    }

    @Test
    @DisplayName("Total Apple sans GRANT : plus de temps réel (cap 0)")
    void totalSansGrantApple() throws Exception {
        remboursementTotalSansGrant(viaApple);
    }

    @Test
    @DisplayName("Total Google sans GRANT : plus de temps réel (cap 0)")
    void totalSansGrantGoogle() throws Exception {
        remboursementTotalSansGrant(viaGoogle);
    }

    @Test
    @DisplayName("Partiel Stripe 3,00 € sur 9,99 € : accès et 7 sessions de l'achat conservés, GRANT intact")
    void partielStripe() {
        User u = data.user();
        String pi = cle(SubscriptionSource.STRIPE);
        UserSubscription achat = achatEtGrant(u, SubscriptionSource.STRIPE, pi);
        List<Map<String, Object>> decisionsAvant = fx.lignesDecisions(u.getId());

        stripe.dispatch(chargeRefunded(pi, 300));
        em.flush();

        assertThat(fx.ligneAchat(achat.getId()).get("status")).isEqualTo("ACTIVE");
        assertThat(fx.ligneAchat(achat.getId()).get("payment_status")).isEqualTo("PARTIALLY_REFUNDED");
        RealtimeQuotaService.Quota q = quotaRelu(u);
        assertThat(q.achat()).map(UserSubscription::getId).contains(achat.getId());
        assertThat(q.achatRemaining()).isEqualTo(SESSIONS_ACHAT);
        assertThat(q.remaining()).isEqualTo(SESSIONS_ACHAT + SESSIONS_GRANT);
        assertThat(fx.lignesDecisions(u.getId())).isEqualTo(decisionsAvant);
    }

    @Test
    @DisplayName("Partiel Apple 50 % : accès et 7 sessions de l'achat conservés")
    void partielApple() throws Exception {
        User u = data.user();
        String tx = cle(SubscriptionSource.APPLE);
        UserSubscription achat = fx.achatIntegral(u, SubscriptionSource.APPLE, tx, 15, SESSIONS_ACHAT);
        em.flush();

        notificationApple(tx, 50_000);
        em.flush();

        assertThat(fx.ligneAchat(achat.getId()).get("status")).isEqualTo("ACTIVE");
        assertThat(fx.ligneAchat(achat.getId()).get("payment_status")).isEqualTo("PARTIALLY_REFUNDED");
        RealtimeQuotaService.Quota q = quotaRelu(u);
        assertThat(q.canStartRealtime()).isTrue();
        assertThat(q.remaining()).isEqualTo(SESSIONS_ACHAT);
    }
}

package com.sejourfr.app.service.billing;

import com.sejourfr.app.dto.PurchaseIntentRequest;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.PurchaseOrigin;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import com.sejourfr.app.util.ClientContext;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Scénario 18 et arbitrage Q12 : l'origine d'un achat se lit UNIQUEMENT sur une
 * intention valide, consommée une seule fois. Aucune reconstruction : une
 * intention absente, expirée, consommée, d'un autre compte ou d'un autre
 * produit donne {@code UNKNOWN} et une run nulle.
 */
class PurchaseIntentAttributionIT extends AbstractIntegrationTest {

    @Autowired
    private PurchaseIntentService purchaseIntentService;
    @Autowired
    private OneTimeAccessService oneTimeAccessService;
    @Autowired
    private TestData testData;
    @Autowired
    private AuthTestSupport auth;
    @Autowired
    private MockMvc mvc;
    @Autowired
    private JdbcTemplate jdbc;
    @PersistenceContext
    private EntityManager em;

    private static final ClientContext IOS = new ClientContext(ClientPlatform.IOS, "direct");

    /** Un parcours civique fondé par un diagnostic dont la run est connue. */
    private record Parcours(UUID journeyId, UUID runId) {}

    private Parcours parcoursFondeParUnDiagnostic(User user) {
        Attempt attempt = testData.attempt(user);
        em.flush();
        UUID session = UUID.randomUUID();
        jdbc.update("""
                INSERT INTO civic_diagnostic_sessions (id, user_id, attempt_id, mention, config_version, status)
                VALUES (?, ?, ?, 'CSP', 1, 'IN_PROGRESS')""", session, user.getId(), attempt.getId());
        UUID run = UUID.randomUUID();
        jdbc.update("""
                INSERT INTO diagnostic_run (id, diagnostic_type, user_id, civic_diagnostic_session_id,
                    submitted_at, submitted_authenticated)
                VALUES (?, 'CIVIQUE', ?, ?, now(), true)""", run, user.getId(), session);
        UUID journey = UUID.randomUUID();
        jdbc.update("""
                INSERT INTO journey (id, user_id, module, status, target_procedure, next_position)
                VALUES (?, ?, 'CIVIQUE', 'EN_COURS', 'CSP', 1)""", journey, user.getId());
        jdbc.update("""
                INSERT INTO journey_assessment_event (id, journey_id, source_assessment_id, assessment_kind,
                    completed_at)
                VALUES (?, ?, ?, 'CIVIC_DIAGNOSTIC', now())""", UUID.randomUUID(), journey, session);
        return new Parcours(journey, run);
    }

    private UUID intention(User user, Plan plan, String cta, UUID journeyId) {
        return purchaseIntentService.creer(user.getId(), new PurchaseIntentRequest(
                plan.getCode(), cta, journeyId == null ? null : journeyId.toString()), IOS).purchaseIntentId();
    }

    private UserSubscription acheter(User user, Plan plan, Object intentId, Instant purchasedAt) {
        UserSubscription sub = oneTimeAccessService.grantOneTimeAccess(
                user.getId(), plan, SubscriptionSource.APPLE, "tx-" + UUID.randomUUID(), "tx",
                MontantEncaisse.INCONNU,
                new ContexteAchat(null, purchasedAt, intentId == null ? null : intentId.toString()));
        em.flush();
        return sub;
    }

    private boolean consommee(UUID intentId) {
        em.flush();
        return jdbc.queryForObject("SELECT consumed_at IS NOT NULL FROM purchase_intent WHERE id = ?",
                Boolean.class, intentId);
    }

    @Test
    @DisplayName("Intention depuis le Plan, run fondatrice résolue serveur → DIAGNOSTIC_PLAN")
    void ctaDuPlanAvecRun_diagnosticPlan() {
        User user = testData.user();
        Plan plan = testData.plan();
        Parcours parcours = parcoursFondeParUnDiagnostic(user);
        UUID intent = intention(user, plan, "LOCKED_PLAN", parcours.journeyId());

        UserSubscription sub = acheter(user, plan, intent, null);

        assertThat(sub.getOrigin()).isEqualTo(PurchaseOrigin.DIAGNOSTIC_PLAN);
        assertThat(sub.getDiagnosticRunId()).isEqualTo(parcours.runId());
        assertThat(sub.getJourneyId()).isEqualTo(parcours.journeyId());
        assertThat(sub.getPurchaseIntentId()).isEqualTo(intent);
        assertThat(consommee(intent)).isTrue();
    }

    @Test
    @DisplayName("Scénario 18 — achat via un autre CTA → OTHER_CTA, hors tunnel (run nulle)")
    void autreCta_otherCta() {
        User user = testData.user();
        Plan plan = testData.plan();
        Parcours parcours = parcoursFondeParUnDiagnostic(user);
        UUID intent = intention(user, plan, "PRICING", parcours.journeyId());

        UserSubscription sub = acheter(user, plan, intent, null);

        assertThat(sub.getOrigin()).isEqualTo(PurchaseOrigin.OTHER_CTA);
        assertThat(sub.getDiagnosticRunId()).isNull();
        assertThat(sub.getJourneyId()).isEqualTo(parcours.journeyId());
    }

    @Test
    @DisplayName("CTA du Plan sans parcours → UNKNOWN (jamais OTHER_CTA : il vient bien du Plan), pas de run")
    void ctaDuPlanSansParcours_unknown() {
        User user = testData.user();
        Plan plan = testData.plan();
        UUID intent = intention(user, plan, "LOCKED_PLAN", null);

        UserSubscription sub = acheter(user, plan, intent, null);
        assertThat(sub.getOrigin()).isEqualTo(PurchaseOrigin.UNKNOWN);
        assertThat(sub.getDiagnosticRunId()).isNull();
        assertThat(sub.getPurchaseIntentId()).isEqualTo(intent);
    }

    @Test
    @DisplayName("Scénario 18 — achat sans intention → UNKNOWN, hors tunnel")
    void sansIntention_unknown() {
        User user = testData.user();
        parcoursFondeParUnDiagnostic(user);

        UserSubscription sub = acheter(user, testData.plan(), null, null);

        assertThat(sub.getOrigin()).isEqualTo(PurchaseOrigin.UNKNOWN);
        assertThat(sub.getDiagnosticRunId()).isNull();
        assertThat(sub.getPurchaseIntentId()).isNull();
    }

    @Test
    @DisplayName("Scénario 18 — intention déjà consommée → UNKNOWN (usage unique)")
    void intentionDejaConsommee_unknown() {
        User user = testData.user();
        Plan plan = testData.plan();
        UUID intent = intention(user, plan, "PRICING", null);
        acheter(user, plan, intent, null);

        UserSubscription second = acheter(user, plan, intent, null);

        assertThat(second.getOrigin()).isEqualTo(PurchaseOrigin.UNKNOWN);
        assertThat(second.getPurchaseIntentId()).isNull();
    }

    @Test
    @DisplayName("Scénario 18 — intention expirée à l'instant de l'achat → UNKNOWN, non consommée")
    void intentionExpiree_unknown() {
        User user = testData.user();
        Plan plan = testData.plan();
        UUID intent = intention(user, plan, "LOCKED_PLAN", parcoursFondeParUnDiagnostic(user).journeyId());

        UserSubscription sub = acheter(user, plan, intent, Instant.now().plus(25, ChronoUnit.HOURS));

        assertThat(sub.getOrigin()).isEqualTo(PurchaseOrigin.UNKNOWN);
        assertThat(sub.getDiagnosticRunId()).isNull();
        assertThat(consommee(intent)).isFalse();
    }

    @Test
    @DisplayName("Scénario 18 — intention d'un autre compte → UNKNOWN, et elle reste intacte pour son titulaire")
    void intentionDUnAutreCompte_unknown() {
        User titulaire = testData.user();
        User autre = testData.user();
        Plan plan = testData.plan();
        UUID intent = intention(titulaire, plan, "PRICING", null);

        assertThat(acheter(autre, plan, intent, null).getOrigin()).isEqualTo(PurchaseOrigin.UNKNOWN);
        assertThat(consommee(intent)).isFalse();
    }

    @Test
    @DisplayName("Intention d'un autre produit → UNKNOWN")
    void intentionDUnAutreProduit_unknown() {
        User user = testData.user();
        UUID intent = intention(user, testData.plan(), "PRICING", null);

        assertThat(acheter(user, testData.plan(), intent, null).getOrigin()).isEqualTo(PurchaseOrigin.UNKNOWN);
    }

    @Test
    @DisplayName("Identifiant d'intention illisible → UNKNOWN, sans erreur")
    void intentionIllisible_unknown() {
        User user = testData.user();

        assertThat(acheter(user, testData.plan(), "pas-un-uuid", null).getOrigin())
                .isEqualTo(PurchaseOrigin.UNKNOWN);
    }

    @Test
    @DisplayName("Le parcours d'un autre compte est ignoré : ni parcours, ni run ; CTA du Plan → UNKNOWN")
    void parcoursDUnAutreCompte_ignore() {
        User user = testData.user();
        Plan plan = testData.plan();
        Parcours autrui = parcoursFondeParUnDiagnostic(testData.user());
        UUID intent = intention(user, plan, "LOCKED_PLAN", autrui.journeyId());

        UserSubscription sub = acheter(user, plan, intent, null);

        assertThat(sub.getOrigin()).isEqualTo(PurchaseOrigin.UNKNOWN);
        assertThat(sub.getJourneyId()).isNull();
        assertThat(sub.getDiagnosticRunId()).isNull();
    }

    // ------------------------------------------------------------------------
    // POST /api/billing/purchase-intents — contrat gelé pour le lot 3
    // ------------------------------------------------------------------------

    @Test
    @DisplayName("POST /purchase-intents : 201, id + expiration à 24 h, produit résolu par SKU store")
    void endpoint_creeLIntention() throws Exception {
        User user = testData.user();
        Plan plan = testData.plan();
        plan.setAppleProductId("sku.apple." + UUID.randomUUID());
        em.flush();

        mvc.perform(post("/api/billing/purchase-intents")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user))
                        .header("X-Sejourfr-Client", "ios")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"productId\":\"" + plan.getAppleProductId()
                                + "\",\"ctaLocation\":\"LOCKED_PLAN\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.purchaseIntentId").isNotEmpty())
                .andExpect(jsonPath("$.expiresAt").isNotEmpty());

        em.flush();
        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM purchase_intent
                 WHERE user_id = ? AND product_id = ? AND cta_location = 'LOCKED_PLAN'
                   AND platform = 'IOS' AND consumed_at IS NULL
                   AND expires_at = created_at + interval '24 hours'""",
                Integer.class, user.getId(), plan.getCode())).isEqualTo(1);
    }

    @Test
    @DisplayName("POST /purchase-intents : produit inconnu → 404")
    void endpoint_produitInconnu_404() throws Exception {
        mvc.perform(post("/api/billing/purchase-intents")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(testData.user()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"productId\":\"INCONNU\",\"ctaLocation\":\"PRICING\"}"))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("POST /purchase-intents : emplacement de CTA hors liste → 400")
    void endpoint_ctaInconnu_400() throws Exception {
        Plan plan = testData.plan();
        mvc.perform(post("/api/billing/purchase-intents")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(testData.user()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"productId\":\"" + plan.getCode() + "\",\"ctaLocation\":\"BANNIERE\"}"))
                .andExpect(status().isBadRequest());
    }
}

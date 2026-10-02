package com.sejourfr.app.service.adminuser;

import com.sejourfr.app.dto.AuthenticatedUser;
import com.sejourfr.app.dto.SubscriptionStatusResponse;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.AdminAccessOperationType;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PlanPurchaseType;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.SubscriptionService;
import com.sejourfr.app.service.billing.SubscriptionStatusService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AccesAdminFixtures;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.test.web.servlet.MockMvc;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.function.Consumer;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 🛑 <b>Non-régression obligatoire</b> (GO §16 et §18) : SANS décision admin,
 * {@code /api/auth/me}, {@code /api/billing/subscription-status} et la réponse
 * de {@code verify-receipt} ({@link SubscriptionStatusService}, la construction
 * partagée) sont IDENTIQUES à ce que rendait le code d'avant V083.
 *
 * <p>« Avant » est le calcul historique recopié TEL QUEL ci-dessous
 * ({@link Historique}, figé le 2026-10-02 depuis {@code SubscriptionService} et
 * {@code BillingController}) : on compare des arbres JSON complets, sur une
 * matrice d'achats qui couvre empilement, remboursement, expiration,
 * résiliation, récurrent, Intégral + Civique et achat sans fin.
 *
 * <p>Second volet : AVEC décision, {@code /me} et {@code subscription-status}
 * disent la même chose (le mobile écrase l'un par l'autre au démarrage).
 */
class AccesEffectifNonRegressionIT extends AbstractIntegrationTest {

    private static final Duration JOUR = Duration.ofDays(1);

    @Autowired private MockMvc mvc;
    @Autowired private TestData data;
    @Autowired private AuthTestSupport auth;
    @Autowired private ObjectMapper om;
    @Autowired private AccesAdminFixtures fx;
    @Autowired private PlanManager planManager;
    @Autowired private UserManager userManager;
    @Autowired private UserSubscriptionManager subscriptionManager;
    @Autowired private SubscriptionStatusService statusService;
    @Autowired private EntityManager em;

    // ------------------------------------------------- le calcul d'avant V083

    /** Copie conforme du calcul historique (sur les seuls achats). Ne pas « corriger ». */
    static final class Historique {

        static boolean couvre(UserSubscription s, Instant now) {
            return SubscriptionService.covers(s, now);
        }

        static ModuleAccess module(List<UserSubscription> subs, Instant now) {
            ModuleAccess best = ModuleAccess.NONE;
            for (UserSubscription s : subs) {
                if (!couvre(s, now)) continue;
                ModuleAccess access = s.getPlan().getModuleAccess();
                if (access == ModuleAccess.INTEGRAL
                        || (access == ModuleAccess.CIVIQUE && best == ModuleAccess.NONE)) {
                    best = access;
                }
            }
            return best;
        }

        static Instant finLaPlusTardive(List<UserSubscription> subs, Instant now) {
            Instant latest = null;
            for (UserSubscription s : subs) {
                if (!couvre(s, now)) continue;
                Instant e = s.getEndsAt();
                if (e != null && (latest == null || e.isAfter(latest))) latest = e;
            }
            return latest;
        }

        static Optional<UserSubscription> meilleure(List<UserSubscription> subs, Instant now) {
            UserSubscription best = null;
            for (UserSubscription s : subs) {
                if (!couvre(s, now)) continue;
                if (best == null || mieux(s, best)) best = s;
            }
            return Optional.ofNullable(best);
        }

        private static boolean mieux(UserSubscription c, UserSubscription i) {
            ModuleAccess ca = c.getPlan().getModuleAccess();
            ModuleAccess ia = i.getPlan().getModuleAccess();
            if (ca == ModuleAccess.INTEGRAL && ia != ModuleAccess.INTEGRAL) return true;
            if (ca != ModuleAccess.INTEGRAL && ia == ModuleAccess.INTEGRAL) return false;
            if (c.getEndsAt() == null) return i.getEndsAt() != null;
            if (i.getEndsAt() == null) return false;
            return c.getEndsAt().isAfter(i.getEndsAt());
        }

        /** {@code GET /api/realtime/eo/quota} d'avant V084 : le solde et l'allocation de l'achat courant. */
        static java.util.Map<String, Integer> quota(List<UserSubscription> subs, Instant now) {
            return meilleure(subs, now)
                    .map(sub -> java.util.Map.of(
                            "remaining", Math.max(0, sub.getRealtimeEoSessionsRemaining()),
                            "cap", Math.max(0, sub.getPlan().getRealtimeEoSessions())))
                    .orElse(java.util.Map.of("remaining", 0, "cap", 0));
        }

        /** {@code BillingController.getSubscriptionStatus} d'avant V083. */
        static SubscriptionStatusResponse statut(List<UserSubscription> subs, Instant now) {
            return meilleure(subs, now).map(sub -> {
                boolean oneTime = sub.getPlan().getPurchaseType() == PlanPurchaseType.ONE_TIME;
                int cap = Math.max(0, sub.getPlan().getRealtimeEoSessions());
                Integer restant = cap > 0 ? Math.max(0, sub.getRealtimeEoSessionsRemaining()) : null;
                return new SubscriptionStatusResponse(true, sub.getSource(), sub.getProductId(), sub.getEndsAt(),
                        sub.getStatus(), sub.getPlan().getModuleAccess(), sub.isAutoRenew(), oneTime, restant);
            }).orElseGet(SubscriptionStatusResponse::notPremium);
        }
    }

    // ------------------------------------------------------------- matrice

    private record Scenario(String nom, Consumer<User> achats) {}

    private UserSubscription achat(User u, ModuleAccess m, long debutJours, Long finJours,
                                   Consumer<UserSubscription> reglage) {
        Instant now = Instant.now();
        UserSubscription s = fx.achat(u, m, now.plus(JOUR.multipliedBy(debutJours)),
                finJours == null ? null : now.plus(JOUR.multipliedBy(finJours)));
        reglage.accept(s);
        return subscriptionManager.save(s);
    }

    private List<Scenario> matrice() {
        Consumer<UserSubscription> rien = s -> { };
        List<Scenario> l = new ArrayList<>();
        l.add(new Scenario("aucun achat", u -> { }));
        l.add(new Scenario("Civique seul", u -> achat(u, ModuleAccess.CIVIQUE, -3, 87L, rien)));
        l.add(new Scenario("Intégral seul avec solde EO", u -> achat(u, ModuleAccess.INTEGRAL, -3, 27L, s -> {
            s.getPlan().setRealtimeEoSessions(15);
            planManager.save(s.getPlan());
            s.setRealtimeEoSessionsRemaining(7);
        })));
        l.add(new Scenario("Civique (plus long) + Intégral", u -> {
            achat(u, ModuleAccess.CIVIQUE, -3, 300L, rien);
            achat(u, ModuleAccess.INTEGRAL, -3, 20L, rien);
        }));
        l.add(new Scenario("deux Intégral empilés", u -> {
            achat(u, ModuleAccess.INTEGRAL, -3, 27L, rien);
            achat(u, ModuleAccess.INTEGRAL, -1, 57L, rien);
        }));
        l.add(new Scenario("Intégral remboursé + Civique actif", u -> {
            achat(u, ModuleAccess.INTEGRAL, -3, 27L, s -> s.setStatus(SubscriptionStatus.REFUNDED));
            achat(u, ModuleAccess.CIVIQUE, -3, 87L, rien);
        }));
        l.add(new Scenario("achat expiré", u -> achat(u, ModuleAccess.INTEGRAL, -40, -10L, rien)));
        l.add(new Scenario("résilié, fin future", u ->
                achat(u, ModuleAccess.CIVIQUE, -3, 10L, s -> s.setStatus(SubscriptionStatus.CANCELED))));
        l.add(new Scenario("récurrent Apple", u -> achat(u, ModuleAccess.INTEGRAL, -3, 27L, s -> {
            s.setSource(SubscriptionSource.APPLE);
            s.setAutoRenew(true);
            s.getPlan().setPurchaseType(PlanPurchaseType.SUBSCRIPTION);
            planManager.save(s.getPlan());
        })));
        l.add(new Scenario("Intégral sans fin + Intégral fini", u -> {
            achat(u, ModuleAccess.INTEGRAL, -3, null, rien);
            achat(u, ModuleAccess.INTEGRAL, -3, 27L, rien);
        }));
        return l;
    }

    private JsonNode getJson(String url, User u) throws Exception {
        String body = mvc.perform(get(url).header(HttpHeaders.AUTHORIZATION, auth.bearer(u)))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return om.readTree(body);
    }

    @Test
    @DisplayName("Sans décision admin : /me, subscription-status et verify-receipt identiques au calcul d'avant V083")
    void sansDecisionReponsesIdentiques() throws Exception {
        for (Scenario sc : matrice()) {
            User u = data.user();
            sc.achats().accept(u);
            em.flush();
            em.clear();
            Instant now = Instant.now();
            List<UserSubscription> subs = subscriptionManager.findByUserId(u.getId());
            User recharge = userManager.findById(u.getId()).orElseThrow();

            JsonNode me = getJson("/api/auth/me", u);
            JsonNode attenduMe = om.valueToTree(AuthenticatedUser.from(recharge,
                    Historique.module(subs, now), Historique.finLaPlusTardive(subs, now)));
            assertThat(me).as("/me — %s", sc.nom()).isEqualTo(attenduMe);

            JsonNode statut = getJson("/api/billing/subscription-status", u);
            JsonNode attenduStatut = om.valueToTree(Historique.statut(subs, now));
            assertThat(statut).as("subscription-status — %s", sc.nom()).isEqualTo(attenduStatut);

            // verify-receipt rend la même construction après l'achat (ReceiptVerificationService.buildResponse).
            assertThat(om.valueToTree(statusService.statusFor(u.getId())).equals(attenduStatut))
                    .as("verify-receipt — %s", sc.nom()).isTrue();

            // V084 : sans décision, le quota EO temps réel est celui d'avant (forme et valeurs).
            JsonNode quota = getJson("/api/realtime/eo/quota", u);
            assertThat(quota).as("realtime/eo/quota — %s", sc.nom())
                    .isEqualTo(om.valueToTree(Historique.quota(subs, now)));
        }
    }

    @Test
    @DisplayName("V084 — GRANT Intégral avec 10 sessions offertes : même FORME pour le mobile, valeurs du GRANT")
    void grantAvecSessionsFormeInchangee() throws Exception {
        User admin = data.admin();
        User u = data.user();
        fx.agir(u, admin, AdminAccessOperationType.GRANT, ModuleAccess.INTEGRAL, null, null,
                AccesAdminFixtures.jour(20), 10);
        em.flush();

        JsonNode quota = getJson("/api/realtime/eo/quota", u);
        assertThat(quota.propertyNames()).containsExactlyInAnyOrder("remaining", "cap");
        assertThat(quota.get("remaining").asInt()).isEqualTo(10);
        assertThat(quota.get("cap").asInt()).isEqualTo(10);

        JsonNode statut = getJson("/api/billing/subscription-status", u);
        assertThat(statut.get("realtimeSessionsRemaining").asInt()).isEqualTo(10);
        assertThat(statut.get("moduleAccess").asString()).isEqualTo("INTEGRAL");
        // Aucun champ nouveau : les clés servies sont un sous-ensemble de celles du DTO d'avant.
        JsonNode reference = om.valueToTree(new SubscriptionStatusResponse(true, SubscriptionSource.STRIPE, "p",
                Instant.now(), SubscriptionStatus.ACTIVE, ModuleAccess.INTEGRAL, false, true, 1));
        assertThat(reference.propertyNames()).containsAll(statut.propertyNames());
    }

    @Test
    @DisplayName("GO §16 — avec un GRANT Intégral : /me et subscription-status disent la même chose")
    void avecGrantMemeAccesPartout() throws Exception {
        User admin = data.admin();
        User u = data.user();
        fx.achat(u, ModuleAccess.CIVIQUE, Instant.now().minus(JOUR), Instant.now().plus(JOUR.multipliedBy(60)));
        fx.agir(u, admin, AdminAccessOperationType.GRANT, ModuleAccess.INTEGRAL, null, null, AccesAdminFixtures.jour(20));
        em.flush();

        JsonNode me = getJson("/api/auth/me", u);
        JsonNode statut = getJson("/api/billing/subscription-status", u);

        assertThat(me.get("hasTcf").asBoolean()).isTrue();
        assertThat(me.get("hasCivique").asBoolean()).isTrue();
        assertThat(statut.get("moduleAccess").asString()).isEqualTo("INTEGRAL");
        assertThat(statut.get("status").asString()).isEqualTo("ACTIVE");
        assertThat(statut.get("oneTime").asBoolean()).isTrue();
        assertThat(statut.has("source")).as("origine admin : pas de source servie au mobile").isFalse();
        assertThat(statut.has("productId")).isFalse();
        assertThat(Instant.parse(statut.get("expiresAt").asString()))
                .isEqualTo(com.sejourfr.app.util.DateMetierParis.finExclusive(AccesAdminFixtures.jour(20)));
    }

    @Test
    @DisplayName("GO §16 — avec un REVOKE de l'achat : /me et subscription-status ferment tous les deux")
    void avecRevokeMemeAccesPartout() throws Exception {
        User admin = data.admin();
        User u = data.user();
        fx.achat(u, ModuleAccess.INTEGRAL, Instant.now().minus(JOUR), Instant.now().plus(JOUR.multipliedBy(25)));
        fx.agir(u, admin, AdminAccessOperationType.END, ModuleAccess.INTEGRAL, null, null, null);
        em.flush();

        JsonNode me = getJson("/api/auth/me", u);
        JsonNode statut = getJson("/api/billing/subscription-status", u);

        assertThat(me.get("hasTcf").asBoolean()).isFalse();
        assertThat(me.get("hasCivique").asBoolean()).isFalse();
        assertThat(statut).isEqualTo(om.valueToTree(SubscriptionStatusResponse.notPremium()));
    }
}

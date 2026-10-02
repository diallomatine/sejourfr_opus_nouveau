package com.sejourfr.app.support;

import com.sejourfr.app.dto.AdminAccessOperationRequest;
import com.sejourfr.app.dto.AdminAccessOperationResponse;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.AdminAccessOperationType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PaymentStatus;
import com.sejourfr.app.enums.PlanPurchaseType;
import com.sejourfr.app.enums.RealtimeSessionStatus;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.manager.RealtimeSessionManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.adminuser.AdminAccessOperationService;
import com.sejourfr.app.service.adminuser.AdminUserService;
import com.sejourfr.app.service.realtime.RealtimeQuotaService;
import com.sejourfr.app.util.DateMetierParis;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Fabriques du chantier « Admin / Gestion des utilisateurs » : des pass
 * one-time comme en production, des achats, et une action admin réelle
 * (service, avec l'état attendu lu sur la fiche).
 */
@RequiredArgsConstructor
public class AccesAdminFixtures {

    public static final String MOTIF = "Motif de test";

    private final TestData data;
    private final PlanManager planManager;
    private final UserSubscriptionManager subscriptionManager;
    private final AdminUserService adminUserService;
    private final AdminAccessOperationService operationService;
    private final RealtimeSessionManager realtimeSessionManager;
    private final JdbcTemplate jdbc;

    /** Un pass one-time inactif (hors catalogue publié). */
    public Plan pass(ModuleAccess module, int jours) {
        Plan p = data.plan(module);
        p.setName(module == ModuleAccess.INTEGRAL ? "Intégral — pass test" : "Civique — pass test");
        p.setPurchaseType(PlanPurchaseType.ONE_TIME);
        p.setDurationDays(jours);
        p.setActive(false);
        return planManager.save(p);
    }

    public UserSubscription achat(User u, ModuleAccess module, Instant debut, Instant fin) {
        return achat(u, pass(module, 30), debut, fin, SubscriptionSource.STRIPE);
    }

    public UserSubscription achat(User u, Plan plan, Instant debut, Instant fin, SubscriptionSource source) {
        UserSubscription s = new UserSubscription();
        s.setUser(u);
        s.setPlan(plan);
        s.setProductId(plan.getCode());
        s.setSource(source);
        s.setStatus(SubscriptionStatus.ACTIVE);
        s.setAutoRenew(false);
        s.setStartsAt(debut);
        s.setPurchasedAt(debut);
        s.setEndsAt(fin);
        s.setPaymentStatus(PaymentStatus.PAID);
        s.setOriginalTransactionId("cs_test_" + UUID.randomUUID());
        return subscriptionManager.save(s);
    }

    /**
     * Un achat Intégral payé 9,99 € dont le pass inclut {@code sessionsPass}
     * sessions EO temps réel et dont il reste {@code restantes}, clé
     * {@code original_transaction_id = cle} (ce que retrouvent les webhooks).
     */
    public UserSubscription achatIntegral(User u, SubscriptionSource source, String cle,
                                          int sessionsPass, int restantes) {
        Plan plan = pass(ModuleAccess.INTEGRAL, 30);
        plan.setRealtimeEoSessions(sessionsPass);
        planManager.save(plan);
        UserSubscription s = achat(u, plan, Instant.now().minusSeconds(3600),
                Instant.now().plusSeconds(86_400L * 30), source);
        s.setOriginalTransactionId(cle);
        s.setAmountCents(999);
        s.setCurrency("EUR");
        s.setRealtimeEoSessionsRemaining(restantes);
        return subscriptionManager.save(s);
    }

    /**
     * Une session temps réel PENDING réservée comme le fait
     * {@code RealtimeSessionService.start} : un seul porteur, celui que désigne
     * l'autorité du quota (GRANT d'abord, achat ensuite).
     */
    public RealtimeSession sessionReservee(User u, RealtimeQuotaService.Quota q) {
        RealtimeSession s = new RealtimeSession();
        s.setUser(u);
        s.setSubscription(q.achatPorteur().orElse(null));
        s.setAccessOverrideId(q.grantPorteur().map(com.sejourfr.app.entity.AccessOverride::getId).orElse(null));
        s.setEpreuve(EpreuveType.TCF_EO);
        s.setTacheNumero((short) 1);
        s.setProvider("gemini");
        s.setModel("test-model");
        s.setStatus(RealtimeSessionStatus.PENDING);
        return realtimeSessionManager.save(s);
    }

    /** Toutes les décisions d'un compte telles qu'en base (preuve « décision intacte »). */
    public List<Map<String, Object>> lignesDecisions(UUID userId) {
        return jdbc.queryForList("SELECT * FROM access_overrides WHERE user_id = ? ORDER BY id", userId);
    }

    /** Le journal des actions admin d'un compte tel qu'en base. */
    public List<Map<String, Object>> lignesJournal(UUID userId) {
        return jdbc.queryForList("SELECT * FROM admin_access_operations WHERE user_id = ? ORDER BY id", userId);
    }

    /** Le solde EO de la décision courante GRANT INTEGRAL qui couvre maintenant (0 si aucune). */
    public int soldeGrantCourant(UUID userId) {
        Integer n = jdbc.queryForObject("SELECT COALESCE(SUM(realtime_eo_sessions_remaining), 0) FROM access_overrides "
                + "WHERE user_id = ? AND superseded_at IS NULL AND type = 'GRANT' AND product = 'INTEGRAL' "
                + "AND starts_at <= clock_timestamp() AND ends_at > clock_timestamp()", Integer.class, userId);
        return n == null ? 0 : n;
    }

    /** Aujourd'hui (Paris) + {@code jours}. */
    public static LocalDate jour(int jours) {
        return DateMetierParis.aujourdhui(Instant.now()).plusDays(jours);
    }

    /** Une action admin RÉELLE (non dryRun), avec l'état attendu lu sur la fiche. */
    public AdminAccessOperationResponse agir(User cible, User admin, AdminAccessOperationType op,
                                             ModuleAccess produit, ModuleAccess depuis,
                                             LocalDate debut, LocalDate fin) {
        return agir(cible, admin, op, produit, depuis, debut, fin, null);
    }

    /** Idem, en offrant {@code sessionsEo} sessions EO temps réel (V084). */
    public AdminAccessOperationResponse agir(User cible, User admin, AdminAccessOperationType op,
                                             ModuleAccess produit, ModuleAccess depuis,
                                             LocalDate debut, LocalDate fin, Integer sessionsEo) {
        String version = adminUserService.detail(cible.getId()).accessVersion();
        return operationService.executer(cible.getId(), admin.getId(), new AdminAccessOperationRequest(
                op, produit, depuis, debut, fin, MOTIF, false, version, sessionsEo));
    }

    /** L'aperçu ({@code dryRun}) d'une action, sans rien écrire. */
    public AdminAccessOperationResponse apercu(User cible, User admin, AdminAccessOperationType op,
                                               ModuleAccess produit, ModuleAccess depuis,
                                               LocalDate debut, LocalDate fin, Integer sessionsEo) {
        return operationService.executer(cible.getId(), admin.getId(), new AdminAccessOperationRequest(
                op, produit, depuis, debut, fin, MOTIF, true, null, sessionsEo));
    }

    /** La ligne d'achat telle qu'en base, toutes colonnes (preuve « achat intact »). */
    public Map<String, Object> ligneAchat(UUID id) {
        return jdbc.queryForMap("SELECT * FROM user_subscriptions WHERE id = ?", id);
    }

    public int decisionsCourantes(UUID userId) {
        Integer n = jdbc.queryForObject(
                "SELECT count(*) FROM access_overrides WHERE user_id = ? AND superseded_at IS NULL",
                Integer.class, userId);
        return n == null ? 0 : n;
    }
}

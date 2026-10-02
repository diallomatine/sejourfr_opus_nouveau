package com.sejourfr.app.support;

import com.sejourfr.app.dto.AdminAccessOperationRequest;
import com.sejourfr.app.dto.AdminAccessOperationResponse;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.AdminAccessOperationType;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PaymentStatus;
import com.sejourfr.app.enums.PlanPurchaseType;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.adminuser.AdminAccessOperationService;
import com.sejourfr.app.service.adminuser.AdminUserService;
import com.sejourfr.app.util.DateMetierParis;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;

import java.time.Instant;
import java.time.LocalDate;
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

    /** Aujourd'hui (Paris) + {@code jours}. */
    public static LocalDate jour(int jours) {
        return DateMetierParis.aujourdhui(Instant.now()).plusDays(jours);
    }

    /** Une action admin RÉELLE (non dryRun), avec l'état attendu lu sur la fiche. */
    public AdminAccessOperationResponse agir(User cible, User admin, AdminAccessOperationType op,
                                             ModuleAccess produit, ModuleAccess depuis,
                                             LocalDate debut, LocalDate fin) {
        String version = adminUserService.detail(cible.getId()).accessVersion();
        return operationService.executer(cible.getId(), admin.getId(), new AdminAccessOperationRequest(
                op, produit, depuis, debut, fin, MOTIF, false, version));
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

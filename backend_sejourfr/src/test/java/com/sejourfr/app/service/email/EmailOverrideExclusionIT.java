package com.sejourfr.app.service.email;

import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PlanPurchaseType;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.email.automation.EmailAutomationService;
import com.sejourfr.app.support.AbstractEmailIT;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * G-6 (GO §9) : un compte qui porte une décision admin courante est exclu des
 * scénarios Premium fondés sur les seuls achats — il ne reçoit ni « jamais
 * Premium », ni « votre accès se termine ». Le témoin sans décision, lui, les
 * reçoit (même fenêtre, même horloge).
 */
class EmailOverrideExclusionIT extends AbstractEmailIT {

    /** Un an devant, comme EmailAutomationIT : hors de toutes les fenêtres des autres données. */
    private static final Instant T = java.time.LocalDate.now(java.time.ZoneOffset.UTC).plusDays(365)
            .atTime(8, 0).toInstant(java.time.ZoneOffset.UTC);
    private static final Duration JOUR = Duration.ofDays(1);

    @Autowired private EmailAutomationService automation;
    @Autowired private PlanManager planManager;
    @Autowired private UserSubscriptionManager subscriptionManager;

    private void passage(Instant at) {
        clock.set(at);
        automation.runDaily(at);
        awaitEmailExecutorIdle();
    }

    private User compte(Instant createdAt) {
        User u = user();
        jdbc.update("UPDATE users SET created_at = ? WHERE id = ?", Timestamp.from(createdAt), u.getId());
        return u;
    }

    /** Décision admin posée en SQL (le compte est son propre auteur : le nettoyage reste trivial). */
    private void decision(User u, String type, Instant debut, Instant fin) {
        UUID op = UUID.randomUUID();
        jdbc.update("INSERT INTO admin_access_operations (id, user_id, admin_user_id, operation, product, reason, "
                + "before_state, after_state) VALUES (?, ?, ?, 'GRANT', 'CIVIQUE', 'Motif de test', '[]', '[]')",
                op, u.getId(), u.getId());
        jdbc.update("INSERT INTO access_overrides (id, user_id, product, type, starts_at, ends_at, decided_at, reason, "
                        + "created_by, operation_id) VALUES (?, ?, 'CIVIQUE', ?, ?, ?, ?, 'Motif de test', ?, ?)",
                UUID.randomUUID(), u.getId(), type, Timestamp.from(debut), fin == null ? null : Timestamp.from(fin),
                Timestamp.from(debut), u.getId(), op);
    }

    private UserSubscription pass(User u, Instant debut, Instant fin) {
        Plan p = data.plan(ModuleAccess.CIVIQUE);
        p.setName("Civique — pass 1 mois");
        p.setPurchaseType(PlanPurchaseType.ONE_TIME);
        p.setActive(false);
        trackPlan(planManager.save(p));
        UserSubscription s = data.userSubscription(u, p);
        s.setAutoRenew(false);
        s.setStartsAt(debut);
        s.setEndsAt(fin);
        return subscriptionManager.save(s);
    }

    private boolean recu(User u, EmailType type) {
        return rowsOf(u, type).stream().anyMatch(d -> d.getStatus() == com.sejourfr.app.enums.EmailDeliveryStatus.SENT);
    }

    @Test
    @DisplayName("Jamais Premium par achat mais accès accordé par l'admin : pas de NO_PREMIUM_AFTER_7_DAYS")
    void grantExclutJamaisPremium() {
        User temoin = compte(T.minus(JOUR.multipliedBy(8)));
        User accorde = compte(T.minus(JOUR.multipliedBy(8)));
        decision(accorde, "GRANT", T.minus(JOUR.multipliedBy(2)), T.plus(JOUR.multipliedBy(20)));

        passage(T);

        assertThat(recu(temoin, EmailType.NO_PREMIUM_AFTER_7_DAYS)).isTrue();
        assertThat(recu(accorde, EmailType.NO_PREMIUM_AFTER_7_DAYS)).isFalse();
    }

    @Test
    @DisplayName("Pass qui se termine mais accès révoqué par l'admin : pas de PREMIUM_ENDING_2_DAYS")
    void revokeExclutFinDAcces() {
        User temoin = compte(T.minus(JOUR.multipliedBy(40)));
        User revoque = compte(T.minus(JOUR.multipliedBy(40)));
        pass(temoin, T.minus(JOUR.multipliedBy(30)), T.plus(JOUR));
        pass(revoque, T.minus(JOUR.multipliedBy(30)), T.plus(JOUR));
        decision(revoque, "REVOKE", T.minus(JOUR.multipliedBy(3)), null);

        passage(T);

        assertThat(recu(temoin, EmailType.PREMIUM_ENDING_2_DAYS)).isTrue();
        assertThat(rowsOf(revoque)).isEmpty();
    }
}

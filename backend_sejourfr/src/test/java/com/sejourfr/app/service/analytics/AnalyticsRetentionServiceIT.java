package com.sejourfr.app.service.analytics;

import com.sejourfr.app.entity.DiagnosticRun;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AnalyticsDeviceType;
import com.sejourfr.app.enums.AnalyticsEvent;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.DiagnosticRunType;
import com.sejourfr.app.manager.AnalyticsEventManager;
import com.sejourfr.app.manager.AnalyticsIdentityManager;
import com.sejourfr.app.manager.AnalyticsVisitorManager;
import com.sejourfr.app.manager.DiagnosticRunManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Retention des donnees de mesure brutes (Q5, 395 j) : condition de
 * l'exemption CNIL. Les faits metier ne perdent rien.
 */
class AnalyticsRetentionServiceIT extends AbstractIntegrationTest {

    private static final Instant MAINTENANT = Instant.parse("2027-10-01T02:00:00Z");

    @Autowired private AnalyticsRetentionService retention;
    @Autowired private AnalyticsConfig config;
    @Autowired private TestData testData;
    @Autowired private AnalyticsEventManager eventManager;
    @Autowired private AnalyticsVisitorManager visitorManager;
    @Autowired private AnalyticsIdentityManager identityManager;
    @Autowired private DiagnosticRunManager diagnosticRunManager;
    @Autowired private EntityManager em;

    private UUID visiteurVuLe(Instant quand) {
        UUID anon = testData.analyticsVisitor("tiktok", "FR", AnalyticsDeviceType.MOBILE_WEB,
                ClientPlatform.WEB, quand);
        testData.analyticsEvent(anon, AnalyticsEvent.LANDING_VIEWED, quand);
        return anon;
    }

    @Test
    @DisplayName("Au-delà de 395 j : événements et visiteur inactif purgés ; en deçà, tout reste")
    void purgeLaRetention() {
        Instant limite = MAINTENANT.minus(Duration.ofDays(config.rawEventRetentionDays()));
        UUID ancien = visiteurVuLe(limite.minus(Duration.ofDays(1)));
        UUID recent = visiteurVuLe(limite.plus(Duration.ofDays(1)));

        User compte = testData.user();
        identityManager.link(ancien, compte.getId());

        // Un fait du tunnel porte l'identifiant du visiteur purge : il SURVIT.
        DiagnosticRun run = new DiagnosticRun();
        run.setId(UUID.randomUUID());
        run.setDiagnosticType(DiagnosticRunType.CIVIQUE);
        run.setAnonymousId(ancien);
        run.setSubjectViewedAt(limite.minus(Duration.ofDays(2)));
        run.setUpdatedAt(limite.minus(Duration.ofDays(2)));
        diagnosticRunManager.save(run);
        em.flush();

        int purges = retention.purge(MAINTENANT);

        assertThat(purges).isEqualTo(2);
        assertThat(eventManager.countForVisitor(ancien)).isZero();
        assertThat(visitorManager.findById(ancien)).isEmpty();
        assertThat(identityManager.countForUser(compte.getId())).isZero();

        assertThat(eventManager.countForVisitor(recent)).isEqualTo(1);
        assertThat(visitorManager.findById(recent)).isPresent();

        em.clear();
        assertThat(em.find(DiagnosticRun.class, run.getId())).isNotNull();
    }

    /** Un visiteur ancien mais revenu recemment n'est pas purge : on balaie la derniere activite. */
    @Test
    @DisplayName("Un visiteur revenu récemment garde son identifiant ; seuls ses vieux gestes partent")
    void visiteurActifConserve() {
        Instant limite = MAINTENANT.minus(Duration.ofDays(config.rawEventRetentionDays()));
        UUID fidele = visiteurVuLe(limite.minus(Duration.ofDays(30)));
        testData.analyticsEvent(fidele, AnalyticsEvent.PRICING_VIEWED, limite.plus(Duration.ofDays(10)));
        visitorManager.touch(fidele, limite.plus(Duration.ofDays(10)),
                new AnalyticsVisitorManager.Attribution("tiktok", null, null, null, null, "/reussir", null, null),
                false, "FR", AnalyticsDeviceType.MOBILE_WEB, ClientPlatform.WEB);

        retention.purge(MAINTENANT);

        assertThat(visitorManager.findById(fidele)).isPresent();
        assertThat(eventManager.countForVisitor(fidele)).isEqualTo(1);
    }

    @Test
    @DisplayName("La purge avance par lots bornés jusqu'à épuisement")
    void parLots() {
        Instant vieux = MAINTENANT.minus(Duration.ofDays(config.rawEventRetentionDays() + 5L));
        UUID anon = visiteurVuLe(vieux);
        for (int i = 0; i < 3; i++) testData.analyticsEvent(anon, AnalyticsEvent.PRICING_VIEWED, vieux);

        AnalyticsRetentionService petitsLots = new AnalyticsRetentionService(eventManager, visitorManager,
                new AnalyticsConfig(config.analyticsConfigVersion(), config.timezone(), config.cohortWindowDays(),
                        config.claimTokenTtlDays(), config.purchaseIntentTtlHours(), config.anonymousIdTtlDays(),
                        config.rawEventRetentionDays(), 2, config.ingestion(), config.utmSourceGroups(),
                        config.utmSourceFallbackGroup(), config.measurementStart()));

        assertThat(petitsLots.purge(MAINTENANT)).isEqualTo(5);
        assertThat(visitorManager.findById(anon)).isEmpty();
    }
}

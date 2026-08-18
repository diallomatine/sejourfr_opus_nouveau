package com.sejourfr.app.manager;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.FunnelEvent;
import com.sejourfr.app.service.AccountDeletionService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

/**
 * Postgres embarqué, vraies migrations : c'est la contrainte
 * {@code uq_user_funnel_event} qui est vérifiée ici, pas une intention Java.
 */
class UserFunnelEventManagerIT extends AbstractIntegrationTest {

    @Autowired
    private UserFunnelEventManager manager;
    @Autowired
    private TestData testData;
    @Autowired
    private AccountDeletionService accountDeletionService;

    /**
     * L'unicité est ce qui borne la table à 3 lignes par compte, et donc ce qui
     * rend l'endpoint d'écriture sûr sans rate-limit.
     */
    @Test
    void seuleLaPremiereOccurrenceEstEcrite_etUnRejeuNeLevePas() {
        User user = testData.user();

        assertThat(manager.recordFirstOccurrence(
                user.getId(), FunnelEvent.PAYWALL_VIEWED, ClientPlatform.WEB, "tiktok")).isTrue();

        assertThatCode(() -> {
            assertThat(manager.recordFirstOccurrence(
                    user.getId(), FunnelEvent.PAYWALL_VIEWED, ClientPlatform.MOBILE, "instagram"))
                    .isFalse();
            assertThat(manager.recordFirstOccurrence(
                    user.getId(), FunnelEvent.PAYWALL_VIEWED, ClientPlatform.WEB, "tiktok"))
                    .isFalse();
        }).doesNotThrowAnyException();

        assertThat(manager.countForUser(user.getId())).isEqualTo(1);
    }

    @Test
    void unCompteNePorteJamaisPlusDeTroisLignes() {
        User user = testData.user();

        for (int pass = 0; pass < 3; pass++) {
            for (FunnelEvent event : FunnelEvent.values()) {
                manager.recordFirstOccurrence(user.getId(), event, ClientPlatform.WEB, "tiktok");
            }
        }

        assertThat(manager.countForUser(user.getId())).isEqualTo(FunnelEvent.values().length);
    }

    @Test
    void deuxComptesNeSeGenentPas() {
        User first = testData.user();
        User second = testData.user();

        manager.recordFirstOccurrence(
                first.getId(), FunnelEvent.PAYWALL_VIEWED, ClientPlatform.WEB, "tiktok");
        assertThat(manager.recordFirstOccurrence(
                second.getId(), FunnelEvent.PAYWALL_VIEWED, ClientPlatform.WEB, "tiktok")).isTrue();

        assertThat(manager.countForUser(first.getId())).isEqualTo(1);
        assertThat(manager.countForUser(second.getId())).isEqualTo(1);
    }

    /**
     * La suppression de compte est une ANONYMISATION : la ligne {@code users}
     * survit, donc la cascade base ne se déclenche pas. La purge doit être
     * explicite, sinon les étapes de funnel survivraient à la personne.
     */
    @Test
    void laSuppressionDeCompteEmporteLesEtapesDeFunnel() {
        User user = testData.user();
        manager.recordFirstOccurrence(
                user.getId(), FunnelEvent.PAYWALL_VIEWED, ClientPlatform.WEB, "tiktok");
        manager.recordFirstOccurrence(
                user.getId(), FunnelEvent.SUBSCRIBE_CLICKED, ClientPlatform.WEB, "tiktok");
        assertThat(manager.countForUser(user.getId())).isEqualTo(2);

        accountDeletionService.deleteAccount(user.getId());

        assertThat(manager.countForUser(user.getId())).isZero();
    }

    /** Le contexte du moment est facultatif : on n'invente pas de plateforme. */
    @Test
    void unContexteAbsentEstAccepte() {
        User user = testData.user();

        assertThat(manager.recordFirstOccurrence(
                user.getId(), FunnelEvent.PAYWALL_VIEWED, null, null)).isTrue();
        assertThat(manager.countForUser(user.getId())).isEqualTo(1);
    }
}

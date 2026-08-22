package com.sejourfr.app.manager;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AnalyticsDeviceType;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

/**
 * La fusion anonyme -> compte, contre la vraie base.
 *
 * <p>Ce qui est verrouille ici, c'est que cette ecriture <b>ne peut pas casser
 * une connexion</b> : elle a lieu pendant un login, et une mesure d'audience n'a
 * jamais le droit d'empecher quelqu'un d'entrer chez lui.
 */
class AnalyticsIdentityManagerIT extends AbstractIntegrationTest {

    @Autowired
    private AnalyticsIdentityManager identityManager;
    @Autowired
    private AnalyticsVisitorManager visitorManager;
    @Autowired
    private TestData testData;

    private UUID visiteur() {
        UUID anonymousId = UUID.randomUUID();
        visitorManager.touch(anonymousId, Instant.now(),
                new AnalyticsVisitorManager.Attribution("tiktok", null, null, null, null, "/reussir", null),
                true, "FR", AnalyticsDeviceType.MOBILE_WEB, ClientPlatform.WEB);
        return anonymousId;
    }

    @Test
    @DisplayName("Le lien est posé une fois, et les rejeux ne créent rien")
    void idempotent() {
        User user = testData.user();
        UUID anonymousId = visiteur();

        assertThat(identityManager.link(anonymousId, user.getId())).isTrue();
        assertThat(identityManager.link(anonymousId, user.getId())).isFalse();
        assertThat(identityManager.link(anonymousId, user.getId())).isFalse();

        assertThat(identityManager.countForUser(user.getId())).isEqualTo(1);
    }

    /**
     * Un appareil partage — un poste de mediatheque, un telephone familial —
     * porte legitimement deux comptes. C'est precisement pour ca que ce n'est
     * pas une colonne sur le visiteur : une colonne obligerait a en ecraser un.
     */
    @Test
    @DisplayName("Un même appareil peut porter deux comptes")
    void appareilPartage() {
        UUID anonymousId = visiteur();
        User premier = testData.user("premier@analytics.test");
        User second = testData.user("second@analytics.test");

        assertThat(identityManager.link(anonymousId, premier.getId())).isTrue();
        assertThat(identityManager.link(anonymousId, second.getId())).isTrue();

        assertThat(identityManager.countForUser(premier.getId())).isEqualTo(1);
        assertThat(identityManager.countForUser(second.getId())).isEqualTo(1);
    }

    /**
     * 🛑 Le cas qui compte : un client envoie un identifiant dont AUCUN evenement
     * n'est jamais arrive (navigation privee, requete perdue, identifiant
     * fabrique). La cle etrangere echouerait et empoisonnerait la transaction du
     * login. Ici, on n'ecrit simplement rien.
     */
    @Test
    @DisplayName("Un visiteur inconnu n'écrit rien et ne lève surtout pas")
    void visiteurInconnuNeLevePas() {
        User user = testData.user();
        UUID jamaisVu = UUID.randomUUID();

        assertThatCode(() -> assertThat(identityManager.link(jamaisVu, user.getId())).isFalse())
                .doesNotThrowAnyException();
        assertThat(identityManager.countForUser(user.getId())).isZero();
    }

    @Test
    @DisplayName("Un compte inconnu n'écrit rien non plus")
    void compteInconnuNeLevePas() {
        UUID anonymousId = visiteur();
        UUID compteFantome = UUID.randomUUID();
        assertThatCode(() -> assertThat(identityManager.link(anonymousId, compteFantome)).isFalse())
                .doesNotThrowAnyException();
    }

    /**
     * L'anonymisation laisse la ligne {@code users} en place : la cascade base ne
     * part pas, la purge doit etre explicite (meme raison que
     * {@code user_funnel_events}).
     */
    @Test
    @DisplayName("La purge d'un compte retire ses liens")
    void purgeExplicite() {
        User user = testData.user();
        UUID anonymousId = visiteur();
        identityManager.link(anonymousId, user.getId());

        assertThat(identityManager.deleteByUserId(user.getId())).isEqualTo(1);
        assertThat(identityManager.countForUser(user.getId())).isZero();
    }
}

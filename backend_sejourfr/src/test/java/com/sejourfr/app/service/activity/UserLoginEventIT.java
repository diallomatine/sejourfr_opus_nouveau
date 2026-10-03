package com.sejourfr.app.service.activity;

import com.sejourfr.app.dto.LoginRequest;
import com.sejourfr.app.dto.RefreshRequest;
import com.sejourfr.app.dto.RegisterRequest;
import com.sejourfr.app.dto.TokenResponse;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserLoginEvent;
import com.sejourfr.app.enums.AuthKind;
import com.sejourfr.app.enums.AuthProvider;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.manager.UserLoginEventManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.AuthService;
import com.sejourfr.app.support.AbstractEmailIT;
import com.sejourfr.app.support.TestData;
import com.sejourfr.app.util.ClientContext;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Journal des connexions (lot 2, D4) a travers le vrai {@link AuthService},
 * <b>hors transaction de test</b> : l'ecriture part apres le commit de
 * l'authentification ({@code ApresCommit}), dans sa propre transaction. Les
 * branches Google et Apple (methode de CETTE connexion) sont verrouillees par
 * {@code SocialAuthServiceTest} : leurs verifieurs exigent un fournisseur reel.
 */
class UserLoginEventIT extends AbstractEmailIT {

    private static final Instant T0 = Instant.parse("2026-10-03T08:00:00Z");

    @Autowired private AuthService authService;
    @Autowired private UserLoginEventManager loginEvents;
    @Autowired private UserManager userManager;

    private static ClientContext client(ClientPlatform platform) {
        return new ClientContext(platform, "direct");
    }

    private List<UserLoginEvent> evenements(User user) {
        return loginEvents.findByUserId(user.getId());
    }

    @Test
    @DisplayName("Inscription : une ligne SIGNUP / LOCAL / plateforme déclarée ; connexion : une ligne LOGIN")
    void inscriptionPuisConnexion() {
        clock.set(T0);
        String email = "journal" + System.nanoTime() + "@test.sejourfr";
        authService.register(new RegisterRequest(email, TestData.DEFAULT_PASSWORD, "Awa", "Diallo", null, null,
                null, null, null, null), "ua", "ip", client(ClientPlatform.IOS));
        User user = track(userManager.findByEmail(email).orElseThrow());

        List<UserLoginEvent> apresInscription = evenements(user);
        assertThat(apresInscription).hasSize(1);
        assertThat(apresInscription.getFirst().getKind()).isEqualTo(AuthKind.SIGNUP);
        assertThat(apresInscription.getFirst().getAuthMethod()).isEqualTo(AuthProvider.LOCAL);
        assertThat(apresInscription.getFirst().getPlatform()).isEqualTo(ClientPlatform.IOS);
        assertThat(apresInscription.getFirst().getOccurredAt()).isEqualTo(T0);

        authService.login(new LoginRequest(email, TestData.DEFAULT_PASSWORD, null, null, null, null, null), "ua",
                "ip", client(ClientPlatform.MOBILE));

        List<UserLoginEvent> apresConnexion = evenements(user);
        assertThat(apresConnexion).hasSize(2);
        assertThat(apresConnexion).extracting(UserLoginEvent::getKind)
                .containsExactlyInAnyOrder(AuthKind.SIGNUP, AuthKind.LOGIN);
        assertThat(apresConnexion).filteredOn(e -> e.getKind() == AuthKind.LOGIN)
                .extracting(UserLoginEvent::getPlatform).containsExactly(ClientPlatform.MOBILE);
    }

    @Test
    @DisplayName("Un refresh n'écrit jamais de connexion (D4) ; sans contexte, la plateforme est UNKNOWN")
    void refreshNEcritRien() {
        User user = user();
        TokenResponse tokens = authService.login(new LoginRequest(user.getEmail(), TestData.DEFAULT_PASSWORD, null,
                null, null, null, null), "ua", "ip", null);
        assertThat(evenements(user)).hasSize(1);
        assertThat(evenements(user).getFirst().getPlatform()).isEqualTo(ClientPlatform.UNKNOWN);

        authService.refresh(new RefreshRequest(tokens.refreshToken()), "ua", "ip");
        authService.logout(tokens.refreshToken());

        assertThat(evenements(user)).hasSize(1);
    }

    @Test
    @DisplayName("Une connexion qui échoue n'écrit rien")
    void echecDeConnexion() {
        User user = user();
        try {
            authService.login(new LoginRequest(user.getEmail(), "mauvais-mot-de-passe", null, null, null, null, null),
                    "ua", "ip", null);
        } catch (RuntimeException attendu) {
            // identifiants invalides
        }
        assertThat(evenements(user)).isEmpty();
    }
}

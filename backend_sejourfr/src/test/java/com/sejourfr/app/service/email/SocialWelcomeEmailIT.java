package com.sejourfr.app.service.email;

import com.sejourfr.app.dto.GoogleSignInRequest;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EmailDeliveryStatus;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.SocialAuthService;
import com.sejourfr.app.service.social.GoogleTokenVerifier;
import com.sejourfr.app.service.social.SocialIdentity;
import com.sejourfr.app.support.AbstractEmailIT;
import com.sejourfr.app.support.EmailTestSupport;
import com.sejourfr.app.util.ClientContext;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * Le second point de publication de WELCOME : la branche CREATION du sign-in
 * social. Complement D : chaque chemin est prouve dans une vraie transaction.
 */
class SocialWelcomeEmailIT extends AbstractEmailIT {

    @Autowired private SocialAuthService socialAuthService;
    @Autowired private UserManager userManager;
    @MockitoBean private GoogleTokenVerifier googleVerifier;

    @Test
    @DisplayName("Premier sign-in Google : WELCOME apres commit ; une reconnexion n'envoie rien")
    void creationSocialeEnvoieBienvenue() {
        SocialIdentity id = data.socialIdentity();
        when(googleVerifier.verify("tok")).thenReturn(id);

        socialAuthService.loginWithGoogle(new GoogleSignInRequest("tok", null, null, null), "ua", "127.0.0.1",
                ClientContext.unknown());
        User u = track(userManager.findByEmail(id.email()).orElseThrow());

        EmailTestSupport.await("WELCOME envoye", () -> hasStatus(u, EmailType.WELCOME, EmailDeliveryStatus.SENT));

        socialAuthService.loginWithGoogle(new GoogleSignInRequest("tok", null, null, null), "ua", "127.0.0.1",
                ClientContext.unknown());
        EmailTestSupport.settle();
        awaitEmailExecutorIdle();

        assertThat(mails.sentTo(id.email())).hasSize(1);
        assertThat(rowsOf(u, EmailType.WELCOME)).hasSize(1);
    }
}

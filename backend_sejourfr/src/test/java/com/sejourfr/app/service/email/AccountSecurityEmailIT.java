package com.sejourfr.app.service.email;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EmailDeliveryStatus;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.AuthService;
import com.sejourfr.app.service.UserProfileService;
import com.sejourfr.app.support.AbstractEmailIT;
import com.sejourfr.app.support.EmailTestSupport;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Les mails de securite de bout en bout : reinitialisation, mot de passe change
 * (les DEUX chemins, arbitrage n°8), confirmation d'une nouvelle adresse, et
 * l'ANCIENNE adresse prevenue (arbitrage n°10).
 */
class AccountSecurityEmailIT extends AbstractEmailIT {

    @Autowired private AuthService authService;
    @Autowired private UserProfileService userProfileService;
    @Autowired private UserManager userManager;

    private static String token(String url) {
        return url.substring(url.indexOf("token=") + "token=".length());
    }

    @Test
    @DisplayName("Reset demande puis applique : PASSWORD_RESET (lien a jeton) puis PASSWORD_CHANGED")
    void resetPuisChangement() {
        User u = user();

        authService.requestPasswordReset(u.getEmail());
        EmailTestSupport.await("PASSWORD_RESET", () -> hasStatus(u, EmailType.PASSWORD_RESET, EmailDeliveryStatus.SENT));
        EmailMessage reset = mails.sentOfType(EmailType.PASSWORD_RESET).stream()
                .filter(m -> m.recipient().equals(u.getEmail())).findFirst().orElseThrow();
        assertThat(reset.variables().get("resetUrl")).contains("/reinitialiser-mot-de-passe?token=");
        assertThat(reset.variables()).containsEntry("expiresInMinutes", "60");
        assertThat(reset.toString()).doesNotContain(token(reset.variables().get("resetUrl")));

        authService.resetPassword(token(reset.variables().get("resetUrl")), "NouveauMotDePasse1");

        EmailTestSupport.await("PASSWORD_CHANGED", () -> hasStatus(u, EmailType.PASSWORD_CHANGED, EmailDeliveryStatus.SENT));
        assertThat(rowsOf(u, EmailType.PASSWORD_CHANGED)).singleElement()
                .satisfies(d -> assertThat(d.getOccurredAt()).isNotNull());
    }

    @Test
    @DisplayName("Changement connecte du mot de passe : PASSWORD_CHANGED avec l'heure du changement")
    void changementConnecte() {
        User u = user();

        userProfileService.changePassword(u.getId(), TestData.DEFAULT_PASSWORD, "UnAutreMotDePasse9");

        EmailTestSupport.await("PASSWORD_CHANGED", () -> hasStatus(u, EmailType.PASSWORD_CHANGED, EmailDeliveryStatus.SENT));
        EmailMessage m = mails.sentOfType(EmailType.PASSWORD_CHANGED).stream()
                .filter(x -> x.recipient().equals(u.getEmail())).findFirst().orElseThrow();
        assertThat(m.variables().get("changedAt")).contains(" à ");
        assertThat(m.variables().get("supportUrl")).endsWith("/contact");
    }

    @Test
    @DisplayName("Changement d'adresse : lien vers la NOUVELLE adresse, puis l'ANCIENNE est prevenue")
    void changementDAdresse() {
        User u = user();
        String ancienne = u.getEmail();
        String nouvelle = trackRecipient("nouvelle-" + UUID.randomUUID() + "@test.sejourfr");

        userProfileService.requestEmailChange(u.getId(), nouvelle, TestData.DEFAULT_PASSWORD);
        EmailTestSupport.await("EMAIL_CHANGE_CONFIRMATION",
                () -> hasStatus(u, EmailType.EMAIL_CHANGE_CONFIRMATION, EmailDeliveryStatus.SENT));
        EmailMessage confirmation = mails.sentTo(nouvelle).getFirst();
        assertThat(confirmation.type()).isEqualTo(EmailType.EMAIL_CHANGE_CONFIRMATION);

        userProfileService.confirmEmailChange(token(confirmation.variables().get("confirmUrl")));

        EmailTestSupport.await("EMAIL_CHANGED", () -> hasStatus(u, EmailType.EMAIL_CHANGED, EmailDeliveryStatus.SENT));
        EmailMessage prevenue = mails.sentTo(ancienne).stream()
                .filter(m -> m.type() == EmailType.EMAIL_CHANGED).findFirst().orElseThrow();
        assertThat(prevenue.variables().get("newEmailMasked")).startsWith("n***@").doesNotContain(nouvelle);
        assertThat(userManager.findById(u.getId()).orElseThrow().getEmail()).isEqualTo(nouvelle);
    }

    @Test
    @DisplayName("SMTP en panne sur un reset : FAILED, et la demande a quand meme reussi")
    void resetSmtpEnPanne() {
        User u = user();
        mails.failNext(100);

        authService.requestPasswordReset(u.getEmail());

        EmailTestSupport.await("PASSWORD_RESET en echec", () -> hasStatus(u, EmailType.PASSWORD_RESET, EmailDeliveryStatus.FAILED));
        assertThat(jdbc.queryForObject("SELECT count(*) FROM password_reset_tokens WHERE user_id = ?",
                Long.class, u.getId())).isEqualTo(1);
    }
}

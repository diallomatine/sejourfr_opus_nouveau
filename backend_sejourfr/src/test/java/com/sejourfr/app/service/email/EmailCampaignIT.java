package com.sejourfr.app.service.email;

import com.sejourfr.app.config.EmailProperties;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EmailDeliveryStatus;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.support.AbstractEmailIT;
import com.sejourfr.app.support.AuthTestSupport;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Campagnes de service : {@code POST /api/admin/campaigns/{code}/send}.
 *
 * <p>La base de test peut contenir d'autres comptes eligibles : les assertions
 * portent sur les comptes du test, et un envoi boucle jusqu'a NOTHING_TO_SEND.
 */
class EmailCampaignIT extends AbstractEmailIT {

    private static final String URL = "/api/admin/campaigns/{code}/send";

    @Autowired private MockMvc mockMvc;
    @Autowired private AuthTestSupport auth;
    @Autowired private EmailProperties emailProperties;
    @Autowired private SpringMailEmailSender renderer;

    private String admin;
    private User a;
    private User b;
    private User inactive;
    private User deleted;
    private User anonymized;
    private User otherAdmin;

    @BeforeEach
    void setUp() {
        admin = auth.bearer(track(data.admin()));
        a = user();
        b = user();
        inactive = user();
        jdbc.update("UPDATE users SET is_active = false WHERE id = ?", inactive.getId());
        deleted = user();
        jdbc.update("UPDATE users SET deleted_at = now() WHERE id = ?", deleted.getId());
        anonymized = user();
        jdbc.update("UPDATE users SET email = ? WHERE id = ?",
                "deleted-" + anonymized.getId() + "@anon.sejourfr", anonymized.getId());
        otherAdmin = track(data.admin());
    }

    private ResultActions call(String code, String mode, String... params) throws Exception {
        var req = post(URL, code).param("mode", mode).header(HttpHeaders.AUTHORIZATION, admin);
        for (int i = 0; i < params.length; i += 2) {
            req = req.param(params[i], params[i + 1]);
        }
        return mockMvc.perform(req);
    }

    /** Envoie des vagues jusqu'a epuisement (au plus 10). */
    private void sendAll(String code) throws Exception {
        for (int i = 0; i < 10; i++) {
            String body = call(code, "send", "batch", "100").andExpect(status().isOk())
                    .andReturn().getResponse().getContentAsString();
            if (body.contains("\"NOTHING_TO_SEND\"")) {
                return;
            }
        }
        throw new AssertionError("la campagne ne s'epuise pas");
    }

    private int mailsTo(User u) {
        return mails.sentTo(jdbc.queryForObject("SELECT email FROM users WHERE id = ?", String.class, u.getId()))
                .size();
    }

    @Test
    void dryRunNEnvoieRienEtMasqueLesAdresses() throws Exception {
        call("incident", "dry-run")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("DRY_RUN"))
                .andExpect(jsonPath("$.waveSize").value(10))
                .andExpect(jsonPath("$.remaining").value(org.hamcrest.Matchers.greaterThanOrEqualTo(2)));
        awaitEmailExecutorIdle();
        assertThat(mails.sent()).isEmpty();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM email_campaign_log WHERE user_id IN (?, ?)",
                Long.class, a.getId(), b.getId())).isZero();
        String body = call("incident", "dry-run").andReturn().getResponse().getContentAsString();
        assertThat(body).doesNotContain(a.getEmail()).doesNotContain(b.getEmail());
    }

    @Test
    void sendNeServQueLesComptesActifsUserNonSupprimesNonAnonymises() throws Exception {
        assertThat(emailProperties.getAutomation().isEnabled())
                .as("le drapeau d'automatisation est coupe : la campagne part quand meme")
                .isFalse();

        sendAll("incident");

        assertThat(mailsTo(a)).isEqualTo(1);
        assertThat(mailsTo(b)).isEqualTo(1);
        for (User excluded : List.of(inactive, deleted, anonymized, otherAdmin)) {
            assertThat(mailsTo(excluded)).as("exclu %s", excluded.getId()).isZero();
        }
        assertThat(hasStatus(a, EmailType.CAMPAIGN_INCIDENT, EmailDeliveryStatus.SENT)).isTrue();
        assertThat(jdbc.queryForObject("SELECT status FROM email_campaign_log WHERE campaign_code = 'incident' "
                + "AND user_id = ?", String.class, a.getId())).isEqualTo("SENT");

        EmailMessage m = mails.sentTo(a.getEmail()).getFirst();
        SpringMailEmailSender.Rendered r = renderer.render(m);
        assertThat(r.subject()).isEqualTo("Mise à jour de SejourFR : l'application mobile peut être perturbée");
        assertThat(r.text()).contains("Merci de votre patience,\nL'équipe SejourFR")
                .doesNotContain("À bientôt").doesNotContain("désabonner");
        assertThat(m.unsubscribeUrl()).isNull();
    }

    @Test
    void relancerNeSertQueLesNonServisEtRepriseLesEchecs() throws Exception {
        sendAll("reprise");
        assertThat(mailsTo(a)).isEqualTo(1);

        sendAll("reprise");
        call("reprise", "send").andExpect(jsonPath("$.status").value("NOTHING_TO_SEND"));
        assertThat(mailsTo(a)).isEqualTo(1);
        assertThat(mailsTo(b)).isEqualTo(1);

        // Une autre campagne est independante.
        User c = user();
        mails.failNext(4); // 1 tentative + 3 relances immediates : le premier compte echoue
        call("incident", "send", "batch", "100")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("STOPPED_ON_ERROR"))
                .andExpect(jsonPath("$.waveFailed").value(1));
        sendAll("incident");
        for (User u : List.of(a, b, c)) {
            assertThat(mails.sentTo(u.getEmail()).stream()
                    .filter(x -> x.type() == EmailType.CAMPAIGN_INCIDENT).count()).isEqualTo(1);
        }
    }

    @Test
    void testNEnvoieQuAUneSeuleAdresseSansToucherLaCampagne() throws Exception {
        String to = trackRecipient("proprio-test@test.sejourfr");
        call("incident", "test", "to", to)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("TEST_SENT"))
                .andExpect(jsonPath("$.waveSent").value(1));
        awaitEmailExecutorIdle();
        assertThat(mails.sent()).hasSize(1);
        assertThat(mails.sent().getFirst().recipient()).isEqualTo(to);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM email_campaign_log WHERE user_id IN (?, ?)",
                Long.class, a.getId(), b.getId())).isZero();

        call("incident", "test").andExpect(status().isBadRequest());
    }

    @Test
    void reserveAuxAdminsEtCodeControle() throws Exception {
        mockMvc.perform(post(URL, "incident").param("mode", "dry-run")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(a)))
                .andExpect(status().isForbidden());
        call("promo", "dry-run").andExpect(status().isBadRequest());
        call("incident", "tout").andExpect(status().isBadRequest());
    }
}

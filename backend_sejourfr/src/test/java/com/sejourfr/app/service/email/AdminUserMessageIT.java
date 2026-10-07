package com.sejourfr.app.service.email;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EmailDeliveryStatus;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.service.ConversationService;
import com.sejourfr.app.support.AbstractEmailIT;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.EmailTestSupport;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Écrire à un compte depuis la console (D-58) : {@code POST /api/admin/users/{id}/messages}
 * crée une conversation rattachée au compte et le mail {@code ADMIN_MESSAGE} part
 * APRÈS COMMIT, par le port, tracé dans {@code email_deliveries}. Hors transaction
 * de test ({@link AbstractEmailIT}) : un mail reçu prouve que la publication est
 * transactionnelle.
 */
class AdminUserMessageIT extends AbstractEmailIT {

    @Autowired private MockMvc mvc;
    @Autowired private AuthTestSupport auth;
    @Autowired private ObjectMapper om;
    @Autowired private ConversationService conversationService;
    @Autowired private SpringMailEmailSender renderer;

    private User admin;
    private String bearer;
    private final List<UUID> recipients = new ArrayList<>();

    @BeforeEach
    void setUp() {
        admin = track(data.admin());
        bearer = auth.bearer(admin);
    }

    /** Les messages signés par l'admin doivent partir avant lui (author_id sans cascade). */
    @AfterEach
    void purgeConversations() {
        awaitEmailExecutorIdle();
        for (UUID id : recipients) {
            jdbc.update("DELETE FROM conversations WHERE user_id = ?", id);
        }
    }

    private User destinataire(String firstName) {
        User u = user();
        recipients.add(u.getId());
        jdbc.update("UPDATE users SET first_name = ? WHERE id = ?", firstName, u.getId());
        return u;
    }

    private ResultActions envoyer(UUID userId, String token, Map<String, String> body) throws Exception {
        return mvc.perform(post("/api/admin/users/" + userId + "/messages")
                .header(HttpHeaders.AUTHORIZATION, token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(om.writeValueAsString(body)));
    }

    private int conversationsOf(User u) {
        Integer n = jdbc.queryForObject("SELECT count(*) FROM conversations WHERE user_id = ?", Integer.class, u.getId());
        return n == null ? 0 : n;
    }

    @Test
    @DisplayName("Envoi : conversation rattachée au compte, message signé par l'admin, ADMIN_MESSAGE après commit, texte échappé")
    void envoiCreeLaConversationEtLeMail() throws Exception {
        User u = destinataire("Alice");

        JsonNode res = om.readTree(envoyer(u.getId(), bearer, Map.of(
                        "subject", "  Votre\r\naccès  TCF ",
                        "body", "Bonjour <b>Alice</b> & co.\nDeuxième ligne"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString());

        UUID conversationId = UUID.fromString(res.get("id").asText());
        assertThat(res.get("userId").asText()).isEqualTo(u.getId().toString());
        assertThat(res.get("subject").asText()).isEqualTo("Votre accès TCF");
        assertThat(res.get("status").asText()).isEqualTo("REPONDU");
        assertThat(res.get("messages")).hasSize(1);
        assertThat(res.get("messages").get(0).get("senderType").asText()).isEqualTo("ADMIN");
        assertThat(res.get("messages").get(0).get("authorId").asText()).isEqualTo(admin.getId().toString());

        Map<String, Object> conv = jdbc.queryForMap(
                "SELECT user_id, contact_email, unread_for_admin, unread_for_user FROM conversations WHERE id = ?",
                conversationId);
        assertThat(conv.get("user_id")).isEqualTo(u.getId());
        assertThat(conv.get("contact_email")).isNull();
        assertThat(conv.get("unread_for_admin")).isEqualTo(false);
        assertThat(conv.get("unread_for_user")).isEqualTo(true);
        UUID messageId = UUID.fromString(res.get("messages").get(0).get("id").asText());

        EmailTestSupport.await("ADMIN_MESSAGE", () -> hasStatus(u, EmailType.ADMIN_MESSAGE, EmailDeliveryStatus.SENT));
        assertThat(rowsOf(u, EmailType.ADMIN_MESSAGE)).singleElement().satisfies(d -> {
            assertThat(d.getDeduplicationKey()).isEqualTo("ADMIN_MESSAGE:" + messageId);
            assertThat(d.getReferenceId()).isEqualTo(messageId);
            assertThat(d.getRecipient()).isEqualTo(u.getEmail());
        });
        EmailMessage mail = mails.sentTo(u.getEmail()).getFirst();
        assertThat(mail.type()).isEqualTo(EmailType.ADMIN_MESSAGE);
        assertThat(mail.unsubscribeUrl()).as("message de service : aucun désabonnement").isNull();

        SpringMailEmailSender.Rendered r = renderer.render(mail);
        assertThat(r.subject()).isEqualTo("Votre accès TCF");
        assertThat(r.html()).contains("Bonjour Alice,")
                .contains("Bonjour &lt;b&gt;Alice&lt;/b&gt; &amp; co.<br/>")
                .doesNotContain("<b>Alice</b>");
        assertThat(r.text()).contains("Bonjour <b>Alice</b> & co.\nDeuxième ligne");
    }

    @Test
    @DisplayName("Compte supprimé : 409, aucune conversation, aucun mail")
    void compteSupprimeRefuse() throws Exception {
        User u = destinataire("Bob");
        jdbc.update("UPDATE users SET deleted_at = now(), is_active = false WHERE id = ?", u.getId());

        envoyer(u.getId(), bearer, Map.of("subject", "Bonjour", "body", "Un message"))
                .andExpect(status().isConflict());

        assertThat(conversationsOf(u)).isZero();
        awaitEmailExecutorIdle();
        assertThat(mails.sentTo(u.getEmail())).isEmpty();
    }

    @Test
    @DisplayName("Compte inconnu : 404")
    void compteInconnu() throws Exception {
        envoyer(UUID.randomUUID(), bearer, Map.of("subject", "Bonjour", "body", "Un message"))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("Validation : objet 3–150, message 1–5000 (blancs exclus) → 400, rien d'écrit")
    void validation() throws Exception {
        User u = destinataire("Chloé");

        envoyer(u.getId(), bearer, Map.of("subject", "ab", "body", "ok")).andExpect(status().isBadRequest());
        envoyer(u.getId(), bearer, Map.of("subject", "x".repeat(151), "body", "ok")).andExpect(status().isBadRequest());
        envoyer(u.getId(), bearer, Map.of("subject", "   a   ", "body", "ok")).andExpect(status().isBadRequest());
        envoyer(u.getId(), bearer, Map.of("subject", "Objet", "body", "   ")).andExpect(status().isBadRequest());
        envoyer(u.getId(), bearer, Map.of("subject", "Objet", "body", "y".repeat(5001))).andExpect(status().isBadRequest());

        assertThat(conversationsOf(u)).isZero();
    }

    @Test
    @DisplayName("Un compte USER ne peut ni envoyer ni prévisualiser : 403")
    void reserveAuxAdmins() throws Exception {
        User u = destinataire("Dan");
        String userBearer = auth.bearer(u);

        envoyer(u.getId(), userBearer, Map.of("subject", "Bonjour", "body", "Un message"))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/admin/users/" + u.getId() + "/messages/preview")
                        .header(HttpHeaders.AUTHORIZATION, userBearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(om.writeValueAsString(Map.of("subject", "Bonjour", "body", "Un message"))))
                .andExpect(status().isForbidden());
        assertThat(conversationsOf(u)).isZero();
    }

    @Test
    @DisplayName("Aperçu : le vrai gabarit, texte échappé, rien d'écrit ni d'envoyé")
    void apercuSansEffet() throws Exception {
        User u = destinataire("Emma");

        JsonNode res = om.readTree(mvc.perform(post("/api/admin/users/" + u.getId() + "/messages/preview")
                        .header(HttpHeaders.AUTHORIZATION, bearer)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(om.writeValueAsString(Map.of("subject", "Objet", "body", "<i>Salut</i>\nFin"))))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString());

        assertThat(res.get("recipient").asText()).isEqualTo(u.getEmail());
        assertThat(res.get("subject").asText()).isEqualTo("Objet");
        assertThat(res.get("html").asText()).contains("Bonjour Emma,").contains("&lt;i&gt;Salut&lt;/i&gt;<br/>")
                .contains("L'équipe SejourFR");
        assertThat(res.get("text").asText()).contains("<i>Salut</i>\nFin");
        assertThat(conversationsOf(u)).isZero();
        awaitEmailExecutorIdle();
        assertThat(mails.sentTo(u.getEmail())).isEmpty();
        assertThat(rowsOf(u)).isEmpty();
    }

    @Test
    @DisplayName("Réponse dans une conversation rattachée au compte : ADMIN_MESSAGE à son adresse, clé par message")
    void reponseDansLaConversationDuCompte() throws Exception {
        User u = destinataire("Farid");
        UUID conversationId = UUID.fromString(om.readTree(envoyer(u.getId(), bearer,
                        Map.of("subject", "Suivi", "body", "Premier message"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString()).get("id").asText());
        EmailTestSupport.await("premier ADMIN_MESSAGE", () -> hasStatus(u, EmailType.ADMIN_MESSAGE, EmailDeliveryStatus.SENT));

        var reply = conversationService.reply(conversationId, admin.getEmail(), "Deuxième message");

        EmailTestSupport.await("second ADMIN_MESSAGE", () -> rowsOf(u, EmailType.ADMIN_MESSAGE).stream()
                .filter(d -> d.getStatus() == EmailDeliveryStatus.SENT).count() == 2);
        assertThat(rows("ADMIN_MESSAGE:" + reply.id())).hasSize(1);
        assertThat(mails.sentTo(u.getEmail())).anySatisfy(m -> {
            assertThat(m.variables()).containsEntry("message", "Deuxième message").containsEntry("subject", "Suivi");
        });
    }
}

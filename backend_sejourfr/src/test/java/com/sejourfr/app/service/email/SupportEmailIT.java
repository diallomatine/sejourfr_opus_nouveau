package com.sejourfr.app.service.email;

import com.sejourfr.app.dto.ContactRequest;
import com.sejourfr.app.dto.ContactResponse;
import com.sejourfr.app.entity.EmailDelivery;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EmailDeliveryStatus;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.service.ContactService;
import com.sejourfr.app.service.ConversationService;
import com.sejourfr.app.support.AbstractEmailIT;
import com.sejourfr.app.support.EmailTestSupport;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Formulaire de contact et reponse du support (arbitrage n°9) : accuse et
 * reponse passent par le port et le journal ; le RELAIS vers le support reste
 * synchrone et sans ligne de journal.
 */
class SupportEmailIT extends AbstractEmailIT {

    @Autowired private ContactService contactService;
    @Autowired private ConversationService conversationService;

    private String visiteur() {
        return trackRecipient("visiteur-" + UUID.randomUUID() + "@test.sejourfr");
    }

    private UUID conversationOf(String email) {
        return jdbc.queryForObject("SELECT id FROM conversations WHERE contact_email = ?", UUID.class, email);
    }

    @Test
    @DisplayName("Contact : relais synchrone au support (sans journal) et accuse CONTACT_RECEIVED apres commit")
    void contactRelaiEtAccuse() {
        String email = visiteur();

        ContactResponse res = contactService.submit(new ContactRequest("Dan", email, "Bug", "Ça ne marche pas."));

        assertThat(mails.relayed()).anySatisfy(r -> {
            assertThat(r.replyTo()).isEqualTo(email);
            assertThat(r.subject()).isEqualTo("[Contact SejourFR] Bug");
        });
        EmailTestSupport.await("CONTACT_RECEIVED", () -> rowsTo(email).stream()
                .anyMatch(d -> d.getStatus() == EmailDeliveryStatus.SENT));
        List<EmailDelivery> rows = rowsTo(email);
        assertThat(rows).singleElement().satisfies(d -> {
            assertThat(d.getEmailType()).isEqualTo(EmailType.CONTACT_RECEIVED);
            assertThat(d.getUserId()).isNull();
            assertThat(d.getDeduplicationKey()).isEqualTo("CONTACT_RECEIVED:" + conversationOf(email));
        });
        assertThat(mails.sentTo(email).getFirst().variables()).containsEntry("ticketId", res.ticketId())
                .containsEntry("message", "Ça ne marche pas.");
    }

    @Test
    @DisplayName("Relais au support en panne : la demande reste enregistree et l'accuse part quand meme")
    void relaisEnPanne() {
        String email = visiteur();
        mails.failRelay(true);

        ContactResponse res = contactService.submit(new ContactRequest("Eve", email, "Sujet", "Message"));

        assertThat(res.ticketId()).startsWith("SF-");
        assertThat(conversationOf(email)).isNotNull();
        EmailTestSupport.await("CONTACT_RECEIVED", () -> !mails.sentTo(email).isEmpty());
    }

    @Test
    @DisplayName("Reponse de l'equipe : SUPPORT_REPLY vers le contact, cle par message")
    void reponseDuSupport() {
        String email = visiteur();
        contactService.submit(new ContactRequest("Fanny", email, "Question", "Bonjour"));
        UUID conversation = conversationOf(email);
        User admin = user(("admin-" + UUID.randomUUID() + "@test.sejourfr"));
        jdbc.update("UPDATE users SET role = 'ADMIN' WHERE id = ?", admin.getId());

        var reply = conversationService.reply(conversation, admin.getEmail(), "Voici la réponse.");

        EmailTestSupport.await("SUPPORT_REPLY", () -> rowsTo(email).stream()
                .anyMatch(d -> d.getEmailType() == EmailType.SUPPORT_REPLY && d.getStatus() == EmailDeliveryStatus.SENT));
        assertThat(rowsTo(email)).filteredOn(d -> d.getEmailType() == EmailType.SUPPORT_REPLY).singleElement()
                .satisfies(d -> assertThat(d.getDeduplicationKey()).isEqualTo("SUPPORT_REPLY:" + reply.id()));
        assertThat(mails.sentTo(email)).anySatisfy(m -> {
            assertThat(m.type()).isEqualTo(EmailType.SUPPORT_REPLY);
            assertThat(m.variables()).containsEntry("reply", "Voici la réponse.").containsEntry("subject", "Question");
        });
    }
}

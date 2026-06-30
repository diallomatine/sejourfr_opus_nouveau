package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.ConversationDetailDto;
import com.sejourfr.app.dto.ConversationSummaryDto;
import com.sejourfr.app.dto.MessageDto;
import com.sejourfr.app.entity.Conversation;
import com.sejourfr.app.entity.Message;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.MessageSender;
import com.sejourfr.app.enums.MessageStatus;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class MessageMapperTest {

    private final MessageMapper mapper = new MessageMapper();

    private User user(UUID id, String first, String last, String email) {
        User u = new User();
        u.setId(id);
        u.setFirstName(first);
        u.setLastName(last);
        u.setEmail(email);
        return u;
    }

    private Conversation conversation(UUID id, User user) {
        Conversation c = new Conversation();
        c.setId(id);
        c.setUser(user);
        c.setSubject("Problème de paiement");
        c.setStatus(MessageStatus.NOUVEAU);
        c.setCreatedAt(Instant.parse("2026-01-01T00:00:00Z"));
        c.setLastMessageAt(Instant.parse("2026-01-02T00:00:00Z"));
        c.setUnreadForAdmin(true);
        c.setUnreadForUser(false);
        return c;
    }

    private Message message(UUID id, Conversation c, MessageSender sender, User author) {
        Message m = new Message();
        m.setId(id);
        m.setConversation(c);
        m.setSenderType(sender);
        m.setAuthor(author);
        m.setBody("Bonjour");
        m.setCreatedAt(Instant.parse("2026-01-02T08:00:00Z"));
        return m;
    }

    @Test
    void toDto_withAuthor_usesAuthorFullName() {
        UUID authorId = UUID.randomUUID();
        User author = user(authorId, "Karim", "Test", "karim@example.fr");
        Conversation c = conversation(UUID.randomUUID(), author);
        UUID msgId = UUID.randomUUID();

        MessageDto dto = mapper.toDto(message(msgId, c, MessageSender.USER, author));

        assertThat(dto.id()).isEqualTo(msgId);
        assertThat(dto.conversationId()).isEqualTo(c.getId());
        assertThat(dto.senderType()).isEqualTo(MessageSender.USER);
        assertThat(dto.authorId()).isEqualTo(authorId);
        assertThat(dto.authorName()).isEqualTo("Karim Test");
        assertThat(dto.body()).isEqualTo("Bonjour");
        assertThat(dto.createdAt()).isEqualTo(Instant.parse("2026-01-02T08:00:00Z"));
    }

    @Test
    void toDto_authorWithBlankNames_fallsBackToEmail() {
        User author = user(UUID.randomUUID(), null, null, "noname@example.fr");
        Conversation c = conversation(UUID.randomUUID(), author);

        MessageDto dto = mapper.toDto(message(UUID.randomUUID(), c, MessageSender.USER, author));

        assertThat(dto.authorName()).isEqualTo("noname@example.fr");
    }

    @Test
    void toDto_noAuthorAdminSender_usesSupportLabel() {
        Conversation c = conversation(UUID.randomUUID(), null);
        c.setContactName("Jean Visiteur");
        c.setContactEmail("jean@visiteur.fr");

        MessageDto dto = mapper.toDto(message(UUID.randomUUID(), c, MessageSender.ADMIN, null));

        assertThat(dto.authorId()).isNull();
        assertThat(dto.authorName()).isEqualTo("Support SejourFR");
    }

    @Test
    void toDto_noAuthorUserSender_usesContactDisplayName() {
        Conversation c = conversation(UUID.randomUUID(), null);
        c.setContactName("Jean Visiteur");
        c.setContactEmail("jean@visiteur.fr");

        MessageDto dto = mapper.toDto(message(UUID.randomUUID(), c, MessageSender.USER, null));

        assertThat(dto.authorId()).isNull();
        assertThat(dto.authorName()).isEqualTo("Jean Visiteur");
    }

    @Test
    void toDto_noAuthorUserSender_blankContactName_usesContactEmail() {
        Conversation c = conversation(UUID.randomUUID(), null);
        c.setContactName("   ");
        c.setContactEmail("jean@visiteur.fr");

        MessageDto dto = mapper.toDto(message(UUID.randomUUID(), c, MessageSender.USER, null));

        assertThat(dto.authorName()).isEqualTo("jean@visiteur.fr");
    }

    @Test
    void toSummary_withUser_mapsEveryField() {
        UUID userId = UUID.randomUUID();
        User user = user(userId, "Karim", "Test", "karim@example.fr");
        Conversation c = conversation(UUID.randomUUID(), user);

        ConversationSummaryDto dto = mapper.toSummary(c, "dernier message…", 4L);

        assertThat(dto.id()).isEqualTo(c.getId());
        assertThat(dto.userId()).isEqualTo(userId);
        assertThat(dto.userEmail()).isEqualTo("karim@example.fr");
        assertThat(dto.userFullName()).isEqualTo("Karim Test");
        assertThat(dto.subject()).isEqualTo("Problème de paiement");
        assertThat(dto.status()).isEqualTo(MessageStatus.NOUVEAU);
        assertThat(dto.createdAt()).isEqualTo(Instant.parse("2026-01-01T00:00:00Z"));
        assertThat(dto.lastMessageAt()).isEqualTo(Instant.parse("2026-01-02T00:00:00Z"));
        assertThat(dto.unreadForAdmin()).isTrue();
        assertThat(dto.lastMessagePreview()).isEqualTo("dernier message…");
        assertThat(dto.messageCount()).isEqualTo(4L);
    }

    @Test
    void toSummary_guestContact_usesContactEmailAndName() {
        Conversation c = conversation(UUID.randomUUID(), null);
        c.setContactName("Jean Visiteur");
        c.setContactEmail("jean@visiteur.fr");

        ConversationSummaryDto dto = mapper.toSummary(c, null, 0L);

        assertThat(dto.userId()).isNull();
        assertThat(dto.userEmail()).isEqualTo("jean@visiteur.fr");
        assertThat(dto.userFullName()).isEqualTo("Jean Visiteur");
        assertThat(dto.lastMessagePreview()).isNull();
    }

    @Test
    void toDetail_mapsConversationAndMessages() {
        UUID userId = UUID.randomUUID();
        User user = user(userId, "Karim", "Test", "karim@example.fr");
        Conversation c = conversation(UUID.randomUUID(), user);
        c.setUnreadForUser(true);

        Message m1 = message(UUID.randomUUID(), c, MessageSender.USER, user);
        Message m2 = message(UUID.randomUUID(), c, MessageSender.ADMIN, null);

        ConversationDetailDto dto = mapper.toDetail(c, List.of(m1, m2));

        assertThat(dto.id()).isEqualTo(c.getId());
        assertThat(dto.userId()).isEqualTo(userId);
        assertThat(dto.userEmail()).isEqualTo("karim@example.fr");
        assertThat(dto.userFullName()).isEqualTo("Karim Test");
        assertThat(dto.subject()).isEqualTo("Problème de paiement");
        assertThat(dto.status()).isEqualTo(MessageStatus.NOUVEAU);
        assertThat(dto.createdAt()).isEqualTo(Instant.parse("2026-01-01T00:00:00Z"));
        assertThat(dto.lastMessageAt()).isEqualTo(Instant.parse("2026-01-02T00:00:00Z"));
        assertThat(dto.unreadForAdmin()).isTrue();
        assertThat(dto.unreadForUser()).isTrue();
        assertThat(dto.messages()).hasSize(2);
        assertThat(dto.messages().get(0).id()).isEqualTo(m1.getId());
        assertThat(dto.messages().get(0).authorName()).isEqualTo("Karim Test");
        assertThat(dto.messages().get(1).id()).isEqualTo(m2.getId());
        assertThat(dto.messages().get(1).authorName()).isEqualTo("Support SejourFR");
    }
}

package com.sejourfr.app.service;

import com.sejourfr.app.dto.ConversationDetailDto;
import com.sejourfr.app.dto.ConversationSummaryDto;
import com.sejourfr.app.dto.MessageDto;
import com.sejourfr.app.entity.Conversation;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.MessageSender;
import com.sejourfr.app.enums.MessageStatus;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ConversationServiceIT extends AbstractIntegrationTest {

    @Autowired
    private ConversationService conversationService;

    @Autowired
    private TestData testData;

    @Test
    void createFromContactCreatesUnreadNewConversation() {
        Conversation c = conversationService.createFromContact(
                "Alice", "alice@example.com", "Question", "Bonjour, j'ai une question.");

        assertThat(c.getId()).isNotNull();
        assertThat(c.getStatus()).isEqualTo(MessageStatus.NOUVEAU);
        assertThat(c.isUnreadForAdmin()).isTrue();

        ConversationDetailDto detail = conversationService.getDetail(c.getId());
        assertThat(detail.subject()).isEqualTo("Question");
        assertThat(detail.messages()).hasSize(1);
        assertThat(detail.messages().get(0).senderType()).isEqualTo(MessageSender.USER);
        assertThat(detail.messages().get(0).body()).isEqualTo("Bonjour, j'ai une question.");
    }

    @Test
    void getDetailAbsentThrowsNotFound() {
        assertThatThrownBy(() -> conversationService.getDetail(UUID.randomUUID()))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void markReadFlipsStatusAndUnread() {
        Conversation c = conversationService.createFromContact(
                "Bob", "bob@example.com", "Sujet", "Message");

        ConversationDetailDto detail = conversationService.markRead(c.getId());
        assertThat(detail.status()).isEqualTo(MessageStatus.LU);
        assertThat(detail.unreadForAdmin()).isFalse();
    }

    @Test
    void replyAppendsAdminMessageAndMarksReplied() {
        Conversation c = conversationService.createFromContact(
                "Carol", "carol@example.com", "Sujet", "Message");
        User admin = testData.admin();

        MessageDto reply = conversationService.reply(c.getId(), admin.getEmail(), "Voici notre réponse.");
        assertThat(reply.senderType()).isEqualTo(MessageSender.ADMIN);
        assertThat(reply.body()).isEqualTo("Voici notre réponse.");

        ConversationDetailDto detail = conversationService.getDetail(c.getId());
        assertThat(detail.status()).isEqualTo(MessageStatus.REPONDU);
        assertThat(detail.unreadForUser()).isTrue();
        assertThat(detail.messages()).hasSize(2);
    }

    @Test
    void replyWithUnknownAdminThrowsNotFound() {
        Conversation c = conversationService.createFromContact(
                "Dan", "dan@example.com", "Sujet", "Message");
        assertThatThrownBy(() -> conversationService.reply(c.getId(), "ghost@nowhere.test", "x"))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void updateStatusClearsUnreadWhenNotNouveau() {
        Conversation c = conversationService.createFromContact(
                "Eve", "eve@example.com", "Sujet", "Message");

        ConversationDetailDto detail = conversationService.updateStatus(c.getId(), MessageStatus.ARCHIVE);
        assertThat(detail.status()).isEqualTo(MessageStatus.ARCHIVE);
        assertThat(detail.unreadForAdmin()).isFalse();
    }

    @Test
    void deleteRemovesConversation() {
        Conversation c = conversationService.createFromContact(
                "Fay", "fay@example.com", "Sujet", "Message");
        conversationService.delete(c.getId());

        assertThatThrownBy(() -> conversationService.getDetail(c.getId()))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void searchAndCountUnreadReflectNewConversations() {
        long before = conversationService.countUnread();
        conversationService.createFromContact("Gus", "gus@example.com", "Recherche-XYZ", "Message");

        Page<ConversationSummaryDto> page = conversationService.search(
                null, null, null, "Recherche-XYZ", PageRequest.of(0, 20));
        assertThat(page.getContent()).hasSize(1);
        assertThat(page.getContent().get(0).lastMessagePreview()).isEqualTo("Message");
        assertThat(page.getContent().get(0).messageCount()).isEqualTo(1);

        assertThat(conversationService.countUnread()).isEqualTo(before + 1);
    }
}

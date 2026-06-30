package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Conversation;
import com.sejourfr.app.entity.Message;
import com.sejourfr.app.enums.MessageSender;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class MessageManagerIT extends AbstractIntegrationTest {

    @Autowired
    private MessageManager manager;

    @Autowired
    private TestData testData;

    private Message message(Conversation conversation, Instant createdAt) {
        Message m = new Message();
        m.setConversation(conversation);
        m.setSenderType(MessageSender.USER);
        m.setAuthor(conversation.getUser());
        m.setBody("Corps " + UUID.randomUUID());
        m.setCreatedAt(createdAt);
        return manager.save(m);
    }

    @Test
    void saveSetsId() {
        Message saved = testData.message();

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getCreatedAt()).isNotNull();
    }

    @Test
    void findByConversationOrderedByCreatedAtAsc() {
        Conversation conv = testData.conversation();
        Instant base = Instant.now().truncatedTo(ChronoUnit.SECONDS);
        // Insertion volontairement désordonnée pour prouver le tri SQL, pas l'ordre d'insert.
        Message middle = message(conv, base.minus(20, ChronoUnit.SECONDS));
        Message oldest = message(conv, base.minus(30, ChronoUnit.SECONDS));
        Message newest = message(conv, base.minus(10, ChronoUnit.SECONDS));
        Message otherConvMessage = testData.message(testData.conversation());

        List<Message> result = manager.findByConversationOrdered(conv.getId());

        assertThat(result)
                .extracting(Message::getId)
                .containsExactly(oldest.getId(), middle.getId(), newest.getId())
                .doesNotContain(otherConvMessage.getId());
    }

    @Test
    void findByConversationUnknownReturnsEmpty() {
        assertThat(manager.findByConversationOrdered(UUID.randomUUID())).isEmpty();
    }
}

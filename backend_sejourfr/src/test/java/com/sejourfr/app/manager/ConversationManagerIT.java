package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Conversation;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.jpa.domain.Specification;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class ConversationManagerIT extends AbstractIntegrationTest {

    @Autowired
    private ConversationManager manager;

    @Autowired
    private TestData testData;

    @PersistenceContext
    private EntityManager em;

    private static Specification<Conversation> unreadForAdmin() {
        return (root, query, cb) -> cb.isTrue(root.get("unreadForAdmin"));
    }

    private static Specification<Conversation> byUser(UUID userId) {
        return (root, query, cb) -> cb.equal(root.get("user").get("id"), userId);
    }

    private Conversation conversation(User user, boolean unreadForAdmin) {
        Conversation c = testData.conversation(user);
        c.setUnreadForAdmin(unreadForAdmin);
        return manager.save(c);
    }

    @Test
    void findByIdAbsentReturnsEmpty() {
        assertThat(manager.findById(UUID.randomUUID())).isEmpty();
    }

    @Test
    void saveSetsTimestamps() {
        Conversation saved = testData.conversation();

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(saved.getLastMessageAt()).isNotNull();
    }

    @Test
    void countUnreadForAdmin() {
        User u = testData.user();
        conversation(u, true);
        conversation(u, true);
        conversation(u, false);

        assertThat(manager.countUnreadForAdmin()).isEqualTo(2);
    }

    @Test
    void searchByUnreadOnly() {
        User u1 = testData.user();
        User u2 = testData.user();
        Conversation unread1 = conversation(u1, true);
        Conversation read = conversation(u1, false);
        Conversation unread2 = conversation(u2, true);

        Page<Conversation> page = manager.search(unreadForAdmin(), PageRequest.of(0, 50));

        assertThat(page.getContent())
                .extracting(Conversation::getId)
                .contains(unread1.getId(), unread2.getId())
                .doesNotContain(read.getId());
    }

    @Test
    void searchByUnreadAndUserCombinesFilters() {
        User u1 = testData.user();
        User u2 = testData.user();
        Conversation u1Unread = conversation(u1, true);
        Conversation u1Read = conversation(u1, false);
        Conversation u2Unread = conversation(u2, true);

        Page<Conversation> page = manager.search(
                unreadForAdmin().and(byUser(u1.getId())), PageRequest.of(0, 50));

        assertThat(page.getContent())
                .extracting(Conversation::getId)
                .containsExactly(u1Unread.getId())
                .doesNotContain(u1Read.getId(), u2Unread.getId());
    }

    @Test
    void deleteByUserIdRemovesOnlyThatUsersConversations() {
        User u1 = testData.user();
        User u2 = testData.user();
        Conversation c1 = testData.conversation(u1);
        Conversation c2 = testData.conversation(u1);
        testData.message(c1);
        Conversation other = testData.conversation(u2);

        int deleted = manager.deleteByUserId(u1.getId());

        assertThat(deleted).isEqualTo(2);
        em.flush();
        em.clear();
        assertThat(manager.findById(c1.getId())).isEmpty();
        assertThat(manager.findById(c2.getId())).isEmpty();
        assertThat(manager.findById(other.getId())).isPresent();
    }

    @Test
    void deleteRemovesRow() {
        Conversation saved = testData.conversation();
        UUID id = saved.getId();

        manager.delete(saved);

        assertThat(manager.findById(id)).isEmpty();
    }
}

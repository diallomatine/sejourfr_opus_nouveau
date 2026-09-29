package com.sejourfr.app.specification;

import com.sejourfr.app.entity.Conversation;
import com.sejourfr.app.enums.MessageStatus;
import org.springframework.data.jpa.domain.Specification;
import java.util.UUID;

public final class ConversationSpecifications {

    private ConversationSpecifications() {}

    public static Specification<Conversation> hasStatus(MessageStatus status) {
        return (root, q, cb) -> status == null ? null : cb.equal(root.get("status"), status);
    }

    public static Specification<Conversation> unreadOnly(Boolean unreadOnly) {
        return (root, q, cb) -> Boolean.TRUE.equals(unreadOnly) ? cb.isTrue(root.get("unreadForAdmin")) : null;
    }

    public static Specification<Conversation> hasUser(UUID userId) {
        return (root, q, cb) -> userId == null ? null : cb.equal(root.get("user").get("id"), userId);
    }

    public static Specification<Conversation> subjectContains(String search) {
        return (root, q, cb) -> {
            if (search == null || search.isBlank()) return null;
            return cb.like(cb.lower(root.get("subject")), "%" + search.toLowerCase() + "%");
        };
    }
}

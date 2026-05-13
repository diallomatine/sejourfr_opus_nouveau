package com.sejourfr.app.message;

import com.sejourfr.app.user.User;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class MessageMapper {

    public MessageDto toDto(Message m) {
        User author = m.getAuthor();
        return new MessageDto(
                m.getId(),
                m.getConversation().getId(),
                m.getSenderType(),
                author != null ? author.getId() : null,
                author != null ? fullName(author) : null,
                m.getBody(),
                m.getCreatedAt()
        );
    }

    public ConversationSummaryDto toSummary(Conversation c, String lastPreview, long messageCount) {
        User u = c.getUser();
        return new ConversationSummaryDto(
                c.getId(),
                u.getId(),
                u.getEmail(),
                fullName(u),
                c.getSubject(),
                c.getStatus(),
                c.getCreatedAt(),
                c.getLastMessageAt(),
                c.isUnreadForAdmin(),
                lastPreview,
                messageCount
        );
    }

    public ConversationDetailDto toDetail(Conversation c, List<Message> messages) {
        User u = c.getUser();
        List<MessageDto> dtos = messages.stream().map(this::toDto).toList();
        return new ConversationDetailDto(
                c.getId(),
                u.getId(),
                u.getEmail(),
                fullName(u),
                c.getSubject(),
                c.getStatus(),
                c.getCreatedAt(),
                c.getLastMessageAt(),
                c.isUnreadForAdmin(),
                c.isUnreadForUser(),
                dtos
        );
    }

    private String fullName(User u) {
        String first = u.getFirstName() != null ? u.getFirstName() : "";
        String last = u.getLastName() != null ? u.getLastName() : "";
        String joined = (first + " " + last).trim();
        return joined.isEmpty() ? u.getEmail() : joined;
    }
}

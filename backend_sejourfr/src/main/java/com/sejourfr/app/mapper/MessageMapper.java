package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.ConversationDetailDto;
import com.sejourfr.app.dto.ConversationSummaryDto;
import com.sejourfr.app.dto.MessageDto;
import com.sejourfr.app.entity.Conversation;
import com.sejourfr.app.entity.Message;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.MessageSender;
import org.springframework.stereotype.Component;
import java.util.List;
import java.util.UUID;

@Component
public class MessageMapper {

    public MessageDto toDto(Message m) {
        User author = m.getAuthor();
        // Message entrant d'un contact non connecté : pas d'auteur User. On
        // affiche le nom du contact (côté USER) ou « Support » (côté ADMIN).
        String authorName = author != null
                ? fullName(author)
                : m.getSenderType() == MessageSender.ADMIN
                ? "Support SejourFR"
                : displayName(m.getConversation());
        return new MessageDto(
                m.getId(),
                m.getConversation().getId(),
                m.getSenderType(),
                author != null ? author.getId() : null,
                authorName,
                m.getBody(),
                m.getCreatedAt()
        );
    }

    public ConversationSummaryDto toSummary(Conversation c, String lastPreview, long messageCount) {
        return new ConversationSummaryDto(
                c.getId(),
                userId(c),
                displayEmail(c),
                displayName(c),
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
        List<MessageDto> dtos = messages.stream().map(this::toDto).toList();
        return new ConversationDetailDto(
                c.getId(),
                userId(c),
                displayEmail(c),
                displayName(c),
                c.getSubject(),
                c.getStatus(),
                c.getCreatedAt(),
                c.getLastMessageAt(),
                c.isUnreadForAdmin(),
                c.isUnreadForUser(),
                dtos
        );
    }

    // ------------------------------------------------------------------------
    // Affichage : compte rattaché si présent, sinon coordonnées du contact.
    // ------------------------------------------------------------------------

    private UUID userId(Conversation c) {
        return c.getUser() != null ? c.getUser().getId() : null;
    }

    private String displayEmail(Conversation c) {
        return c.getUser() != null ? c.getUser().getEmail() : c.getContactEmail();
    }

    private String displayName(Conversation c) {
        if (c.getUser() != null) return fullName(c.getUser());
        String name = c.getContactName();
        return name != null && !name.isBlank() ? name : displayEmail(c);
    }

    private String fullName(User u) {
        String first = u.getFirstName() != null ? u.getFirstName() : "";
        String last = u.getLastName() != null ? u.getLastName() : "";
        String joined = (first + " " + last).trim();
        return joined.isEmpty() ? u.getEmail() : joined;
    }
}

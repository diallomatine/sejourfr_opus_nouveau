package com.sejourfr.app.service;

import com.sejourfr.app.dto.ConversationDetailDto;
import com.sejourfr.app.dto.ConversationSummaryDto;
import com.sejourfr.app.dto.MessageDto;
import com.sejourfr.app.entity.Conversation;
import com.sejourfr.app.entity.Message;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.MessageSender;
import com.sejourfr.app.enums.MessageStatus;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.ConversationManager;
import com.sejourfr.app.manager.MessageManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.mapper.MessageMapper;
import com.sejourfr.app.specification.ConversationSpecifications;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Boite de reception admin : recherche / detail / reponse / statut / suppression
 * sur les conversations utilisateur.
 */
@Service
@Transactional
@RequiredArgsConstructor
public class ConversationService {

    private static final int PREVIEW_MAX = 140;

    private final ConversationManager conversationManager;
    private final MessageManager messageManager;
    private final UserManager userManager;
    private final MessageMapper mapper;
    private final MailService mailService;

    @Transactional(readOnly = true)
    public Page<ConversationSummaryDto> search(
            MessageStatus status, Boolean unreadOnly, UUID userId, String search, Pageable pageable) {
        Specification<Conversation> spec = Specification.allOf(
                ConversationSpecifications.hasStatus(status),
                ConversationSpecifications.unreadOnly(unreadOnly),
                ConversationSpecifications.hasUser(userId),
                ConversationSpecifications.subjectContains(search)
        );
        return conversationManager.search(spec, pageable).map(this::toSummary);
    }

    @Transactional(readOnly = true)
    public ConversationDetailDto getDetail(UUID id) {
        Conversation c = loadOrThrow(id);
        List<Message> messages = messageManager.findByConversationOrdered(id);
        return mapper.toDetail(c, messages);
    }

    public ConversationDetailDto markRead(UUID id) {
        Conversation c = loadOrThrow(id);
        c.setUnreadForAdmin(false);
        if (c.getStatus() == MessageStatus.NOUVEAU) {
            c.setStatus(MessageStatus.LU);
        }
        return mapper.toDetail(c, messageManager.findByConversationOrdered(id));
    }

    public MessageDto reply(UUID conversationId, String adminEmail, String body) {
        Conversation c = loadOrThrow(conversationId);
        User admin = userManager.findByEmail(adminEmail)
                .orElseThrow(() -> NotFoundException.of("User", adminEmail));

        Message m = new Message();
        m.setConversation(c);
        m.setSenderType(MessageSender.ADMIN);
        m.setAuthor(admin);
        m.setBody(body);
        Message saved = messageManager.save(m);

        c.setLastMessageAt(saved.getCreatedAt() != null ? saved.getCreatedAt() : Instant.now());
        c.setUnreadForAdmin(false);
        c.setUnreadForUser(true);
        c.setStatus(MessageStatus.REPONDU);

        // Conversation issue du formulaire de contact (visiteur sans compte) :
        // la réponse part par email (async, best-effort). Les conversations
        // in-app (user rattaché) se lisent dans l'app, pas d'email.
        if (c.getContactEmail() != null && !c.getContactEmail().isBlank()) {
            mailService.sendConversationReplyEmail(
                    c.getContactEmail(), c.getContactName(), c.getSubject(), body);
        }

        return mapper.toDto(saved);
    }

    /**
     * Crée une conversation depuis le formulaire de contact public : un message
     * entrant (côté USER, sans auteur car le visiteur n'a pas forcément de
     * compte), non lu côté admin, statut {@code NOUVEAU}. C'est ce qui alimente
     * la boite de réception admin.
     */
    public Conversation createFromContact(String name, String email, String subject, String message) {
        Conversation c = new Conversation();
        c.setContactName(name);
        c.setContactEmail(email);
        c.setSubject(subject);
        c.setStatus(MessageStatus.NOUVEAU);
        c.setUnreadForAdmin(true);
        c.setUnreadForUser(false);
        Conversation saved = conversationManager.save(c);

        Message m = new Message();
        m.setConversation(saved);
        m.setSenderType(MessageSender.USER);
        m.setBody(message);
        Message savedMessage = messageManager.save(m);

        saved.setLastMessageAt(
                savedMessage.getCreatedAt() != null ? savedMessage.getCreatedAt() : Instant.now());
        return saved;
    }

    public ConversationDetailDto updateStatus(UUID id, MessageStatus newStatus) {
        Conversation c = loadOrThrow(id);
        c.setStatus(newStatus);
        if (newStatus != MessageStatus.NOUVEAU) {
            c.setUnreadForAdmin(false);
        }
        return mapper.toDetail(c, messageManager.findByConversationOrdered(id));
    }

    public void delete(UUID id) {
        conversationManager.delete(loadOrThrow(id));
    }

    public long countUnread() {
        return conversationManager.countUnreadForAdmin();
    }

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------

    private Conversation loadOrThrow(UUID id) {
        return conversationManager.findById(id)
                .orElseThrow(() -> NotFoundException.of("Conversation", id));
    }

    private ConversationSummaryDto toSummary(Conversation c) {
        List<Message> messages = messageManager.findByConversationOrdered(c.getId());
        String preview = "";
        if (!messages.isEmpty()) {
            String body = messages.get(messages.size() - 1).getBody();
            preview = body.length() > PREVIEW_MAX ? body.substring(0, PREVIEW_MAX) + "..." : body;
        }
        return mapper.toSummary(c, preview, messages.size());
    }
}

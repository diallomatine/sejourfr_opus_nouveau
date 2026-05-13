package com.sejourfr.app.message;

import com.sejourfr.app.common.NotFoundException;
import com.sejourfr.app.message.enums.MessageSender;
import com.sejourfr.app.message.enums.MessageStatus;
import com.sejourfr.app.user.User;
import com.sejourfr.app.user.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@Transactional
public class ConversationService {

    private static final int PREVIEW_MAX = 140;

    private final ConversationRepository conversationRepository;
    private final MessageRepository messageRepository;
    private final UserRepository userRepository;
    private final MessageMapper mapper;

    public ConversationService(ConversationRepository conversationRepository,
                               MessageRepository messageRepository,
                               UserRepository userRepository,
                               MessageMapper mapper) {
        this.conversationRepository = conversationRepository;
        this.messageRepository = messageRepository;
        this.userRepository = userRepository;
        this.mapper = mapper;
    }

    @Transactional(readOnly = true)
    public Page<ConversationSummaryDto> search(MessageStatus status, Boolean unreadOnly,
                                               UUID userId, String search, Pageable pageable) {
        Specification<Conversation> spec = Specification.allOf(
                ConversationSpecifications.hasStatus(status),
                ConversationSpecifications.unreadOnly(unreadOnly),
                ConversationSpecifications.hasUser(userId),
                ConversationSpecifications.subjectContains(search)
        );
        return conversationRepository.findAll(spec, pageable).map(this::toSummary);
    }

    @Transactional(readOnly = true)
    public ConversationDetailDto getDetail(UUID id) {
        Conversation c = conversationRepository.findById(id)
                .orElseThrow(() -> NotFoundException.of("Conversation", id));
        List<Message> messages = messageRepository.findByConversationIdOrderByCreatedAtAsc(id);
        return mapper.toDetail(c, messages);
    }

    public ConversationDetailDto markRead(UUID id) {
        Conversation c = conversationRepository.findById(id)
                .orElseThrow(() -> NotFoundException.of("Conversation", id));
        c.setUnreadForAdmin(false);
        if (c.getStatus() == MessageStatus.NOUVEAU) {
            c.setStatus(MessageStatus.LU);
        }
        List<Message> messages = messageRepository.findByConversationIdOrderByCreatedAtAsc(id);
        return mapper.toDetail(c, messages);
    }

    public MessageDto reply(UUID conversationId, String adminEmail, String body) {
        Conversation c = conversationRepository.findById(conversationId)
                .orElseThrow(() -> NotFoundException.of("Conversation", conversationId));
        User admin = userRepository.findByEmail(adminEmail)
                .orElseThrow(() -> NotFoundException.of("User", adminEmail));

        Message m = new Message();
        m.setConversation(c);
        m.setSenderType(MessageSender.ADMIN);
        m.setAuthor(admin);
        m.setBody(body);
        Message saved = messageRepository.save(m);

        c.setLastMessageAt(saved.getCreatedAt() != null ? saved.getCreatedAt() : Instant.now());
        c.setUnreadForAdmin(false);
        c.setUnreadForUser(true);
        c.setStatus(MessageStatus.REPONDU);

        return mapper.toDto(saved);
    }

    public ConversationDetailDto updateStatus(UUID id, MessageStatus newStatus) {
        Conversation c = conversationRepository.findById(id)
                .orElseThrow(() -> NotFoundException.of("Conversation", id));
        c.setStatus(newStatus);
        if (newStatus != MessageStatus.NOUVEAU) {
            c.setUnreadForAdmin(false);
        }
        List<Message> messages = messageRepository.findByConversationIdOrderByCreatedAtAsc(id);
        return mapper.toDetail(c, messages);
    }

    public void delete(UUID id) {
        Conversation c = conversationRepository.findById(id)
                .orElseThrow(() -> NotFoundException.of("Conversation", id));
        conversationRepository.delete(c);
    }

    public long countUnread() {
        return conversationRepository.countByUnreadForAdminTrue();
    }

    private ConversationSummaryDto toSummary(Conversation c) {
        List<Message> messages = messageRepository.findByConversationIdOrderByCreatedAtAsc(c.getId());
        String preview = "";
        if (!messages.isEmpty()) {
            String body = messages.get(messages.size() - 1).getBody();
            preview = body.length() > PREVIEW_MAX ? body.substring(0, PREVIEW_MAX) + "..." : body;
        }
        return mapper.toSummary(c, preview, messages.size());
    }
}

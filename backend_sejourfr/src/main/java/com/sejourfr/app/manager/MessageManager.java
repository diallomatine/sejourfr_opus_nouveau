package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Message;
import com.sejourfr.app.repository.MessageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link Message}.
 */
@Component
@RequiredArgsConstructor
public class MessageManager {

    private final MessageRepository repository;

    public List<Message> findByConversationOrdered(UUID conversationId) {
        return repository.findByConversationIdOrderByCreatedAtAsc(conversationId);
    }

    public Message save(Message message) {
        return repository.save(message);
    }
}

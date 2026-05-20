package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Conversation;
import com.sejourfr.app.repository.ConversationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link Conversation}.
 */
@Component
@RequiredArgsConstructor
public class ConversationManager {

    private final ConversationRepository repository;

    public Optional<Conversation> findById(UUID id) {
        return repository.findById(id);
    }

    /** Recherche paginee avec specifications dynamiques (filtres admin). */
    public Page<Conversation> search(Specification<Conversation> spec, Pageable pageable) {
        return repository.findAll(spec, pageable);
    }

    public long countUnreadForAdmin() {
        return repository.countByUnreadForAdminTrue();
    }

    public void delete(Conversation conversation) {
        repository.delete(conversation);
    }
}

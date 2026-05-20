package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.repository.AttemptRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link Attempt}.
 * Seule classe autorisee a appeler {@link AttemptRepository}.
 */
@Component
@RequiredArgsConstructor
public class AttemptManager {

    private final AttemptRepository repository;

    public Attempt save(Attempt attempt) {
        return repository.save(attempt);
    }

    public Optional<Attempt> findById(UUID id) {
        return repository.findById(id);
    }

    public long countByUserId(UUID userId) {
        return repository.countByUserId(userId);
    }

    public long countByExamTemplateId(UUID examTemplateId) {
        return repository.countByExamTemplateId(examTemplateId);
    }

    /**
     * Lookup sécurisé d'un attempt guest : exige user IS NULL ET même IP.
     */
    public Optional<Attempt> findGuestByIdAndIp(UUID id, String clientIp) {
        return repository.findByIdAndClientIpAndUserIsNull(id, clientIp);
    }

    /** Historique utilisateur filtre, plafonne par {@code limit}. */
    public List<Attempt> findByUserFiltered(UUID userId, AttemptType type, Module module, int limit) {
        return repository.findByUserFiltered(userId, type, module, PageRequest.of(0, limit));
    }
}

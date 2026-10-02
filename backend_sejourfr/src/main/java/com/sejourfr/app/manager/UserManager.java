package com.sejourfr.app.manager;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AuthProvider;
import com.sejourfr.app.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Couche d'acces aux donnees pour {@link User}.
 * Minimaliste : on n'expose que ce qui est consomme par les services migres.
 * D'autres methodes seront ajoutees au fur et a mesure des refactos.
 */
@Component
@RequiredArgsConstructor
public class UserManager {

    private final UserRepository repository;

    public Optional<User> findById(UUID id) {
        return repository.findById(id);
    }

    public Optional<User> findByEmail(String email) {
        return repository.findByEmail(email);
    }

    public boolean existsByEmail(String email) {
        return repository.existsByEmail(email);
    }

    public Optional<User> findByProvider(AuthProvider provider, String providerUserId) {
        return repository.findByAuthProviderAndProviderUserId(provider, providerUserId);
    }

    public User save(User user) {
        return repository.save(user);
    }

    public long count() {
        return repository.count();
    }

    /** Recherche paginée de la console admin « Utilisateurs ». */
    public Page<User> findAll(Specification<User> spec, Pageable pageable) {
        return repository.findAll(spec, pageable);
    }

    public List<User> findAllById(Collection<UUID> ids) {
        if (ids.isEmpty()) return List.of();
        return repository.findAllById(ids);
    }
}

package com.sejourfr.app.manager;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

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

    public User save(User user) {
        return repository.save(user);
    }

    public long count() {
        return repository.count();
    }
}

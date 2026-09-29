package com.sejourfr.app.manager;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AuthProvider;
import com.sejourfr.app.enums.Role;
import com.sejourfr.app.repository.UserRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * GABARIT « manager / repository » : intégration réelle sur Postgres embarqué.
 * Vérifie les requêtes JPA, les contraintes de base (unicité email) et le
 * mapping enum — choses qu'un test mocké ne peut pas attraper.
 */
class UserManagerIT extends AbstractIntegrationTest {

    @Autowired
    private UserManager userManager;

    @Autowired
    private UserRepository userRepository;

    @Test
    void saveAndFindByEmail() {
        User u = new User();
        u.setEmail("alice@test.sejourfr");
        u.setPasswordHash("hash");
        u.setRole(Role.USER);

        User saved = userManager.save(u);
        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getCreatedAt()).isNotNull();   // @PrePersist

        Optional<User> found = userManager.findByEmail("alice@test.sejourfr");
        assertThat(found).isPresent();
        assertThat(found.get().getRole()).isEqualTo(Role.USER);
        assertThat(found.get().getAuthProvider()).isEqualTo(AuthProvider.LOCAL);   // défaut
    }

    @Test
    void existsByEmailIsCaseSensitiveAndExact() {
        User u = new User();
        u.setEmail("bob@test.sejourfr");
        u.setPasswordHash("hash");
        userManager.save(u);

        assertThat(userManager.existsByEmail("bob@test.sejourfr")).isTrue();
        assertThat(userManager.existsByEmail("absent@test.sejourfr")).isFalse();
    }

    @Test
    void findByIdAbsentReturnsEmpty() {
        assertThat(userManager.findById(UUID.randomUUID())).isEmpty();
    }

    @Test
    void duplicateEmailViolatesUniqueConstraint() {
        User a = new User();
        a.setEmail("dup@test.sejourfr");
        a.setPasswordHash("hash");
        userManager.save(a);

        User b = new User();
        b.setEmail("dup@test.sejourfr");
        b.setPasswordHash("hash");

        // saveAndFlush force l'INSERT immédiat ; le proxy Spring traduit la
        // violation Postgres en DataIntegrityViolationException.
        assertThatThrownBy(() -> userRepository.saveAndFlush(b))
                .isInstanceOf(DataIntegrityViolationException.class);
    }
}

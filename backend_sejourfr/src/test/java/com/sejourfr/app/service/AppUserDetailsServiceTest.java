package com.sejourfr.app.service;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.Role;
import com.sejourfr.app.manager.UserManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Test unitaire pur du mapping User → Spring UserDetails : autorité
 * {@code ROLE_<role>}, mot de passe et drapeau {@code active} (enabled).
 */
class AppUserDetailsServiceTest {

    private UserManager userManager;
    private AppUserDetailsService service;

    @BeforeEach
    void setUp() {
        userManager = mock(UserManager.class);
        service = new AppUserDetailsService(userManager);
    }

    private static User user(String email, Role role, boolean active) {
        User u = new User();
        u.setId(UUID.randomUUID());
        u.setEmail(email);
        u.setPasswordHash("hash");
        u.setRole(role);
        u.setActive(active);
        return u;
    }

    @Test
    void unknownEmail_throwsUsernameNotFound() {
        when(userManager.findByEmail("none@test.fr")).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.loadUserByUsername("none@test.fr"))
                .isInstanceOf(UsernameNotFoundException.class);
    }

    @Test
    void mapsUserRoleAndActive() {
        when(userManager.findByEmail("u@test.fr"))
                .thenReturn(Optional.of(user("u@test.fr", Role.USER, true)));

        UserDetails details = service.loadUserByUsername("u@test.fr");

        assertThat(details.getUsername()).isEqualTo("u@test.fr");
        assertThat(details.getPassword()).isEqualTo("hash");
        assertThat(details.isEnabled()).isTrue();
        assertThat(details.getAuthorities())
                .extracting(Object::toString)
                .containsExactly("ROLE_USER");
    }

    @Test
    void adminRole_mapsToRoleAdminAuthority() {
        when(userManager.findByEmail("a@test.fr"))
                .thenReturn(Optional.of(user("a@test.fr", Role.ADMIN, true)));

        UserDetails details = service.loadUserByUsername("a@test.fr");

        assertThat(details.getAuthorities())
                .extracting(Object::toString)
                .containsExactly("ROLE_ADMIN");
    }

    @Test
    void inactiveUser_isDisabled() {
        when(userManager.findByEmail("off@test.fr"))
                .thenReturn(Optional.of(user("off@test.fr", Role.USER, false)));

        UserDetails details = service.loadUserByUsername("off@test.fr");

        assertThat(details.isEnabled()).isFalse();
    }
}

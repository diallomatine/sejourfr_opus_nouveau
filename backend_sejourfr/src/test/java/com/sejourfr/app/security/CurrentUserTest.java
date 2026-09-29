package com.sejourfr.app.security;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.Role;
import com.sejourfr.app.manager.UserManager;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CurrentUserTest {

    @Mock
    private UserManager userManager;

    @InjectMocks
    private CurrentUser currentUser;

    @AfterEach
    void clearContext() {
        SecurityContextHolder.clearContext();
    }

    private void authenticateAs(String email) {
        UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                email, null, List.of(new SimpleGrantedAuthority("ROLE_USER")));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    void get_returnsAuthenticatedUser() {
        User u = new User();
        u.setId(UUID.randomUUID());
        u.setEmail("karim@sejourfr.fr");
        u.setRole(Role.USER);
        authenticateAs("karim@sejourfr.fr");
        when(userManager.findByEmail("karim@sejourfr.fr")).thenReturn(Optional.of(u));

        assertThat(currentUser.get()).isSameAs(u);
    }

    @Test
    void getId_returnsUserId() {
        UUID id = UUID.randomUUID();
        User u = new User();
        u.setId(id);
        u.setEmail("a@b.fr");
        authenticateAs("a@b.fr");
        when(userManager.findByEmail("a@b.fr")).thenReturn(Optional.of(u));

        assertThat(currentUser.getId()).isEqualTo(id);
    }

    @Test
    void get_unauthenticated_throwsAccessDenied() {
        SecurityContextHolder.clearContext();

        assertThatThrownBy(() -> currentUser.get())
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void get_userNotFound_throwsAccessDenied() {
        authenticateAs("ghost@sejourfr.fr");
        when(userManager.findByEmail("ghost@sejourfr.fr")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> currentUser.get())
                .isInstanceOf(AccessDeniedException.class);
    }
}

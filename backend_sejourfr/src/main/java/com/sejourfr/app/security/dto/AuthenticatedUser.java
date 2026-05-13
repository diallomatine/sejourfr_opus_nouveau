package com.sejourfr.app.security.dto;

import com.sejourfr.app.user.User;
import com.sejourfr.app.user.enums.Role;

import java.util.UUID;

public record AuthenticatedUser(
        UUID id,
        String email,
        String firstName,
        String lastName,
        Role role
) {
    public static AuthenticatedUser from(User u) {
        return new AuthenticatedUser(u.getId(), u.getEmail(), u.getFirstName(), u.getLastName(), u.getRole());
    }
}

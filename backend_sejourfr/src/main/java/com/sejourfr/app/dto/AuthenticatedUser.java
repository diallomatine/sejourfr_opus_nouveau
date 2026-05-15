package com.sejourfr.app.dto;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.Role;
import com.sejourfr.app.enums.TargetProcedure;
import java.util.UUID;

public record AuthenticatedUser(
        UUID id,
        String email,
        String firstName,
        String lastName,
        Role role,
        TargetProcedure targetProcedure,
        boolean isPremium
) {
    public static AuthenticatedUser from(User u, boolean isPremium) {
        return new AuthenticatedUser(
                u.getId(),
                u.getEmail(),
                u.getFirstName(),
                u.getLastName(),
                u.getRole(),
                u.getTargetProcedure(),
                isPremium
        );
    }
}

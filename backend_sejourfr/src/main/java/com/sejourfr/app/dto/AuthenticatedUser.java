package com.sejourfr.app.dto;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AuthProvider;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.Role;
import com.sejourfr.app.enums.TargetProcedure;
import java.time.Instant;
import java.util.UUID;

public record AuthenticatedUser(
        UUID id,
        String email,
        String firstName,
        String lastName,
        Role role,
        TargetProcedure targetProcedure,
        boolean isPremium,
        boolean hasCivique,
        boolean hasTcf,
        Instant premiumEndsAt,
        AuthProvider authProvider
) {
    public static AuthenticatedUser from(User u, ModuleAccess access, Instant premiumEndsAt) {
        return new AuthenticatedUser(
                u.getId(),
                u.getEmail(),
                u.getFirstName(),
                u.getLastName(),
                u.getRole(),
                u.getTargetProcedure(),
                access != ModuleAccess.NONE,
                access.hasCivique(),
                access.hasTcf(),
                premiumEndsAt,
                u.getAuthProvider()
        );
    }
}

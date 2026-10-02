package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AuthProvider;
import com.sejourfr.app.enums.Role;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;

import java.time.Instant;
import java.util.UUID;

/**
 * Bloc « Compte » de la fiche admin (spec §5.5), lecture seule. 🛑 Jamais de
 * hash, de jeton ni d'identifiant de fournisseur social. {@code lastLoginAt} =
 * dernière authentification par identifiants ou social (un refresh de jeton ne
 * la met pas à jour).
 */
public record AdminUserAccountDto(
        UUID id,
        String email,
        String firstName,
        String lastName,
        String displayName,
        Instant createdAt,
        Instant lastLoginAt,
        String accountStatus,
        String accountStatusLabel,
        Role role,
        AuthProvider authProvider,
        boolean internal,
        TargetProcedure targetProcedure,
        TargetLevel targetLevel
) {}

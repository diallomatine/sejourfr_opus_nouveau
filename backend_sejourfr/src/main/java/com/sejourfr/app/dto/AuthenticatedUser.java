package com.sejourfr.app.dto;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AuthProvider;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.Role;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * L'utilisateur courant, tel que les trois fronts le lisent
 * ({@code GET /api/auth/me}).
 *
 * <p><b>{@code targetLevel} est DÉRIVÉ, jamais recopié depuis la colonne.</b>
 * Il vaut {@link TargetProcedure#niveauVise} : la démarche fait plancher, ce que
 * le candidat déclare peut le dépasser. Une ligne héritée incohérente
 * ({@code NAT} + {@code B1}, produite avant que le serveur ne pose lui-même le
 * palier) sort donc corrigée, sans migration — et aucun front ne peut afficher
 * un couple contradictoire.
 */
public record AuthenticatedUser(
        UUID id,
        String email,
        String firstName,
        String lastName,
        Role role,
        TargetProcedure targetProcedure,
        /** Palier VISÉ, plancher de la démarche appliqué. Null si rien n'est connu. */
        TargetLevel targetLevel,
        /**
         * Jour de l'examen déclaré par le candidat. {@code null} = pas de date,
         * réponse pleine et la plus fréquente. Les fronts l'affichent, ils ne
         * dérivent RIEN d'elle : le décompte en jours est servi ailleurs, par le
         * serveur.
         */
        LocalDate examDate,
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
                TargetProcedure.niveauVise(u.getTargetProcedure(), u.getTargetLevel()),
                u.getExamDate(),
                access != ModuleAccess.NONE,
                access.hasCivique(),
                access.hasTcf(),
                premiumEndsAt,
                u.getAuthProvider()
        );
    }
}

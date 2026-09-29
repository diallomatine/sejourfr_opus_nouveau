package com.sejourfr.app.dto;

import com.sejourfr.app.enums.TargetProcedure;
import jakarta.validation.constraints.NotNull;

/**
 * Payload pour PUT /api/me/target-path.
 *
 * Définit le parcours administratif visé par l'utilisateur :
 * CSP (Carte de séjour pluriannuelle), CR (Carte de résident)
 * ou NAT (Naturalisation française).
 */
public record UpdateTargetProcedureRequest(
        @NotNull TargetProcedure targetProcedure
) {}

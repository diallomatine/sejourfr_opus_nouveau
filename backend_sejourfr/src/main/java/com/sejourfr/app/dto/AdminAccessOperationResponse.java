package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AdminAccessOperationType;

import java.util.List;
import java.util.UUID;

/**
 * Résultat (ou aperçu, {@code dryRun}) d'une action admin. {@code preview} est
 * la phrase de confirmation calculée serveur ; {@code confirmationRequired}
 * dit si la modale doit demander une seconde validation (correction de
 * produit, raccourcissement, fin immédiate). {@code accesses} et
 * {@code effectiveAccess} = l'état RÉSULTANT, calculé par l'autorité unique.
 * {@code operationId} absent en aperçu. {@code accessVersion} : la version à
 * renvoyer pour l'action suivante.
 */
public record AdminAccessOperationResponse(
        boolean dryRun,
        UUID operationId,
        AdminAccessOperationType operation,
        String preview,
        boolean confirmationRequired,
        List<String> changes,
        AdminEffectiveAccessDto effectiveAccess,
        List<AdminUserAccessDto> accesses,
        String accessVersion
) {}

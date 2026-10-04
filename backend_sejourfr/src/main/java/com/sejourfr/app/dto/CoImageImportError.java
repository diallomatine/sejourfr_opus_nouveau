package com.sejourfr.app.dto;

import com.sejourfr.app.enums.CoImageImportErrorCode;

/**
 * Une erreur du rapport d'import CO image.
 *
 * @param field chemin du champ fautif, relatif a la question pour une erreur de
 *              question ({@code externalId}, {@code choices[2]}, {@code image}…),
 *              au manifeste ou au nom du fichier pour une erreur de lot ;
 *              {@code null} quand l'erreur porte sur l'ensemble
 */
public record CoImageImportError(
        CoImageImportErrorCode code,
        String field,
        String message
) {}

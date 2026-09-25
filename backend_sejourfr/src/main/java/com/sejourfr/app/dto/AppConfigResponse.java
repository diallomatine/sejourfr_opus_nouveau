package com.sejourfr.app.dto;

/**
 * Reponse de {@code GET /api/public/app-config} (controle G, option a).
 *
 * @param minSupportedVersion version minimale de l'application par systeme ;
 *                            {@code null} = aucune exigence, personne n'est bloque
 */
public record AppConfigResponse(MinSupportedVersion minSupportedVersion) {

    /** {@code "MAJOR.MINOR.PATCH"} ou {@code null}, par systeme. */
    public record MinSupportedVersion(String ios, String android) {
    }
}

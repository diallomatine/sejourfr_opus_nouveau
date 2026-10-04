package com.sejourfr.app.dto;

import java.util.List;

/**
 * Manifeste d'un lot de questions CO image (partie {@code manifest} du
 * multipart d'import). Format §4.2 de l'audit : {@code version = "1"},
 * {@code format = "CO_IMAGE"}, 1 a N questions.
 */
public record CoImageImportManifest(
        String version,
        String format,
        List<CoImageImportQuestion> questions
) {}

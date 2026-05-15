package com.sejourfr.app.dto;

import com.sejourfr.app.enums.MediaType;

import java.util.UUID;

/**
 * Vue publique d'un Media renvoyée au runner.
 *
 * Si {@link #inlineSvg} est non-null, le front doit le rendre tel quel
 * (les questions TCF compréhension écrite avec captures dessinées passent
 * par ce canal). Sinon, charger l'image/audio via {@link #url}.
 */
public record MediaResponse(
        UUID id,
        MediaType type,
        String url,
        Integer durationSeconds,
        String transcript,
        String inlineSvg
) {}

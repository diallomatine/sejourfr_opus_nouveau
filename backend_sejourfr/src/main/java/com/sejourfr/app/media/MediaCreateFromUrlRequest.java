package com.sejourfr.app.media;

import com.sejourfr.app.media.enums.MediaType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record MediaCreateFromUrlRequest(
        @NotNull(message = "Le type est requis")
        MediaType type,

        @NotBlank(message = "L'URL est requise")
        @Size(max = 500)
        String url,

        Integer durationSec,

        @Size(max = 500)
        String altText
) {}

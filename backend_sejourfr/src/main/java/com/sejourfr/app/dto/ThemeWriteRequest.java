package com.sejourfr.app.dto;

import com.sejourfr.app.enums.Module;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record ThemeWriteRequest(
        @NotNull(message = "Le module est requis")
        Module module,

        @NotBlank(message = "Le code est requis")
        @Size(max = 64)
        String code,

        @NotBlank(message = "Le nom est requis")
        @Size(max = 200)
        String name,

        String description,
        int displayOrder
) {}

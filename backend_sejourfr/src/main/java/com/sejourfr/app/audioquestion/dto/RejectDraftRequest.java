package com.sejourfr.app.audioquestion.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RejectDraftRequest(
    @NotBlank @Size(max = 2000) String reason
) {}

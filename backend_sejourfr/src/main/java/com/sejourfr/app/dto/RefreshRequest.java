package com.sejourfr.app.dto;

import jakarta.validation.constraints.NotBlank;

public record RefreshRequest(
        @NotBlank(message = "refreshToken requis")
        String refreshToken
) {}

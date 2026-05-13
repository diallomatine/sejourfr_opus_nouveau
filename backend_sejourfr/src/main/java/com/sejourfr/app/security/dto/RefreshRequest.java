package com.sejourfr.app.security.dto;

import jakarta.validation.constraints.NotBlank;

public record RefreshRequest(
        @NotBlank(message = "refreshToken requis")
        String refreshToken
) {}

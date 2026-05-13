package com.sejourfr.app.dto;

public record TokenResponse(
        String accessToken,
        String refreshToken,
        long expiresInSeconds,
        String tokenType,
        AuthenticatedUser user
) {
    public static TokenResponse of(String access, String refresh, long ttl, AuthenticatedUser user) {
        return new TokenResponse(access, refresh, ttl, "Bearer", user);
    }
}

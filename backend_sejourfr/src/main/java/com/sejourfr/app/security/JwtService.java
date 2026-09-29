package com.sejourfr.app.security;

import com.sejourfr.app.entity.User;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;

@Service
public class JwtService {

    public static final String TYPE_ACCESS = "access";
    public static final String TYPE_REFRESH = "refresh";
    private static final String CLAIM_TYPE = "type";
    private static final String CLAIM_ROLE = "role";
    private static final String CLAIM_EMAIL = "email";
    private final JwtProperties properties;
    private final SecretKey key;

    public JwtService(JwtProperties properties) {
        this.properties = properties;
        if (properties.getSecret() == null || properties.getSecret().isBlank()) {
            throw new IllegalStateException(
                    "sejourfr.security.jwt.secret est requis (Base64, >= 32 octets)");
        }
        byte[] bytes = Decoders.BASE64.decode(properties.getSecret());
        if (bytes.length < 32) {
            throw new IllegalStateException("Secret JWT trop court : >= 32 octets requis");
        }
        this.key = Keys.hmacShaKeyFor(bytes);
    }

    public String generateAccessToken(User user) {
        Instant now = Instant.now();
        Instant exp = now.plus(Duration.ofMinutes(properties.getAccessTokenTtlMinutes()));
        return Jwts.builder()
                .issuer(properties.getIssuer())
                .subject(user.getId().toString())
                .claim(CLAIM_TYPE, TYPE_ACCESS)
                .claim(CLAIM_EMAIL, user.getEmail())
                .claim(CLAIM_ROLE, user.getRole().name())
                .issuedAt(Date.from(now))
                .expiration(Date.from(exp))
                .signWith(key)
                .compact();
    }

    /**
     * Génère un refresh token signé contenant un {@code jti} qui sert d'index
     * dans la table {@code refresh_tokens} côté serveur. À chaque
     * {@code /refresh}, on lookup cette row pour vérifier que la session n'a
     * pas été révoquée (cf. {@code SessionService}).
     */
    public String generateRefreshToken(User user, UUID jti) {
        Instant now = Instant.now();
        Instant exp = now.plus(Duration.ofDays(properties.getRefreshTokenTtlDays()));
        return Jwts.builder()
                .issuer(properties.getIssuer())
                .subject(user.getId().toString())
                .id(jti.toString())
                .claim(CLAIM_TYPE, TYPE_REFRESH)
                .issuedAt(Date.from(now))
                .expiration(Date.from(exp))
                .signWith(key)
                .compact();
    }

    /**
     * Extrait le {@code jti} d'un refresh token. Lève {@link IllegalArgumentException}
     * si absent ou mal formé — un refresh token sans jti n'est pas exploitable
     * par le serveur (toutes les sessions modernes en ont un).
     */
    public UUID extractJti(Claims claims) {
        String jtiStr = claims.getId();
        if (jtiStr == null || jtiStr.isBlank()) {
            throw new IllegalArgumentException("Refresh token sans jti");
        }
        return UUID.fromString(jtiStr);
    }

    /** Durée de vie d'un refresh token (utilisée par {@code SessionService}). */
    public Duration refreshTokenTtl() {
        return Duration.ofDays(properties.getRefreshTokenTtlDays());
    }

    public Claims parseAndValidate(String token) {
        try {
            return Jwts.parser()
                    .verifyWith(key)
                    .requireIssuer(properties.getIssuer())
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
        } catch (JwtException ex) {
            throw new JwtException("Token JWT invalide : " + ex.getMessage(), ex);
        }
    }

    public boolean isAccessToken(Claims claims) {
        return TYPE_ACCESS.equals(claims.get(CLAIM_TYPE, String.class));
    }

    public boolean isRefreshToken(Claims claims) {
        return TYPE_REFRESH.equals(claims.get(CLAIM_TYPE, String.class));
    }

    public long accessTokenTtlSeconds() {
        return properties.getAccessTokenTtlMinutes() * 60L;
    }
}

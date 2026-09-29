package com.sejourfr.app.security;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.Role;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import org.junit.jupiter.api.Test;

import java.util.Base64;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JwtServiceTest {

    /** Base64 de 48 octets (cf. application-test.yaml) — secret HMAC valide. */
    private static final String VALID_SECRET =
            "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWYwMTIzNDU2Nzg5YWJjZGVm";
    private static final String ISSUER = "sejourfr-test";

    private JwtProperties props(String secret, String issuer) {
        JwtProperties p = new JwtProperties();
        p.setSecret(secret);
        p.setIssuer(issuer);
        return p;
    }

    private JwtService service(String secret, String issuer) {
        return new JwtService(props(secret, issuer));
    }

    private User user(UUID id, String email, Role role) {
        User u = new User();
        u.setId(id);
        u.setEmail(email);
        u.setRole(role);
        return u;
    }

    @Test
    void accessToken_roundTrip_exposesSubjectEmailRole() {
        JwtService svc = service(VALID_SECRET, ISSUER);
        UUID id = UUID.randomUUID();
        User u = user(id, "karim@sejourfr.fr", Role.USER);

        String token = svc.generateAccessToken(u);
        Claims claims = svc.parseAndValidate(token);

        assertThat(claims.getSubject()).isEqualTo(id.toString());
        assertThat(claims.get("email", String.class)).isEqualTo("karim@sejourfr.fr");
        assertThat(claims.get("role", String.class)).isEqualTo("USER");
        assertThat(svc.isAccessToken(claims)).isTrue();
        assertThat(svc.isRefreshToken(claims)).isFalse();
    }

    @Test
    void refreshToken_carriesJti() {
        JwtService svc = service(VALID_SECRET, ISSUER);
        UUID jti = UUID.randomUUID();
        User u = user(UUID.randomUUID(), "a@b.fr", Role.ADMIN);

        String token = svc.generateRefreshToken(u, jti);
        Claims claims = svc.parseAndValidate(token);

        assertThat(svc.extractJti(claims)).isEqualTo(jti);
        assertThat(svc.isRefreshToken(claims)).isTrue();
        assertThat(svc.isAccessToken(claims)).isFalse();
    }

    @Test
    void extractJti_missingJti_throws() {
        JwtService svc = service(VALID_SECRET, ISSUER);
        // un access token n'a pas de jti
        Claims claims = svc.parseAndValidate(
                svc.generateAccessToken(user(UUID.randomUUID(), "x@y.fr", Role.USER)));

        assertThatThrownBy(() -> svc.extractJti(claims))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void wrongIssuer_rejected() {
        JwtService issuer = service(VALID_SECRET, "issuer-A");
        JwtService verifier = service(VALID_SECRET, "issuer-B");
        String token = issuer.generateAccessToken(user(UUID.randomUUID(), "a@b.fr", Role.USER));

        assertThatThrownBy(() -> verifier.parseAndValidate(token))
                .isInstanceOf(JwtException.class);
    }

    @Test
    void tamperedToken_rejected() {
        JwtService svc = service(VALID_SECRET, ISSUER);
        String token = svc.generateAccessToken(user(UUID.randomUUID(), "a@b.fr", Role.USER));
        String tampered = token.substring(0, token.length() - 3) + "abc";

        assertThatThrownBy(() -> svc.parseAndValidate(tampered))
                .isInstanceOf(JwtException.class);
    }

    @Test
    void garbageToken_rejected() {
        JwtService svc = service(VALID_SECRET, ISSUER);

        assertThatThrownBy(() -> svc.parseAndValidate("not-a-jwt"))
                .isInstanceOf(JwtException.class);
    }

    @Test
    void expiredToken_rejected() {
        JwtProperties p = props(VALID_SECRET, ISSUER);
        p.setAccessTokenTtlMinutes(-10); // exp dans le passé
        JwtService svc = new JwtService(p);
        String token = svc.generateAccessToken(user(UUID.randomUUID(), "a@b.fr", Role.USER));

        assertThatThrownBy(() -> svc.parseAndValidate(token))
                .isInstanceOf(JwtException.class);
    }

    @Test
    void accessTokenTtlSeconds_isMinutesTimes60() {
        JwtProperties p = props(VALID_SECRET, ISSUER);
        p.setAccessTokenTtlMinutes(60);
        assertThat(new JwtService(p).accessTokenTtlSeconds()).isEqualTo(3600L);
    }

    @Test
    void constructor_blankSecret_throws() {
        assertThatThrownBy(() -> service("   ", ISSUER))
                .isInstanceOf(IllegalStateException.class);
        assertThatThrownBy(() -> service(null, ISSUER))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void constructor_secretTooShort_throws() {
        String shortSecret = Base64.getEncoder()
                .encodeToString("under-32-bytes".getBytes());
        assertThatThrownBy(() -> service(shortSecret, ISSUER))
                .isInstanceOf(IllegalStateException.class);
    }
}

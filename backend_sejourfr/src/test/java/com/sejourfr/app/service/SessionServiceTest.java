package com.sejourfr.app.service;

import com.sejourfr.app.entity.RefreshToken;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.RefreshTokenManager;
import com.sejourfr.app.security.JwtService;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Test unitaire pur du cycle de vie de session : émission, rotation
 * (révocation de l'ancien + chaînage replaced_by), refus des tokens
 * invalides/révoqués/expirés, logout idempotent. JwtService mocké (pas de
 * vraie crypto JWT) — on pilote directement les verdicts.
 */
class SessionServiceTest {

    private JwtService jwtService;
    private RefreshTokenManager refreshTokenManager;
    private SessionService service;

    @BeforeEach
    void setUp() {
        jwtService = mock(JwtService.class);
        refreshTokenManager = mock(RefreshTokenManager.class);
        service = new SessionService(jwtService, refreshTokenManager);

        when(jwtService.refreshTokenTtl()).thenReturn(Duration.ofDays(30));
        when(jwtService.generateAccessToken(any())).thenReturn("access");
        when(jwtService.generateRefreshToken(any(), any())).thenReturn("refresh");
    }

    private static User activeUser() {
        User u = new User();
        u.setId(UUID.randomUUID());
        u.setActive(true);
        return u;
    }

    // ------------------------------------------------------------------ openSession

    @Test
    void openSession_persistsRefreshTokenAndSignsBoth() {
        User u = activeUser();

        SessionService.IssuedTokens tokens = service.openSession(u, "ua", "ip");

        assertThat(tokens.accessToken()).isEqualTo("access");
        assertThat(tokens.refreshToken()).isEqualTo("refresh");
        assertThat(tokens.user()).isSameAs(u);
        org.mockito.ArgumentCaptor<RefreshToken> captor = org.mockito.ArgumentCaptor.forClass(RefreshToken.class);
        verify(refreshTokenManager).save(captor.capture());
        RefreshToken rt = captor.getValue();
        assertThat(rt.getJti()).isEqualTo(tokens.jti());
        assertThat(rt.getUser()).isSameAs(u);
        assertThat(rt.getExpiresAt()).isAfter(Instant.now());
    }

    // ------------------------------------------------------------------ rotate (refus)

    @Test
    void rotate_invalidJwt_throwsBusiness() {
        when(jwtService.parseAndValidate("bad")).thenThrow(new JwtException("nope"));
        assertThatThrownBy(() -> service.rotate("bad", "ua", "ip"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("invalide");
    }

    @Test
    void rotate_notARefreshToken_throws() {
        Claims claims = mock(Claims.class);
        when(jwtService.parseAndValidate("acc")).thenReturn(claims);
        when(jwtService.isRefreshToken(claims)).thenReturn(false);

        assertThatThrownBy(() -> service.rotate("acc", "ua", "ip"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("pas un refresh token");
    }

    @Test
    void rotate_noJti_throws() {
        Claims claims = mock(Claims.class);
        when(jwtService.parseAndValidate("tok")).thenReturn(claims);
        when(jwtService.isRefreshToken(claims)).thenReturn(true);
        when(jwtService.extractJti(claims)).thenThrow(new IllegalArgumentException("no jti"));

        assertThatThrownBy(() -> service.rotate("tok", "ua", "ip"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("jti");
    }

    @Test
    void rotate_unknownJti_throws() {
        Claims claims = mock(Claims.class);
        UUID jti = UUID.randomUUID();
        when(jwtService.parseAndValidate("tok")).thenReturn(claims);
        when(jwtService.isRefreshToken(claims)).thenReturn(true);
        when(jwtService.extractJti(claims)).thenReturn(jti);
        when(refreshTokenManager.findByJti(jti)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.rotate("tok", "ua", "ip"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("révoquée ou inconnue");
    }

    @Test
    void rotate_revokedToken_throws() {
        RefreshToken stored = storedToken(activeUser());
        stored.setRevokedAt(Instant.now());
        stubRotateLookup(stored);

        assertThatThrownBy(() -> service.rotate("tok", "ua", "ip"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("révoquée");
        verify(refreshTokenManager, never()).save(any());
    }

    @Test
    void rotate_expiredToken_throws() {
        RefreshToken stored = storedToken(activeUser());
        stored.setExpiresAt(Instant.now().minus(1, ChronoUnit.DAYS));
        stubRotateLookup(stored);

        assertThatThrownBy(() -> service.rotate("tok", "ua", "ip"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("expirée");
    }

    @Test
    void rotate_inactiveUser_throws() {
        User u = activeUser();
        u.setActive(false);
        RefreshToken stored = storedToken(u);
        stubRotateLookup(stored);

        assertThatThrownBy(() -> service.rotate("tok", "ua", "ip"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("désactivé");
    }

    @Test
    void rotate_success_revokesOld_chainsReplacedBy_issuesNew() {
        RefreshToken stored = storedToken(activeUser());
        UUID oldJti = stored.getJti();
        stubRotateLookup(stored);

        SessionService.IssuedTokens tokens = service.rotate("tok", "ua", "ip");

        assertThat(stored.getRevokedAt()).isNotNull();
        assertThat(stored.getReplacedBy()).isNotNull().isNotEqualTo(oldJti);
        assertThat(tokens.jti()).isEqualTo(stored.getReplacedBy());
        assertThat(tokens.accessToken()).isEqualTo("access");
        // save() appelé deux fois : nouveau token + ancien marqué révoqué.
        verify(refreshTokenManager, times(2)).save(any());
    }

    // ------------------------------------------------------------------ closeSession

    @Test
    void closeSession_nullOrBlank_isNoop() {
        service.closeSession(null);
        service.closeSession("  ");
        verify(jwtService, never()).parseAndValidate(any());
    }

    @Test
    void closeSession_validToken_revokes() {
        RefreshToken stored = storedToken(activeUser());
        stubRotateLookup(stored);

        service.closeSession("tok");

        assertThat(stored.getRevokedAt()).isNotNull();
        verify(refreshTokenManager).save(stored);
    }

    @Test
    void closeSession_alreadyRevoked_doesNotResave() {
        RefreshToken stored = storedToken(activeUser());
        stored.setRevokedAt(Instant.now());
        stubRotateLookup(stored);

        service.closeSession("tok");

        verify(refreshTokenManager, never()).save(any());
    }

    @Test
    void closeSession_invalidToken_silent() {
        when(jwtService.parseAndValidate("bad")).thenThrow(new JwtException("nope"));
        service.closeSession("bad");
        verify(refreshTokenManager, never()).save(any());
    }

    // ------------------------------------------------------------------ revokeAll

    @Test
    void revokeAllForUser_delegatesAndReturnsCount() {
        UUID userId = UUID.randomUUID();
        when(refreshTokenManager.revokeAllForUser(userId)).thenReturn(3);

        assertThat(service.revokeAllForUser(userId)).isEqualTo(3);
        verify(refreshTokenManager).revokeAllForUser(userId);
    }

    // ------------------------------------------------------------------ helpers

    private RefreshToken storedToken(User user) {
        RefreshToken rt = new RefreshToken();
        rt.setJti(UUID.randomUUID());
        rt.setUser(user);
        rt.setExpiresAt(Instant.now().plus(30, ChronoUnit.DAYS));
        return rt;
    }

    private void stubRotateLookup(RefreshToken stored) {
        Claims claims = mock(Claims.class);
        when(jwtService.parseAndValidate("tok")).thenReturn(claims);
        when(jwtService.isRefreshToken(claims)).thenReturn(true);
        when(jwtService.extractJti(claims)).thenReturn(stored.getJti());
        when(refreshTokenManager.findByJti(stored.getJti())).thenReturn(Optional.of(stored));
    }
}

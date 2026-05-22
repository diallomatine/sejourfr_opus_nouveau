package com.sejourfr.app.service;

import com.sejourfr.app.entity.RefreshToken;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.RefreshTokenManager;
import com.sejourfr.app.security.JwtService;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/**
 * Cycle de vie d'une session utilisateur : émission d'un couple access/refresh,
 * rotation au {@code /refresh}, révocation au logout ou à la cascade
 * (changePassword / resetPassword / confirmEmailChange).
 *
 * <p>Le refresh token est un JWT signé contenant un {@code jti} qui sert
 * d'index dans la table {@code refresh_tokens} côté serveur — état persisté =
 * révocable. Cf. audit Vuln 3.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class SessionService {

    private final JwtService jwtService;
    private final RefreshTokenManager refreshTokenManager;

    /**
     * Couple access + refresh fraîchement émis. {@code jti} retourné pour
     * traçabilité éventuelle côté caller (logs). {@code user} permet de
     * construire le {@code TokenResponse} sans re-charger l'entité.
     */
    public record IssuedTokens(String accessToken, String refreshToken, UUID jti, User user) {}

    /**
     * Démarre une nouvelle session — appelé par login (LOCAL ou social).
     * Crée une row {@code refresh_tokens} et signe le JWT correspondant.
     */
    @Transactional
    public IssuedTokens openSession(User user, String userAgent, String ipAddress) {
        UUID jti = UUID.randomUUID();
        RefreshToken rt = new RefreshToken();
        rt.setJti(jti);
        rt.setUser(user);
        rt.setExpiresAt(Instant.now().plus(jwtService.refreshTokenTtl()));
        rt.setUserAgent(truncate(userAgent, 500));
        rt.setIpAddress(truncate(ipAddress, 64));
        refreshTokenManager.save(rt);

        String access = jwtService.generateAccessToken(user);
        String refresh = jwtService.generateRefreshToken(user, jti);
        return new IssuedTokens(access, refresh, jti, user);
    }

    /**
     * Rotate la session : valide l'ancien refresh JWT, vérifie qu'il a une
     * row active, révoque l'ancien et émet un successeur.
     *
     * @throws BusinessException si le token est invalide / révoqué / inconnu /
     *         le user n'est plus actif.
     */
    @Transactional
    public IssuedTokens rotate(String refreshTokenJwt, String userAgent, String ipAddress) {
        Claims claims;
        try {
            claims = jwtService.parseAndValidate(refreshTokenJwt);
        } catch (JwtException ex) {
            throw new BusinessException("Refresh token invalide");
        }
        if (!jwtService.isRefreshToken(claims)) {
            throw new BusinessException("Le token fourni n'est pas un refresh token");
        }

        UUID jti;
        try {
            jti = jwtService.extractJti(claims);
        } catch (IllegalArgumentException ex) {
            throw new BusinessException("Refresh token sans jti — token obsolète, reconnectez-vous");
        }

        RefreshToken stored = refreshTokenManager.findByJti(jti)
                .orElseThrow(() -> new BusinessException("Session révoquée ou inconnue"));

        if (stored.isRevoked()) {
            // Detection de potentiel re-use : un token révoqué qui revient.
            // Pour l'instant on logge et on refuse — un attaquant qui aurait
            // volé un token verra son accès refusé. Plus tard on pourrait
            // cascade-revoke toute la chaîne.
            log.warn("Tentative de re-use d'un refresh token révoqué jti={} user={}",
                    jti, stored.getUser().getId());
            throw new BusinessException("Session révoquée");
        }
        if (stored.isExpired()) {
            throw new BusinessException("Session expirée");
        }

        User user = stored.getUser();
        if (!user.isActive()) {
            throw new BusinessException("Compte désactivé");
        }

        // Rotation : nouveau jti, ancien marqué revoked + replaced_by.
        UUID newJti = UUID.randomUUID();
        RefreshToken next = new RefreshToken();
        next.setJti(newJti);
        next.setUser(user);
        next.setExpiresAt(Instant.now().plus(jwtService.refreshTokenTtl()));
        next.setUserAgent(truncate(userAgent, 500));
        next.setIpAddress(truncate(ipAddress, 64));
        refreshTokenManager.save(next);

        stored.setRevokedAt(Instant.now());
        stored.setReplacedBy(newJti);
        refreshTokenManager.save(stored);

        String access = jwtService.generateAccessToken(user);
        String refresh = jwtService.generateRefreshToken(user, newJti);
        return new IssuedTokens(access, refresh, newJti, user);
    }

    /**
     * Logout : révoque le refresh token fourni. Idempotent et silencieux —
     * un token invalide, inconnu ou déjà révoqué renvoie sans erreur.
     */
    @Transactional
    public void closeSession(String refreshTokenJwt) {
        if (refreshTokenJwt == null || refreshTokenJwt.isBlank()) return;
        try {
            Claims claims = jwtService.parseAndValidate(refreshTokenJwt);
            if (!jwtService.isRefreshToken(claims)) return;
            UUID jti = jwtService.extractJti(claims);
            Optional<RefreshToken> stored = refreshTokenManager.findByJti(jti);
            stored.ifPresent(t -> {
                if (!t.isRevoked()) {
                    t.setRevokedAt(Instant.now());
                    refreshTokenManager.save(t);
                }
            });
        } catch (Exception ignored) {
            // Logout silencieux : peu importe pourquoi le token n'est pas
            // valide, l'effet (user déconnecté) doit toujours être atteint
            // côté client.
        }
    }

    /**
     * Révoque toutes les sessions actives d'un utilisateur — à appeler après
     * changePassword, resetPassword, confirmEmailChange. Force l'attaquant
     * potentiel à se reconnecter (mais il n'a plus le nouveau mot de passe).
     */
    @Transactional
    public int revokeAllForUser(UUID userId) {
        int revoked = refreshTokenManager.revokeAllForUser(userId);
        if (revoked > 0) {
            log.info("Révocation de {} session(s) active(s) pour user={}", revoked, userId);
        }
        return revoked;
    }

    private static String truncate(String s, int max) {
        if (s == null) return null;
        return s.length() <= max ? s : s.substring(0, max);
    }
}

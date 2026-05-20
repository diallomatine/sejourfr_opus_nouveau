package com.sejourfr.app.service;

import com.sejourfr.app.dto.AuthenticatedUser;
import com.sejourfr.app.dto.LoginRequest;
import com.sejourfr.app.dto.RefreshRequest;
import com.sejourfr.app.dto.RegisterRequest;
import com.sejourfr.app.dto.TokenResponse;
import com.sejourfr.app.entity.PasswordResetToken;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.Role;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.PasswordResetTokenManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.security.JwtService;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Optional;
import java.util.UUID;

/**
 * Facade unique pour AuthController : login / refresh / me, register et
 * password reset (request + apply).
 */
@Service
@Transactional
@RequiredArgsConstructor
public class AuthService {

    private static final Duration RESET_TOKEN_TTL = Duration.ofHours(1);
    private static final int RESET_TOKEN_BYTES = 48;

    private final AuthenticationManager authenticationManager;
    private final UserManager userManager;
    private final PasswordResetTokenManager passwordResetTokenManager;
    private final JwtService jwtService;
    private final SubscriptionService subscriptionService;
    private final MailService mailService;
    private final PasswordEncoder passwordEncoder;

    private final SecureRandom random = new SecureRandom();

    // ------------------------------------------------------------------------
    // Login / refresh / me
    // ------------------------------------------------------------------------

    public TokenResponse login(LoginRequest req) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(req.email(), req.password()));
        } catch (BadCredentialsException ex) {
            throw new BadCredentialsException("Identifiants invalides");
        }

        User u = userManager.findByEmail(req.email())
                .orElseThrow(() -> new BadCredentialsException("Identifiants invalides"));

        u.setLastLoginAt(Instant.now());
        return buildTokenResponse(u);
    }

    public TokenResponse refresh(RefreshRequest req) {
        Claims claims;
        try {
            claims = jwtService.parseAndValidate(req.refreshToken());
        } catch (JwtException ex) {
            throw new BusinessException("Refresh token invalide");
        }
        if (!jwtService.isRefreshToken(claims)) {
            throw new BusinessException("Le token fourni n'est pas un refresh token");
        }

        UUID userId = UUID.fromString(claims.getSubject());
        User u = userManager.findById(userId)
                .orElseThrow(() -> NotFoundException.of("User", userId));
        if (!u.isActive()) {
            throw new BusinessException("Compte desactive");
        }
        return buildTokenResponse(u);
    }

    @Transactional(readOnly = true)
    public AuthenticatedUser me(String email) {
        User u = userManager.findByEmail(email)
                .orElseThrow(() -> NotFoundException.of("User", email));
        SubscriptionService.CurrentAccess current = subscriptionService.currentAccess(u.getId());
        return AuthenticatedUser.from(u, current.module(), current.endsAt());
    }

    // ------------------------------------------------------------------------
    // Register
    // ------------------------------------------------------------------------

    /**
     * Cree un compte USER puis enchaine sur {@link #login} pour retourner les
     * tokens (l'utilisateur est connecte sans avoir a re-saisir son mot de passe).
     */
    public TokenResponse register(RegisterRequest req) {
        String email = req.email().toLowerCase().trim();
        if (userManager.existsByEmail(email)) {
            throw new IllegalArgumentException("Un compte existe déjà avec cet email");
        }

        User user = new User();
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(req.password()));
        user.setFirstName(req.firstName().trim());
        user.setLastName(req.lastName().trim());
        user.setRole(Role.USER);
        user.setCreatedAt(Instant.now());
        userManager.save(user);

        return login(new LoginRequest(email, req.password()));
    }

    // ------------------------------------------------------------------------
    // Password reset
    // ------------------------------------------------------------------------

    /**
     * Genere un token de reset, le persiste hash et envoie l'email.
     * <p>
     * Ne revele JAMAIS si l'email existe ou pas — silencieux + 200 cote API,
     * sinon on permet l'enumeration des comptes.
     */
    public void requestPasswordReset(String email) {
        Optional<User> userOpt = userManager.findByEmail(email.toLowerCase().trim());
        if (userOpt.isEmpty()) return; // silencieux

        User user = userOpt.get();
        passwordResetTokenManager.invalidateAllForUser(user.getId(), Instant.now());

        String rawToken = generateRawToken();
        PasswordResetToken token = new PasswordResetToken();
        token.setUser(user);
        token.setTokenHash(sha256(rawToken));
        token.setExpiresAt(Instant.now().plus(RESET_TOKEN_TTL));
        passwordResetTokenManager.save(token);

        mailService.sendPasswordResetEmail(user.getEmail(), rawToken);
    }

    /**
     * Applique un reset a partir du token recu par email.
     *
     * @throws IllegalArgumentException si le token est invalide ou expire.
     */
    public void resetPassword(String rawToken, String newPassword) {
        PasswordResetToken token = passwordResetTokenManager.findByTokenHash(sha256(rawToken))
                .orElseThrow(() -> new IllegalArgumentException("Token invalide"));

        if (!token.isValid()) {
            throw new IllegalArgumentException("Token expiré ou déjà utilisé");
        }

        User user = token.getUser();
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userManager.save(user);

        token.setUsedAt(Instant.now());
        passwordResetTokenManager.save(token);
    }

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------

    private TokenResponse buildTokenResponse(User u) {
        String access = jwtService.generateAccessToken(u);
        String refresh = jwtService.generateRefreshToken(u);
        SubscriptionService.CurrentAccess current = subscriptionService.currentAccess(u.getId());
        return TokenResponse.of(access, refresh, jwtService.accessTokenTtlSeconds(),
                AuthenticatedUser.from(u, current.module(), current.endsAt()));
    }

    private String generateRawToken() {
        byte[] bytes = new byte[RESET_TOKEN_BYTES];
        random.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private static String sha256(String value) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(value.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}

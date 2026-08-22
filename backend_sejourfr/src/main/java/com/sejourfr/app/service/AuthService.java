package com.sejourfr.app.service;

import com.sejourfr.app.dto.AuthenticatedUser;
import com.sejourfr.app.dto.LoginRequest;
import com.sejourfr.app.dto.RefreshRequest;
import com.sejourfr.app.dto.RegisterRequest;
import com.sejourfr.app.dto.TokenResponse;
import com.sejourfr.app.entity.PasswordResetToken;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.Role;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.PasswordResetTokenManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.security.JwtService;
import com.sejourfr.app.service.analytics.AnalyticsIdentityService;
import com.sejourfr.app.util.ClientContext;
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
    private final SessionService sessionService;
    private final SubscriptionService subscriptionService;
    private final MailService mailService;
    private final MeService meService;
    private final PasswordEncoder passwordEncoder;
    private final AnalyticsIdentityService analyticsIdentityService;

    private final SecureRandom random = new SecureRandom();

    // ------------------------------------------------------------------------
    // Login / refresh / me
    // ------------------------------------------------------------------------

    public TokenResponse login(LoginRequest req, String userAgent, String ipAddress) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(req.email(), req.password()));
        } catch (BadCredentialsException ex) {
            throw new BadCredentialsException("Identifiants invalides");
        }

        User u = userManager.findByEmail(req.email())
                .orElseThrow(() -> new BadCredentialsException("Identifiants invalides"));

        u.setLastLoginAt(Instant.now());
        // Rattache le parcours anonyme de cet appareil au compte. Posé à CHAQUE
        // connexion et pas seulement à l'inscription : un visiteur peut avoir
        // parcouru le site longtemps avant, sur un appareil qu'il n'utilisait
        // pas le jour de la création. Idempotent, et best-effort — une mesure
        // d'audience n'a jamais le droit d'empêcher quelqu'un de se connecter.
        analyticsIdentityService.link(req.anonymousId(), u.getId());
        return buildTokenResponse(u, userAgent, ipAddress);
    }

    public TokenResponse refresh(RefreshRequest req, String userAgent, String ipAddress) {
        SessionService.IssuedTokens tokens = sessionService.rotate(
                req.refreshToken(), userAgent, ipAddress);
        return tokenResponseFrom(tokens);
    }

    /**
     * Révoque le refresh token fourni — endpoint POST /api/auth/logout.
     * Silencieux : un token déjà invalide / expiré renvoie sans erreur (côté
     * client la session est effacée localement quoi qu'il arrive).
     */
    public void logout(String refreshToken) {
        sessionService.closeSession(refreshToken);
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
     *
     * <p><b>La démarche visée, si elle est fournie, passe par
     * {@link MeService#updateTargetProcedure} — jamais par une écriture locale.</b>
     * C'est le seul point d'écriture de {@code users.target_procedure} et donc le
     * seul endroit qui pose {@code users.target_level} : poser le palier ici
     * aurait fait une deuxième copie de la table démarche → niveau, exactement le
     * défaut qui a tiré un candidat visant la naturalisation vers le B1. Sans
     * démarche, on ne touche à rien (le mobile n'en envoie pas : il a son écran
     * de parcours dédié).
     *
     * <p><b>La provenance est posée ici et jamais ailleurs</b>
     * ({@code users.signup_source} / {@code signup_platform}) : c'est le seul
     * instant où « d'où vient ce compte » a un sens. La réécrire à une visite
     * ultérieure attribuerait toutes les acquisitions au dernier canal utilisé.
     */
    public TokenResponse register(RegisterRequest req, String userAgent, String ipAddress,
                                  ClientContext client) {
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
        ClientContext ctx = client == null ? ClientContext.unknown() : client;
        user.setSignupSource(ctx.source());
        user.setSignupPlatform(ctx.platform());
        userManager.save(user);

        if (req.targetProcedure() != null) {
            meService.updateTargetProcedure(user.getId(), req.targetProcedure());
        }

        mailService.sendWelcomeEmail(user.getEmail(), user.getFirstName());

        // Le lien anonyme -> compte est posé par le login enchaîné ci-dessous :
        // on lui repasse l'anonymousId reçu ici. Un seul point d'écriture, donc
        // aucun risque qu'inscription et connexion divergent.
        return login(new LoginRequest(email, req.password(), req.anonymousId()),
                userAgent, ipAddress);
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

        // Cascade : révoque toutes les sessions actives (audit Vuln 3). Un
        // refresh token volé devient invalide après reset, donc l'attaquant
        // ne peut plus prolonger sa session.
        sessionService.revokeAllForUser(user.getId());
    }

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------

    private TokenResponse buildTokenResponse(User u, String userAgent, String ipAddress) {
        SessionService.IssuedTokens tokens = sessionService.openSession(u, userAgent, ipAddress);
        return tokenResponseFrom(tokens);
    }

    private TokenResponse tokenResponseFrom(SessionService.IssuedTokens tokens) {
        User u = tokens.user();
        SubscriptionService.CurrentAccess current = subscriptionService.currentAccess(u.getId());
        return TokenResponse.of(tokens.accessToken(), tokens.refreshToken(),
                jwtService.accessTokenTtlSeconds(),
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

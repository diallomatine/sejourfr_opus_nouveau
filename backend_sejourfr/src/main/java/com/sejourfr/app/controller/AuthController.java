package com.sejourfr.app.controller;

import com.sejourfr.app.dto.*;
import com.sejourfr.app.ratelimit.RateLimitGuard;
import com.sejourfr.app.service.AuthService;
import com.sejourfr.app.service.UserProfileService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final UserProfileService userProfileService;
    private final RateLimitGuard rateLimitGuard;

    /**
     * Récupère l'IP de l'appelant en respectant les headers du reverse proxy
     * (X-Forwarded-For) puis fallback sur {@code request.getRemoteAddr()}.
     * Pour observabilité / forensics — pas pour de la sécurité (ces headers
     * sont trivialement spoofables, on les stocke juste comme metadata).
     */
    static String clientIp(HttpServletRequest request) {
        String xff = request.getHeader("X-Forwarded-For");
        if (xff != null && !xff.isBlank()) {
            int comma = xff.indexOf(',');
            return (comma > 0 ? xff.substring(0, comma) : xff).trim();
        }
        return request.getRemoteAddr();
    }

    static String userAgent(HttpServletRequest request) {
        return request.getHeader("User-Agent");
    }

    @PostMapping("/login")
    public TokenResponse login(@Valid @RequestBody LoginRequest req, HttpServletRequest http) {
        rateLimitGuard.checkLogin(clientIp(http), req.email());
        return authService.login(req, userAgent(http), clientIp(http));
    }

    @PostMapping("/refresh")
    public TokenResponse refresh(@Valid @RequestBody RefreshRequest req, HttpServletRequest http) {
        return authService.refresh(req, userAgent(http), clientIp(http));
    }

    /**
     * Révoque le refresh token côté serveur (table {@code refresh_tokens}).
     * Idempotent : un token déjà invalide / expiré renvoie 204 sans erreur,
     * le client doit toujours nettoyer son storage local après.
     */
    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(@Valid @RequestBody LogoutRequest req) {
        authService.logout(req.refreshToken());
    }

    @GetMapping("/me")
    public AuthenticatedUser me(@AuthenticationPrincipal UserDetails principal) {
        return authService.me(principal.getUsername());
    }

    /**
     * Cree un compte USER + retourne directement les tokens (auto-login).
     */
    @PostMapping("/register")
    public TokenResponse register(@Valid @RequestBody RegisterRequest req, HttpServletRequest http) {
        rateLimitGuard.checkRegister(clientIp(http));
        return authService.register(req, userAgent(http), clientIp(http));
    }

    @PostMapping("/forgot-password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void forgotPassword(@Valid @RequestBody ForgotPasswordRequest req, HttpServletRequest http) {
        rateLimitGuard.checkForgotPassword(clientIp(http));
        authService.requestPasswordReset(req.email());
    }

    @PostMapping("/reset-password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void resetPassword(@Valid @RequestBody ResetPasswordRequest req, HttpServletRequest http) {
        rateLimitGuard.checkResetPassword(clientIp(http));
        authService.resetPassword(req.token(), req.newPassword());
    }

    /**
     * Endpoint **public** (pas d'auth) appelé quand l'utilisateur clique sur
     * le lien envoyé à son nouvel email. Applique le changement et renvoie
     * une page HTML statique de confirmation (le user peut ne pas être
     * connecté sur le device qui ouvre le lien, donc on ne peut pas
     * répondre en JSON pour le client mobile).
     */
    @GetMapping(value = "/confirm-email-change", produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> confirmEmailChange(@RequestParam("token") String token) {
        try {
            String newEmail = userProfileService.confirmEmailChange(token);
            return ResponseEntity.ok(userProfileService.renderEmailChangeConfirmationPage(true,
                    "Votre nouvel email est désormais : " + newEmail));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode())
                    .body(userProfileService.renderEmailChangeConfirmationPage(false,
                            e.getReason() != null ? e.getReason() : "Lien invalide ou expiré."));
        }
    }
}

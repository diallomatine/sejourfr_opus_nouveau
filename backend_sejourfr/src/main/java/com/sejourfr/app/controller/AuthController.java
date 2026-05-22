package com.sejourfr.app.controller;

import com.sejourfr.app.dto.*;
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

    @PostMapping("/login")
    public TokenResponse login(@Valid @RequestBody LoginRequest req, HttpServletRequest http) {
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
        throw new IllegalArgumentException("Les inscriptions sont temporairement desactivées");
        //return authService.register(req, userAgent(http), clientIp(http));
    }

    @PostMapping("/forgot-password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void forgotPassword(@Valid @RequestBody ForgotPasswordRequest req) {
        authService.requestPasswordReset(req.email());
    }

    @PostMapping("/reset-password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void resetPassword(@Valid @RequestBody ResetPasswordRequest req) {
        authService.resetPassword(req.token(), req.newPassword());
    }

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
            return ResponseEntity.ok(confirmationHtml(true,
                    "Votre nouvel email est désormais : " + newEmail));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(confirmationHtml(false,
                    e.getReason() != null ? e.getReason() : "Lien invalide ou expiré."));
        }
    }

    /**
     * Page HTML minimale, autonome (pas de dépendance vers le front). Ne
     * traduit pas tous les cas d'erreur — juste un message clair + un lien
     * de retour vers l'accueil.
     */
    private static String confirmationHtml(boolean ok, String message) {
        String title = ok ? "Email confirmé" : "Lien invalide";
        String emoji = ok ? "✅" : "⚠️";
        String accent = ok ? "#168F5B" : "#E1372F";
        return """
                <!doctype html>
                <html lang="fr">
                <head>
                  <meta charset="utf-8" />
                  <meta name="viewport" content="width=device-width, initial-scale=1" />
                  <title>%s — SejourFR</title>
                  <style>
                    body { font-family: -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
                           background: #FAFAF7; color: #0F1839; margin: 0;
                           min-height: 100vh; display: grid; place-items: center; padding: 24px; }
                    .card { background: white; border: 1px solid #E4E7F2; border-radius: 16px;
                            padding: 32px 28px; max-width: 420px; text-align: center;
                            box-shadow: 0 8px 24px rgba(15, 24, 57, 0.06); }
                    .emoji { font-size: 48px; margin-bottom: 12px; }
                    h1 { font-size: 22px; margin: 0 0 8px; color: %s; }
                    p { font-size: 14px; line-height: 1.5; color: #6B7299; margin: 0 0 18px; }
                    .hint { font-size: 12px; color: #9CA2BD; margin-top: 24px; }
                  </style>
                </head>
                <body>
                  <div class="card">
                    <div class="emoji">%s</div>
                    <h1>%s</h1>
                    <p>%s</p>
                    <p class="hint">Tu peux fermer cette page et revenir dans l'app SejourFR.</p>
                  </div>
                </body>
                </html>
                """.formatted(title, accent, emoji, title, escapeHtml(message));
    }

    private static String escapeHtml(String s) {
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }
}

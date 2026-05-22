package com.sejourfr.app.controller;

import com.sejourfr.app.dto.*;
import com.sejourfr.app.service.AuthService;
import com.sejourfr.app.service.UserProfileService;
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
    public TokenResponse login(@Valid @RequestBody LoginRequest req) {
        return authService.login(req);
    }

    @PostMapping("/refresh")
    public TokenResponse refresh(@Valid @RequestBody RefreshRequest req) {
        return authService.refresh(req);
    }

    @GetMapping("/me")
    public AuthenticatedUser me(@AuthenticationPrincipal UserDetails principal) {
        return authService.me(principal.getUsername());
    }

    /**
     * Cree un compte USER + retourne directement les tokens (auto-login).
     */
    @PostMapping("/register")
    public TokenResponse register(@Valid @RequestBody RegisterRequest req) {
        throw new IllegalArgumentException("Les inscriptions sont temporairement desactivées");
        //return authService.register(req);
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

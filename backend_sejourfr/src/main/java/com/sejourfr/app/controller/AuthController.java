package com.sejourfr.app.controller;

import com.sejourfr.app.dto.*;
import com.sejourfr.app.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

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
}

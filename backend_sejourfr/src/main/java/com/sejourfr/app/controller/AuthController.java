package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AuthenticatedUser;
import com.sejourfr.app.dto.ForgotPasswordRequest;
import com.sejourfr.app.dto.LoginRequest;
import com.sejourfr.app.dto.RefreshRequest;
import com.sejourfr.app.dto.RegisterRequest;
import com.sejourfr.app.dto.ResetPasswordRequest;
import com.sejourfr.app.dto.TokenResponse;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.service.AuthService;
import com.sejourfr.app.service.PasswordResetService;
import com.sejourfr.app.service.UserRegistrationService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;
    private final UserRegistrationService registrationService;
    private final PasswordResetService passwordResetService;

    public AuthController(
            AuthService authService,
            UserRegistrationService registrationService,
            PasswordResetService passwordResetService
    ) {
        this.authService = authService;
        this.registrationService = registrationService;
        this.passwordResetService = passwordResetService;
    }

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
     * Crée un compte USER et délègue ensuite à login() pour récupérer les tokens.
     */
    @PostMapping("/register")
    public TokenResponse register(@Valid @RequestBody RegisterRequest req) {
        User user = registrationService.register(req);
        return authService.login(new LoginRequest(user.getEmail(), req.password()));
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<Void> forgotPassword(@Valid @RequestBody ForgotPasswordRequest req) {
        passwordResetService.requestReset(req.email());
        return ResponseEntity.ok().build();
    }

    @PostMapping("/reset-password")
    public ResponseEntity<Void> resetPassword(@Valid @RequestBody ResetPasswordRequest req) {
        passwordResetService.resetPassword(req.token(), req.newPassword());
        return ResponseEntity.ok().build();
    }
}

package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AppleSignInRequest;
import com.sejourfr.app.dto.GoogleSignInRequest;
import com.sejourfr.app.dto.TokenResponse;
import com.sejourfr.app.service.SocialAuthService;
import com.sejourfr.app.util.ClientContextResolver;
import com.sejourfr.app.util.ClientIpResolver;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/**
 * Sign-in / sign-up via providers externes.
 * <p>
 * Le client (web GIS, mobile google_sign_in/sign_in_with_apple) recupere un
 * ID token aupres du provider, le POST ici, et recoit en retour les memes
 * tokens JWT qu'un login email/mdp. Si l'utilisateur n'existe pas, un
 * compte est cree automatiquement.
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class SocialAuthController {

    private final SocialAuthService socialAuthService;
    private final ClientIpResolver clientIpResolver;
    private final ClientContextResolver clientContextResolver;

    @PostMapping("/google")
    public TokenResponse google(@Valid @RequestBody GoogleSignInRequest req, HttpServletRequest http) {
        if (!socialAuthService.isGoogleConfigured()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Google sign-in non configure cote backend");
        }
        return socialAuthService.loginWithGoogle(req, AuthController.userAgent(http),
                clientIpResolver.resolve(http), clientContextResolver.resolve(http));
    }

    @PostMapping("/apple")
    public TokenResponse apple(@Valid @RequestBody AppleSignInRequest req, HttpServletRequest http) {
        if (!socialAuthService.isAppleConfigured()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Apple sign-in non configure cote backend");
        }
        return socialAuthService.loginWithApple(req, AuthController.userAgent(http),
                clientIpResolver.resolve(http), clientContextResolver.resolve(http));
    }
}

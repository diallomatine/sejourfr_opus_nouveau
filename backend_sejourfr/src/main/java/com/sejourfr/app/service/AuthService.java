package com.sejourfr.app.service;

import com.sejourfr.app.dto.AuthenticatedUser;
import com.sejourfr.app.dto.LoginRequest;
import com.sejourfr.app.dto.RefreshRequest;
import com.sejourfr.app.dto.TokenResponse;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.repository.UserRepository;
import com.sejourfr.app.security.JwtService;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Service
@Transactional
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final UserRepository userRepository;
    private final JwtService jwtService;
    private final SubscriptionService subscriptionService;

    public AuthService(AuthenticationManager authenticationManager,
                       UserRepository userRepository,
                       JwtService jwtService,
                       SubscriptionService subscriptionService) {
        this.authenticationManager = authenticationManager;
        this.userRepository = userRepository;
        this.jwtService = jwtService;
        this.subscriptionService = subscriptionService;
    }

    public TokenResponse login(LoginRequest req) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(req.email(), req.password()));
        } catch (BadCredentialsException ex) {
            throw new BadCredentialsException("Identifiants invalides");
        }

        User u = userRepository.findByEmail(req.email())
                .orElseThrow(() -> new BadCredentialsException("Identifiants invalides"));

        u.setLastLoginAt(Instant.now());

        String access = jwtService.generateAccessToken(u);
        String refresh = jwtService.generateRefreshToken(u);
        SubscriptionService.CurrentAccess current = subscriptionService.currentAccess(u.getId());
        return TokenResponse.of(access, refresh, jwtService.accessTokenTtlSeconds(),
                AuthenticatedUser.from(u, current.module(), current.endsAt()));
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
        User u = userRepository.findById(userId)
                .orElseThrow(() -> NotFoundException.of("User", userId));
        if (!u.isActive()) {
            throw new BusinessException("Compte desactive");
        }

        String access = jwtService.generateAccessToken(u);
        String newRefresh = jwtService.generateRefreshToken(u);
        SubscriptionService.CurrentAccess current = subscriptionService.currentAccess(u.getId());
        return TokenResponse.of(access, newRefresh, jwtService.accessTokenTtlSeconds(),
                AuthenticatedUser.from(u, current.module(), current.endsAt()));
    }

    @Transactional(readOnly = true)
    public AuthenticatedUser me(String email) {
        User u = userRepository.findByEmail(email)
                .orElseThrow(() -> NotFoundException.of("User", email));
        SubscriptionService.CurrentAccess current = subscriptionService.currentAccess(u.getId());
        return AuthenticatedUser.from(u, current.module(), current.endsAt());
    }
}

package com.sejourfr.app.security;

import com.sejourfr.app.service.AppUserDetailsService;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final String HEADER = "Authorization";
    private static final String PREFIX = "Bearer ";

    /**
     * Attribut de requete pose quand un jeton d'acces valide a authentifie la
     * requete : l'id du compte ({@code sub}). Lu par
     * {@code UserActivityInterceptor} (activite, D1) sans requete SQL de plus.
     */
    public static final String ATTR_USER_ID = "sejourfr.userId";

    private final JwtService jwtService;
    private final AppUserDetailsService userDetailsService;

    public JwtAuthenticationFilter(JwtService jwtService, AppUserDetailsService userDetailsService) {
        this.jwtService = jwtService;
        this.userDetailsService = userDetailsService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {

        String header = request.getHeader(HEADER);
        if (header == null || !header.startsWith(PREFIX)) {
            chain.doFilter(request, response);
            return;
        }

        String token = header.substring(PREFIX.length()).trim();
        try {
            Claims claims = jwtService.parseAndValidate(token);
            if (!jwtService.isAccessToken(claims)) {
                chain.doFilter(request, response);
                return;
            }

            String email = claims.get("email", String.class);
            if (email != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                UserDetails userDetails = userDetailsService.loadUserByUsername(email);
                UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                        userDetails, null, userDetails.getAuthorities());
                auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(auth);
                UUID userId = userIdOf(claims);
                if (userId != null) request.setAttribute(ATTR_USER_ID, userId);
            }
        } catch (JwtException | UsernameNotFoundException ex) {
            // Token invalide ou utilisateur inexistant : on laisse passer sans authentification.
            // Spring Security renverra 401/403 si l'endpoint l'exige.
            SecurityContextHolder.clearContext();
        }

        chain.doFilter(request, response);
    }

    private static UUID userIdOf(Claims claims) {
        try {
            return claims.getSubject() == null ? null : UUID.fromString(claims.getSubject());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}

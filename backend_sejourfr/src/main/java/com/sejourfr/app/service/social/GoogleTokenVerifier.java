package com.sejourfr.app.service.social;

import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.jwk.source.JWKSourceBuilder;
import com.nimbusds.jose.proc.JWSKeySelector;
import com.nimbusds.jose.proc.JWSVerificationKeySelector;
import com.nimbusds.jose.proc.SecurityContext;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.proc.ConfigurableJWTProcessor;
import com.nimbusds.jwt.proc.DefaultJWTClaimsVerifier;
import com.nimbusds.jwt.proc.DefaultJWTProcessor;
import com.sejourfr.app.config.SocialAuthProperties;
import com.sejourfr.app.enums.AuthProvider;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.net.URL;
import java.util.List;
import java.util.Set;

/**
 * Verifie un ID token Google :
 * <ul>
 *   <li>signature RS256 contre les cles publiques Google (cache JWKS auto)</li>
 *   <li>issuer = "accounts.google.com" ou "https://accounts.google.com"</li>
 *   <li>audience dans la liste {@code sejourfr.oauth.google.audiences}</li>
 *   <li>token non expire</li>
 *   <li>claim {@code email_verified} = true</li>
 * </ul>
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class GoogleTokenVerifier implements SocialTokenVerifier {

    private static final String JWKS_URL = "https://www.googleapis.com/oauth2/v3/certs";
    private static final Set<String> ACCEPTED_ISSUERS = Set.of(
            "accounts.google.com",
            "https://accounts.google.com"
    );

    private final SocialAuthProperties properties;

    private ConfigurableJWTProcessor<SecurityContext> processor;

    @PostConstruct
    void init() {
        if (!isConfigured()) {
            log.info("Google sign-in non configure (sejourfr.oauth.google.audiences vide) - endpoint /api/auth/google renverra 503");
            return;
        }
        try {
            JWKSource<SecurityContext> jwkSource = JWKSourceBuilder
                    .create(new URL(JWKS_URL))
                    .cache(true)
                    .retrying(true)
                    .build();
            JWSKeySelector<SecurityContext> keySelector =
                    new JWSVerificationKeySelector<>(JWSAlgorithm.RS256, jwkSource);
            ConfigurableJWTProcessor<SecurityContext> p = new DefaultJWTProcessor<>();
            p.setJWSKeySelector(keySelector);
            // On verifie l'issuer et la presence des claims standards.
            // L'audience est verifiee manuellement (liste de valeurs acceptees).
            p.setJWTClaimsSetVerifier(new DefaultJWTClaimsVerifier<>(
                    null,
                    new JWTClaimsSet.Builder().build(),
                    Set.of("sub", "iat", "exp", "aud", "iss", "email")
            ));
            this.processor = p;
            log.info("Google sign-in configure : {} audience(s) autorisee(s)", properties.getGoogle().getAudiences().size());
        } catch (Exception e) {
            throw new IllegalStateException("Impossible d'initialiser GoogleTokenVerifier", e);
        }
    }

    @Override
    public boolean isConfigured() {
        return properties.getGoogle().isConfigured();
    }

    @Override
    public SocialIdentity verify(String idToken) {
        if (!isConfigured()) {
            throw new InvalidSocialTokenException("Google sign-in non configure cote backend");
        }
        JWTClaimsSet claims;
        try {
            claims = processor.process(idToken, null);
        } catch (Exception e) {
            throw new InvalidSocialTokenException("ID token Google invalide : " + e.getMessage(), e);
        }

        String issuer = claims.getIssuer();
        if (issuer == null || !ACCEPTED_ISSUERS.contains(issuer)) {
            throw new InvalidSocialTokenException("Issuer Google inattendu : " + issuer);
        }

        List<String> aud = claims.getAudience();
        List<String> allowed = properties.getGoogle().getAudiences();
        boolean audOk = aud != null && aud.stream().anyMatch(allowed::contains);
        if (!audOk) {
            throw new InvalidSocialTokenException("Audience Google non autorisee : " + aud);
        }

        try {
            Boolean verified = claims.getBooleanClaim("email_verified");
            if (verified == null || !verified) {
                throw new InvalidSocialTokenException("Email Google non verifie");
            }
        } catch (Exception e) {
            throw new InvalidSocialTokenException("Email Google non verifie", e);
        }

        String email = safeString(claims, "email");
        if (email == null || email.isBlank()) {
            throw new InvalidSocialTokenException("Email absent du token Google");
        }

        return new SocialIdentity(
                AuthProvider.GOOGLE,
                claims.getSubject(),
                email.toLowerCase().trim(),
                safeString(claims, "given_name"),
                safeString(claims, "family_name")
        );
    }

    private static String safeString(JWTClaimsSet claims, String name) {
        try {
            return claims.getStringClaim(name);
        } catch (Exception e) {
            return null;
        }
    }
}

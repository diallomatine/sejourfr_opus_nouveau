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
 * Verifie un identityToken Apple :
 * <ul>
 *   <li>signature RS256 contre les cles publiques Apple (cache JWKS auto)</li>
 *   <li>issuer = "https://appleid.apple.com"</li>
 *   <li>audience dans la liste {@code sejourfr.oauth.apple.audiences} (Bundle ID iOS)</li>
 *   <li>token non expire</li>
 * </ul>
 * <p>
 * Note : Apple ne renvoie le nom/prenom qu'au tout premier consent, via les
 * champs `fullName` du framework AuthenticationServices. Ces valeurs sont
 * absentes du JWT — c'est le client iOS qui doit les transmettre dans le
 * payload {@code AppleSignInRequest}.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AppleTokenVerifier implements SocialTokenVerifier {

    private static final String JWKS_URL = "https://appleid.apple.com/auth/keys";
    private static final String EXPECTED_ISSUER = "https://appleid.apple.com";

    private final SocialAuthProperties properties;

    private ConfigurableJWTProcessor<SecurityContext> processor;

    @PostConstruct
    void init() {
        if (!isConfigured()) {
            log.info("Apple sign-in non configure (sejourfr.oauth.apple.audiences vide) - endpoint /api/auth/apple renverra 503");
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
            p.setJWTClaimsSetVerifier(new DefaultJWTClaimsVerifier<>(
                    null,
                    new JWTClaimsSet.Builder().issuer(EXPECTED_ISSUER).build(),
                    Set.of("sub", "iat", "exp", "aud", "iss")
            ));
            this.processor = p;
            log.info("Apple sign-in configure : {} audience(s) autorisee(s)", properties.getApple().getAudiences().size());
        } catch (Exception e) {
            throw new IllegalStateException("Impossible d'initialiser AppleTokenVerifier", e);
        }
    }

    @Override
    public boolean isConfigured() {
        return properties.getApple().isConfigured();
    }

    @Override
    public SocialIdentity verify(String idToken) {
        if (!isConfigured()) {
            throw new InvalidSocialTokenException("Apple sign-in non configure cote backend");
        }
        JWTClaimsSet claims;
        try {
            claims = processor.process(idToken, null);
        } catch (Exception e) {
            throw new InvalidSocialTokenException("ID token Apple invalide : " + e.getMessage(), e);
        }

        List<String> aud = claims.getAudience();
        List<String> allowed = properties.getApple().getAudiences();
        boolean audOk = aud != null && aud.stream().anyMatch(allowed::contains);
        if (!audOk) {
            throw new InvalidSocialTokenException("Audience Apple non autorisee : " + aud);
        }

        String email = safeString(claims, "email");
        if (email == null || email.isBlank()) {
            throw new InvalidSocialTokenException("Email absent du token Apple");
        }

        // Vérif email_verified : Apple autorise un utilisateur à associer
        // n'importe quelle adresse à son Apple ID, et expose ce claim pour
        // distinguer celles qu'il a réellement validées. Sans cette garde,
        // combiné au refus de fallback par email (cf. SocialAuthService),
        // on resterait vulnérable à un sign-up frauduleux avec l'adresse
        // d'une victime non encore inscrite — l'attaquant créerait le
        // compte avant elle. Cf. audit Vuln 2.
        //
        // Apple est inconsistant sur le type (Boolean ou String selon la
        // version), donc on accepte les deux.
        if (!isEmailVerified(claims)) {
            throw new InvalidSocialTokenException("Email non vérifié par Apple");
        }

        // Apple ne renvoie pas given_name / family_name dans le JWT.
        return new SocialIdentity(
                AuthProvider.APPLE,
                claims.getSubject(),
                email.toLowerCase().trim(),
                null,
                null
        );
    }

    /**
     * Lit le claim {@code email_verified} en tolérant les deux formats que
     * Apple peut renvoyer ({@code Boolean} ou {@code String "true"/"false"}).
     * Strict : {@code null} ou absent → non vérifié.
     */
    private static boolean isEmailVerified(JWTClaimsSet claims) {
        Object raw = claims.getClaim("email_verified");
        if (raw instanceof Boolean b) return b;
        if (raw instanceof String s) return "true".equalsIgnoreCase(s);
        return false;
    }

    private static String safeString(JWTClaimsSet claims, String name) {
        try {
            return claims.getStringClaim(name);
        } catch (Exception e) {
            return null;
        }
    }
}

package com.sejourfr.app.service.email;

import com.sejourfr.app.config.EmailProperties;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Le jeton des liens de desabonnement ENGAGEMENT (brief §6) :
 * {@code base64url(userId) . keyVersion . base64url(HMAC-SHA256(secret[keyVersion],
 * "unsub:engagement|" + userId + "|" + keyVersion))}.
 *
 * <ul>
 *   <li>La cle COURANTE signe ; toutes les cles du trousseau verifient — un lien
 *       survit a une rotation.</li>
 *   <li>Comparaison a temps constant ({@link MessageDigest#isEqual}).</li>
 *   <li>Pas d'expiration : un lien de desabonnement doit marcher des mois apres.</li>
 * </ul>
 *
 * <p>🛑 Un jeton ne se loggue jamais, en entier ou en partie.
 */
@Component
@RequiredArgsConstructor
public class UnsubscribeTokenService {

    private static final String ALGO = "HmacSHA256";
    private static final Base64.Encoder B64 = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder B64D = Base64.getUrlDecoder();

    private final EmailProperties properties;

    /** Echec au demarrage si la cle courante manque : un lien signe avec rien ne vaut rien. */
    @PostConstruct
    void verifierTrousseau() {
        EmailProperties.Unsubscribe cfg = properties.getUnsubscribe();
        String current = cfg.getKeys().get(cfg.getCurrentKeyVersion());
        if (current == null || current.isBlank()) {
            throw new IllegalStateException("sejourfr.email.unsubscribe.keys."
                    + cfg.getCurrentKeyVersion() + " est absente (EMAIL_UNSUBSCRIBE_KEY_V"
                    + cfg.getCurrentKeyVersion() + ")");
        }
    }

    public String create(UUID userId) {
        int version = properties.getUnsubscribe().getCurrentKeyVersion();
        String secret = properties.getUnsubscribe().getKeys().get(version);
        return B64.encodeToString(userId.toString().getBytes(StandardCharsets.UTF_8))
                + "." + version + "." + B64.encodeToString(sign(secret, userId, version));
    }

    /**
     * @return le compte designe par un jeton VALIDE ; vide pour tout le reste
     *         (format, version inconnue, signature fausse) — sans distinguer les cas.
     */
    public Optional<UUID> verify(String token) {
        if (token == null || token.length() > 512) return Optional.empty();
        String[] parts = token.split("\\.", -1);
        if (parts.length != 3) return Optional.empty();
        try {
            UUID userId = UUID.fromString(new String(B64D.decode(parts[0]), StandardCharsets.UTF_8));
            int version = Integer.parseInt(parts[1]);
            Map<Integer, String> keys = properties.getUnsubscribe().getKeys();
            String secret = keys.get(version);
            if (secret == null || secret.isBlank()) return Optional.empty();
            byte[] expected = sign(secret, userId, version);
            byte[] given = B64D.decode(parts[2]);
            return MessageDigest.isEqual(expected, given) ? Optional.of(userId) : Optional.empty();
        } catch (IllegalArgumentException e) {
            return Optional.empty();
        }
    }

    private static byte[] sign(String secret, UUID userId, int version) {
        try {
            Mac mac = Mac.getInstance(ALGO);
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), ALGO));
            return mac.doFinal(("unsub:engagement|" + userId + "|" + version)
                    .getBytes(StandardCharsets.UTF_8));
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException("HMAC indisponible", e);
        }
    }
}

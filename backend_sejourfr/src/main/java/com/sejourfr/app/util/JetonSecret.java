package com.sejourfr.app.util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HexFormat;

/**
 * <b>Autorite unique</b> des jetons secrets « en clair chez le client, hash en
 * base » : jeton de reinitialisation de mot de passe, {@code claimToken} d'une
 * {@code diagnostic_run}. Deux copies privees du meme SHA-256 hexadecimal
 * auraient fini par diverger (encodage, casse), et un hash qui diverge ne
 * retrouve plus rien.
 *
 * <p>⚠️ {@code UserProfileService} (changement d'email) garde son propre hash,
 * en base64url : ses jetons deja emis sont stockes sous ce format, le changer
 * les invaliderait.
 */
public final class JetonSecret {

    private static final SecureRandom RANDOM = new SecureRandom();

    private JetonSecret() {
    }

    /** Jeton aleatoire de {@code octets} octets, en base64url sans bourrage. */
    public static String tirer(int octets) {
        byte[] bytes = new byte[octets];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    /** SHA-256 hexadecimal minuscule (64 caracteres). */
    public static String sha256Hex(String valeur) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(md.digest(valeur.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    /**
     * Le jeton recu correspond-il au hash stocke ? Comparaison a temps
     * constant ; un jeton ou un hash absent ne correspond a rien.
     */
    public static boolean correspond(String jeton, String hashStocke) {
        if (jeton == null || jeton.isBlank() || hashStocke == null) return false;
        return MessageDigest.isEqual(
                sha256Hex(jeton.trim()).getBytes(StandardCharsets.US_ASCII),
                hashStocke.getBytes(StandardCharsets.US_ASCII));
    }
}

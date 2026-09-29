package com.sejourfr.app.util;

import java.util.Arrays;
import java.util.function.Function;

/**
 * Un enregistrement de candidat ne survit jamais à son usage.
 *
 * <p>Décision produit (motif : consentement) : l'audio d'une production sert
 * UNIQUEMENT à produire la transcription, puis il disparaît. Il n'est écrit ni
 * sur R2, ni en base, ni sur disque. Il ne reste donc, en tout et pour tout,
 * qu'un {@code byte[]} vivant le temps d'une requête.
 *
 * <p>Ce helper est le <b>seul endroit</b> où cette promesse est tenue de manière
 * déterministe : le tampon est <b>remis à zéro dans un {@code finally}</b>, donc
 * y compris quand l'appel échoue (Whisper indisponible, quota, exception
 * inattendue). Sans lui, les octets restaient lisibles dans le tas jusqu'au
 * prochain GC — et dans un heap dump indéfiniment.
 *
 * <p>À utiliser à chaque fois qu'on manipule les octets d'une production de
 * candidat. Ne pas contourner en passant le tableau à un service qui le
 * garderait : rien ne doit le référencer après le retour.
 */
public final class AudioEphemere {

    private AudioEphemere() {}

    /**
     * Exécute {@code action} sur les octets, puis efface le tampon <b>quoi qu'il
     * arrive</b>.
     *
     * @param bytes  les octets audio ; ils sont écrasés au retour
     * @param action ce qu'on en fait — typiquement l'appel de transcription
     * @return ce que rend {@code action}
     */
    public static <T> T avecOctets(byte[] bytes, Function<byte[], T> action) {
        try {
            return action.apply(bytes);
        } finally {
            effacer(bytes);
        }
    }

    /** Remise à zéro sur place. {@code null} toléré : rien à effacer. */
    public static void effacer(byte[] bytes) {
        if (bytes != null) {
            Arrays.fill(bytes, (byte) 0);
        }
    }
}

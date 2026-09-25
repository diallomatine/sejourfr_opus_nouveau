package com.sejourfr.app.dto;

import java.util.List;

/**
 * Compte rendu d'un lot (reponse <b>202</b>).
 *
 * <p>{@code received = accepted + duplicates + rejected.size()}. Un doublon
 * (meme {@code eventId} ou meme {@code dedupKey} deja recu) n'est pas une
 * erreur : le client peut purger sa file. Un rejet est definitif pour cet
 * evenement : le renvoyer tel quel serait rejete de nouveau, le client le
 * purge aussi.
 *
 * @param received   evenements recus
 * @param accepted   evenements ecrits
 * @param duplicates evenements deja connus, rien n'a ete ecrit
 * @param rejected   evenements refuses, avec leur position et le motif
 */
public record AnalyticsBatchResponse(int received, int accepted, int duplicates, List<Rejection> rejected) {

    /**
     * @param index   position dans {@code events} (0-based)
     * @param eventId identifiant tel que recu, {@code null} s'il manquait
     * @param reason  motif nomme (champ, valeur recue, attendu)
     */
    public record Rejection(int index, String eventId, String reason) {}
}

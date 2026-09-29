package com.sejourfr.app.dto;

import java.util.List;
import java.util.UUID;

/**
 * Une notion du referentiel, <b>avec sa couverture mesuree</b> (lot L8).
 *
 * <p>La couverture est ce qui decide de son sort a la porte de revue
 * ({@code 50_} §6.1.3) : trop peu de questions ⇒ candidate a la fusion, trop
 * ⇒ candidate a la scission. Elle est <b>mesuree</b>, jamais estimee.
 *
 * <p>🛑 <b>Le seuil n'est PAS applique ici.</b> La regle de {@code 50_} §6.1
 * degrade <b>par notion ET par mention</b> : une notion peut etre pleinement
 * utilisable pour un candidat NAT et seulement visible en revision pour un
 * CSP. Rendre un seul verdict global effacerait exactement cette nuance. Les
 * comptes sont donc servis, et c'est l'appelant qui tranche pour SA mention.
 *
 * @param questionsTaguees questions dont un humain a VALIDE cette notion
 * @param parMention       le meme compte, ventile par mention (CSP/CR/NAT)
 * @param suggestions      propositions machine non encore validees. 🛑 Elles ne
 *                         comptent PAS comme couverture : une suggestion n'est
 *                         pas une decision
 */
public record CivicNotionDto(
        UUID id,
        String code,
        String label,
        /** La frontiere metier de la notion, {@code null} si elle n'en a pas. */
        String description,
        String themeCode,
        int displayOrder,
        boolean active,
        /** Code de la notion qui reprend celle-ci apres fusion. {@code null} = vivante. */
        String mergedIntoCode,
        long questionsTaguees,
        List<CouvertureMention> parMention,
        long suggestions
) {
    /** @param mention la valeur de {@code Difficulty} qui sert de mention civique */
    public record CouvertureMention(String mention, long questions) {}
}

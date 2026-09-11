package com.sejourfr.app.dto;

import java.util.List;
import java.util.UUID;

/**
 * Une question a taguer, telle que l'ecran de tagging la voit (lot L8).
 *
 * <p>🛑 <b>{@code notionCode} nul = PAS ENCORE TAGUEE</b>, jamais « sans
 * notion ». Une question non taguee attend un humain ; elle n'est pas hors
 * programme, et l'ecran doit le dire ainsi.
 *
 * <p>🛑 Les <b>suggestions</b> sont affichees pour accelerer la decision, pas
 * pour la prendre. Elles arrivent triees par confiance decroissante, et aucune
 * n'est pre-selectionnee : un tag valide est toujours un geste.
 *
 * <p>🛑 <b>Le relecteur doit voir la QUESTION ENTIERE</b> — enonce, quatre
 * propositions, bonne reponse, explication. {@code 20_} §3.2 le prevoyait des
 * l'origine ({@code PROMPT_TAG_NOTION_v1} recoit exactement ces champs) et il
 * s'etait perdu : rattacher une question a une notion sur son seul enonce, c'est
 * trancher sans la moitie du texte. La {@code rationale} de la machine joue le
 * meme role — c'est elle qui fait passer la relecture de 15 s a 6 s.
 */
public record QuestionTaggingDto(
        UUID questionId,
        String enonce,
        /** L'explication editoriale de la question, {@code null} si elle n'en a pas. */
        String explication,
        /** Les propositions, dans leur ordre d'affichage, la bonne marquee. */
        List<Choix> choix,
        String themeCode,
        /** La mention visee par la question ({@code CSP} / {@code CR} / {@code NAT}). */
        String mention,
        String notionCode,
        String notionLabel,
        List<Suggestion> suggestions
) {
    public record Choix(String label, boolean correct) {}

    /**
     * @param rationale     la phrase par laquelle la machine se justifie,
     *                      {@code null} si la campagne n'en a pas produit
     * @param reviewVerdict ce que la relecture humaine en a fait,
     *                      {@code null} tant qu'elle n'a pas eu lieu —
     *                      🛑 jamais annonce par un client : le serveur deduit
     *                      {@code VALIDATED} / {@code CORRECTED} lui-meme
     */
    public record Suggestion(
            String notionCode,
            String notionLabel,
            double confidence,
            String rationale,
            String reviewVerdict) {}
}

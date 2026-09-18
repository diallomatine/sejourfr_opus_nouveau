package com.sejourfr.app.enums;

/**
 * Les <b>gratuites nominatives</b> qu'un candidat peut consommer une seule fois
 * dans sa vie.
 *
 * <p>🛑 <b>Deux freebies, pas un au choix</b> (arbitrage D-17 bis, 2026-09-18) :
 * un examen blanc d'expression <b>ecrite</b> et un examen blanc d'expression
 * <b>orale</b>. Un candidat qui a use le sien en EE garde le sien en EO. Chacun
 * est <b>complet</b> — les trois taches sont reellement corrigees, le LLM est
 * appele, l'analyse entiere est rendue : c'est la vitrine du produit, pas un
 * apercu.
 *
 * <p>🛑 <b>Cet enum est le MIROIR du {@code CHECK} de la base, jamais son
 * autorite</b> ({@code chk_free_entitlement_code}, V067). Ajouter une gratuite
 * est donc une migration : un code libre ferait qu'une faute de frappe rendrait
 * a nouveau gratuite une gratuite deja consommee, <b>sans que rien ne le
 * signale</b>. Meme discipline que {@code chk_journey_lot_exam_type} et
 * {@code chk_skills_section}.
 *
 * <p><b>Branche depuis P4</b> (2026-09-18) : {@code FreeExamEntitlementService}
 * ecrit la ligne a la <b>remise de l'analyse</b> et {@code ProductionAccessService}
 * la relit pour poser le verrou et le {@code locked} servi.
 */
public enum FreeEntitlementCode {

    /**
     * L'examen blanc d'<b>expression ecrite</b>, offert une fois a vie, analyse
     * IA comprise.
     *
     * <p>Le rejeu de l'epreuve reste ouvert ; c'est l'<b>analyse</b> du second
     * passage qui est premium. En EE, le texte produit reste relisible, donc un
     * rejeu sans analyse est honnete.
     */
    EXAM_BLANC_EE,

    /**
     * L'examen blanc d'<b>expression orale</b>, offert une fois a vie, analyse
     * IA comprise.
     *
     * <p>⚠️ Le rejeu y est un cas a part, et c'est deja consigne : sans appel a
     * Whisper, un rejeu EO ne laisse <b>rien</b> a relire — aucun audio de
     * candidat n'est conserve. Le paywall se presente donc <b>au demarrage de
     * la tache</b>, pas apres la soumission : faire produire un candidat dans
     * le vide est un mauvais geste.
     */
    EXAM_BLANC_EO;

    /**
     * La gratuite d'examen blanc qui correspond a cette epreuve, ou
     * {@code null} pour toute epreuve qui n'en a pas.
     *
     * <p>🛑 <b>LA seule table epreuve -> code du depot.</b> Deux copies de cette
     * correspondance finiraient par consommer {@code EXAM_BLANC_EE} sur un oral,
     * c'est-a-dire par offrir deux fois la meme gratuite a un candidat et
     * jamais a un autre. Meme discipline que la table des paliers TCF, qui a
     * vecu en six copies.
     *
     * <p>{@code null} pour CO / CE / STRUCTURE / TCF_COMPLET, et c'est voulu :
     * les examens QCM gardent leur regle de slot (« slot 1 offert ET rejouable a
     * volonte », inchangee), et un examen <b>complet</b> n'est pas une gratuite
     * — ce sont ses sous-epreuves EE et EO qui portent chacune la leur.
     */
    public static FreeEntitlementCode pourExamenBlanc(EpreuveType epreuve) {
        if (epreuve == null) return null;
        return switch (epreuve) {
            case TCF_EE -> EXAM_BLANC_EE;
            case TCF_EO -> EXAM_BLANC_EO;
            default -> null;
        };
    }
}

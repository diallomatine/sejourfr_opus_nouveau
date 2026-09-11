package com.sejourfr.app.service.plancivique;

/**
 * Ce que le catalogue offre sur une cible, <b>pour la mention du candidat</b>
 * ({@code 50_} §6.1).
 *
 * <p>🛑 <b>Trois etats, pas deux — et la difference est EDITORIALE.</b> Le
 * referentiel valide (V058) l'a mesuree question par question : CSP, CR et NAT
 * ne sont pas trois niveaux du meme programme, ce sont <b>trois programmes
 * differents</b>. « Devenir francais » porte 10 questions en NAT et <b>zero</b>
 * en CSP ; « Les devoirs du citoyen » en porte 4 en NAT. Les deux recevaient le
 * meme verdict, alors que la premiere n'a <b>rien a faire</b> chez un candidat
 * CSP et que la seconde attend <b>une seule question</b>. Confondre les deux,
 * c'est perdre le signal qui dit quoi ecrire.
 *
 * <p>🛑 <b>{@link #NON_APPLICABLE} n'est pas un mauvais verdict</b>, et ce n'est
 * pas non plus un manque : c'est une <b>absence de programme</b>. Meme invariant
 * que {@link CivicMaitrise#NON_EVALUEE} et que le {@code null = inconnu, jamais
 * mauvais} du depot — la confusion inverse a produit les faux
 * {@code A1_NON_ATTEINT} du TCF (V040/V041/V042).
 *
 * <p>🛑 <b>Aucun libelle ici.</b> Ce DTO sert des faits ; si un ecran doit un
 * jour <b>dire</b> « pas au programme de votre demarche », la phrase arrive
 * servie ou ne s'affiche pas — aucun front ne fabrique sa table de libelles.
 */
public enum CivicDotation {

    /** Assez de questions dans la mention : la cible est une unite de parcours. */
    SERVABLE,

    /**
     * La cible <b>existe</b> pour ce candidat, mais sous le minimum : de 1 a
     * {@code minimum - 1} questions. Elle reste visible en revision libre et
     * n'est <b>jamais</b> proposee en priorite ({@code 50_} §6.1).
     */
    CONTENU_INSUFFISANT,

    /**
     * <b>Zero</b> question dans la mention : la notion n'existe pas pour ce
     * candidat. 🛑 Ce n'est pas « il manque de la matiere », c'est « ce n'est
     * pas son programme ».
     */
    NON_APPLICABLE;

    /**
     * <b>L'unique derivation.</b> 🛑 Ni le plan ni le scorer ne refont cette
     * comparaison : deux copies d'un seuil finissent toujours par diverger
     * (regle du depot, la table des paliers a vecu en six copies).
     *
     * <p>Le {@code minimum} n'est pas le meme aux deux grains, et c'est voulu :
     * une <b>notion</b> se compare a
     * {@code CivicPlanProperties.questionsMinParNotion} (5, l'unite de parcours),
     * un <b>theme</b> a {@code questionsParSerie} (10, de quoi remplir la serie
     * qu'on lui proposerait).
     *
     * @param questions questions actives de la cible <b>dans la mention</b>
     * @param minimum   le seuil de ce grain
     */
    public static CivicDotation depuis(long questions, int minimum) {
        if (questions <= 0) return NON_APPLICABLE;
        return questions < minimum ? CONTENU_INSUFFISANT : SERVABLE;
    }

    /** Le plan ne propose que ca. Les deux autres etats ne sont pas des nuances. */
    public boolean estServable() {
        return this == SERVABLE;
    }
}

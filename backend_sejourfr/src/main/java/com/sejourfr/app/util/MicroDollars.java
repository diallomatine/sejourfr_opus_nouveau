package com.sejourfr.app.util;

/**
 * L'unite dans laquelle le depot enregistre ce qu'il depense, et la regle
 * d'arrondi qui va avec. <b>Une seule declaration pour toutes les factures</b>,
 * quelle que soit la maniere dont le fournisseur les calcule.
 *
 * <p><b>Pourquoi un endroit a part.</b> Deux choses tres differentes se facturent
 * ici : un appel LLM se paie <i>au token</i> ({@link CoutAppelLlm}), une
 * transcription Whisper se paie <i>a la minute d'audio</i>
 * ({@link CoutTranscription}). Les deux formules n'ont rien a voir et ne doivent
 * pas etre fondues. En revanche l'<b>unite</b> et l'<b>arrondi</b> sont une
 * decision unique du depot : si les deux en gardaient une copie, elles
 * finiraient par diverger — c'est exactement ce qui avait produit onze copies de
 * {@code estimateCostCents}, chacune avec ses propres approximations.
 *
 * <p><b>Le millionieme de dollar.</b> Les couts etaient arrondis au <i>centime
 * superieur</i> avant d'etre persistes. Sur une micro-analyse a 0,0013 $ cela
 * multipliait la facture enregistree par ~8 ; sur une transcription de 95 s
 * (l'audio median du depot, 0,0095 $) par ~1,05. Le micro-dollar tient toute la
 * gamme sans distorsion et reste un <b>entier</b>, donc additionnable sans
 * erreur de virgule flottante quand un second appel s'ajoute au premier.
 *
 * <p><b>On arrondit toujours au SUPERIEUR</b> — la prudence historique est
 * conservee, mais a une granularite 10 000 fois plus fine, donc sans effet
 * mesurable sur ce qu'on lit.
 */
public final class MicroDollars {

    /** Millioniemes de dollar dans un dollar. */
    public static final long PAR_DOLLAR = 1_000_000L;

    private MicroDollars() {
    }

    /**
     * Convertit un montant en dollars vers l'entier persiste.
     *
     * @return {@code null} quand il n'y a rien a facturer — jamais {@code 0}, qui
     *         se lirait « gratuit », c'est-a-dire une affirmation, alors qu'on
     *         n'a rien mesure.
     */
    public static Integer depuisUsd(double usd) {
        if (!Double.isFinite(usd) || usd <= 0) return null;
        return (int) Math.min(Math.ceil(usd * PAR_DOLLAR), Integer.MAX_VALUE);
    }
}

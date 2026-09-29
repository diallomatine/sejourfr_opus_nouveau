package com.sejourfr.app.util;

/**
 * Cout d'UNE transcription Whisper, en <b>micro-dollars</b>, seul endroit du
 * depot ou ce calcul existe.
 *
 * <p><b>Whisper facture a la MINUTE, pas au token.</b> C'est la raison d'etre de
 * cette classe a cote de {@link CoutAppelLlm} : la formule n'a rien de commun
 * avec celle d'un appel LLM (ni cache de prefixe, ni tarif de sortie, ni heures
 * pleines), et tordre l'une pour y faire entrer l'autre aurait produit un calcul
 * que personne ne peut relire. Ce qui est <b>partage</b>, c'est l'unite et la
 * regle d'arrondi — {@link MicroDollars} — parce que c'est une decision du
 * depot, pas une propriete du fournisseur.
 *
 * <p><b>Ce qui est corrige.</b> Le calcul precedent arrondissait au <i>centime
 * superieur</i>. Sur l'audio median du depot (~95 s, soit 0,0095 $) il facturait
 * 1 centime : environ 5 % de trop. C'etait le dernier endroit du depot ou une
 * facture etait arrondie au centime.
 *
 * @param usdParMinute tarif du modele de transcription, en dollars par minute
 *                     d'audio. Vient de la configuration
 *                     ({@code sejourfr.openai.whisper.cost-per-minute-usd}),
 *                     jamais d'une constante Java : un tarif est une donnee
 *                     commerciale du fournisseur, il se corrige par une variable
 *                     d'environnement.
 */
public record CoutTranscription(double usdParMinute) {

    private static final double SECONDES_PAR_MINUTE = 60.0;

    /**
     * @param dureeSecondes duree detectee par le fournisseur sur le fichier
     *                      reellement recu.
     * @return cout en micro-dollars, ou {@code null} quand la duree est inconnue
     *         ou nulle, et quand aucun tarif n'est configure — on n'invente pas
     *         un montant, et un {@code 0} persiste se lirait « gratuit ».
     */
    public Integer microDollars(Integer dureeSecondes) {
        if (dureeSecondes == null || dureeSecondes <= 0) return null;
        if (usdParMinute <= 0) return null;
        return MicroDollars.depuisUsd(dureeSecondes / SECONDES_PAR_MINUTE * usdParMinute);
    }
}

package com.sejourfr.app.config;

/**
 * Les TROIS tarifs d'un fournisseur de LLM, plus sa modulation horaire.
 *
 * <p>Le modele a deux tarifs (entree / sortie) ne represente plus la grille
 * reelle : depuis le 2026-08-16 16:00 UTC, DeepSeek facture <b>separement</b> les
 * tokens d'entree servis depuis son cache de prefixe et ceux qui ne le sont pas,
 * et double l'ensemble sur deux plages horaires. Entre le tarif de cache et le
 * tarif de sortie en heure pleine, il y a un facteur <b>188</b> — un seul chiffre
 * « entree » ne peut pas dire ca.
 *
 * <p><b>Retombee obligatoire pour tout fournisseur qui n'a pas ces notions.</b>
 * Un provider sans tarif de cache laisse
 * {@link #getCostPerMillionCachedInputTokens()} a 0 et paie tout au tarif
 * d'entree : c'est l'hypothese PRUDENTE (on surestime, jamais l'inverse). Un
 * provider sans heures pleines laisse {@link #getPeakMultiplier()} a 1. Aucune
 * configuration supplementaire n'est donc exigee pour brancher un modele inedit
 * — l'invariant « changer de LLM ne touche aucun {@code .java} ni {@code .yaml} »
 * survit, et {@code EvaluationProviderSwapTest} le prouve.
 */
public interface TarifsLlm {

    /**
     * USD / 1M tokens d'entree qui n'ont PAS ete servis par le cache de prefixe
     * du fournisseur. C'est le tarif d'entree « normal », celui qui existait
     * seul avant l'introduction du cache.
     */
    double getCostPerMillionInputTokens();

    /** USD / 1M tokens de sortie. */
    double getCostPerMillionOutputTokens();

    /**
     * USD / 1M tokens d'entree servis depuis le cache de prefixe.
     * <b>0 = ce fournisseur n'a pas de tarif de cache</b> → on facture ces
     * tokens au tarif d'entree plein.
     */
    default double getCostPerMillionCachedInputTokens() {
        return 0.0;
    }

    /**
     * Facteur applique aux trois tarifs pendant les heures pleines du
     * fournisseur. <b>1 = pas d'heures pleines</b>. DeepSeek publie exactement
     * un doublement (×2) sur ses trois tarifs et ses deux gammes de modeles :
     * un facteur unique dit donc la grille sans la recopier six fois. Si un
     * fournisseur cessait d'etre proportionnel, il faudrait scinder — pas avant.
     */
    default double getPeakMultiplier() {
        return 1.0;
    }

    /**
     * Plages d'heures pleines en <b>UTC</b>, format
     * {@code "HH:mm-HH:mm,HH:mm-HH:mm"}, bornes {@code [debut, fin[}. Vide = le
     * fournisseur facture le meme prix a toute heure.
     *
     * <p>Jamais en dur dans le Java : une plage horaire est une donnee
     * commerciale du fournisseur, elle se corrige par une variable
     * d'environnement.
     */
    default String getPeakUtcRanges() {
        return "";
    }
}

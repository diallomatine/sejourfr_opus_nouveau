package com.sejourfr.app.enums;

/**
 * D'ou vient un achat (arbitrage Q12, chantier Suivi) — colonne
 * {@code user_subscriptions.origin}.
 *
 * <p>🛑 Aucune reconstruction heuristique : l'origine se lit UNIQUEMENT sur une
 * {@code purchase_intent} valide (meme compte, meme produit, non expiree, non
 * consommee). Une intention absente ou invalide donne {@link #UNKNOWN}, jamais
 * « la run la plus recente ». {@code null} en base = achat anterieur a la mesure.
 */
public enum PurchaseOrigin {

    /** Intention posee depuis un CTA du Plan, et la run fondatrice du parcours est connue. */
    DIAGNOSTIC_PLAN,

    /** Intention valide, posee ailleurs que sur le Plan (tarifs, correction IA...). */
    OTHER_CTA,

    /**
     * Intention absente, perdue, expiree, deja consommee ou d'un autre compte ;
     * ou intention du Plan sans run fondatrice resoluble (l'achat vient du Plan,
     * mais on ne sait pas de quel diagnostic : inconnu, pas « autre CTA »).
     */
    UNKNOWN
}

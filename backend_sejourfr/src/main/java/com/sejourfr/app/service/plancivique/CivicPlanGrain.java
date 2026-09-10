package com.sejourfr.app.service.plancivique;

/**
 * Le <b>grain</b> auquel le plan travaille un thème ({@code 20_} §3.3).
 *
 * <p>🛑 <b>Il se mesure, il ne se décrète pas</b> : un thème passe en
 * {@link #NOTION} quand la part de ses questions actives réellement taguées
 * franchit le seuil. Au lancement de ce lot, 0 question sur 1 016 est taguée —
 * les cinq thèmes sont donc en {@link #THEME}, et c'est le mode <b>prévu</b> par
 * la spec (§3.3 phase 1), pas une panne.
 *
 * <p>🛑 <b>La bascule est PAR THÈME</b>, jamais globale : un thème tagué à 90 %
 * n'a pas à attendre celui qui est à 10 %.
 */
public enum CivicPlanGrain {

    /** Mode dégradé assumé : « Renforcer : Système institutionnel ». */
    THEME,

    /** Le grain visé : « Le Parlement ». */
    NOTION
}

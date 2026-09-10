package com.sejourfr.app.enums;

/**
 * Ou en est la preparation d'un module (Accueil, Plan, Examens).
 *
 * <h2>🛑 UN SEUL ETAT, TROIS PORTES</h2>
 * <p>L'Accueil, le Plan et les Examens montrent tous les trois la meme
 * prochaine action — parce qu'ils lisent tous les trois <b>cet</b> etat. Trois
 * ecrans qui deduiraient chacun leur version finiraient par proposer trois
 * choses differentes au meme candidat, et c'est exactement ce que l'arbitrage
 * du 2026-09-10 interdit : « il n'y a qu'un seul etat backend. Les trois ecrans
 * ne creent pas trois parcours differents. »
 *
 * <p>🛑 <b>Le serveur expose l'ETAPE, pas la phrase.</b> « Faire mon diagnostic
 * complet » et « Votre plan TCF n'est pas encore pret » appartiennent aux
 * fronts — meme regle que {@code PlanChangeDto} et les jalons.
 *
 * <h2>Asymetrie assumee entre les deux modules</h2>
 * <p>Le TCF a <b>deux</b> diagnostics, qui servent deux objectifs differents :
 * le rapide cree la confiance et donne une premiere estimation, le complet
 * mesure reellement CO/CE/EE/EO et construit le Plan. Le civique n'en a
 * <b>qu'un</b> : ses questions sont deja rapides, deterministes et sans cout
 * LLM, donc un pre-diagnostic n'apporterait rien et dupliquerait le tunnel du
 * TCF (arbitrage du proprietaire, 2026-09-10).
 *
 * <p>D'ou {@link #ESTIMATION_FAITE}, qui n'existe que cote TCF.
 */
public enum PreparationEtape {

    /** Rien n'a commence sur ce module. */
    DIAGNOSTIC_A_FAIRE,

    /**
     * Un diagnostic est ouvert et inacheve. L'avancement reel est servi a cote
     * (2 epreuves sur 4, 14 questions sur 24) : l'ecran affiche « Reprendre ».
     */
    DIAGNOSTIC_EN_COURS,

    /**
     * <b>TCF uniquement</b> : la premiere estimation est faite, le diagnostic
     * complet ne l'est pas.
     *
     * <p>Le Plan ne peut pas encore etre construit — il manque l'oral et les
     * deux comprehensions. C'est l'etape ou l'ecran dit « Votre plan TCF n'est
     * pas encore pret » plutot que d'afficher un plan bati sur une seule
     * production ecrite.
     */
    ESTIMATION_FAITE,

    /** Le diagnostic qui construit le Plan est termine : le Plan est utilisable. */
    PLAN_PRET
}

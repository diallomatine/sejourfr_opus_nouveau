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
     * <p>🛑 <b>REVOQUE le 2026-09-12 (arbitrage du proprietaire)</b> — ce
     * commentaire disait : « Le Plan ne peut pas encore etre construit … c'est
     * l'etape ou l'ecran dit "Votre plan TCF n'est pas encore pret" ». C'est
     * <b>faux</b> depuis toujours cote moteur ({@code LearningPlanService.get()}
     * passe {@code ACTIVE} des que le diagnostic <b>rapide</b> est clos, et
     * batit ses priorites sur ses observations reelles), et c'est desormais
     * <b>interdit</b> cote produit : le diagnostic complet n'est plus un
     * prerequis d'acces au Plan, seulement un moyen de l'affiner.
     *
     * <p>A cette etape le Plan est donc <b>disponible et provisoire</b> — bati
     * uniquement sur ce que le rapide a mesure, sans aucune priorite inventee
     * sur les competences qu'il n'a pas observees. Le fait a lire est
     * {@code PreparationDto.ModulePreparation.planDisponible}, jamais cette
     * valeur d'enum : l'etape dit <b>ou en est le diagnostic</b>, pas si le
     * Plan existe.
     */
    ESTIMATION_FAITE,

    /**
     * Le diagnostic qui <b>affine</b> le Plan est termine.
     *
     * <p>⚠️ Ne veut <b>pas</b> dire « le Plan commence ici » (cf.
     * {@link #ESTIMATION_FAITE}) : cote TCF il dit que les 4 epreuves sont
     * mesurees, donc que le Plan n'est plus provisoire et qu'aucune invitation
     * au diagnostic complet n'a plus lieu d'etre.
     */
    PLAN_PRET
}

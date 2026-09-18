package com.sejourfr.app.enums;

/**
 * Ou en est un <b>cycle</b> du parcours.
 *
 * <p>🛑 <b>PERSISTE</b>, contrairement a {@link JourneyStepStatus} — et
 * l'arbitrage D-14 (2026-09-18) tient les deux ensemble, sans se contredire.
 * Le statut d'une <b>etape</b> se recalcule entierement a la lecture depuis
 * {@code closed_at}, {@code resolution} et l'ordre de cloture : le persister
 * creerait une seconde autorite sur « ou en est ce candidat ? ». Le statut du
 * <b>cycle</b>, lui, n'est pas un derive : c'est une <b>memoire
 * d'ordonnancement</b>. Rien dans les etapes, les lots ou le journal
 * d'evaluations ne permet de reconstituer « ce cycle-ci a ete historise a cette
 * date parce que le candidat a demande une actualisation de son plan » — cela
 * depend d'un <b>evenement</b>, pas d'un etat.
 *
 * <p>Meme argument que {@link JourneyLotStatus#SUPERSEDED} et que
 * {@link JourneyStepResolution}, et meme argument que
 * {@code plan_pinned_priorities} avant eux.
 */
public enum JourneyStatus {

    /**
     * Le cycle que le candidat a sous les yeux. 🛑 <b>Un seul par (candidat,
     * module)</b>, tenu par l'index unique partiel {@code uq_journey_en_cours}
     * — le parcours s'ecrit depuis quatre branchements best-effort (D-24), une
     * regle que seul un service tiendrait serait contournee par le suivant.
     */
    EN_COURS,

    /**
     * Le cycle <b>suivant</b>, en train de se remplir — et <b>invisible du
     * candidat</b> (D-13).
     *
     * <p>Les evaluations passees pendant le cycle en cours y deposent les
     * priorites qu'elles detectent au-dela du budget de leur epreuve. C'est la
     * <b>revocation</b> de R2 « les priorites au-dela ne sont ni stockees ni
     * mises en attente » : le plafond de trois priorites par lot reste un budget
     * pedagogique, ce qui change est la <b>destination</b> de ce qui deborde —
     * la mise en attente, au lieu de l'oubli.
     *
     * <p>Un seul par (candidat, module) aussi ({@code uq_journey_en_attente}).
     */
    EN_ATTENTE,

    /**
     * Le cycle est clos et rejoint l'historique. Sa date d'historisation est
     * <b>obligatoire</b> ({@code chk_journey_historisation}) et son
     * {@code exitLevel} est un <b>fait date</b> (D-12), jamais recalcule
     * ensuite.
     *
     * <p>🛑 <b>Libres et multiples</b> : un candidat en accumule autant qu'il a
     * de cycles derriere lui, et c'est exactement ce que la page Progression
     * lira.
     */
    HISTORISE
}

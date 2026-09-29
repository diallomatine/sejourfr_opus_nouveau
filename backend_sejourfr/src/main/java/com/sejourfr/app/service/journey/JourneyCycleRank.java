package com.sejourfr.app.service.journey;

/**
 * <b>Le rang d'un cycle dans l'histoire d'un candidat</b> — « Cycle 2 ».
 *
 * <p>🛑 <b>Une regle, une autorite.</b> Deux ecrans lisent ce nombre : le Plan,
 * par {@code JourneyCycleDto.numero} (le cycle <b>en cours</b>), et la page
 * Progression, par {@code JourneyHistoryCycleDto.numero} (chaque cycle
 * <b>historise</b>). Les deux derivations partaient du meme fait — « combien de
 * cycles ont ete crees avant celui-ci » — et les ecrire deux fois aurait suffi a
 * les faire diverger : un candidat aurait lu « Cycle 3 » sur son Plan et vu son
 * predecesseur numerote « Cycle 3 » dans son historique. C'est le defaut le plus
 * cher du depot (la table des paliers en six copies) ; a la deuxieme occurrence,
 * on extrait.
 *
 * <p>La regle est <b>chronologique et rien d'autre</b> : le rang ne se persiste
 * pas, ne se renumerote pas, et ne depend ni du statut ni du niveau cible du
 * cycle. Un changement d'objectif ne cree pas de cycle (D-13, A27), il n'avance
 * donc aucun rang.
 */
final class JourneyCycleRank {

    private JourneyCycleRank() {}

    /**
     * Le rang d'un cycle, connaissant le nombre de cycles du meme module
     * <b>crees avant lui</b>. Le premier cycle vaut {@code 1}.
     *
     * <p>Les deux appelants n'ont pas la meme facon de compter ce « avant », et
     * c'est normal — c'est le <b>nombre</b> qui doit rester unique, pas la
     * requete :
     * <ul>
     *   <li>le cycle <b>en cours</b> : tous ses predecesseurs sont historises
     *       (un seul {@code EN_COURS} par candidat et par module, et le
     *       {@code EN_ATTENTE} est cree <b>pendant</b> lui), donc « crees
     *       avant » = « historises » — un simple {@code count} ;</li>
     *   <li>un cycle <b>historise</b> : son rang dans la liste des cycles du
     *       module ordonnee par {@code created_at} croissant.</li>
     * </ul>
     */
    static int rang(int cyclesCreesAvant) {
        return cyclesCreesAvant + 1;
    }
}

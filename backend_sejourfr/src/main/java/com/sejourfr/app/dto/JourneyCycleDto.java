package com.sejourfr.app.dto;

/**
 * <b>L'avancement du cycle</b> : la barre continue et son repere.
 *
 * <p>🛑 <b>Tout est derive a la lecture</b> (D-12, D-14). Rien de ce record
 * n'est persiste : le cycle ne porte en base que son <b>statut</b>, ses niveaux
 * d'entree / de sortie et sa date d'historisation — les seuls faits qu'aucun
 * recalcul ne saurait reconstituer.
 *
 * <p>🛑 <b>Des nombres, pas des phrases</b> (B-11). « 3 étapes sur 8 terminées »
 * et « Cycle 2 » sont composes par les fronts, dans leurs libelles miroirs. Le
 * serveur n'en sert aucun mot.
 *
 * @param numero          le rang de ce cycle dans l'histoire du candidat :
 *                        nombre de cycles <b>historises</b> du module + 1. Le
 *                        premier cycle vaut donc {@code 1}.
 * @param etapesTerminees etapes cloturees du cycle, <b>obsoletes exclues</b> :
 *                        une etape que la file a rendue caduque n'a pas ete
 *                        « terminee » par le candidat, et la compter le
 *                        feliciterait pour du travail qu'il n'a pas fait.
 * @param etapesTotal     etapes du cycle, obsoletes exclues — le denominateur
 *                        de la barre.
 * @param complete        plus <b>aucune</b> etape ouverte : les quatre blocs
 *                        sont termines. C'est la condition — et la seule — qui
 *                        ouvre l'ecran « Prochaine étape » (spec §6).
 * @param cycleDeMesure   ce cycle ne porte <b>aucune</b> etape d'entrainement :
 *                        c'est un cycle d'examens seuls. 🛑 <b>Derive, pas une
 *                        colonne</b> : a la fin d'un tel cycle, proposer un
 *                        second examen complet enchaine n'aurait aucun sens, et
 *                        la seule issue offerte est l'actualisation.
 */
public record JourneyCycleDto(
        int numero,
        int etapesTerminees,
        int etapesTotal,
        boolean complete,
        boolean cycleDeMesure
) {}

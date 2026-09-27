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
 * @param complete        plus <b>aucune</b> etape <b>obligatoire</b> ouverte
 *                        ({@code JourneyCycleAffinage.termine}) : hors
 *                        affinage, plus aucune etape ouverte du tout. C'est le fait dont l'ecran tire
 *                        « <b>Cycle entierement travaille</b> ».
 *                        <p>C'est aussi la <b>seule</b> condition de la fin
 *                        de cycle depuis D-66 (2026-09-27) : l'examen blanc
 *                        complet n'en fait plus partie, il ne reste que
 *                        l'actualisation.</p>
 * @param cycleDeMesure   ce cycle ne porte <b>aucune</b> etape d'entrainement :
 *                        c'est un cycle d'examens seuls. 🛑 <b>Derive, pas une
 *                        colonne</b>. C'est le <b>cycle d'examens</b> qu'ouvre
 *                        le jalon « Faire un examen blanc complet » (D-68) :
 *                        le jalon n'y est jamais propose.
 * @param cycleDAffinage  ce cycle est le <b>premier</b>, amorce par le
 *                        diagnostic rapide (2026-09-27, D-64) : il sert a
 *                        AFFINER la mesure. Ses examens d'epreuve sont ouverts
 *                        d'emblee (aucun verrou {@code PROGRESSION}), ses
 *                        competences sont <b>facultatives</b>, et il est
 *                        {@code complete} — donc actualisable — des que ses
 *                        examens sont passes. 🛑 Autorite :
 *                        {@code JourneyCycleAffinage} ; les fronts n'en
 *                        tirent que leurs phrases, jamais un verrou.
 *                        <p>⚠️ En affinage, {@code etapesTotal} compte les
 *                        etapes <b>obligatoires</b> plus les facultatives deja
 *                        faites : une competence non travaillee ne retient pas
 *                        la barre sous 100 %.</p>
 * @param prioritesCycleSuivant <b>combien de priorites le cycle SUIVANT
 *                        portera</b>, deja identifiees (2026-09-27, D-67) :
 *                        l'ecran l'ecrit sous « Actualiser mon plan »,
 *                        derniere etape de la timeline. 🛑 Autorite :
 *                        {@code JourneyCycleSuivant} — cote TCF, les etapes
 *                        d'entrainement ouvertes du cycle en attente ; cote
 *                        civique, les unites que l'amorce retiendrait. C'est le
 *                        nombre <b>retenu</b> (au plus
 *                        {@code maxPrioritiesPerLot} par epreuve / thematique),
 *                        jamais le nombre calcule. {@code null} en
 *                        consultation d'un cycle clos.
 */
public record JourneyCycleDto(
        int numero,
        int etapesTerminees,
        int etapesTotal,
        boolean complete,
        boolean cycleDeMesure,
        boolean cycleDAffinage,
        Integer prioritesCycleSuivant
) {}

package com.sejourfr.app.dto;

import com.sejourfr.app.enums.JourneyFinDeCycle;

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
 *                        <p>⚠️ <b>Ce n'est plus la seule condition qui ouvre
 *                        l'ecran « Prochaine étape »</b> (2026-09-20) :
 *                        l'<b>examen de fin de cycle</b> se debloque des
 *                        {@code finDeCycleExamenRatio} des etapes terminees
 *                        (80 % en v3). L'<b>actualisation</b>, elle, attend
 *                        toujours ce {@code complete}-ci.</p>
 * @param cycleDeMesure   ce cycle ne porte <b>aucune</b> etape d'entrainement :
 *                        c'est un cycle d'examens seuls. 🛑 <b>Derive, pas une
 *                        colonne</b> : a la fin d'un tel cycle, proposer un
 *                        second examen complet enchaine n'aurait aucun sens, et
 *                        la seule issue offerte est l'actualisation.
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
 * @param finDeCycle      ce qui <b>clot</b> ce cycle, servi des son debut
 *                        (2026-09-27) : la derniere etape de la timeline du
 *                        Plan l'annonce avant qu'elle soit atteinte. 🛑
 *                        Autorite : {@link JourneyFinDeCycle#de}, la meme qui
 *                        decide de {@code nextStep.examenCompletPossible}.
 */
public record JourneyCycleDto(
        int numero,
        int etapesTerminees,
        int etapesTotal,
        boolean complete,
        boolean cycleDeMesure,
        boolean cycleDAffinage,
        JourneyFinDeCycle finDeCycle
) {}

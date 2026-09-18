package com.sejourfr.app.dto;

/**
 * <b>Les issues d'un cycle termine</b> (spec §6) — la carte finale a deux
 * actions.
 *
 * <p>🛑 <b>{@code null} tant que le cycle n'est pas termine</b> : ces deux
 * gestes historisent le cycle en cours, et les proposer plus tot reviendrait a
 * offrir de jeter un plan que le candidat n'a pas fini.
 *
 * <p>🛑 <b>Deux booleens, aucune phrase</b> (B-11) : « Passer l'examen blanc
 * complet », « Actualiser mon plan sans examen complet » et « Objectif
 * atteint » sont composes par les fronts.
 *
 * @param examenCompletPossible « Passer l'examen blanc complet » : le cycle en
 *                              cours est historise et un <b>cycle de mesure</b>
 *                              devient le cycle courant — quatre blocs, chacun
 *                              ne portant que son examen. 🛑 <b>Faux a la fin
 *                              d'un cycle de mesure</b> : enchainer un second
 *                              examen complet n'a aucun sens pedagogique.
 *                              ⚠️ Cette action <b>cree le cycle</b>, elle ne
 *                              demarre aucun examen : l'examen reste lance par
 *                              {@code /api/full-tcf-exams}.
 * @param actualisationPossible « Actualiser mon plan » : le cycle en attente
 *                              devient le cycle courant. Toujours vrai quand le
 *                              cycle est termine — y compris quand le cycle en
 *                              attente est <b>vide</b>, cas ou l'etat servi
 *                              reste celui du « plus rien a faire »
 *                              ({@code UP_TO_DATE}).
 */
public record JourneyNextStepDto(
        boolean examenCompletPossible,
        boolean actualisationPossible
) {}

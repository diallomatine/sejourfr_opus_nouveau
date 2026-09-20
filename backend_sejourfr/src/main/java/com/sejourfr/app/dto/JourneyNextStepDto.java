package com.sejourfr.app.dto;

/**
 * <b>Les issues d'un cycle termine</b> (spec §6) — la carte finale a deux
 * actions.
 *
 * <p>⚠️ <b>Servi des 80 % depuis le 2026-09-20</b>, et non plus au cycle entier :
 * c'est l'<b>examen de fin de cycle</b> qui se debloque tot
 * ({@code finDeCycleExamenRatio}, configuration versionnee). {@code null} en
 * dessous de cette part. 🛑 <b>L'actualisation, elle, garde sa regle</b> — voir
 * {@link #actualisationPossible()}.
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
 *                              devient le cycle courant. Vrai quand le cycle est
 *                              <b>termine</b>, et alors toujours — y compris
 *                              quand le cycle en attente est <b>vide</b>, cas ou
 *                              l'etat servi reste celui du « plus rien a faire »
 *                              ({@code UP_TO_DATE}).
 *                              <p>🛑 <b>Faux entre 80 % et 100 %</b> (2026-09-20) :
 *                              ce geste <b>historise</b> le cycle et promeut le
 *                              suivant. L'offrir avant la fin jetterait du
 *                              travail que le candidat n'a pas demande a
 *                              abandonner. Seul l'examen de fin de cycle se
 *                              debloque tot.</p>
 */
public record JourneyNextStepDto(
        boolean examenCompletPossible,
        boolean actualisationPossible
) {}

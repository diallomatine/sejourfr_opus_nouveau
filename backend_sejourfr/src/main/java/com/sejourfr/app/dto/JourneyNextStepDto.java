package com.sejourfr.app.dto;

/**
 * <b>L'issue d'un cycle termine</b> — la carte de fin de cycle.
 *
 * <p>🛑 <b>Une seule issue depuis le 2026-09-27</b> (D-66, decision du
 * proprietaire) : « Actualiser mon plan ». L'examen blanc complet a quitte la
 * fin de cycle — il devient un <b>jalon propose</b> au-dessus du Plan
 * ({@code JourneyDto.examenComplet}, D-68) — et avec lui le booleen
 * {@code examenCompletPossible}, supprime.
 *
 * <p>{@code null} tant que le cycle n'est pas termine : ce geste historise le
 * cycle et promeut le suivant, l'offrir avant la fin jetterait du travail que
 * le candidat n'a pas demande a abandonner.
 *
 * @param actualisationPossible « Actualiser mon plan » : le cycle en attente
 *                              devient le cycle courant. Vrai quand le cycle est
 *                              <b>termine</b>, y compris quand le cycle en
 *                              attente est <b>vide</b> ({@code UP_TO_DATE}
 *                              ensuite).
 */
public record JourneyNextStepDto(
        boolean actualisationPossible
) {}

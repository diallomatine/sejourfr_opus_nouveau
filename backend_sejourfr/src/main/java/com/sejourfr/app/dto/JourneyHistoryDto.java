package com.sejourfr.app.dto;

import java.util.List;

/**
 * <b>L'historique des cycles</b>, tel que {@code GET /api/me/plan/journey/history}
 * le sert : l'ecran « Ma progression » (maquette
 * {@code docs/progression/histo_cycle.html}).
 *
 * <p>🛑 <b>Des faits, pas des phrases</b> (B-11). « 4–16 septembre »,
 * « Cycle 2 », « 6 compétences · 3 examens », « Niveau B1 », « A2 → B1 » sont
 * composes par les fronts, dans leurs libelles miroirs. Le serveur sert des
 * dates, des nombres, des enums et des titres de competence — et pas un mot de
 * plus.
 *
 * <p>🛑 <b>Jamais {@code null}, jamais absent.</b> Un candidat qui n'a ferme
 * aucun cycle recoit {@link #cycles()} <b>vide</b> et des statistiques a zero :
 * l'ecran sait dire « rien encore », il ne sait pas dire « inconnu ».
 *
 * @param stats  les trois compteurs de l'en-tete, tous du <b>module TCF</b>.
 * @param cycles les cycles <b>historises</b>, du <b>plus recent au plus
 *               ancien</b> ({@code historise_at DESC}) — l'ordre de la maquette,
 *               et l'ordre servi : aucun front ne retrie. 🛑 Le cycle
 *               <b>en cours</b> n'y figure pas (il n'est pas termine), et le
 *               cycle <b>EN ATTENTE</b> n'y figure <b>jamais</b> — il est
 *               invisible du candidat par construction (D-13).
 */
public record JourneyHistoryDto(
        JourneyHistoryStatsDto stats,
        List<JourneyHistoryCycleDto> cycles
) {}

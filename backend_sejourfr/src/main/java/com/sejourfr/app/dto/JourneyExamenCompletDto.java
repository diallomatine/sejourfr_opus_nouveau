package com.sejourfr.app.dto;

import com.sejourfr.app.enums.JourneyJalonRaison;

/**
 * <b>Le jalon « Faire un examen blanc complet »</b> — propose au-dessus du Plan,
 * sous la carte « À faire maintenant » (2026-09-27, D-68).
 *
 * <p>🛑 <b>Sa presence EST la proposition</b> : {@code JourneyDto.examenComplet}
 * vaut {@code null} quand il n'est pas propose, et aucun front ne recombine la
 * condition. Autorite unique : {@code JourneyJalonExamenComplet}, la meme que
 * le refus 409 de {@code POST …/journey/measurement-cycle} — le bouton servi
 * et le refus serveur ne peuvent pas diverger.
 *
 * <p>🛑 <b>Des faits, pas des phrases</b> (B-11) : « Vous avez terminé 3
 * cycles de travail » se compose dans les fronts.
 *
 * @param raison          pourquoi il est propose.
 * @param cyclesDeTravail cycles de travail termines depuis le dernier examen
 *                        blanc complet, le cycle en cours compris s'il est
 *                        termine. Servi quelle que soit la raison.
 */
public record JourneyExamenCompletDto(
        JourneyJalonRaison raison,
        int cyclesDeTravail
) {}

package com.sejourfr.app.dto;

import com.sejourfr.app.enums.JourneyFinDeCycle;
import com.sejourfr.app.enums.TargetLevel;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * <b>Un cycle CLOS, relu tel qu'il etait</b> — l'ecran de consultation de
 * « Mes cycles » ({@code GET /api/me/plan/journey/history/{journeyId}},
 * 2026-09-27).
 *
 * <h2>🛑 Le MEME cycle que le Plan, en lecture seule</h2>
 * <p>{@link #cycle()} et {@link #blocs()} sont les <b>memes DTO</b> que ceux du
 * Plan courant ({@link JourneyCycleDto}, {@link JourneyBlocDto},
 * {@link JourneyStepDto}), batis par les <b>memes regles</b>
 * ({@code JourneyBlocResolver}, {@code JourneyCycleAffinage}) sur les etapes
 * <b>persistees</b> du cycle. Ce qui fait la consultation est SERVI, jamais
 * deduit par un front :
 * <ul>
 *   <li>aucun verrou : {@code locked = false}, {@code lockReason = null} ;</li>
 *   <li>aucune action : {@code assessment = null}, {@code exercise = null},
 *       {@code progress = null} — un cycle clos ne se rejoue pas ;</li>
 *   <li>une etape restee ouverte est {@code NON_FAITE}, jamais « a venir » ;
 *       un bloc inacheve est {@code INACHEVE}, jamais « en cours ».</li>
 * </ul>
 *
 * <h2>🛑 Fige = ce qui est persiste</h2>
 * <p>Clotures, resolutions, positions, dates et niveaux d'entree / de sortie
 * sont lus sur les lignes. Aucun calcul de maitrise, aucun acces, aucune
 * election d'etape courante n'est rejoue : ce sont des faits d'<b>aujourd'hui</b>,
 * et un cycle clos n'en a plus.
 *
 * @param journeyId  l'identifiant du cycle — celui que l'ecran a demande.
 * @param numero     son rang, <b>meme regle</b> que l'historique et le Plan
 *                   ({@code JourneyCycleRank}).
 * @param debut      {@code journey.created_at}.
 * @param fin        {@code journey.historise_at} — jamais {@code null} ici.
 * @param finDeCycle <b>le geste qui l'a clos</b> (V077). {@code null} =
 *                   inconnu (cycle clos avant V077) : l'ecran dit « Cycle
 *                   terminé », sans inventer l'issue. {@code INTERROMPU}
 *                   = mis de cote par le jalon d'examen complet (D-68).
 * @param objectif   l'objectif du cycle, servi avec son libelle.
 */
public record JourneyCycleArchiveDto(
        UUID journeyId,
        int numero,
        Instant debut,
        Instant fin,
        JourneyFinDeCycle finDeCycle,
        JourneyObjectifRefDto objectif,
        /** Lu tel quel sur la ligne — <b>TCF</b>. {@code null} = inconnu. */
        TargetLevel entryLevel,
        TargetLevel exitLevel,
        /** Lu tel quel sur la ligne — <b>CIVIQUE</b>, sur 40. {@code null} = inconnu. */
        Short entryScore,
        Short exitScore,
        JourneyCycleDto cycle,
        List<JourneyBlocDto> blocs
) {}

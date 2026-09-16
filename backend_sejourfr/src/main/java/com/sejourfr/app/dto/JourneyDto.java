package com.sejourfr.app.dto;

import com.sejourfr.app.enums.JourneyState;
import com.sejourfr.app.enums.JourneySuggestionType;
import com.sejourfr.app.enums.TargetLevel;

import java.util.List;

/**
 * Le parcours TCF, tel que {@code GET /api/me/plan/journey} le sert.
 *
 * <p>🛑 <b>Une seule reponse alimente la carte « À faire maintenant » ET la
 * timeline</b> (§15). C'est la propriete qui rend impossible la contradiction
 * corrigee le 2026-09-16, ou l'Accueil annoncait une action et le Plan une autre
 * au meme instant pour le meme candidat.
 */
public record JourneyDto(
        /** {@code null} quand {@code state == NEEDS_OBJECTIVE} : il n'y a pas de parcours. */
        TargetLevel targetLevel,
        JourneyState state,
        /**
         * L'etape a faire maintenant : la premiere ouverte <b>et executable</b>
         * (arbitrage D-1).
         *
         * <p>{@code null} dans trois cas, et les fronts les distinguent par
         * {@link #state()} : aucun objectif declare ({@code NEEDS_OBJECTIVE}),
         * plus rien a faire ({@code UP_TO_DATE}), ou des etapes ouvertes mais
         * aucune executable ({@code LOCKED} — la carte montre alors la premiere
         * etape de {@link #steps()}, verrouillee, avec son paywall).
         */
        JourneyStepDto current,
        /**
         * Les etapes a afficher, <b>deja filtrees</b> (§14) et dans l'ordre de la
         * file. Les etapes {@code OBSOLETE} n'y sont jamais.
         */
        List<JourneyStepDto> steps,
        /** Combien d'etapes a venir sont repliees derriere « Voir les etapes suivantes ». */
        int hiddenUpcomingCount,
        /** {@code null} est le cas courant : une suggestion n'est pas une etape (§8). */
        JourneySuggestionType suggestion
) {}

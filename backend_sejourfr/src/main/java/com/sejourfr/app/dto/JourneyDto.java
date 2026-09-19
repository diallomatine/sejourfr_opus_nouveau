package com.sejourfr.app.dto;

import com.sejourfr.app.enums.JourneyState;
import com.sejourfr.app.enums.JourneySuggestionType;

import java.util.List;

/**
 * Le parcours TCF, tel que {@code GET /api/me/plan/journey} le sert.
 *
 * <p>🛑 <b>Une seule reponse alimente la carte « À faire maintenant » ET la
 * timeline</b> (§15). C'est la propriete qui rend impossible la contradiction
 * corrigee le 2026-09-16, ou l'Accueil annoncait une action et le Plan une autre
 * au meme instant pour le meme candidat.
 *
 * <h2>Le cycle borne (D-12) se SUPERPOSE a la file, il ne la remplace pas</h2>
 * <p>{@link #cycle()}, {@link #blocs()} et {@link #nextStep()} sont la lecture
 * <b>par epreuve</b> de la meme file : les memes etapes, regroupees. Aucune
 * position n'est renumerotee, aucune etape n'est dupliquee — une etape
 * d'entrainement apparait dans son bloc, et l'examen d'un bloc dans
 * {@link JourneyBlocDto#exam()}.
 *
 * <h2>⚠️ {@code steps} et {@code hiddenUpcomingCount} ont disparu (P6)</h2>
 * <p>Les deux champs de transition et le <b>fenetrage d'affichage</b> (§14) qui
 * les alimentait ont ete retires le 2026-09-18, dans la passe qui a bascule les
 * deux fronts sur {@link #blocs()}. « Refonte = suppression immediate de
 * l'ancien » : la cohabitation etait datee, pas permanente. La lecture du cycle
 * est {@link #blocs()}, qui porte <b>toutes</b> les etapes non obsoletes, sans
 * plafond d'affichage — donc sans compteur de repli.
 */
public record JourneyDto(
        /**
         * <b>L'objectif du cycle, servi</b> — un palier CECRL cote TCF, une
         * mention cote civique, et l'ecran ne branche pas (D-50).
         *
         * <p>⚠️ <b>Remplace {@code targetLevel}</b>, qui etait le dernier champ
         * type TCF de ce contrat : un cycle civique ne pouvait pas s'y
         * exprimer. « Refonte = suppression immediate de l'ancien » — les deux
         * fronts lisent {@code objectif} dans la meme passe.
         *
         * <p>{@code null} quand {@code state == NEEDS_OBJECTIVE} : il n'y a pas
         * de parcours.
         */
        JourneyObjectifRefDto objectif,
        JourneyState state,
        /**
         * L'etape a faire maintenant : la premiere ouverte <b>et executable</b>
         * (arbitrage D-1).
         *
         * <p>{@code null} dans quatre cas, et les fronts les distinguent par
         * {@link #state()} : aucun objectif declare ({@code NEEDS_OBJECTIVE}),
         * cycle termine ({@code CYCLE_COMPLETED}), plus rien a faire
         * ({@code UP_TO_DATE}), ou des etapes ouvertes mais aucune executable
         * ({@code LOCKED} — la carte montre alors la premiere etape verrouillee,
         * avec son paywall).
         */
        JourneyStepDto current,
        /** {@code null} est le cas courant : une suggestion n'est pas une etape (§8). */
        JourneySuggestionType suggestion,
        /** L'avancement du cycle borne (D-12). {@code null} sans parcours. */
        JourneyCycleDto cycle,
        /**
         * Les quatre blocs du cycle, <b>dans l'ordre CO, CE, EO, EE</b>
         * ({@code TcfDomainProfileDto.ORDRE}, D-9 / D-20). Vide sans parcours.
         */
        List<JourneyBlocDto> blocs,
        /**
         * Les issues de fin de cycle (spec §6). 🛑 <b>{@code null} sauf cycle
         * termine.</b>
         */
        JourneyNextStepDto nextStep
) {}

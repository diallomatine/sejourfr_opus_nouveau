package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;

import java.time.Instant;
import java.util.UUID;

/**
 * Une <b>vraie transition</b> du moteur de maitrise sur une competence :
 * « A renforcer &rarr; Solide », « Priorite &rarr; En consolidation ».
 *
 * <p>Elle n'est <b>jamais fabriquee</b>. Elle se mesure en faisant tourner le
 * meme {@code SkillMasteryEngine} deux fois sur le meme historique : une fois
 * arrete au debut de la fenetre, une fois complet. Si les deux etats different,
 * quelque chose a bouge ; sinon il n'y a rien a raconter et aucune ligne
 * n'existe. C'est la difference entre un bloc « ce qui a change » et un bandeau
 * d'encouragement.
 *
 * <p><b>Une premiere observation n'est pas une transition</b> : {@link #before()}
 * n'est jamais {@code null}. Decouvrir un niveau, c'est une mesure initiale, pas
 * un changement — et l'annoncer comme tel remplirait le bloc de bruit au sortir
 * du diagnostic. La designation d'une nouvelle priorite est servie a part, sur
 * {@code PlanRecentChangesDto.newPriority}.
 *
 * <p>🛑 <b>Aucun libelle.</b> Les deux etats portent deja les leurs
 * ({@code SkillMasteryState}), le sens de la marche est donne par
 * {@link #progress()}, et la phrase appartient aux fronts.
 *
 * @param before     etat au debut de la fenetre, jamais {@code null}
 * @param after      etat maintenant, jamais {@code null} et toujours different
 *                   de {@link #before()}
 * @param progress   {@code true} si la competence a monte dans l'echelle
 *                   {@code PRIORITY} &rarr; {@code TO_REINFORCE} &rarr;
 *                   {@code CONSOLIDATING} &rarr; {@code SOLID}. Calcule
 *                   <b>serveur</b> pour qu'aucun front n'ait a coder l'ordre des
 *                   quatre etats — trois copies auraient fini par peindre trois
 *                   fleches differentes
 * @param observedAt derniere observation de la competence, celle qui date le
 *                   changement
 */
public record PlanMasteryTransitionDto(
        UUID skillId,
        String skillCode,
        String title,
        SkillSection section,
        SkillMasteryState before,
        SkillMasteryState after,
        boolean progress,
        Instant observedAt
) {}

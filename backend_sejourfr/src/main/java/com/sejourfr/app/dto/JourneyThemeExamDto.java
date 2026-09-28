package com.sejourfr.app.dto;

import com.sejourfr.app.service.examenblanc.ExamenBlancAccessService;

import java.util.UUID;

/**
 * <b>L'examen blanc de theme que lance l'etape d'examen d'un bloc CIVIQUE</b>
 * — le pendant civique de {@link PlanDomainAssessmentDto}, que le TCF sert sur
 * la meme etape ({@code JourneyStepDto.assessment}).
 *
 * <p>🛑 <b>Servi, jamais compose par un front</b> (2026-09-28) : l'etape
 * d'examen d'un bloc civique arrivait sans aucune action ({@code assessment}
 * est une table d'epreuves TCF, {@code pour(null)} rendait {@code null}), et
 * les deux fronts la rendaient donc sans bouton « Commencer » — un cul-de-sac
 * sur le premier cycle d'examens (D-69 ter). Le front ne deduit ni le theme ni
 * le creneau : il les relaie a {@code POST /api/attempts}
 * ({@code MOCK_EXAM}, module {@code CIVIQUE}), exactement comme la grille des
 * examens blancs du theme.
 *
 * @param themeId    le theme du bloc — {@code StartAttemptRequest.themeId}
 * @param slotNumber le creneau de la grille, lu chez l'autorite du verrou
 *                   ({@code ExamenBlancAccessService.CRENEAU_OFFERT}) : offert
 *                   et rejouable pour tout compte, comme le slot servi par
 *                   {@code PlanDomainAssessmentResolver} cote TCF. Mesurer un
 *                   theme ne bute donc jamais sur le paywall.
 *
 * <p>🛑 <b>Deux points d'appel, une seule fabrique</b> ({@link #offert}) :
 * l'etape d'examen du Plan ({@code JourneyStepDto.examenTheme}) et la carte
 * d'un theme jamais evalue de l'Accueil ({@code CivicPlanDto.ThemeLigne.evaluation},
 * 2026-09-28). Aucun ne recopie le creneau.
 */
public record JourneyThemeExamDto(UUID themeId, int slotNumber) {

    /** L'examen blanc du theme sur le creneau offert, rejouable par tout compte. */
    public static JourneyThemeExamDto offert(UUID themeId) {
        return new JourneyThemeExamDto(themeId, ExamenBlancAccessService.CRENEAU_OFFERT);
    }
}

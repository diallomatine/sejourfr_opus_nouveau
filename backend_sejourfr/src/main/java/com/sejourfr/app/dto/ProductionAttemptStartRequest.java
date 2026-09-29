package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

/**
 * Payload pour {@code POST /api/attempts/production} : cree un attempt vide
 * (sans piocher de questions QCM) dedie aux epreuves productives EO / EE.
 *
 * Differences avec {@link StartAttemptRequest} :
 *   - `epreuve` est requis et doit etre une epreuve productive (TCF_EO, TCF_EE
 *     ou TCF_COMPLET pour un conteneur d'examen blanc).
 *   - pas de questions QCM associees, donc pas de `themeId` / `difficulty` /
 *     `questionType` / `size`.
 *   - `parentAttemptId` (optionnel) : pour les sous-attempts d'un examen blanc
 *     TCF complet ; null pour un entrainement isole.
 */
public record ProductionAttemptStartRequest(
        @NotNull Module module,
        @NotNull EpreuveType epreuve,
        UUID parentAttemptId,
        // True pour une session d'examen blanc production (3 tâches). Marque
        // l'attempt (slot_number posé) : les soumissions de cette session
        // passent outre le quota d'entraînement, et les sessions d'examen
        // comptent dans le budget gratuit (cf. ProductionSubmissionService).
        Boolean exam,
        // Slot de la grille d'examens blancs (1-10) quand exam=true. Pilote la
        // composition déterministe des 3 sujets (bandes A2/B1/B2, cf.
        // ProductionExamCompositionService). Null/absent → slot 1.
        Integer slotNumber
) {}

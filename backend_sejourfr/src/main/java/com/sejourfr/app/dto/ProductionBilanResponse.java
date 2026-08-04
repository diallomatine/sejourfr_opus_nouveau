package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Bilan serveur d'une session production EE/EO (un attempt + ses soumissions).
 *
 * <p>{@code niveauGlobal} n'est renseigné que pour une <b>session d'examen
 * blanc</b> ({@code exam = true}) dont les {@code expectedCount} tâches sont
 * évaluées : moyenne pondérée des compétences des tâches (cf.
 * {@code ProductionBilanService}), plafonnée B2. Jamais de niveau en
 * entraînement libre — seule la note /20 et le feedback y sont restitués.
 *
 * <p>{@code correspondanceTcf} accompagne {@code niveauGlobal} : la fourchette
 * de note officielle du TCF IRN pour ce niveau. C'est le seul endroit où elle a
 * un sens — au TCF, la note /20 est celle d'une épreuve entière, pas d'une
 * tâche.
 */
public record ProductionBilanResponse(
        UUID attemptId,
        EpreuveType epreuve,
        boolean exam,
        // Slot de la grille d'examens blancs (1-10) joué par cette session ;
        // null pour un entraînement libre ou un sous-attempt d'examen complet.
        Integer slotNumber,
        // Épreuve finalisée (fin de session, chrono écoulé, abandon). Une
        // épreuve terminée incomplète a son niveau calculé avec les tâches
        // manquantes comptées 0.
        boolean finished,
        int evaluatedCount,
        int expectedCount,
        BigDecimal moyenneSur20,
        NiveauCecrl niveauGlobal,
        // Fourchette de note officielle du TCF IRN correspondant a
        // niveauGlobal. Null exactement quand niveauGlobal l'est. Ce n'est
        // toujours pas une conversion de moyenneSur20, meme depuis les
        // rubriques v6 qui notent sur l'echelle du TCF : notre note porte sur
        // une seule tache, celle du TCF sur l'epreuve entiere. On part du
        // NIVEAU et on affiche sa fourchette officielle (cf. BandeNoteTcf).
        CorrespondanceTcfDto correspondanceTcf
) {
}

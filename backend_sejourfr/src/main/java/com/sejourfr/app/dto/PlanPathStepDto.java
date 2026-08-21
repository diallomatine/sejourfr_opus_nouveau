package com.sejourfr.app.dto;

import com.sejourfr.app.enums.PlanPathStepKind;
import com.sejourfr.app.enums.PlanPathStepStatus;
import com.sejourfr.app.enums.TargetLevel;

/**
 * Une etape du chemin vers l'objectif, telle que le Plan la sert.
 *
 * <p>Le serveur dit <b>quoi</b> et <b>ou en est le candidat</b> ; le titre
 * (« Construire votre B1 ») appartient aux fronts, comme pour les jalons et
 * pour {@code PlanChangeDto}.
 *
 * @param kind   nature de l'etape
 * @param level  palier concerne — renseigne <b>uniquement</b> sur
 *               {@link PlanPathStepKind#BUILD_LEVEL}, {@code null} ailleurs
 * @param status faite, en cours, ou a venir
 */
public record PlanPathStepDto(
        PlanPathStepKind kind,
        TargetLevel level,
        PlanPathStepStatus status
) {}

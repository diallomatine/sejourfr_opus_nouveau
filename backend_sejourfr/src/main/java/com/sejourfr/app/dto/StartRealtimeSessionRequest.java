package com.sejourfr.app.dto;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

/**
 * Demande de demarrage d'une session d'expression orale temps reel (T1 ou T2).
 *
 * @param productionTaskId la consigne T1/T2 (EO) a jouer.
 * @param attemptId        attempt de rattachement : entrainement isole (peut
 *                         etre {@code null}, un attempt sera cree au besoin par
 *                         le flux standard) ou sous-attempt EO d'un examen
 *                         complet. Optionnel.
 */
public record StartRealtimeSessionRequest(
        @NotNull UUID productionTaskId,
        UUID attemptId
) {}

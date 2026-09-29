package com.sejourfr.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

/**
 * Payload JSON pour soumettre une production ecrite (TCF_EE) : POST
 * /api/production-submissions avec Content-Type application/json.
 * Pour l'oral (audio), on utilise multipart/form-data sur la meme route.
 */
public record SubmitProductionTextRequest(
        @NotNull UUID productionTaskId,
        @NotNull UUID attemptId,
        @NotBlank String texte,
        /**
         * Cle d'idempotence tiree par le client (V046). Renvoyer la meme cle
         * rend la MEME soumission, sans second appel LLM ni second decompte de
         * quota. <b>Facultative</b> : un client qui ne l'envoie pas garde
         * l'ancien comportement.
         */
        UUID clientSubmissionId
) {
}

package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillSelfEvaluation;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

/**
 * Payload JSON pour rendre une production ECRITE sur un petit sujet :
 * {@code POST /api/skill-attempts} en {@code application/json}. L'oral passe
 * par la meme route en {@code multipart/form-data}.
 *
 * <p>{@code requestAnalysis=false} enregistre la production sans declencher
 * d'analyse IA : c'est le cas gratuit et illimite, et le seul moyen de
 * s'entrainer sans consommer son quota.
 */
public record SubmitSkillTextRequest(
        @NotNull UUID skillPromptId,
        @NotBlank String texte,
        /** Facultative et declarative : sans aucun effet sur le verdict. */
        SkillSelfEvaluation selfEvaluation,
        @NotNull Boolean requestAnalysis,
        /**
         * Cle d'idempotence tiree par le client (V046). Renvoyer la meme cle
         * rend la MEME production, sans second appel LLM ni seconde analyse
         * decomptee. <b>Facultative</b> : un client qui ne l'envoie pas garde
         * l'ancien comportement.
         */
        UUID clientSubmissionId
) {
}

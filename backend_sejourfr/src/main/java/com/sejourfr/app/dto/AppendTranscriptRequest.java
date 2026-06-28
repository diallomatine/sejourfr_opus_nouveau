package com.sejourfr.app.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * Fragment de transcript relaye par le client au fil de la conversation. Le
 * client agrege les events de transcription Gemini (entree candidat + sortie
 * examinateur) et les pousse ici (batches ~1-2 s) pour une capture serveur
 * fiable du dialogue — artefact de notation (lot 2).
 *
 * @param speaker {@code CANDIDATE} ou {@code EXAMINER}.
 * @param text    le texte du fragment.
 */
public record AppendTranscriptRequest(
        @NotBlank String speaker,
        @NotBlank String text
) {}

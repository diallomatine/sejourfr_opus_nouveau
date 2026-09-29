package com.sejourfr.app.dto;

import java.util.List;
import java.util.UUID;

/**
 * Récapitulatif d'un lot de génération audio d'exemples EO. La boucle traite
 * les exemples 1 par 1 : un échec n'interrompt pas le lot.
 */
public record ExampleAudioBatchResultDto(
        UUID batchId,
        int requested,
        int succeeded,
        int failed,
        List<Outcome> outcomes
) {
    public record Outcome(UUID exampleId, boolean success, String errorMessage) {
    }
}

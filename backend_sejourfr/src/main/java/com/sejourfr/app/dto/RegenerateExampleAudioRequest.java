package com.sejourfr.app.dto;

/**
 * Corps optionnel de POST /api/admin/production/examples/audio/{id}/regenerate.
 * {@code voice} : voix Azure souhaitée (ex. fr-FR-HenriNeural). Null => voix par
 * défaut alternée selon l'ordre d'affichage.
 */
public record RegenerateExampleAudioRequest(String voice) {
}

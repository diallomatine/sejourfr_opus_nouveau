package com.sejourfr.app.dto;

import java.util.List;
import java.util.UUID;

/**
 * Un emplacement dans une session, qui pointe vers une question + l'état de la réponse.
 */
public record AttemptQuestionResponse(
        UUID id,
        int position,
        QuestionPublicResponse question,
        boolean answered,
        List<UUID> selectedChoiceIds,
        Boolean correct
) {}

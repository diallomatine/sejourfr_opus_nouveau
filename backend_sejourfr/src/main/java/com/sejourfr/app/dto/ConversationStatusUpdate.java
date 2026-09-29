package com.sejourfr.app.dto;

import com.sejourfr.app.enums.MessageStatus;
import jakarta.validation.constraints.NotNull;

public record ConversationStatusUpdate(
        @NotNull(message = "Le statut est requis")
        MessageStatus status
) {}

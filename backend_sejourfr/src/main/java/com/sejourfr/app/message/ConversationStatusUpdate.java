package com.sejourfr.app.message;

import com.sejourfr.app.message.enums.MessageStatus;
import jakarta.validation.constraints.NotNull;

public record ConversationStatusUpdate(
        @NotNull(message = "Le statut est requis")
        MessageStatus status
) {}

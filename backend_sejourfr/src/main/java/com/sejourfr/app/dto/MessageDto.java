package com.sejourfr.app.dto;

import com.sejourfr.app.enums.MessageSender;
import java.time.Instant;
import java.util.UUID;

public record MessageDto(
        UUID id,
        UUID conversationId,
        MessageSender senderType,
        UUID authorId,
        String authorName,
        String body,
        Instant createdAt
) {}

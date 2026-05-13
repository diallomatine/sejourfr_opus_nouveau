package com.sejourfr.app.message;

import com.sejourfr.app.message.enums.MessageSender;

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

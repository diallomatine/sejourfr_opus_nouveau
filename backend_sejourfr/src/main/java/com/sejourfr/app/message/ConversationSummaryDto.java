package com.sejourfr.app.message;

import com.sejourfr.app.message.enums.MessageStatus;

import java.time.Instant;
import java.util.UUID;

public record ConversationSummaryDto(
        UUID id,
        UUID userId,
        String userEmail,
        String userFullName,
        String subject,
        MessageStatus status,
        Instant createdAt,
        Instant lastMessageAt,
        boolean unreadForAdmin,
        String lastMessagePreview,
        long messageCount
) {}

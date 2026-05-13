package com.sejourfr.app.message;

import com.sejourfr.app.message.enums.MessageStatus;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record ConversationDetailDto(
        UUID id,
        UUID userId,
        String userEmail,
        String userFullName,
        String subject,
        MessageStatus status,
        Instant createdAt,
        Instant lastMessageAt,
        boolean unreadForAdmin,
        boolean unreadForUser,
        List<MessageDto> messages
) {}

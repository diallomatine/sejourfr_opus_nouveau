package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AdminReplyRequest;
import com.sejourfr.app.dto.ConversationDetailDto;
import com.sejourfr.app.dto.ConversationStatusUpdate;
import com.sejourfr.app.dto.ConversationSummaryDto;
import com.sejourfr.app.dto.MessageDto;
import com.sejourfr.app.dto.PageResponse;
import com.sejourfr.app.enums.MessageStatus;
import com.sejourfr.app.service.ConversationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/admin/conversations")
@RequiredArgsConstructor
public class AdminConversationController {

    private final ConversationService conversationService;

    @GetMapping
    public PageResponse<ConversationSummaryDto> search(
            @RequestParam(required = false) MessageStatus status,
            @RequestParam(required = false) Boolean unreadOnly,
            @RequestParam(required = false) UUID userId,
            @RequestParam(required = false) String search,
            @PageableDefault(size = 20, sort = "lastMessageAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return PageResponse.from(conversationService.search(status, unreadOnly, userId, search, pageable));
    }

    @GetMapping("/{id}")
    public ConversationDetailDto getDetail(@PathVariable UUID id) {
        return conversationService.getDetail(id);
    }

    @PostMapping("/{id}/mark-read")
    public ConversationDetailDto markRead(@PathVariable UUID id) {
        return conversationService.markRead(id);
    }

    @PostMapping("/{id}/reply")
    public MessageDto reply(
            @PathVariable UUID id,
            @Valid @RequestBody AdminReplyRequest req,
            @AuthenticationPrincipal UserDetails principal) {
        return conversationService.reply(id, principal.getUsername(), req.body());
    }

    @PatchMapping("/{id}/status")
    public ConversationDetailDto updateStatus(
            @PathVariable UUID id,
            @Valid @RequestBody ConversationStatusUpdate req) {
        return conversationService.updateStatus(id, req.status());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) {
        conversationService.delete(id);
    }

    @GetMapping("/unread-count")
    public UnreadCountResponse unreadCount() {
        return new UnreadCountResponse(conversationService.countUnread());
    }

    public record UnreadCountResponse(long count) {}
}

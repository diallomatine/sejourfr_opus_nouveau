package com.sejourfr.app.message;

import com.sejourfr.app.common.PageResponse;
import com.sejourfr.app.message.enums.MessageStatus;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/admin/conversations")
public class AdminConversationController {

    private final ConversationService service;

    public AdminConversationController(ConversationService service) {
        this.service = service;
    }

    @GetMapping
    public PageResponse<ConversationSummaryDto> search(
            @RequestParam(required = false) MessageStatus status,
            @RequestParam(required = false) Boolean unreadOnly,
            @RequestParam(required = false) UUID userId,
            @RequestParam(required = false) String search,
            @PageableDefault(size = 20, sort = "lastMessageAt", direction = Sort.Direction.DESC) Pageable pageable
    ) {
        Page<ConversationSummaryDto> page = service.search(status, unreadOnly, userId, search, pageable);
        return PageResponse.from(page);
    }

    @GetMapping("/{id}")
    public ConversationDetailDto getDetail(@PathVariable UUID id) {
        return service.getDetail(id);
    }

    @PostMapping("/{id}/mark-read")
    public ConversationDetailDto markRead(@PathVariable UUID id) {
        return service.markRead(id);
    }

    @PostMapping("/{id}/reply")
    public MessageDto reply(@PathVariable UUID id,
                            @Valid @RequestBody AdminReplyRequest req,
                            @AuthenticationPrincipal UserDetails principal) {
        return service.reply(id, principal.getUsername(), req.body());
    }

    @PatchMapping("/{id}/status")
    public ConversationDetailDto updateStatus(@PathVariable UUID id,
                                              @Valid @RequestBody ConversationStatusUpdate req) {
        return service.updateStatus(id, req.status());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) {
        service.delete(id);
    }

    @GetMapping("/unread-count")
    public UnreadCountResponse unreadCount() {
        return new UnreadCountResponse(service.countUnread());
    }

    public record UnreadCountResponse(long count) {}
}

package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AdminAccessOperationRequest;
import com.sejourfr.app.dto.AdminAccessOperationResponse;
import com.sejourfr.app.dto.AdminAccessProductDto;
import com.sejourfr.app.dto.AdminMessagePreviewDto;
import com.sejourfr.app.dto.AdminUserMessageRequest;
import com.sejourfr.app.dto.ConversationDetailDto;
import com.sejourfr.app.dto.AdminUserDetailDto;
import com.sejourfr.app.dto.AdminUserListItemDto;
import com.sejourfr.app.dto.PageResponse;
import com.sejourfr.app.enums.AdminUserFilter;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.ConversationService;
import com.sejourfr.app.service.adminuser.AdminAccessOperationService;
import com.sejourfr.app.service.adminuser.AdminUserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Console admin « Utilisateurs » : retrouver, comprendre et dépanner un compte
 * (spec admin utilisateurs V2). Sécurité : {@code /api/admin/**} → ROLE_ADMIN
 * (SecurityConfig) ; l'admin auteur d'une action est lu dans le contexte de
 * sécurité, jamais dans la requête.
 */
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminUserController {

    private final AdminUserService adminUserService;
    private final AdminAccessOperationService accessOperationService;
    private final ConversationService conversationService;
    private final CurrentUser currentUser;

    @GetMapping("/users")
    public PageResponse<AdminUserListItemDto> list(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) AdminUserFilter filter,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "25") int size) {
        return adminUserService.list(q, filter, page, size);
    }

    @GetMapping("/users/{userId}")
    public AdminUserDetailDto detail(@PathVariable UUID userId) {
        return adminUserService.detail(userId);
    }

    @GetMapping("/access-products")
    public List<AdminAccessProductDto> products() {
        return adminUserService.products();
    }

    @PostMapping("/users/{userId}/access-operations")
    public AdminAccessOperationResponse accessOperation(
            @PathVariable UUID userId,
            @Valid @RequestBody AdminAccessOperationRequest request) {
        return accessOperationService.executer(userId, currentUser.getId(), request);
    }

    /**
     * Écrire à un compte (D-58) : crée une conversation et envoie le mail
     * {@code ADMIN_MESSAGE} après commit. 201 + la conversation créée ; 409 si
     * le compte est supprimé.
     */
    @PostMapping("/users/{userId}/messages")
    @ResponseStatus(HttpStatus.CREATED)
    public ConversationDetailDto sendMessage(
            @PathVariable UUID userId,
            @Valid @RequestBody AdminUserMessageRequest request) {
        return conversationService.sendToUser(userId, currentUser.getId(), request.subject(), request.body());
    }

    /** Aperçu du mail par le vrai gabarit, sans rien enregistrer ni envoyer. */
    @PostMapping("/users/{userId}/messages/preview")
    public AdminMessagePreviewDto previewMessage(
            @PathVariable UUID userId,
            @Valid @RequestBody AdminUserMessageRequest request) {
        return conversationService.previewToUser(userId, request.subject(), request.body());
    }
}

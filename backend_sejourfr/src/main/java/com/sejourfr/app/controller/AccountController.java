package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AccountDeletionResponse;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.AccountDeletionService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Gestion du compte de l'utilisateur courant. Pour l'instant un seul endpoint :
 * la suppression (App Store Guideline 5.1.1(v) — suppression in-app obligatoire).
 */
@RestController
@RequestMapping("/api/account")
@RequiredArgsConstructor
public class AccountController {

    private final AccountDeletionService accountDeletionService;
    private final CurrentUser currentUser;

    /**
     * Supprime le compte de l'utilisateur authentifié. Le {@code userId} vient
     * toujours du principal — jamais d'un paramètre — donc un user ne peut
     * supprimer que son propre compte.
     */
    @DeleteMapping
    public AccountDeletionResponse deleteAccount() {
        return accountDeletionService.deleteAccount(currentUser.getId());
    }
}

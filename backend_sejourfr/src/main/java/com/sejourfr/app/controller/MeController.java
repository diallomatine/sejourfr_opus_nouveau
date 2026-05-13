package com.sejourfr.app.controller;

import com.sejourfr.app.dto.QuestionPublicResponse;
import com.sejourfr.app.dto.UserStatsResponse;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.UserContentService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Endpoints "me" : tout ce qui dépend de l'utilisateur courant.
 */
@RestController
@RequestMapping("/api/me")
public class MeController {

    private final UserContentService service;
    private final CurrentUser currentUser;

    public MeController(UserContentService service, CurrentUser currentUser) {
        this.service = service;
        this.currentUser = currentUser;
    }

    // ------------------------------------------------------------------------
    // Stats
    // ------------------------------------------------------------------------

    @GetMapping("/stats")
    public UserStatsResponse stats(@RequestParam Module module) {
        return service.stats(currentUser.getId(), module);
    }

    // ------------------------------------------------------------------------
    // Favoris
    // ------------------------------------------------------------------------

    @GetMapping("/questions/favorites")
    public List<QuestionPublicResponse> favorites(@RequestParam Module module) {
        return service.favorites(currentUser.getId(), module);
    }

    @PostMapping("/questions/{questionId}/favorite")
    public ResponseEntity<Void> addFavorite(@PathVariable UUID questionId) {
        service.addFavorite(currentUser.getId(), questionId);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/questions/{questionId}/favorite")
    public ResponseEntity<Void> removeFavorite(@PathVariable UUID questionId) {
        service.removeFavorite(currentUser.getId(), questionId);
        return ResponseEntity.noContent().build();
    }

    // ------------------------------------------------------------------------
    // Erreurs
    // ------------------------------------------------------------------------

    @GetMapping("/questions/wrong")
    public List<QuestionPublicResponse> wrong(@RequestParam Module module) {
        return service.wrongAnswered(currentUser.getId(), module);
    }
}

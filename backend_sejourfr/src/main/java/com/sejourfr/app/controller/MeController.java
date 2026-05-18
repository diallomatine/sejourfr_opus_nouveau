package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AttemptSummaryResponse;
import com.sejourfr.app.dto.QuestionPublicResponse;
import com.sejourfr.app.dto.QuestionReviewResponse;
import com.sejourfr.app.dto.UpdateTargetProcedureRequest;
import com.sejourfr.app.dto.UserStatsResponse;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.repository.UserRepository;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.AttemptService;
import com.sejourfr.app.service.UserContentService;
import jakarta.validation.Valid;
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
    private final AttemptService attemptService;
    private final UserRepository userRepository;

    public MeController(
            UserContentService service,
            CurrentUser currentUser,
            AttemptService attemptService,
            UserRepository userRepository
    ) {
        this.service = service;
        this.currentUser = currentUser;
        this.attemptService = attemptService;
        this.userRepository = userRepository;
    }

    // ------------------------------------------------------------------------
    // Parcours administratif visé (CSP / CR / NAT)
    // ------------------------------------------------------------------------

    /**
     * Met à jour le parcours visé par l'utilisateur. Appelé après l'onboarding
     * ou depuis le profil. Une fois renseigné, AttemptService dérive
     * automatiquement la difficulté des questions tirées.
     */
    @PutMapping("/target-path")
    public ResponseEntity<Void> updateTargetPath(
            @Valid @RequestBody UpdateTargetProcedureRequest req
    ) {
        User user = currentUser.get();
        user.setTargetProcedure(req.targetProcedure());
        userRepository.save(user);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/attempts")
    public List<AttemptSummaryResponse> attempts(
            @RequestParam(required = false) AttemptType type,
            @RequestParam(required = false) Module module,
            @RequestParam(defaultValue = "20") int limit
    ) {
        return attemptService.listMine(currentUser.getId(), type, module, limit);
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
    public List<QuestionPublicResponse> favorites(@RequestParam(required = false) Module module) {
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
    public List<QuestionPublicResponse> wrong(@RequestParam(required = false) Module module) {
        return service.wrongAnswered(currentUser.getId(), module);
    }

    // ------------------------------------------------------------------------
    // Revue détaillée (explication + bonnes réponses)
    // ------------------------------------------------------------------------

    @GetMapping("/questions/{questionId}/review")
    public QuestionReviewResponse review(@PathVariable UUID questionId) {
        return service.review(currentUser.getId(), questionId);
    }
}

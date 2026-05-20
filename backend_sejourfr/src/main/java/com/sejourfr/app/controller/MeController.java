package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AttemptSummaryResponse;
import com.sejourfr.app.dto.QuestionPublicResponse;
import com.sejourfr.app.dto.QuestionReviewResponse;
import com.sejourfr.app.dto.UpdateTargetProcedureRequest;
import com.sejourfr.app.dto.UserStatsResponse;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.AttemptService;
import com.sejourfr.app.service.MeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Endpoints "me" : tout ce qui depend de l'utilisateur courant.
 * AttemptService est encore appele directement pour /attempts (listMine) :
 * il ne s'agit pas d'un concept "me" specifique, juste d'un filtre par user.
 */
@RestController
@RequestMapping("/api/me")
@RequiredArgsConstructor
public class MeController {

    private final MeService meService;
    private final AttemptService attemptService;
    private final CurrentUser currentUser;

    // ------------------------------------------------------------------------
    // Parcours administratif vise (CSP / CR / NAT)
    // ------------------------------------------------------------------------

    @PutMapping("/target-path")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void updateTargetPath(@Valid @RequestBody UpdateTargetProcedureRequest req) {
        meService.updateTargetProcedure(currentUser.getId(), req.targetProcedure());
    }

    @GetMapping("/attempts")
    public List<AttemptSummaryResponse> attempts(
            @RequestParam(required = false) AttemptType type,
            @RequestParam(required = false) Module module,
            @RequestParam(defaultValue = "20") int limit) {
        return attemptService.listMine(currentUser.getId(), type, module, limit);
    }

    // ------------------------------------------------------------------------
    // Stats
    // ------------------------------------------------------------------------

    @GetMapping("/stats")
    public UserStatsResponse stats(@RequestParam Module module) {
        return meService.stats(currentUser.getId(), module);
    }

    // ------------------------------------------------------------------------
    // Favoris
    // ------------------------------------------------------------------------

    @GetMapping("/questions/favorites")
    public List<QuestionPublicResponse> favorites(@RequestParam(required = false) Module module) {
        return meService.favorites(currentUser.getId(), module);
    }

    @PostMapping("/questions/{questionId}/favorite")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void addFavorite(@PathVariable UUID questionId) {
        meService.addFavorite(currentUser.getId(), questionId);
    }

    @DeleteMapping("/questions/{questionId}/favorite")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void removeFavorite(@PathVariable UUID questionId) {
        meService.removeFavorite(currentUser.getId(), questionId);
    }

    // ------------------------------------------------------------------------
    // Erreurs
    // ------------------------------------------------------------------------

    @GetMapping("/questions/wrong")
    public List<QuestionPublicResponse> wrong(@RequestParam(required = false) Module module) {
        return meService.wrongAnswered(currentUser.getId(), module);
    }

    // ------------------------------------------------------------------------
    // Revue detaillee (explication + bonnes reponses)
    // ------------------------------------------------------------------------

    @GetMapping("/questions/{questionId}/review")
    public QuestionReviewResponse review(@PathVariable UUID questionId) {
        return meService.review(currentUser.getId(), questionId);
    }
}

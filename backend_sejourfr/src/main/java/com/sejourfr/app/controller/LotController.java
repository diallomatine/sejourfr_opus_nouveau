package com.sejourfr.app.controller;

import com.sejourfr.app.dto.LotDto;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.LotService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Endpoint utilisateur : liste des lots disponibles pour un module + critères.
 * Voir {@link LotService} pour la logique de découpage.
 *
 * <p>Deux modes :
 * <ul>
 *   <li><b>TCF</b> : {@code GET /api/lots?module=TCF&questionType=CO&difficulty=A2}</li>
 *   <li><b>Civique</b> : {@code GET /api/lots?module=CIVIQUE&themeId=...}</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/lots")
@RequiredArgsConstructor
public class LotController {

    private final LotService lotService;
    private final CurrentUser currentUser;

    @GetMapping
    public List<LotDto> list(
            @RequestParam Module module,
            @RequestParam(required = false) QuestionType questionType,
            @RequestParam(required = false) Difficulty difficulty,
            @RequestParam(required = false) UUID themeId
    ) {
        return switch (module) {
            case TCF -> {
                if (difficulty == null) {
                    throw new BusinessException(
                            "difficulty est obligatoire pour les lots TCF (A2/B1/B2).");
                }
                yield lotService.list(currentUser.getId(), module, questionType, difficulty);
            }
            case CIVIQUE -> {
                if (themeId == null) {
                    throw new BusinessException(
                            "themeId est obligatoire pour les lots Civique.");
                }
                yield lotService.listCivique(currentUser.getId(), themeId);
            }
        };
    }
}

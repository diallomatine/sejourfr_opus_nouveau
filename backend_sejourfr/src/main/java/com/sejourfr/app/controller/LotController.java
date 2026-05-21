package com.sejourfr.app.controller;

import com.sejourfr.app.dto.LotDto;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.LotService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Endpoint utilisateur : liste des lots disponibles pour un module / épreuve
 * / niveau. Voir {@link LotService} pour la logique de découpage.
 *
 * <p>Exemple : {@code GET /api/lots?module=TCF&questionType=CO&difficulty=A2}
 * → liste des lots A2 de compréhension orale.
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
            @RequestParam Difficulty difficulty
    ) {
        return lotService.list(currentUser.getId(), module, questionType, difficulty);
    }
}

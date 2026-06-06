package com.sejourfr.app.controller;

import com.sejourfr.app.dto.LotDto;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.service.LotService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Variante publique de {@link LotController} pour les visiteurs non
 * authentifiés : même découpage de séries, sans enrichissement des derniers
 * scores (userId null). Sert les pages séries en mode guest — la série 1 est
 * jouable sans compte (cf. PublicAttemptService), les suivantes verrouillées.
 */
@RestController
@RequestMapping("/api/public/lots")
@RequiredArgsConstructor
public class PublicLotController {

    private final LotService lotService;

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
                yield lotService.list(null, module, questionType, difficulty);
            }
            case CIVIQUE -> {
                if (themeId == null) {
                    throw new BusinessException(
                            "themeId est obligatoire pour les lots Civique.");
                }
                yield lotService.listCivique(null, themeId);
            }
        };
    }
}

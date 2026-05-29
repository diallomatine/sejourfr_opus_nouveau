package com.sejourfr.app.controller;

import com.sejourfr.app.dto.ProductionExampleDto;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.service.ProductionExampleService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Exemples-modeles d'une categorie (epreuve, tacheNumero), lecture seule.
 *   GET /api/production-examples?epreuve=TCF_EO&tacheNumero=3
 */
@RestController
@RequestMapping("/api/production-examples")
@RequiredArgsConstructor
public class ProductionExampleController {

    private final ProductionExampleService productionExampleService;

    @GetMapping
    public List<ProductionExampleDto> list(
            @RequestParam EpreuveType epreuve,
            @RequestParam short tacheNumero) {
        return productionExampleService.listByEpreuveAndTache(epreuve, tacheNumero);
    }
}

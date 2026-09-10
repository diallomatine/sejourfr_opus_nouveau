package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AdminAiCostResponse;
import com.sejourfr.app.service.AdminAiCostService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * <b>Ce que l'IA coute</b>, pour la console d'administration (lot L12).
 *
 * <p><b>Un seul endpoint de lecture</b>, comme l'Analytics : l'ecran recalcule
 * toutes ses sections sur la MEME periode. Cinq endpoints, c'est cinq fenetres
 * a garder coherentes cote console — et le jour ou l'une decale, deux blocs de
 * la meme page racontent deux histoires.
 *
 * <p>{@code from}/{@code to} l'emportent sur {@code days} ; les bornes
 * <i>appliquees</i> sont rendues dans la reponse, pour que l'ecran affiche la
 * periode d'apres le serveur et non d'apres ce qu'il a demande.
 *
 * <p>🛑 <b>Cette route ne declenche aucun appel LLM.</b> Elle lit une vue. Le
 * cout de la supervision du cout est nul, et il doit le rester.
 */
@RestController
@RequestMapping("/api/admin/ai-costs")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminAiCostController {

    private final AdminAiCostService service;

    @GetMapping
    public AdminAiCostResponse lire(
            @RequestParam(required = false) String from,
            @RequestParam(required = false) String to,
            @RequestParam(defaultValue = "30") int days) {
        return service.lire(from, to, days);
    }
}

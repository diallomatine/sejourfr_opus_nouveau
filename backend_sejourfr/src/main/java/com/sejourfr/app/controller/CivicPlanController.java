package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.CivicPlanDto;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.plancivique.CivicPlanGrain;
import com.sejourfr.app.service.plancivique.CivicPlanService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * <b>Le plan civique</b> (L10, {@code 20_} §6).
 *
 * <p>🛑 <b>Rien n'est persiste.</b> Le plan se <b>recalcule a chaque lecture</b>
 * depuis l'historique des reponses : il n'existe ni table {@code civic_plan}, ni
 * {@code civic_plan_item}, ni progression Leitner en base. Corollaire : il n'y a
 * <b>pas</b> de route {@code /recompute} — recalculer, c'est relire.
 *
 * <p>🛑 <b>Aucun appel LLM</b> : le civique est du QCM deterministe.
 */
@RestController
@RequestMapping("/api/me/civic-plan")
@RequiredArgsConstructor
public class CivicPlanController {

    private final CivicPlanService service;
    private final CurrentUser currentUser;

    /**
     * Le plan.
     *
     * <p>🛑 <b>Jamais 204.</b> Sans diagnostic termine, la reponse porte
     * {@code disponible: false} — l'ecran a besoin de savoir <b>pourquoi</b> il
     * n'a rien a montrer pour ouvrir la porte qui debloque, et un corps vide ne
     * le dirait pas.
     *
     * <p>🛑 <b>Le constat est integralement gratuit</b> : les priorites sont
     * servies entieres a tout le monde. Seule la serie porte {@code locked}.
     */
    @GetMapping
    public CivicPlanDto plan() {
        return service.plan(currentUser.getId());
    }

    /**
     * Ouvre la <b>serie ciblee</b> d'une cible du plan.
     *
     * <p>C'est un {@code TRAINING} ordinaire : le front l'ouvre dans le runner
     * de questions existant. 🛑 <b>403 sans abonnement</b> — la meme regle que
     * le {@code locked} du plan, cette fois opposable.
     *
     * @param grain rendu tel quel par le plan : on ne devine pas la nature d'un
     *              identifiant
     */
    @PostMapping("/cibles/{cibleId}/serie")
    @ResponseStatus(HttpStatus.CREATED)
    public AttemptResponse serie(@PathVariable UUID cibleId,
                                 @RequestParam CivicPlanGrain grain) {
        return service.demarrerSerie(currentUser.getId(), cibleId, grain);
    }
}

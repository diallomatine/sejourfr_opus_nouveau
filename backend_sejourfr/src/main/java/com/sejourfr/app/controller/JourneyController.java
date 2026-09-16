package com.sejourfr.app.controller;

import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.journey.JourneyService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * <b>Le parcours TCF</b> — la file d'etapes que le Plan suit.
 *
 * <p>🛑 <b>Aucun {@code targetLevel} en parametre.</b> Le serveur connait le
 * niveau vise du candidat ({@code TargetProcedure.niveauVise}) : l'accepter d'un
 * client ouvrirait la porte a un front qui demande un parcours qui n'est pas le
 * sien. Le chemin suit la convention du depot ({@code /api/me/plan},
 * {@code /api/me/progress}).
 *
 * <p>Une <b>seule</b> reponse alimente la carte « À faire maintenant » <b>et</b>
 * la timeline, sur les six sites d'appel des deux fronts : c'est ce qui rend
 * impossible la contradiction corrigee le 2026-09-16, ou l'Accueil annoncait une
 * action et le Plan une autre au meme instant pour le meme candidat.
 */
@RestController
@RequestMapping("/api/me/plan/journey")
@RequiredArgsConstructor
public class JourneyController {

    private final JourneyService journeyService;
    private final CurrentUser currentUser;

    /**
     * @param expand {@code "all"} pour recevoir <b>toutes</b> les etapes non
     *               obsoletes au lieu du sous-ensemble d'affichage (§14). Sert
     *               l'ecran « Voir les etapes suivantes » ; tout autre valeur est
     *               ignoree, jamais une erreur.
     */
    @GetMapping
    public JourneyDto get(@RequestParam(required = false) String expand) {
        return journeyService.lire(currentUser.getId(), "all".equalsIgnoreCase(expand));
    }
}

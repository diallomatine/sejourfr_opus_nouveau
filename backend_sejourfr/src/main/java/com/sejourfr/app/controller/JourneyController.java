package com.sejourfr.app.controller;

import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.dto.JourneyHistoryDto;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.journey.JourneyCycleService;
import com.sejourfr.app.service.journey.JourneyHistoryService;
import com.sejourfr.app.service.journey.JourneyService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
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
    private final JourneyCycleService cycleService;
    private final JourneyHistoryService historyService;
    private final CurrentUser currentUser;

    /**
     * <p>🛑 <b>Aucun parametre.</b> L'ancien {@code ?expand=all} a disparu avec
     * {@code JourneyDto.steps} (P6, 2026-09-18) : il ne servait qu'a contourner
     * le fenetrage d'affichage de §14, et {@code blocs} porte <b>toujours</b>
     * toutes les etapes non obsoletes. Un client ancien qui l'envoie encore est
     * servi normalement — un parametre inconnu n'a jamais ete une erreur ici.
     */
    @GetMapping
    public JourneyDto get() {
        // ⚠️ MODULE EN DUR, et c'est le SEUL endroit qui reste. Le toggle
        // TCF / Examen civique vit deja dans l'URL cote front ; l'endpoint
        // gagnera son `?module=` avec les ecrans (D-50, P8.7). Une ligne a
        // changer, ici, quand ce jour vient.
        return journeyService.lire(currentUser.getId(), Module.TCF);
    }

    /**
     * <b>L'historique des cycles</b> — l'ecran « Ma progression ».
     *
     * <p>Les cycles <b>historises</b> du module TCF, du plus recent au plus
     * ancien, avec les competences travaillees groupees par epreuve, et les
     * niveaux mesures en entree et en sortie <b>lus tels quels</b> sur la
     * ligne (D-12, A35) — aucun recalcul retroactif.
     *
     * <p>🛑 <b>Aucun parametre, et c'est volontaire</b> (B-10) : le serveur sait
     * qui lit. Accepter un identifiant de candidat laisserait lire l'historique
     * d'un autre.
     */
    @GetMapping("/history")
    public JourneyHistoryDto history() {
        return historyService.lire(currentUser.getId());
    }

    /**
     * <b>Actualiser mon plan</b> — le cycle en attente devient le cycle courant
     * (spec §6).
     *
     * <p>🛑 <b>Aucun parametre, et c'est volontaire</b> (B-10) : le serveur sait
     * quel est le cycle en cours du candidat. Accepter un identifiant de cycle
     * laisserait un client historiser celui d'un autre.
     *
     * <p>Refuse en <b>409</b> si le cycle n'est pas termine : ce geste
     * historise, et il ne doit jamais jeter un plan en cours.
     */
    @PostMapping("/refresh")
    public JourneyDto refresh() {
        return cycleService.actualiser(currentUser.getId(), Module.TCF);
    }

    /**
     * <b>Passer l'examen blanc complet</b> — cree le <b>cycle de mesure</b>
     * (spec §6).
     *
     * <p>🛑 <b>Il ne demarre aucun examen</b> : l'examen blanc complet reste
     * lance par {@code POST /api/full-tcf-exams}, son unique point d'entree.
     *
     * <p>Refuse en <b>409</b> si le cycle n'est pas termine, <b>et</b> si le
     * cycle courant est deja un cycle de mesure — enchainer deux examens
     * complets sans travail entre eux ne mesure rien de nouveau.
     */
    @PostMapping("/measurement-cycle")
    public JourneyDto measurementCycle() {
        return cycleService.creerCycleDeMesure(currentUser.getId(), Module.TCF);
    }
}

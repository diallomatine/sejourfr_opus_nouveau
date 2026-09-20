package com.sejourfr.app.controller;

import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.dto.JourneyHistoryDto;
import com.sejourfr.app.dto.JourneyStepDetailDto;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.journey.JourneyCycleService;
import com.sejourfr.app.service.journey.JourneyHistoryService;
import com.sejourfr.app.service.journey.JourneyService;
import com.sejourfr.app.service.journey.JourneyStepDetailService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PathVariable;
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
    private final JourneyCycleService cycleService;
    private final JourneyHistoryService historyService;
    private final JourneyStepDetailService stepDetailService;
    private final CurrentUser currentUser;

    /**
     * <p>🛑 <b>{@code ?module=} depuis P8.7</b> : le cycle existe pour les DEUX
     * modules, et le toggle « TCF IRN / Examen civique » vit deja dans l'URL
     * cote front — <b>une seule autorite de selection</b> (spec §4). Absent, il
     * vaut {@code TCF} : un client anterieur continue de marcher.
     *
     * <p>🛑 <b>Aucun autre parametre.</b> L'ancien {@code ?expand=all} a disparu avec
     * {@code JourneyDto.steps} (P6, 2026-09-18) : il ne servait qu'a contourner
     * le fenetrage d'affichage de §14, et {@code blocs} porte <b>toujours</b>
     * toutes les etapes non obsoletes. Un client ancien qui l'envoie encore est
     * servi normalement — un parametre inconnu n'a jamais ete une erreur ici.
     */
    @GetMapping
    public JourneyDto get(@RequestParam(required = false) Module module) {
        return journeyService.lire(currentUser.getId(), module == null ? Module.TCF : module);
    }

    /**
     * <b>L'historique des cycles</b> — l'ecran « Ma progression ».
     *
     * <p>Les cycles <b>historises</b> du module demande, du plus recent au plus
     * ancien, avec les etapes travaillees groupees par <b>bloc servi</b> — une
     * epreuve en TCF, une thematique en civique (D-47) —, et les niveaux mesures
     * en entree et en sortie <b>lus tels quels</b> sur la ligne (D-12, A35) :
     * aucun recalcul retroactif.
     *
     * <p>🛑 <b>Le MODULE est le seul parametre</b> (B-10) : le serveur sait qui
     * lit, et accepter un identifiant de candidat laisserait lire l'historique
     * d'un autre. Le defaut reste TCF — un client anterieur a P8.9 garde
     * exactement le comportement d'avant.
     *
     * <p>⚠️ <b>Cote serveur SEULEMENT</b> (P8.9) : l'ecran d'historique civique
     * n'est pas concu, le proprietaire n'en a pas fourni le gabarit. Ce qui est
     * livre ici, c'est le <b>fait servi</b>, pas sa mise en page.
     */
    @GetMapping("/history")
    public JourneyHistoryDto history(@RequestParam(required = false) Module module) {
        return historyService.lire(currentUser.getId(), module == null ? Module.TCF : module);
    }

    /**
     * <b>L'ecran d'ETAPE</b> — les series a reussir pour valider une competence
     * de comprehension (CO/CE) ou une unite officielle civique.
     *
     * <p>🛑 <b>Aucun {@code ?module=}</b>, et c'est le point : l'etape porte son
     * module. Le demander au client aurait ouvert la porte a une demande qui
     * contredit l'etape, et duplique cote fronts une question que le serveur
     * seul sait trancher.
     *
     * <p><b>404</b> si l'etape n'existe pas <b>ou</b> n'appartient pas au
     * candidat — repondre 403 confirmerait l'existence du cycle d'un tiers.
     * <b>422</b> si l'etape ne se travaille pas par series (expression, examen).
     */
    @GetMapping("/steps/{stepId}")
    public JourneyStepDetailDto step(@PathVariable java.util.UUID stepId) {
        return stepDetailService.lire(currentUser.getId(), stepId);
    }

    /**
     * <b>Lancer (ou refaire) une serie</b> de cette etape.
     *
     * <p>Rend le <b>meme</b> {@code AttemptResponse} que tous les autres
     * lancements : les fronts atterrissent sur {@code /sessions/{attemptId}}
     * sans rien apprendre de neuf. 🛑 {@code AttemptResponse.mode} vaut
     * {@code EXAMEN} — aucune correction pendant la passation, audio de CO joue
     * une seule fois.
     *
     * <p><b>403</b> si l'etape est verrouillee (freemium) ou si la serie l'est
     * (la precedente n'est pas <b>reussie</b>) ; <b>422</b> si l'index sort du
     * quota ou si la banque ne peut rien servir.
     */
    @PostMapping("/steps/{stepId}/series/{index}")
    public AttemptResponse demarrerSerie(
            @PathVariable java.util.UUID stepId, @PathVariable int index) {
        return stepDetailService.demarrer(currentUser.getId(), stepId, index);
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
    public JourneyDto refresh(@RequestParam(required = false) Module module) {
        return cycleService.actualiser(
                currentUser.getId(), module == null ? Module.TCF : module);
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
    public JourneyDto measurementCycle(@RequestParam(required = false) Module module) {
        return cycleService.creerCycleDeMesure(
                currentUser.getId(), module == null ? Module.TCF : module);
    }
}

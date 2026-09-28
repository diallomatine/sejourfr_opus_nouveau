package com.sejourfr.app.service.journey;

import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.enums.JourneyFinDeCycle;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.manager.JourneyManager;
import com.sejourfr.app.service.TcfProfileService;
import com.sejourfr.app.service.attempt.AttemptScoringService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;

/**
 * <b>Historiser un cycle</b> — l'unique facon de clore un cycle EN COURS, pour
 * les trois gestes qui le font : l'actualisation (D-66), le jalon d'examen
 * complet (D-68) et la remise a zero du lancement (D-69 ter).
 *
 * <p>Extrait de {@code JourneyCycleService} le 2026-09-28 : le lancement en
 * aurait fait une seconde copie. Le niveau (TCF) ou le score (civique) de
 * sortie est <b>lu</b> chez son autorite et ecrit une fois, jamais recalcule
 * (D-12) ; {@code null} = inconnu, jamais mauvais.
 */
@Component
@RequiredArgsConstructor
class JourneyHistorisation {

    private final JourneyManager journeyManager;
    private final TcfProfileService profileService;

    /** Historise ce cycle avec son geste et rend sa sortie (niveau TCF, ou {@code null}). */
    TargetLevel historiserTcf(Journey enCours, JourneyFinDeCycle geste) {
        TargetLevel sortie = AttemptScoringService.toTargetLevel(
                profileService.levelProfile(enCours.getUser().getId()).globalLevel());
        enCours.setExitLevel(sortie);
        clore(enCours, geste);
        return sortie;
    }

    /**
     * Le score de sortie d'un cycle civique : celui du <b>dernier examen
     * complet</b> passe pendant ce cycle, recopie tel quel ; {@code null} si
     * aucun (un examen de theme ne compte pas : 20 questions, pas 40).
     */
    Short historiserCivique(Journey enCours, JourneyFinDeCycle geste) {
        Short sortie = journeyManager.dernierScoreDExamenComplet(enCours.getId());
        enCours.setExitScore(sortie);
        clore(enCours, geste);
        return sortie;
    }

    /** Selon le module du cycle. */
    void historiser(Journey enCours, JourneyFinDeCycle geste) {
        if (enCours.getModule() == Module.CIVIQUE) {
            historiserCivique(enCours, geste);
        } else {
            historiserTcf(enCours, geste);
        }
    }

    private void clore(Journey enCours, JourneyFinDeCycle geste) {
        enCours.setStatus(JourneyStatus.HISTORISE);
        enCours.setHistoriseAt(Instant.now());
        // 🛑 LE GESTE EST ECRIT ICI, UNE FOIS (V077) : un evenement, que
        // « Mes cycles » raconte tel quel.
        enCours.setFinDeCycle(geste);
        journeyManager.saveEtFlush(enCours);
    }
}

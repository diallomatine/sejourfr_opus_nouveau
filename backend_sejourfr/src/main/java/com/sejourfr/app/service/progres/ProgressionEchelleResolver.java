package com.sejourfr.app.service.progres;

import com.sejourfr.app.dto.ProgressionEchelleDto;
import com.sejourfr.app.enums.BandeNoteTcf;
import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.ProgressionUnite;
import com.sejourfr.app.service.TcfLevelEstimatorService;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticThemeResolver;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * <b>L'axe d'une courbe de progression</b>, servi pour qu'aucun front n'écrive
 * une bande ni un seuil.
 *
 * <p>🛑 <b>Aucune table n'est écrite ici</b> : chaque échelle est lue chez son
 * autorité.
 * <ul>
 *   <li>CO / CE : score de progression 100-499 (bornes de
 *       {@code TcfLevelEstimatorService.calibratedScore}) <b>sans aucune
 *       bande</b> — aucun palier ne dérive de ce nombre depuis le 2026-09-20
 *       (arbitrage D2) ;</li>
 *   <li>EE / EO : note /20, bandes officielles {@link BandeNoteTcf} (D3) ;</li>
 *   <li>civique : bandes d'état obtenues en <b>demandant</b> l'état de chaque
 *       score possible à {@link CivicDiagnosticThemeResolver#etat} — les seuils
 *       0,55 / 0,80 ne sont pas recopiés, et la borne « Solide » tombe d'elle-même
 *       sur le seuil de réussite (16/20, 32/40).</li>
 * </ul>
 */
@Component
@RequiredArgsConstructor
public class ProgressionEchelleResolver {

    /** Note d'épreuve du TCF : la borne haute de la grille officielle (20). */
    public static final int NOTE_MAX = BandeNoteTcf.B2.getScoreMax();

    private final CivicDiagnosticThemeResolver civicThemeResolver;

    /** L'axe d'une épreuve TCF (CO, CE, EE ou EO). */
    public ProgressionEchelleDto tcf(EpreuveType epreuve) {
        if (epreuve == EpreuveType.TCF_EE || epreuve == EpreuveType.TCF_EO) {
            List<ProgressionEchelleDto.Bande> bandes = new ArrayList<>();
            for (BandeNoteTcf b : BandeNoteTcf.values()) {
                bandes.add(new ProgressionEchelleDto.Bande(
                        b.getNiveau(), null, b.getScoreMin(), b.getScoreMax()));
            }
            return new ProgressionEchelleDto(
                    ProgressionUnite.NOTE_20, 0, NOTE_MAX, null, List.copyOf(bandes),
                    List.of(0, 5, 10, 15, 20));
        }
        return new ProgressionEchelleDto(
                ProgressionUnite.PROGRESSION_499,
                TcfLevelEstimatorService.SCORE_PROGRESSION_MIN,
                TcfLevelEstimatorService.SCORE_PROGRESSION_MAX, null, List.of(),
                List.of(TcfLevelEstimatorService.SCORE_PROGRESSION_MIN, 200, 300, 400,
                        TcfLevelEstimatorService.SCORE_PROGRESSION_MAX));
    }

    /**
     * L'axe d'un examen civique de {@code total} questions et de seuil
     * {@code seuil} (20/16 pour un thème, 40/32 pour un global).
     */
    public ProgressionEchelleDto civique(int total, int seuil) {
        List<ProgressionEchelleDto.Bande> bandes = new ArrayList<>();
        CivicThemeState courant = null;
        int debut = 0;
        for (int score = 0; score <= total; score++) {
            CivicThemeState etat = civicThemeResolver.etat(score, total);
            if (etat != courant) {
                if (courant != null) {
                    bandes.add(new ProgressionEchelleDto.Bande(null, courant, debut, score - 1));
                }
                courant = etat;
                debut = score;
            }
        }
        if (courant != null) bandes.add(new ProgressionEchelleDto.Bande(null, courant, debut, total));
        int quart = total / 4;
        return new ProgressionEchelleDto(
                ProgressionUnite.QUESTIONS, 0, total, seuil, List.copyOf(bandes),
                List.of(0, quart, 2 * quart, 3 * quart, total));
    }
}

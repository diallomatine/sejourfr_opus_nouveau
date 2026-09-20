package com.sejourfr.app.dto;

import com.sejourfr.app.enums.Difficulty;

/**
 * Une <b>strate</b> d'un QCM TCF : les items d'un même palier CECRL
 * ({@code A2} / {@code B1} / {@code B2}) posés dans une épreuve, combien ont
 * reçu une réponse, et combien ont été réussis.
 *
 * <p>C'est l'unité du calcul de niveau QCM depuis le 2026-09-20 : le niveau ne
 * se lit plus sur un score global mais <b>strate par strate</b>
 * ({@code TcfLevelEstimatorService.niveauParStrates}).
 *
 * <h2>🛑 Pourquoi {@code repondus} existe, alors qu'aucune règle ne s'en sert</h2>
 * <p>Parce que deux situations très différentes donnent aujourd'hui le même
 * verdict et qu'il ne faut pas qu'elles restent indiscernables :
 * <ul>
 *   <li><b>0 bonne réponse</b> — le candidat a répondu, tout est faux ;</li>
 *   <li><b>0 réponse donnée</b> — la session a été ouverte puis abandonnée.</li>
 * </ul>
 * Les deux valent {@code A1_NON_ATTEINT}, ce qui reste le comportement d'avant
 * et n'est <b>pas</b> arbitré : la distinction est portée par la donnée pour
 * qu'un futur arbitrage n'ait pas à la reconstruire. Un item posé et non
 * répondu compte comme <b>posé et non réussi</b> — dans une épreuve
 * chronométrée qu'on termine d'une traite, ne pas répondre est une réponse.
 *
 * <p>🛑 Les autres valeurs de {@link Difficulty} (CSP/CR/NAT, côté civique) ne
 * sont pas des paliers CECRL : elles n'entrent dans aucune strate.
 */
public record StrateQcm(Difficulty palier, int poses, int repondus, int reussis) {

    /**
     * Strate entièrement répondue — la forme courante en test et sur une
     * épreuve menée à son terme.
     */
    public static StrateQcm mesuree(Difficulty palier, int poses, int reussis) {
        return new StrateQcm(palier, poses, poses, reussis);
    }
}

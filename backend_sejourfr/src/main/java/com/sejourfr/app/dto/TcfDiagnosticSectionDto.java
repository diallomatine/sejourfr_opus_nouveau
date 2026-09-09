package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.TcfDiagnosticSectionState;

import java.util.UUID;

/**
 * Une section du diagnostic TCF, telle que l'ecran d'accueil l'affiche
 * (30_ §5.1).
 *
 * <p>🛑 <b>Aucun score, aucun niveau.</b> 10_ §4.2 l'interdit : « Aucun
 * resultat detaille n'est affiche avant la fin — le resultat est le moment de
 * conversion, il ne doit pas etre dilue. » Le niveau n'apparait que sur l'ecran
 * de resultat, servi par {@link TcfDiagnosticResultDto}.
 */
public record TcfDiagnosticSectionDto(
        EpreuveType epreuve,
        /** {@code null} si la section n'existe pas (mode degrade : pas de contenu). */
        UUID attemptId,
        TcfDiagnosticSectionState etat,
        /** Chrono de la section. {@code null} en EO, qui se chronometre par tache. */
        Integer timeLimitSeconds,
        Integer totalQuestions
) {
}

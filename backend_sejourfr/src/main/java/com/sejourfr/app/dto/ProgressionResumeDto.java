package com.sejourfr.app.dto;

import com.sejourfr.app.enums.NiveauEvolution;

import java.math.BigDecimal;
import java.util.List;

/**
 * Ce que disent ensemble les examens d'une épreuve ou d'un thème — la carte de
 * tête, les encarts et la sparkline. Calculé par {@code ResumeExamensResolver},
 * jamais par un front.
 *
 * @param nombre   examens listés (qualifiants : au moins une réponse ou une
 *                 soumission évaluée)
 * @param dernier  le plus récent, {@code null} sans examen
 * @param meilleur le plus haut score ; à égalité, le plus récent
 * @param premier  le plus ancien portant un score
 * @param ecart    {@code dernier.score − premier.score} ; 🛑 {@code null} avec
 *                 un seul examen (jamais « +0 »)
 * @param sens     signe de l'écart ; {@code INCONNUE} sans écart. {@code BAISSE}
 *                 se sert
 * @param serie    les derniers scores (au plus 7), du plus ancien au plus
 *                 récent — la sparkline
 */
public record ProgressionResumeDto(
        int nombre,
        ProgressionMesureDto dernier,
        ProgressionMesureDto meilleur,
        ProgressionMesureDto premier,
        BigDecimal ecart,
        NiveauEvolution sens,
        List<BigDecimal> serie) {
}

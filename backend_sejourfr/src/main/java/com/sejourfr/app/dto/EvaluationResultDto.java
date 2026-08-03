package com.sejourfr.app.dto;

import com.sejourfr.app.enums.ConfianceEvaluation;
import com.sejourfr.app.enums.NiveauCecrl;

import java.math.BigDecimal;
import java.util.Map;

/**
 * Vue front d'une {@link com.sejourfr.app.entity.AiEvaluation}. Le bloc
 * {@code feedback} est passe depuis le JSONB persiste, expurge des champs de
 * niveau bruts ({@code niveau_cecrl}, {@code justification_niveau}) : le niveau
 * n'a qu'une seule porte de sortie, {@link #niveauObserve}.
 *
 * <p><b>Niveau PAR TACHE, formulation prudente.</b> Le niveau par soumission
 * etait deja calcule et persiste, mais non expose. Il l'est desormais sous la
 * forme « performance observee », a afficher avec {@link #confiance} et
 * {@link #avertissementNiveau} :
 *
 * <pre>
 * Performance observee sur cette tache : proche du niveau B1
 * Estimation pedagogique, confiance moyenne. Le niveau final depend des trois taches.
 * </pre>
 *
 * <p><b>Garde-fou non negociable</b> : {@code niveauObserve} n'est jamais
 * renseigne sans {@code confiance}. Les evaluations anterieures au schema v2
 * (pas de confiance persistee) laissent donc les trois champs a {@code null} —
 * comportement identique a l'existant, aucun front ne casse.
 *
 * <p>Le <b>bilan d'epreuve</b> ({@code ProductionBilanResponse},
 * {@code FullTcfExamResponse.SubAttempt.cecrlLevel}) reste le SEUL niveau qui
 * fait foi.
 *
 * <p>Structure utile de {@code feedback} (schema de sortie v2) :
 * {@code note_globale}, {@code confiance}, {@code confiance_raisons},
 * {@code accomplissement} ({@code points_traites[]} / {@code points_oublies[]},
 * chacun {@code {libelle, obligatoire}}), {@code scores_criteres[]}
 * ({@code code}, {@code label}, {@code note_sur_20}, {@code bande},
 * {@code commentaire}, {@code preuve}), {@code points_forts[]},
 * {@code points_a_ameliorer[]} (2 max), {@code suggestions[]},
 * {@code exemples_corriges[]}, {@code avertissements[]}. Tous ces champs sont
 * facultatifs cote front : une evaluation v3 en base n'en porte qu'une partie.
 */
public record EvaluationResultDto(
        BigDecimal noteSurVingt,
        /** Niveau observe SUR CETTE TACHE. Null si la confiance est inconnue (eval pre-v2). */
        NiveauCecrl niveauObserve,
        /** Certitude de l'evaluation. Null pour une eval anterieure au schema v2. */
        ConfianceEvaluation confiance,
        /** Rappel a afficher sous le niveau observe. Null quand il n'y a pas de niveau. */
        String avertissementNiveau,
        Map<String, Object> feedback
) {
}

package com.sejourfr.app.dto;

import com.sejourfr.app.enums.ConfianceEvaluation;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SituationDansNiveau;

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
 *
 * <p><b>Ajouts du schema v5</b> (rubriques v8), tout aussi facultatifs — les
 * evaluations anterieures ne les portent pas et rien n'a ete migre :
 * <ul>
 *   <li>{@code accomplissement.objectif} : {@code ATTEINT} |
 *       {@code PARTIELLEMENT_ATTEINT} | {@code NON_ATTEINT} (cf.
 *       {@link com.sejourfr.app.enums.ObjectifTache}) — verdict de la tache, a
 *       afficher EN TETE d'ecran ;</li>
 *   <li>{@code accomplissement.objectif_resume} : une phrase adressee au
 *       candidat, qui dit ce qu'il a fait ;</li>
 *   <li>{@code version_amelioree} : chaine a la RACINE du feedback, sa
 *       production reecrite au palier au-dessus. Presente sur les taches
 *       ECRITES uniquement, absente en EO (retiree cote serveur).</li>
 * </ul>
 * {@code points_forts[]} est plafonne a 2 et {@code exemples_corriges[]} a 3.
 *
 * <p><b>Bloc {@code version_ciblee}</b> (facultatif, EE uniquement, produit par
 * un SECOND appel LLM totalement separe de la correction) :
 * {@code {niveau_vise, niveau_constate, texte, ce_qui_manque[]}} — la meme
 * reponse redigee au niveau que le candidat VISE, et 2 a 3 choses concretes qui
 * l'en separent. Absent quand le second appel a echoue, ou sur toute evaluation
 * anterieure a cette fonctionnalite.
 *
 * <p>Le niveau vise est {@code max(palier exige par la demarche, TargetLevel
 * declare)} — cf. {@link com.sejourfr.app.enums.TargetProcedure#niveauVise}. La
 * demarche fait PLANCHER : {@code NAT} exige le B2 depuis le 1er janvier 2026,
 * un candidat qui la vise n'a donc jamais « atteint son objectif » a B1.
 *
 * <p><b>Bloc {@code niveau_vise_atteint}</b>, exclusif du precedent :
 * {@code {niveau_vise, niveau_constate}}, pose par le serveur quand la
 * production atteint deja le palier vise. Il n'y a alors pas de marche au-dessus
 * a montrer, et les fronts l'ANNONCENT (victoire) au lieu de laisser la section
 * disparaitre en silence — un front ne saurait pas distinguer cet etat d'un
 * second appel LLM en echec. Absent en EO et sur les evaluations anterieures.
 *
 * <p><b>La note /20 n'est plus affichee sur une tache isolee</b> — decision
 * produit : au TCF, un correcteur attribue un NIVEAU par tache, la note ne porte
 * que sur l'epreuve entiere. {@link #noteSurVingt} reste calculee, persistee et
 * exposee (bilan d'epreuve, admin, calibration) ; c'est
 * {@link #situationDansNiveau} qui porte, sur l'ecran d'une tache, le signal de
 * progression a l'interieur du palier.
 */
public record EvaluationResultDto(
        BigDecimal noteSurVingt,
        /** Niveau observe SUR CETTE TACHE. Null si la confiance est inconnue (eval pre-v2). */
        NiveauCecrl niveauObserve,
        /** Certitude de l'evaluation. Null pour une eval anterieure au schema v2. */
        ConfianceEvaluation confiance,
        /** Rappel a afficher sous le niveau observe. Null quand il n'y a pas de niveau. */
        String avertissementNiveau,
        /**
         * Position de la production DANS sa propre bande CECRL (3 crans),
         * derivee serveur. Null quand il n'y a ni note ni niveau situable.
         */
        SituationDansNiveau situationDansNiveau,
        /** Libelle pret a afficher (« A2 solide »). Null en meme temps que le cran. */
        String situationDansNiveauLabel,
        Map<String, Object> feedback
) {
}

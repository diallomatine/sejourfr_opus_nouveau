package com.sejourfr.app.dto;

import com.sejourfr.app.enums.ConfianceEvaluation;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ProductionEvaluabilite;
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
 * {@code points_a_ameliorer[]} (2 max), {@code avertissements[]}. Tous ces champs
 * sont facultatifs cote front : une evaluation v3 en base n'en porte qu'une partie.
 *
 * <p><b>Champs RETIRES par le contrat v9</b> (rubriques v15) : {@code suggestions[]}
 * et {@code exemples_corriges[]}. Ils n'etaient affiches que dans le bloc replie
 * « Voir l'analyse complete », supprime de l'ecran de resultat. Le correcteur ne
 * les produit plus et le serveur les retire d'une sortie qui les porterait quand
 * meme. <b>Les evaluations anterieures les conservent</b> : rien n'est migre, la
 * console de calibration les affiche encore, et un front doit continuer de les
 * lire sans supposer leur presence.
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
 * {@code points_forts[]} est plafonne a 2 (et {@code exemples_corriges[]} l'etait
 * a 3, tant que le contrat le portait).
 *
 * <p><b>Bloc {@code version_ciblee}</b> (facultatif, EE <b>et</b> EO, produit par
 * un SECOND appel LLM totalement separe de la correction) : le PLAN D'ACTION du
 * candidat vers le niveau qu'il VISE. Absent quand le second appel a echoue, sur
 * toute evaluation anterieure a cette fonctionnalite, et — a l'oral — quand la
 * transcription est trop abimee pour qu'on puisse reformuler quoi que ce soit.
 *
 * <p>Trois formes, une seule cle. Un front distingue l'ecrit de l'oral a la
 * presence de {@code exemple_cible} ou de {@code reformulations} :
 * <ul>
 *   <li><b>contrat v2, ECRIT</b> : {@code {niveau_vise, niveau_constate,
 *       leviers[2..3] {action, exemple}, exemple_cible {texte, segments[2..3]
 *       {extrait, apport}}, a_retenir {formule, explication}}}. Chaque
 *       {@code extrait} est garanti <b>sous-chaine exacte</b> de
 *       {@code exemple_cible.texte} : le front peut le surligner sans le
 *       chercher approximativement ;</li>
 *   <li><b>contrat v2, ORAL</b> : idem, mais {@code exemple_cible} est remplace
 *       par {@code reformulations[2..3] {original, reformule, apport}}. La
 *       production orale <b>n'est jamais reecrite en entier</b> — ce que lit le
 *       modele est une transcription automatique. {@code original} est le texte
 *       EXACT du passage du candidat, resolu par le serveur depuis un numero de
 *       segment : aucun entier ne traverse ce contrat ;</li>
 *   <li><b>contrat v1</b> (retour arriere) : {@code {niveau_vise,
 *       niveau_constate, texte, ce_qui_manque[]}}, EE uniquement.</li>
 * </ul>
 * Les evaluations deja persistees gardent la forme qu'elles avaient : un front
 * doit traiter les trois, et l'absence du bloc.
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
 * second appel LLM en echec. Absent sur les evaluations anterieures ; present a
 * l'oral aussi depuis le contrat v2.
 *
 * <p><b>Une production INEXPLOITABLE ne porte aucun verdict</b> (2026-08-21) :
 * vide, quasi vide, langue non francaise ou recopiage de la consigne, elle
 * n'appelle aucun correcteur et sort avec {@link #evaluabilite} a
 * {@code NON_EVALUABLE}, {@link #noteSurVingt} et {@link #niveauObserve} a
 * {@code null}. Elle portait auparavant 0/20 et {@code A1_NON_ATTEINT} — une
 * absence de preuve enregistree comme la preuve du niveau le plus faible, que
 * {@code TcfProfileService} lisait ensuite comme le niveau EE/EO du candidat.
 *
 * <p><b>La note /20 n'est plus affichee sur une tache isolee</b> — decision
 * produit : au TCF, un correcteur attribue un NIVEAU par tache, la note ne porte
 * que sur l'epreuve entiere. {@link #noteSurVingt} reste calculee, persistee et
 * exposee (bilan d'epreuve, admin, calibration) ; c'est
 * {@link #situationDansNiveau} qui porte, sur l'ecran d'une tache, le signal de
 * progression a l'interieur du palier.
 */
public record EvaluationResultDto(
        /**
         * La production a-t-elle pu etre OBSERVEE ? Jamais {@code null} —
         * {@code EVALUABLE} sur toutes les evaluations anterieures a V041.
         *
         * <p>⚠️ <b>Trois etats, pas deux.</b> {@code evaluation} entierement
         * absente (cote {@code ProductionSubmissionDto}) = « pas encore
         * evaluee ». Presente avec {@code NON_EVALUABLE} = « rendue, mais il
         * n'y avait rien a observer » : {@link #noteSurVingt},
         * {@link #niveauObserve} et {@link #situationDansNiveau} valent alors
         * {@code null}, et {@code feedback.avertissements} dit pourquoi. Les
         * deux ne se disent pas pareil au candidat, mais la phrase appartient
         * aux fronts : le serveur n'expose ici qu'un fait.
         */
        ProductionEvaluabilite evaluabilite,
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

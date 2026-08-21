package com.sejourfr.app.dto;

import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanActionNature;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Une priorité du Plan, c'est-à-dire une <b>étape</b>.
 *
 * <p><b>Deux jeux de compteurs, à ne jamais confondre.</b>
 * <ul>
 *   <li>{@code promptCount} / {@code attemptedCount} / {@code validatedCount}
 *       décrivent la <b>compétence entière</b> et ont exactement la sémantique
 *       de {@link SkillDto} — sujets ACTIFS de la compétence, sujets déjà tentés
 *       par ce candidat, sujets validés. Ils sortent du même calcul serveur : un
 *       front ne doit jamais voir « 2 sur 15 » ici et « 3 sur 15 » dans le
 *       module Compétences.</li>
 *   <li>{@code stepPromptCount} / {@code stepAttemptedCount} /
 *       {@code stepValidatedCount} / {@code stepCompleted} décrivent l'<b>étape</b>
 *       : les {@code LearningPlanStep.PROMPTS_PAR_ETAPE} premiers sujets actifs
 *       de la compétence, et rien d'autre. <b>C'est ce couple que les fronts
 *       affichent sur l'anneau de progression d'une étape</b> — « 2/5 », pas
 *       « 2/15 ».</li>
 * </ul>
 * Les deux sont dérivés serveur, jamais persistés, jamais recalculés par un
 * front.
 */
public record LearningPlanPriorityDto(
        UUID skillId,
        String skillCode,
        String title,
        SkillSection section,
        /**
         * <b>Ce que le Plan demande de faire</b> sur cette etape :
         * {@code A_RENFORCER} (fragilite observee), {@code A_VERIFIER} (etape
         * terminee, verification en situation) ou {@code A_ACQUERIR}
         * (competence du palier en construction, <b>jamais travaillee</b>).
         *
         * <p>🛑 Une entree {@code A_ACQUERIR} n'a rien d'observe : son
         * {@link #status()}, son {@link #explanation()}, son {@link #evidence()},
         * sa {@link #confidence()} et son {@link #observedAt()} valent
         * {@code null}, et son {@link #masteryState()} aussi. Ce n'est pas un
         * trou de donnees, c'est le fait meme : rien n'a ete constate, donc rien
         * n'a echoue. Les fronts lisent cette nature, jamais la nullite d'un
         * champ.
         */
        PlanActionNature nature,
        LearningPlanSkillStatus status,
        String explanation,
        String evidence,
        ObservationConfidence confidence,
        Instant observedAt,
        PlanRecommendedExerciseDto recommendedExercise,
        int promptCount,
        int attemptedCount,
        int validatedCount,
        /** Sujets de l'étape : au plus les 5 premiers sujets actifs, moins si la compétence en publie moins. */
        int stepPromptCount,
        /** Sujets de l'étape déjà traités (tout sauf « À faire »). */
        int stepAttemptedCount,
        /** Sujets de l'étape dont le critère a été validé. Toujours ≤ {@link #stepAttemptedCount()}. */
        int stepValidatedCount,
        /**
         * {@code true} quand les sujets de l'étape ont <b>tous</b> été traités.
         * Terminée ≠ tout validé : on peut finir une étape sans valider chaque
         * critère, d'où {@link #stepValidatedCount()} à côté.
         *
         * <p>Une étape terminée <b>reste affichée</b> : les priorités ne changent
         * qu'à l'arrivée d'une nouvelle observation, donc à la prochaine
         * production. Aux fronts de le dire, pas de la faire disparaître.
         */
        boolean stepCompleted,
        /**
         * <b>Le périmètre de l'étape</b> : les identifiants des sujets qui la
         * composent, dans l'ordre de l'étape (rang d'affichage croissant).
         * Toujours présent, jamais {@code null}, et {@code stepPromptIds.size()
         * == stepPromptCount} par construction.
         *
         * <p>Il est servi parce qu'un front qui ouvre la compétence <b>depuis le
         * Plan</b> doit rester dans l'étape — les mêmes 5 sujets, « 2/5 » — au
         * lieu de retomber sur la fiche générique et son « 1/15 ». La règle
         * « les {@code LearningPlanStep.PROMPTS_PAR_ETAPE} premiers sujets
         * actifs » vit côté serveur ({@code LearningPlanStep.scope}) et
         * <b>ne se réimplémente nulle part</b> : deux copies finiraient par
         * désigner deux étapes différentes.
         *
         * <p>Liste <b>vide</b> quand la compétence n'a aucun sujet actif — cas
         * normal, pas une erreur ; plus courte que 5 quand elle en publie moins.
         * Le périmètre vaut ce qui existe, aucun identifiant n'est inventé.
         */
        List<UUID> stepPromptIds,
        /**
         * Etat de maitrise agrege de la competence, issu du meme moteur que
         * {@code SkillDto.masteryState}. Derive serveur, jamais persiste,
         * {@code null} sans observation. A ne pas confondre avec
         * {@link #status()}, verdict de la <b>derniere production</b>.
         */
        SkillMasteryState masteryState,
        /**
         * {@code true} quand le candidat a assez travaille cette competence en
         * exercices cibles, sur des sujets differents, <b>sans preuve de
         * transfert recente</b> : le Plan doit alors cesser d'empiler les
         * micro-sujets et proposer une verification en situation.
         *
         * <p>Signal interne exposé aux fronts pour qu'ils changent le libelle de
         * l'etape (« Verifions maintenant… » plutot que « encore 3 exercices ») ;
         * ce n'est pas un etat de maitrise et il ne s'affiche jamais comme tel.
         * L'exercice recommande, lui, ne change pas encore — c'est la suite du
         * chantier.
         */
        boolean readyForReassessment,
        /**
         * {@code true} quand ce candidat ne peut pas produire sur la compétence
         * de cette priorité. Le Plan reste <b>intégralement visible</b> : on
         * pose un cadenas, on ne masque jamais une priorité — masquer priverait
         * le candidat du résultat de sa propre production.
         */
        boolean locked
) {}

package com.sejourfr.app.dto;

import com.sejourfr.app.enums.PlanActionNature;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;

import java.time.Instant;
import java.util.UUID;

/**
 * Un <b>entrainement</b> de la seance : l'action a faire, et les faits qui
 * expliquent pourquoi elle est la.
 *
 * <p>🛑 <b>Aucune phrase.</b> Le serveur expose des faits — combien de sujets
 * traites sur combien, si la competence attend une verification, quel palier
 * elle travaille, ou elle en est — et les fronts composent « Pourquoi cette
 * seance ? ». Meme doctrine que {@code PlanChangeDto} et que les jalons de
 * {@code PlanRecommendedExerciseDto}, qui ne portent ni titre ni competence.
 * Un paragraphe ecrit en Java serait a reecrire dans trois langues d'interface
 * et se contredirait avec les cartes qui l'entourent.
 *
 * <p><b>Ce que le front lit pour dire « pourquoi »</b> : {@code exercise.kind()}
 * donne la nature de l'action, {@link #stepAttemptedCount()} /
 * {@link #stepPromptCount()} l'avancement de l'etape (« 3 sujets sur 5 »),
 * {@link #readyForReassessment()} le passage a la verification,
 * {@link #masteryState()} l'etat agrege, et {@link #level()} le palier travaille
 * en comprehension — a rapprocher de {@code PlanDomainDto.blockingLevel()} pour
 * dire « c'est ce palier qui bloque votre comprehension orale ».
 *
 * <p><b>Une seule action par item</b> : soit un {@code exercise}, soit un
 * {@code assessment}, jamais les deux. Un item {@code A_EVALUER} est le seul a
 * porter le second — c'est ce qui permet a la seance de commencer par « votre
 * oral n'a pas pu etre analyse, refaites-en un » au lieu d'empiler des
 * micro-exercices sur le domaine qu'on sait deja mesurer.
 *
 * <p><b>Le bloc competence est vide sur un jalon</b> ({@code skillId},
 * {@code skillCode}, {@code title}, {@code section} a {@code null}) : un examen
 * blanc ne travaille pas une competence, il les verifie toutes. Les fronts
 * lisent {@code exercise.kind()}, jamais la nullite d'un champ.
 *
 * @param nature               <b>ce que le Plan demande de faire</b> ici :
 *                             mesurer ({@code A_EVALUER}), reparer
 *                             ({@code A_RENFORCER}), verifier
 *                             ({@code A_VERIFIER}) ou apprendre
 *                             ({@code A_ACQUERIR}). Jamais {@code null}. C'est
 *                             ce champ que les fronts lisent, jamais la nullite
 *                             d'un autre.
 * @param exercise             l'entrainement a lancer. {@code null} sur le
 *                             <b>seul</b> cas {@code A_EVALUER}, ou l'action
 *                             n'est pas un exercice mais une mesure : les deux
 *                             champs sont <b>mutuellement exclusifs</b>, exactement
 *                             comme les identifiants de
 *                             {@code PlanRecommendedExerciseDto}
 * @param assessment           la mesure a lancer, <b>renseignee sur le seul</b>
 *                             {@code A_EVALUER} : le candidat a rendu une
 *                             production sur ce domaine et le correcteur n'a rien
 *                             pu y observer. On ne lui propose pas un exercice de
 *                             plus, on va le mesurer
 * @param level                palier travaille ({@code "A1"}..{@code "B2"}),
 *                             renseigne en comprehension ; {@code null} en
 *                             expression et sur un jalon. Chaine et non
 *                             {@code TargetLevel} : le referentiel des
 *                             competences descend jusqu'a {@code A1}, meme
 *                             convention que {@code skills.target_level}
 * @param masteryState         etat agrege de la competence, {@code null} sur un
 *                             jalon comme sur une competence jamais observee
 * @param stepPromptCount      sujets de l'etape ; {@code 0} en comprehension,
 *                             qui n'a pas d'etape a cinq sujets
 * @param readyForReassessment le moteur juge la competence prete a etre
 *                             verifiee <b>et</b> l'etape est terminee
 * @param locked               ce candidat ne peut pas lancer cette action. Elle
 *                             reste <b>designee et visible</b> : savoir quoi
 *                             travailler est ce que le Plan apporte
 * @param lastActivityAt       <b>date de la derniere activite sur cette
 *                             competence</b>, {@code null} quand elle n'a jamais
 *                             ete observee et sur un jalon (qui ne travaille
 *                             aucune competence). C'est un <b>fait</b>, pas un
 *                             verdict : le serveur ne dit pas « fait
 *                             aujourd'hui » — il n'a pas d'horloge dans cette
 *                             construction, et un booleen calcule ici serait
 *                             faux des la minute suivante. Les fronts le
 *                             comparent a leur journee courante (Europe/Paris)
 *                             pour cocher la ligne ; la <b>coche vit donc dans
 *                             le compte</b> et survit a un rechargement comme au
 *                             passage d'un appareil a l'autre, ce qu'un marqueur
 *                             local ne faisait pas.
 *
 *                             <p>Lu sur {@code learning_plan_observations
 *                             .observed_at}, <b>toutes observations confondues</b>
 *                             — {@code NOT_OBSERVED} compris : le correcteur
 *                             n'a rien pu observer, mais le candidat a bien
 *                             travaille. A ne pas confondre avec
 *                             {@code LearningPlanPriorityDto.observedAt}, qui
 *                             est la derniere observation <b>probante</b>.
 */
public record PlanSeanceItemDto(
        PlanActionNature nature,
        PlanRecommendedExerciseDto exercise,
        PlanDomainAssessmentDto assessment,
        UUID skillId,
        String skillCode,
        String title,
        SkillSection section,
        String level,
        SkillMasteryState masteryState,
        int stepPromptCount,
        int stepAttemptedCount,
        int stepValidatedCount,
        boolean stepCompleted,
        boolean readyForReassessment,
        boolean locked,
        Instant lastActivityAt
) {}

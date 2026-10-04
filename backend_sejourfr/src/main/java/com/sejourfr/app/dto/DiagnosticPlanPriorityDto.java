package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;

import java.util.UUID;

/**
 * <b>Une priorite du lot du Plan</b>, servie sur le rapport du diagnostic
 * rapide ({@code DiagnosticResultDto.planPriorities}).
 *
 * <p>🛑 <b>Le lot du Plan est l'unique autorite des priorites</b> que montrent
 * le rapport, l'ecran de transition et le Plan, par {@code skillId} : ces
 * lignes sont lues sur les etapes {@code TRAIN_SKILL} dont
 * {@code source_assessment_id} est la session, jamais sur
 * {@code summary_json.priority_skill_codes} — une seconde source a deja
 * designe d'autres competences que le Plan sur 7 sessions sur 7 (audit du
 * 2026-10-04).
 *
 * @param rank             1..n, l'ordre de la file du lot (son
 *                         {@code severity_rank}). Les fronts ne retrient rien.
 * @param explanation      le constat de l'analyse du diagnostic pour cette
 *                         competence (jointure par {@code skillId}),
 *                         {@code null} s'il n'y en a pas — la purge orale peut
 *                         l'avoir retire, ou la competence n'a pas ete observee
 *                         par ce diagnostic.
 * @param generalCriterion le critere general de la competence
 *                         ({@code skills.general_criterion}) — l'explication
 *                         pedagogique generique, jamais nulle.
 * @param inCurrentCycle   {@code true} si l'etape est dans le cycle
 *                         {@code EN_COURS} et n'est pas rendue obsolete
 *                         ({@code SUPERSEDED}) — donc visible dans le Plan.
 *                         {@code false} si le lot attend dans le cycle
 *                         {@code EN_ATTENTE} (diagnostic passe apres un examen
 *                         du cycle d'examens), s'il appartient a un cycle deja
 *                         historise, ou si une evaluation plus recente l'a
 *                         remplace. Les fronts n'affichent « deja integrees a
 *                         votre plan » que sur {@code true}.
 */
public record DiagnosticPlanPriorityDto(
        UUID skillId,
        String skillCode,
        String skillTitle,
        SkillSection section,
        SkillTaskCode taskCode,
        int rank,
        String explanation,
        String generalCriterion,
        boolean inCurrentCycle
) {}

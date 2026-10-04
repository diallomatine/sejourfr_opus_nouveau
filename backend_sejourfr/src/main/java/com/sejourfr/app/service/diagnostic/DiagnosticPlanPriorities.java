package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.dto.DiagnosticPlanPriorityDto;
import com.sejourfr.app.dto.DiagnosticSkillObservationDto;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.manager.JourneyStepManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * <b>Les priorites du rapport du diagnostic rapide, LUES sur le lot du Plan.</b>
 *
 * <p>🛑 <b>Une seule autorite</b> : les etapes {@code TRAIN_SKILL} que la
 * session a versees au parcours TCF ({@code source_assessment_id = session}).
 * Aucun repli sur {@code summary_json.priority_skill_codes} : c'est
 * precisement cette seconde source qui designait d'autres competences que le
 * Plan (audit du 2026-10-04, §3.3). Pas de lot — zero fragilite, crochet du
 * parcours pas encore rattrape, session anterieure au parcours — donne une
 * liste <b>vide</b>, jamais une liste devinee.
 *
 * <p><b>Quel cycle</b>, quand la session a nourri plusieurs cycles (un cycle
 * historise puis remplace a sa premiere lecture, V082, reprend le diagnostic
 * comme reference) : le cycle {@code EN_COURS} s'il en porte, sinon le cycle
 * {@code EN_ATTENTE}, sinon le plus recent. C'est la file que le candidat a,
 * ou aura, sous les yeux.
 */
@Component
@RequiredArgsConstructor
public class DiagnosticPlanPriorities {

    private final JourneyStepManager stepManager;

    /**
     * @param constats les observations du diagnostic, par {@code skillId} — le
     *                 constat de chaque priorite y est joint, jamais recalcule.
     */
    public List<DiagnosticPlanPriorityDto> lire(
            UUID userId, UUID sessionId, Map<UUID, DiagnosticSkillObservationDto> constats) {
        List<JourneyStep> etapes = stepManager.findEntrainementsDeLEvaluation(userId, sessionId);
        if (etapes.isEmpty()) return List.of();
        Journey cycle = cycleRetenu(etapes);
        List<DiagnosticPlanPriorityDto> priorites = new ArrayList<>();
        Set<UUID> vues = new HashSet<>();
        for (JourneyStep etape : etapes) {
            Skill skill = etape.getSkill();
            if (skill == null || !etape.getJourney().getId().equals(cycle.getId())) continue;
            if (!vues.add(skill.getId())) continue;
            DiagnosticSkillObservationDto constat = constats.get(skill.getId());
            priorites.add(new DiagnosticPlanPriorityDto(
                    skill.getId(), skill.getCode(), skill.getTitle(), skill.getSection(),
                    skill.getTaskCode(), priorites.size() + 1,
                    constat == null ? null : constat.explanation(),
                    skill.getGeneralCriterion(),
                    visibleDansLePlan(cycle, etape)));
        }
        return List.copyOf(priorites);
    }

    /** Les etapes arrivent du cycle le plus recent au plus ancien. */
    private static Journey cycleRetenu(List<JourneyStep> etapes) {
        return etapes.stream()
                .map(JourneyStep::getJourney)
                .min(Comparator.comparingInt(DiagnosticPlanPriorities::preference))
                .orElseThrow();
    }

    private static int preference(Journey cycle) {
        return switch (cycle.getStatus()) {
            case EN_COURS -> 0;
            case EN_ATTENTE -> 1;
            case HISTORISE -> 2;
        };
    }

    private static boolean visibleDansLePlan(Journey cycle, JourneyStep etape) {
        return cycle.getStatus() == JourneyStatus.EN_COURS
                && etape.getResolution() != JourneyStepResolution.SUPERSEDED;
    }
}

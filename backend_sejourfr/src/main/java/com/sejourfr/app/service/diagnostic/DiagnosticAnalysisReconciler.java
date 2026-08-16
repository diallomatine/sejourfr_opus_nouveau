package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * LE SERVEUR DÉRIVE, IL NE REFUSE PLUS — étape déterministe appliquée à la
 * sortie du correcteur <b>avant</b> {@link DiagnosticAnalysisValidator}.
 *
 * <p>Deux motifs de refus ont détruit un diagnostic réel en production, donc les
 * deux productions du candidat :
 * <ol>
 *   <li>« priority et status PRIORITY divergent » — un invariant <b>qui n'était
 *       écrit nulle part dans le prompt</b>, sur un champ entièrement
 *       <b>redondant</b> : {@code priority} ne porte aucune information que
 *       {@code status} n'ait déjà. C'est {@code status} qui est persisté sur
 *       {@code learning_plan_observations}, contraint en base et lu par tout le
 *       moteur du Plan : il fait foi, {@code priority} s'en déduit ;</li>
 *   <li>« maximum 2 priorités par production » — un plafond, donc une
 *       <b>troncature</b>, comme {@code capListe} côté évaluation : plafond
 *       déclaré au contrat, troncature serveur.</li>
 * </ol>
 *
 * <p>Le contrat v1 ne bouge pas (ni rubriques, ni tool-schema) : le retrait du
 * champ à la source est une passe v2 séparée. Ici, on cesse simplement de punir
 * ce qu'on sait recalculer.
 *
 * <p><b>Le serveur n'abaisse jamais qu'un cran et ne relève jamais</b> — même
 * philosophie que {@code applyCouplage} / {@code applyPlafonds} /
 * {@code applyConfiance} / {@code CompetenceLevelEvidenceGuard}.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DiagnosticAnalysisReconciler {

    private final DiagnosticReconciliationMetrics metrics;

    /**
     * Rend une copie de la sortie où {@code priority} est dérivé de
     * {@code status} et le plafond de priorités appliqué. Ce qui n'est pas
     * structurellement exploitable est laissé tel quel : c'est le validateur qui
     * le refusera, et lui seul.
     *
     * @param allowedSkills allowlist du sujet, <b>déjà triée</b> par
     *                      {@code display_order} (l'ordre éditorial
     *                      d'importance) — son index sert de rang de départage.
     */
    public Map<String, Object> reconcile(Map<String, Object> output, List<Skill> allowedSkills) {
        if (output == null || !(output.get("skills") instanceof List<?> skills)) return output;

        List<Object> reconciled = new ArrayList<>(skills.size());
        List<Map<String, Object>> priorities = new ArrayList<>();
        for (Object raw : skills) {
            if (!(raw instanceof Map<?, ?> skill)) {
                reconciled.add(raw);
                continue;
            }
            Map<String, Object> item = copy(skill);
            boolean declared = Boolean.TRUE.equals(item.get("priority"));
            // Une compétence non observée n'est jamais prioritaire : le
            // validateur exige par ailleurs qu'elle soit NOT_OBSERVED.
            boolean observed = !Boolean.FALSE.equals(item.get("observed"));
            boolean derived = observed && LearningPlanSkillStatus.PRIORITY.name()
                    .equals(String.valueOf(item.get("status")).trim());
            if (declared != derived) {
                metrics.enregistrer(derived
                        ? DiagnosticReconciliationMetrics.Motif.PRIORITE_DERIVEE_POSEE
                        : DiagnosticReconciliationMetrics.Motif.PRIORITE_DERIVEE_RETIREE);
            }
            item.put("priority", derived);
            if (derived) priorities.add(item);
            reconciled.add(item);
        }
        tronque(priorities, allowedSkills);

        Map<String, Object> normalized = new LinkedHashMap<>(output);
        normalized.put("skills", reconciled);
        return normalized;
    }

    /**
     * Garde les deux meilleures priorités et abaisse le surplus d'un cran.
     *
     * <p>Départage : {@link DiagnosticPriorityRanking}, la règle partagée avec
     * l'assemblage des deux productions — confiance décroissante puis rang
     * d'allowlist, <b>jamais</b> l'alphabet du code.
     */
    private void tronque(List<Map<String, Object>> priorities, List<Skill> allowedSkills) {
        int plafond = DiagnosticAnalysisValidator.MAX_PRIORITIES_PER_PRODUCTION;
        if (priorities.size() <= plafond) return;
        Map<String, Integer> order = new HashMap<>();
        for (int rank = 0; rank < allowedSkills.size(); rank++) {
            order.put(allowedSkills.get(rank).getCode(), rank);
        }
        List<DiagnosticPriorityRanking.Ranked> ranked =
                DiagnosticPriorityRanking.ranked(priorities, order);
        for (DiagnosticPriorityRanking.Ranked surplus
                : ranked.subList(plafond, ranked.size())) {
            surplus.item().put("status", LearningPlanSkillStatus.TO_REINFORCE.name());
            surplus.item().put("priority", false);
            metrics.enregistrer(DiagnosticReconciliationMetrics.Motif.PRIORITE_TRONQUEE);
            log.info("Priorité diagnostic tronquée skill={} : PRIORITY -> TO_REINFORCE",
                    surplus.skillCode());
        }
    }

    /** Copie à plat, clés d'origine comprises : le validateur juge le contrat entier. */
    private static Map<String, Object> copy(Map<?, ?> skill) {
        Map<String, Object> item = new LinkedHashMap<>();
        skill.forEach((key, value) -> item.put(String.valueOf(key), value));
        return item;
    }
}

package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.DiagnosticCommunicationStatus;
import com.sejourfr.app.enums.DiagnosticTaskCompletion;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.service.EvaluationProductionSegments;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Garde-fou serveur : allowlist exhaustive, preuves réelles et max de priorités. */
@Component
public class DiagnosticAnalysisValidator {

    private static final Set<String> ROOT_KEYS = Set.of(
            "level_estimate", "task_completion", "communication_status", "summary",
            "strengths", "weaknesses", "skills");
    private static final Set<String> SKILL_KEYS = Set.of(
            "skill_code", "observed", "status", "evidence_segment",
            "explanation", "confidence", "priority");
    static final int MAX_PRIORITIES_PER_PRODUCTION = 2;
    static final int MAX_SUMMARY_LENGTH = 280;
    static final int MAX_LIST_ITEM_LENGTH = 180;
    static final int MAX_EXPLANATION_LENGTH = 220;
    static final int MAX_SKILL_CODE_LENGTH = 16;

    public List<String> violations(
            Map<String, Object> output,
            List<Skill> allowedSkills,
            EvaluationProductionSegments segments) {
        List<String> violations = new ArrayList<>();
        if (output == null || output.isEmpty()) {
            return List.of("sortie vide");
        }
        exactKeys(output.keySet(), ROOT_KEYS, "racine", violations);
        enumValue(output.get("level_estimate"), NiveauCecrl.class, "level_estimate", violations);
        if (parseEnum(output.get("level_estimate"), NiveauCecrl.class) instanceof NiveauCecrl level
                && (level == NiveauCecrl.C1 || level == NiveauCecrl.C2)) {
            violations.add("level_estimate doit être plafonné à B2");
        }
        enumValue(output.get("task_completion"), DiagnosticTaskCompletion.class,
                "task_completion", violations);
        enumValue(output.get("communication_status"), DiagnosticCommunicationStatus.class,
                "communication_status", violations);
        boundedString(output.get("summary"), "summary", MAX_SUMMARY_LENGTH, violations);
        stringList(output.get("strengths"), "strengths", 3,
                MAX_LIST_ITEM_LENGTH, violations);
        stringList(output.get("weaknesses"), "weaknesses", 3,
                MAX_LIST_ITEM_LENGTH, violations);

        Set<String> allowed = allowedSkills.stream().map(Skill::getCode)
                .collect(java.util.stream.Collectors.toCollection(java.util.LinkedHashSet::new));
        Object rawSkills = output.get("skills");
        if (!(rawSkills instanceof List<?> skills)) {
            violations.add("skills doit être une liste");
            return violations;
        }
        Set<String> seen = new HashSet<>();
        int priorities = 0;
        for (int index = 0; index < skills.size(); index++) {
            Object raw = skills.get(index);
            if (!(raw instanceof Map<?, ?> skill)) {
                violations.add("skills[" + index + "] doit être un objet");
                continue;
            }
            Set<String> keys = skill.keySet().stream().map(String::valueOf)
                    .collect(java.util.stream.Collectors.toSet());
            exactKeys(keys, SKILL_KEYS, "skills[" + index + "]", violations);
            String code = string(skill.get("skill_code"));
            if (code.length() > MAX_SKILL_CODE_LENGTH) {
                violations.add("skill_code dépasse " + MAX_SKILL_CODE_LENGTH + " caractères : " + code);
            }
            if (!allowed.contains(code)) violations.add("skill_code hors allowlist : " + code);
            if (!seen.add(code)) violations.add("skill_code dupliqué : " + code);
            if (!(skill.get("observed") instanceof Boolean observed)) {
                violations.add(code + " : observed doit être booléen");
                continue;
            }
            LearningPlanSkillStatus status = parseEnum(
                    skill.get("status"), LearningPlanSkillStatus.class);
            if (status == null) violations.add(code + " : status invalide");
            ObservationConfidence confidence = parseEnum(
                    skill.get("confidence"), ObservationConfidence.class);
            if (confidence == null) violations.add(code + " : confidence invalide");
            boundedString(skill.get("explanation"), code + ".explanation",
                    MAX_EXPLANATION_LENGTH, violations);
            boolean priority = skill.get("priority") instanceof Boolean value && value;
            if (!(skill.get("priority") instanceof Boolean)) {
                violations.add(code + " : priority doit être booléen");
            }
            if (priority) priorities++;
            if (priority != (status == LearningPlanSkillStatus.PRIORITY)) {
                violations.add(code + " : priority et status PRIORITY divergent");
            }
            Object evidence = skill.get("evidence_segment");
            if (!observed) {
                if (status != LearningPlanSkillStatus.NOT_OBSERVED) {
                    violations.add(code + " : non observée doit être NOT_OBSERVED");
                }
                if (evidence != null) violations.add(code + " : preuve interdite si non observée");
                if (priority) violations.add(code + " : une compétence non observée ne peut être prioritaire");
                if (confidence != null && confidence != ObservationConfidence.LOW) {
                    violations.add(code + " : une compétence non observée doit avoir une confiance LOW");
                }
            } else {
                if (status == LearningPlanSkillStatus.NOT_OBSERVED) {
                    violations.add(code + " : observée ne peut pas être NOT_OBSERVED");
                }
                if (!isStrictPositiveInteger(evidence)
                        || segments.texte(((Number) evidence).intValue()).isEmpty()) {
                    violations.add(code + " : evidence_segment absent ou hors bornes");
                }
            }
        }
        if (!seen.equals(allowed)) {
            Set<String> missing = new HashSet<>(allowed);
            missing.removeAll(seen);
            if (!missing.isEmpty()) violations.add("compétences manquantes : " + missing);
        }
        if (priorities > MAX_PRIORITIES_PER_PRODUCTION) {
            violations.add("maximum " + MAX_PRIORITIES_PER_PRODUCTION
                    + " priorités par production (reçu " + priorities + ")");
        }
        return violations;
    }

    /** Résout les numéros vers des extraits exacts avant toute persistance. */
    public Map<String, Object> normalize(
            Map<String, Object> output, EvaluationProductionSegments segments) {
        Map<String, Object> normalized = new LinkedHashMap<>();
        for (String key : List.of("level_estimate", "task_completion", "communication_status",
                "summary", "strengths", "weaknesses")) {
            normalized.put(key, output.get(key));
        }
        List<Map<String, Object>> normalizedSkills = new ArrayList<>();
        if (output.get("skills") instanceof List<?> skills) {
            for (Object raw : skills) {
                if (!(raw instanceof Map<?, ?> skill)) continue;
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("skill_code", string(skill.get("skill_code")));
                item.put("observed", skill.get("observed"));
                item.put("status", string(skill.get("status")));
                Object segment = skill.get("evidence_segment");
                item.put("evidence_segment", segment);
                item.put("evidence", segment instanceof Number n
                        ? segments.texte(n.intValue()).orElse(null) : null);
                item.put("explanation", string(skill.get("explanation")));
                item.put("confidence", string(skill.get("confidence")));
                item.put("priority", skill.get("priority"));
                normalizedSkills.add(item);
            }
        }
        normalized.put("skills", normalizedSkills);
        return normalized;
    }

    private static void exactKeys(
            Set<String> actual, Set<String> expected, String path, List<String> violations) {
        Set<String> missing = new HashSet<>(expected);
        missing.removeAll(actual);
        Set<String> extra = new HashSet<>(actual);
        extra.removeAll(expected);
        if (!missing.isEmpty()) violations.add(path + " : champs manquants " + missing);
        if (!extra.isEmpty()) violations.add(path + " : champs hors contrat " + extra);
    }

    private static void nonBlank(Object value, String path, List<String> violations) {
        if (!(value instanceof String text) || text.isBlank()) {
            violations.add(path + " doit être une chaîne non vide");
        }
    }

    private static void boundedString(
            Object value, String path, int maxLength, List<String> violations) {
        nonBlank(value, path, violations);
        if (value instanceof String text && text.length() > maxLength) {
            violations.add(path + " dépasse " + maxLength + " caractères");
        }
    }

    private static void stringList(
            Object value, String path, int maxItems, int maxItemLength,
            List<String> violations) {
        if (!(value instanceof List<?> list)) {
            violations.add(path + " doit être une liste");
            return;
        }
        if (list.size() > maxItems) {
            violations.add(path + " dépasse " + maxItems + " éléments");
        }
        for (Object item : list) {
            boundedString(item, path + "[]", maxItemLength, violations);
        }
    }

    /** Jackson peut fournir Double, BigDecimal ou BigInteger : aucun arrondi implicite. */
    private static boolean isStrictPositiveInteger(Object value) {
        if (!(value instanceof Number number)) return false;
        try {
            BigDecimal decimal;
            if (number instanceof BigDecimal bigDecimal) {
                decimal = bigDecimal;
            } else if (number instanceof BigInteger bigInteger) {
                decimal = new BigDecimal(bigInteger);
            } else {
                double floating = number.doubleValue();
                if (!Double.isFinite(floating)) return false;
                decimal = new BigDecimal(number.toString());
            }
            BigDecimal integer = decimal.stripTrailingZeros();
            if (integer.scale() > 0) return false;
            return integer.compareTo(BigDecimal.ONE) >= 0
                    && integer.compareTo(BigDecimal.valueOf(Integer.MAX_VALUE)) <= 0;
        } catch (NumberFormatException ignored) {
            return false;
        }
    }

    private static <E extends Enum<E>> void enumValue(
            Object value, Class<E> type, String path, List<String> violations) {
        if (parseEnum(value, type) == null) violations.add(path + " invalide");
    }

    private static <E extends Enum<E>> E parseEnum(Object value, Class<E> type) {
        if (value == null) return null;
        try {
            return Enum.valueOf(type, value.toString().trim());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    private static String string(Object value) { return value == null ? "" : value.toString().trim(); }
}

package com.sejourfr.app.progression.domain;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;

import java.util.Objects;

/**
 * <b>L'unite d'agregation du moteur</b> : un palier receptif ({@code CO:A2}) ou
 * une competence productive ({@code EE:EE_CONNECTEURS_B1}).
 *
 * <p>Une ligne de {@code progression_state} par {@code userId + stateKey +
 * engineVersion} (§27.2). La forme textuelle est celle que portent les logs
 * d'observabilite (§46) et {@code progression_prediction_log} (§47.1) ; elle
 * est stable et ne doit pas etre reformulee.
 *
 * @param stateType le profil de seuils applicable — jamais deduit du domaine
 * @param section   CO / CE en receptif, EE / EO en productif
 * @param level     le palier mesure ; {@code null} pour une competence
 * @param skillId   la competence du referentiel ; {@code null} en receptif
 */
public record ProgressionStateKey(
        ProgressionStateType stateType,
        SkillSection section,
        TargetLevel level,
        String skillId
) {

    public ProgressionStateKey {
        Objects.requireNonNull(stateType, "stateType");
        Objects.requireNonNull(section, "section");
        if (stateType == ProgressionStateType.RECEPTIVE_LEVEL) {
            if (level == null) {
                throw new IllegalArgumentException("RECEPTIVE_LEVEL exige un level");
            }
            if (skillId != null) {
                throw new IllegalArgumentException("RECEPTIVE_LEVEL n'a pas de skillId");
            }
            if (section != SkillSection.CO && section != SkillSection.CE) {
                throw new IllegalArgumentException("RECEPTIVE_LEVEL vaut pour CO ou CE");
            }
        } else {
            if (skillId == null || skillId.isBlank()) {
                throw new IllegalArgumentException("PRODUCTIVE_SKILL exige un skillId");
            }
            if (section != SkillSection.EE && section != SkillSection.EO) {
                throw new IllegalArgumentException("PRODUCTIVE_SKILL vaut pour EE ou EO");
            }
        }
    }

    /** {@code CO:A2} — la cle d'un palier de comprehension. */
    public static ProgressionStateKey receptive(SkillSection section, TargetLevel level) {
        return new ProgressionStateKey(
                ProgressionStateType.RECEPTIVE_LEVEL, section, level, null);
    }

    /** {@code EE:EE_CONNECTEURS_B1} — la cle d'une competence de production. */
    public static ProgressionStateKey productive(SkillSection section, String skillId) {
        return new ProgressionStateKey(
                ProgressionStateType.PRODUCTIVE_SKILL, section, null, skillId);
    }

    /** La forme textuelle stable, celle des logs et de la table d'etats. */
    public String asText() {
        return stateType == ProgressionStateType.RECEPTIVE_LEVEL
                ? section.name() + ":" + level.name()
                : section.name() + ":" + skillId;
    }

    @Override
    public String toString() {
        return asText();
    }
}

package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillSection;

import java.util.UUID;

/** De quoi nommer une competence et y renvoyer, sans embarquer tout son etat. */
public record PlanSkillRefDto(
        UUID skillId,
        String skillCode,
        String title,
        SkillSection section
) {}

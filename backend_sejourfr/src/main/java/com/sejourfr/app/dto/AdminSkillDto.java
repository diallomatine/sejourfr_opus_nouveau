package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;

import java.time.Instant;
import java.util.UUID;

/**
 * Une competence vue de la console admin. Se distingue de {@code SkillDto} —
 * la vue candidat — sur trois points : elle expose {@code active} et les
 * horodatages (le candidat ne voit jamais une competence desactivee), elle
 * porte {@link #generalCriterion} que le candidat lit deja mais qui est ici
 * EDITABLE, et son {@link #promptCount} compte les sujets <b>desactives
 * compris</b> — l'editeur doit savoir ce qu'il y a dans la boite, pas ce qui en
 * sort.
 */
public record AdminSkillDto(
        UUID id,
        SkillSection section,
        SkillTaskCode taskCode,
        /** Code editorial, immuable apres creation : les seeds s'appuient dessus. */
        String code,
        String title,
        String description,
        /** Critere general de la competence, distinct du critere unique de chaque sujet. */
        String generalCriterion,
        String targetLevel,
        int displayOrder,
        boolean active,
        long promptCount,
        Instant createdAt,
        Instant updatedAt
) {
}

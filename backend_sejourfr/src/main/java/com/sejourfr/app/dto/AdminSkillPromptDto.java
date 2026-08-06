package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillDifficulty;
import com.sejourfr.app.enums.SkillSection;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Un petit sujet vu de la console admin, <b>references comprises</b> — c'est la
 * difference majeure avec la vue candidat, ou les references sont gardees
 * derriere une route dediee tant que le candidat n'a pas produit. L'editeur,
 * lui, doit voir ce qu'il publie.
 *
 * <p>{@link #references} peut etre vide (sujet en cours de redaction) : la
 * console affiche alors « A completer » plutot que de casser.
 *
 * <p>{@link #attemptCount} compte les tentatives de TOUS les candidats : c'est
 * lui qui explique pourquoi une suppression peut etre refusee en 409.
 */
public record AdminSkillPromptDto(
        UUID id,
        UUID skillId,
        String skillCode,
        /** Copie de la section de la competence parente : jamais fournie par le client. */
        SkillSection section,
        /** Code editorial, immuable apres creation. */
        String code,
        String title,
        String context,
        String instruction,
        String uniqueCriterion,
        /** Section EE uniquement — nul en EO (CHECK en base). */
        Integer recommendedMinWords,
        Integer recommendedMaxWords,
        /** Section EO uniquement — nul en EE (CHECK en base). */
        Integer recommendedDurationSeconds,
        SkillDifficulty difficultyLevel,
        int displayOrder,
        boolean active,
        List<SkillReferenceDto> references,
        long attemptCount,
        Instant createdAt,
        Instant updatedAt
) {
}

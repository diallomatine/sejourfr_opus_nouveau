package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;

import java.util.UUID;

/**
 * Usage reel d'une competence, pour l'ecran de statistiques admin : ce que les
 * candidats travaillent, et ce qu'ils reussissent.
 *
 * <p><b>{@link #validatedRate} est nul, jamais zero, quand rien n'a ete
 * analyse.</b> Un taux de 0 % se lit « les candidats echouent » ; l'absence de
 * taux se lit « personne n'a encore fait analyser ». Les deux menent a des
 * decisions editoriales opposees, d'ou le refus de renvoyer {@code 0.0} par
 * commodite. La console affiche « aucune analyse ».
 */
public record AdminSkillStatsDto(
        UUID skillId,
        String code,
        String title,
        SkillSection section,
        /**
         * Tache d'appartenance, <b>{@code null} pour une competence de
         * COMPREHENSION</b> (section {@code CO} / {@code CE}) : celles-ci
         * n'appartiennent a aucune des 6 taches officielles. Les fronts doivent
         * lire le domaine sur {@code section} et le niveau sur
         * {@code targetLevel}, jamais deduire l'un de l'autre depuis la tache.
         */
        SkillTaskCode taskCode,
        long promptCount,
        /** Tentatives de tous les candidats sur les sujets de la competence. */
        long attemptCount,
        /** Parmi elles, celles qui portent un verdict IA (echecs d'analyse exclus). */
        long analysedCount,
        /** Part de verdicts VALIDATED parmi les analysees, 0..1. Nul si aucune. */
        Double validatedRate
) {
}

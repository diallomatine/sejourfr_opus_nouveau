package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillTaskCode;

/**
 * Une tache d'un domaine d'<b>expression</b> (EE1..EE3, EO1..EO3) vue depuis le
 * Plan : combien de ses competences ont deja ete observees.
 *
 * <p>« 3 / 8 observees » n'est pas une note : une competence non observee n'est
 * pas une competence ratee (brief §96), c'est une competence que le candidat n'a
 * pas encore eu l'occasion de montrer. Le denominateur est <b>lu en base</b>
 * (competences actives de la tache), jamais la constante 8 ecrite en dur : le
 * volume du referentiel est verrouille par {@code SkillSeedIT}, pas par le
 * schema, et une tache qui en publierait sept se decrirait honnetement.
 *
 * @param taskCode      la tache
 * @param tacheNumero   1, 2 ou 3 — ce que les ecrans de production attendent
 * @param observedSkills competences de la tache deja observees au moins une fois
 * @param totalSkills   competences actives de la tache
 */
public record PlanDomainTaskDto(
        SkillTaskCode taskCode,
        int tacheNumero,
        int observedSkills,
        int totalSkills
) {}

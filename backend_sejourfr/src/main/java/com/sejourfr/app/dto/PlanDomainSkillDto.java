package com.sejourfr.app.dto;

import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.PlanActionNature;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;

import java.time.Instant;
import java.util.UUID;

/**
 * Une competence du referentiel d'une <b>epreuve</b>, vue depuis le Plan : ou en
 * est le candidat dessus, et peut-il la travailler.
 *
 * <p>C'est la ligne de l'ecran « Mon diagnostic », qui se lit <b>epreuve par
 * epreuve</b> : le niveau estime du domaine, puis toutes ses competences avec
 * leur statut. La liste est <b>uniforme sur les quatre domaines</b> — les 24
 * competences des trois taches en expression, les trois competences de palier en
 * comprehension — pour qu'un front n'ait qu'<b>une</b> facon de lire une carte
 * d'epreuve.
 *
 * <h2>🛑 Le serveur expose des FAITS, jamais une phrase</h2>
 * Aucun libelle FR ne voyage ici : les libelles de {@link LearningPlanSkillStatus},
 * {@link SkillMasteryState} et {@link PlanActionNature} sont recopies a la main
 * dans chaque front et geles par {@code SkillLabelsTest}.
 *
 * <h2>Trois nullites, trois faits differents</h2>
 * <ul>
 *   <li>{@link #status()} vaut {@link LearningPlanSkillStatus#NOT_OBSERVED}
 *       quand rien n'a jamais ete observe — <b>jamais {@code null}</b> : une
 *       competence est toujours dans un des quatre etats, et « non observee »
 *       est un etat, pas une absence de donnee ;</li>
 *   <li>{@link #masteryState()} et {@link #observedAt()} valent {@code null}
 *       dans ce meme cas : le moteur de maitrise ne conclut rien sans
 *       observation, et <i>null = inconnu, jamais mauvais</i> ;</li>
 *   <li>{@link #nature()} vaut {@code null} des que le Plan ne demande
 *       <b>rien</b> sur cette competence — le cas de l'immense majorite d'entre
 *       elles. Une competence {@code SOLID}, ou simplement non observee hors du
 *       palier que le cycle construit, n'est pas une action : on ne fabrique pas
 *       une nature pour remplir une colonne.</li>
 * </ul>
 *
 * @param skillId      la competence
 * @param skillCode    son code editorial ({@code EE1-C3}, {@code CO-B1}...)
 * @param title        son titre editorial
 * @param section      son domaine — <b>c'est lui qui fait foi</b>, jamais la tache
 * @param taskCode     sa tache, {@code null} en comprehension (CO/CE n'en ont pas)
 * @param tacheNumero  1, 2 ou 3, {@code null} en comprehension
 * @param targetLevel  le palier porte par {@code skills.target_level} ;
 *                     {@code null} si la colonne descend sous {@code A2}, ce que
 *                     {@link TargetLevel} ne sait pas dire
 * @param status       le verdict de la <b>derniere production probante</b>, ou
 *                     {@code NOT_OBSERVED}
 * @param masteryState l'etat <b>agrege</b> ({@code SkillMasteryEngine}),
 *                     {@code null} sans observation
 * @param nature       l'<b>action</b> que le Plan demande sur cette competence,
 *                     ou {@code null} s'il n'en demande aucune
 * @param observedAt   date de la derniere observation probante, {@code null} sans
 * @param locked       ce candidat ne peut pas travailler cette competence
 *                     ({@code SkillAccessService}, unique autorite)
 */
public record PlanDomainSkillDto(
        UUID skillId,
        String skillCode,
        String title,
        SkillSection section,
        SkillTaskCode taskCode,
        Short tacheNumero,
        TargetLevel targetLevel,
        LearningPlanSkillStatus status,
        SkillMasteryState masteryState,
        PlanActionNature nature,
        Instant observedAt,
        boolean locked
) {}

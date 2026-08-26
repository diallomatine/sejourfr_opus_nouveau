package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.PlanDomainPriority;
import com.sejourfr.app.enums.TargetLevel;

import java.util.List;

/**
 * Un des quatre domaines du TCF, <b>vu par le Plan</b> : son niveau estime, ce
 * que le Plan a decide d'en faire, et de quoi ouvrir sa fiche de detail.
 *
 * <p><b>A ne pas confondre avec {@link TcfDomainDto}</b>, servi sur le
 * dashboard : celui-la repond a « quel est mon niveau ? », celui-ci a « qu'est-ce
 * que je fais de ce domaine maintenant ? ». Le <b>niveau est le meme</b> — il
 * vient de {@code TcfProfileService}, unique autorite, et n'est pas recalcule
 * ici : deux surfaces qui repondent differemment a la meme question, c'est le
 * defaut deja corrige sur le niveau TCF estime.
 *
 * <p>{@code evaluated == false} &hArr; {@code niveau == null} : le domaine n'a
 * jamais ete mesure, donc son niveau est <b>inconnu</b>, jamais mauvais. Sa
 * priorite vaut alors {@link PlanDomainPriority#A_EVALUER} et <b>ne devient
 * jamais une faiblesse</b>.
 *
 * <p><b>Les deux blocs de detail s'excluent</b>, parce que les deux familles de
 * domaines ne se travaillent pas pareil :
 * <ul>
 *   <li><b>comprehension</b> (CO / CE) : {@link #paliers()} porte les trois
 *       competences de palier et {@link #blockingLevel()} celle qui bloque ;
 *       {@link #taches()} est vide ;</li>
 *   <li><b>expression</b> (EO / EE) : {@link #taches()} porte les trois taches
 *       et leur couverture ; {@link #paliers()} est vide, et
 *       {@link #consolidatedLevel()} / {@link #blockingLevel()} valent
 *       {@code null} — la notion de palier consolide n'existe que la ou la
 *       progression est sequentielle.</li>
 * </ul>
 * Les deux listes sont <b>toujours presentes</b>, jamais {@code null}.
 *
 * <p><b>{@link #skills()}, lui, est UNIFORME sur les quatre domaines</b> : les 24
 * competences des trois taches en expression, les trois competences de palier en
 * comprehension. C'est ce qui permet a l'ecran « Mon diagnostic » de se lire
 * epreuve par epreuve avec <b>une seule</b> facon de rendre une carte, la ou
 * {@link #paliers()} et {@link #taches()} restent les deux vues specialisees.
 * Les trois compteurs qui l'accompagnent en sont <b>derives</b>, jamais recomptes
 * ailleurs : leur somme vaut toujours {@code skills().size()}, ce qui interdit a
 * un front d'afficher un « + N » faux.
 *
 * @param epreuve           {@code TCF_CO} | {@code TCF_CE} | {@code TCF_EO} | {@code TCF_EE}
 * @param evaluated         le domaine porte un niveau opposable
 * @param niveau            niveau estime, {@code null} si jamais evalue
 * @param priority          ce que le Plan en fait — derive serveur
 * @param consolidatedLevel comprehension : plus haut palier consolide, prerequis
 *                          compris ({@code ComprehensionLevelResolver}) ;
 *                          {@code null} si rien ne l'est
 * @param blockingLevel     comprehension : premier palier non consolide,
 *                          {@code null} quand les trois le sont
 * @param paliers           comprehension : A2, B1, B2 dans cet ordre ; vide en expression
 * @param taches            expression : taches 1, 2, 3 dans cet ordre ; vide en comprehension
 * @param skills            <b>toutes</b> les competences actives du domaine, dans
 *                          l'ordre du referentiel (tache puis rang d'affichage en
 *                          expression, A2 &rarr; B1 &rarr; B2 en comprehension).
 *                          <b>Jamais {@code null}</b> ; vide seulement si le
 *                          referentiel l'est.
 * @param fragileSkillCount competences observees {@code PRIORITY} ou
 *                          {@code TO_REINFORCE}
 * @param solidSkillCount   competences observees {@code SOLID}
 * @param notObservedSkillCount competences jamais observees — <b>ce n'est pas une
 *                          faiblesse</b>, c'est une absence de mesure
 * @param nextTargetLevel   le palier que <b>ce domaine</b> construit
 *                          ({@code PlanDomainTargetLevelResolver}, autorite
 *                          unique). {@code null} quand il n'y a rien a
 *                          construire : domaine jamais mesure, ou <b>deja a
 *                          l'objectif</b> — il s'entretient alors, il ne
 *                          redescend pas.
 *                          <p>🛑 <b>Servi, jamais recalcule par un front.</b> Les
 *                          deux fronts en tenaient chacun une copie
 *                          ({@code diagnosticNextLevel}, {@code nextLevel}) qui
 *                          ignorait l'objectif du candidat : un candidat B1
 *                          visant le B1 lisait « prochain palier B2 ».
 * @param acquireCount      competences <b>a acquerir</b> sur ce domaine
 *                          ({@code nature == A_ACQUERIR}). Sous-ensemble de
 *                          {@code notObservedSkillCount}, et <b>uniquement des
 *                          competences EXECUTABLES</b> : le compte ne promet
 *                          jamais un contenu qui n'existe pas
 *                          ({@code PlanContentAvailability}).
 * @param readyForValidationCount competences <b>pretes a etre verifiees</b>
 *                          ({@code nature == A_VERIFIER}). Sous-ensemble de
 *                          {@code fragileSkillCount}.
 * @param notObservedWithoutActionCount competences jamais observees <b>sur
 *                          lesquelles le Plan ne demande rien</b> — le vrai
 *                          « pas encore assez de donnees pour se prononcer ».
 *                          <p>🛑 {@code notObservedSkillCount} moins
 *                          {@code acquireCount}, <b>calcule ici</b> : le mobile
 *                          le derivait de son cote, et les deux nombres
 *                          divergeaient des qu'une acquisition existait. Deux
 *                          champs nommes distinctement plutot qu'une
 *                          soustraction faite par chaque front.
 */
public record PlanDomainDto(
        EpreuveType epreuve,
        boolean evaluated,
        NiveauCecrl niveau,
        PlanDomainPriority priority,
        TargetLevel consolidatedLevel,
        TargetLevel blockingLevel,
        List<PlanDomainLevelDto> paliers,
        List<PlanDomainTaskDto> taches,
        List<PlanDomainSkillDto> skills,
        int fragileSkillCount,
        int solidSkillCount,
        int notObservedSkillCount,
        TargetLevel nextTargetLevel,
        int acquireCount,
        int readyForValidationCount,
        int notObservedWithoutActionCount
) {

    /**
     * Le domaine tel que {@link com.sejourfr.app.service.PlanCycleResolver} le
     * resout : niveau, urgence, paliers et taches, <b>sans</b> sa liste de
     * competences.
     *
     * <p>Cette liste ne peut pas etre remplie la : sa colonne {@code nature}
     * depend des priorites et des acquisitions, que le Plan n'a pas encore
     * choisies a ce moment — et son {@code locked} depend d'un acces qui n'est
     * resolu qu'ensuite. Elle est donc posee en un seul endroit,
     * {@code PlanDomainSkillResolver}, par {@link #withSkills}.
     */
    public static PlanDomainDto sansCompetences(
            EpreuveType epreuve,
            boolean evaluated,
            NiveauCecrl niveau,
            PlanDomainPriority priority,
            TargetLevel consolidatedLevel,
            TargetLevel blockingLevel,
            List<PlanDomainLevelDto> paliers,
            List<PlanDomainTaskDto> taches) {
        return new PlanDomainDto(epreuve, evaluated, niveau, priority,
                consolidatedLevel, blockingLevel, paliers, taches, List.of(),
                0, 0, 0, null, 0, 0, 0);
    }

    /**
     * Le meme domaine, avec ses competences et les trois compteurs qui en sont
     * <b>derives</b>. Reserve a {@code PlanDomainSkillResolver}, unique autorite :
     * deux endroits qui compteraient chacun de leur cote finiraient par afficher
     * deux totaux differents pour la meme epreuve.
     */
    public PlanDomainDto withSkills(
            List<PlanDomainSkillDto> skills,
            int fragileSkillCount,
            int solidSkillCount,
            int notObservedSkillCount,
            TargetLevel nextTargetLevel,
            int acquireCount,
            int readyForValidationCount) {
        return new PlanDomainDto(epreuve, evaluated, niveau, priority,
                consolidatedLevel, blockingLevel, paliers, taches,
                skills, fragileSkillCount, solidSkillCount, notObservedSkillCount,
                nextTargetLevel, acquireCount, readyForValidationCount,
                notObservedSkillCount - acquireCount);
    }
}

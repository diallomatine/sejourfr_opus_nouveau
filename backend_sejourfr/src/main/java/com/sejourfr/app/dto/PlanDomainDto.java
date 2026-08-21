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
 */
public record PlanDomainDto(
        EpreuveType epreuve,
        boolean evaluated,
        NiveauCecrl niveau,
        PlanDomainPriority priority,
        TargetLevel consolidatedLevel,
        TargetLevel blockingLevel,
        List<PlanDomainLevelDto> paliers,
        List<PlanDomainTaskDto> taches
) {}

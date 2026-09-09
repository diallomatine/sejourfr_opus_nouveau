package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanDomainDto;
import com.sejourfr.app.dto.PlanDomainSkillDto;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.PlanActionNature;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * <b>Les competences de chaque epreuve</b>, avec leur statut : ce que l'ecran
 * « Mon diagnostic » lit domaine par domaine.
 *
 * <p>Il ne <b>decide</b> rien. Tout ce qu'il pose vient d'une autorite existante,
 * qu'il <b>appelle</b> ou dont il recoit le resultat :
 * <table>
 *   <caption>D'ou vient chaque colonne</caption>
 *   <tr><th>champ</th><th>autorite</th></tr>
 *   <tr><td>{@code status} / {@code observedAt}</td>
 *       <td>{@code LearningPlanPriorityResolver.latestObservedBySkill}</td></tr>
 *   <tr><td>{@code masteryState}</td><td>{@code SkillMasteryEngine}</td></tr>
 *   <tr><td>{@code nature}</td><td>les cartes que {@code LearningPlanService}
 *       vient d'empiler</td></tr>
 *   <tr><td>{@code locked}</td><td>{@code SkillAccessService}</td></tr>
 * </table>
 *
 * <h2>🛑 Ce qui n'est PAS fabrique</h2>
 * <ul>
 *   <li>une competence jamais observee sort en {@link LearningPlanSkillStatus#NOT_OBSERVED}
 *       avec un {@code masteryState} et un {@code observedAt} <b>nuls</b> :
 *       <i>null = inconnu, jamais mauvais</i>, et une absence de mesure n'est pas
 *       une faiblesse ;</li>
 *   <li>une competence sur laquelle le Plan ne demande rien n'a <b>aucune</b>
 *       nature. On ne remplit pas une colonne : {@code SOLID} n'est pas une
 *       action, et une competence non observee hors du palier en construction
 *       non plus.</li>
 * </ul>
 *
 * <h2>Les trois compteurs</h2>
 * Ils sont <b>derives de la liste</b> qui les accompagne, jamais recomptes
 * ailleurs — les quatre valeurs de {@link LearningPlanSkillStatus} sont
 * exhaustives et disjointes, donc
 * {@code fragile + solid + notObserved == skills.size()} par construction. C'est
 * ce qui garantit qu'un « + N autres » affiche un vrai nombre, comme le compteur
 * serveur du rapport de diagnostic.
 *
 * <h2>Cout</h2>
 * <b>Zero requete.</b> Le referentiel arrive deja charge
 * ({@code PlanCycleResolver.Resolution.referentiel()}), l'historique et les etats
 * de maitrise aussi, et l'acces a ete resolu une fois pour tout l'ecran.
 */
@Component
public class PlanDomainSkillResolver {

    /** Les paliers de comprehension, du plus bas au plus haut : l'ordre est la regle. */
    private static final List<TargetLevel> PALIERS =
            List.of(TargetLevel.A2, TargetLevel.B1, TargetLevel.B2);

    /**
     * Les quatre domaines, avec la liste de leurs competences et les trois
     * compteurs qui en decoulent.
     *
     * @param domaines    les domaines resolus par {@link PlanCycleResolver}, sans
     *                    leurs competences
     * @param referentiel le referentiel actif entier, deja charge
     * @param latest      la derniere observation <b>probante</b> de chaque
     *                    competence ; une competence absente n'a jamais ete
     *                    observee
     * @param mastery     les etats de maitrise deja calcules sur ce meme
     *                    historique ; une competence absente n'a pas d'etat
     * @param natures     l'action demandee par le Plan, competence par
     *                    competence — <b>tout le pool</b>, pas seulement les
     *                    cartes affichees. C'est la difference qui a fait
     *                    apparaitre « rien a travailler » sur une epreuve qui
     *                    avait seize competences a apprendre : la carte lisait
     *                    une liste deja tronquee par un plafond d'ecran.
     * @param paliers     le palier que chaque domaine construit
     *                    ({@code PlanDomainTargetLevelResolver}, autorite
     *                    unique) — recopie tel quel sur le domaine pour que les
     *                    fronts cessent d'en tenir chacun une copie
     * @param access      ce que ce candidat peut travailler
     */
    public List<PlanDomainDto> attach(
            List<PlanDomainDto> domaines,
            List<Skill> referentiel,
            Map<UUID, LearningPlanObservation> latest,
            Map<UUID, SkillMasteryEngine.SkillMastery> mastery,
            Map<UUID, PlanActionNature> natures,
            Map<SkillSection, TargetLevel> paliers,
            SkillAccessService.SkillAccess access) {

        Map<SkillSection, List<Skill>> parSection = parSection(referentiel);
        List<PlanDomainDto> enrichis = new ArrayList<>(domaines.size());
        for (PlanDomainDto domaine : domaines) {
            List<Skill> competences =
                    parSection.getOrDefault(PlanCycleResolver.section(domaine.epreuve()), List.of());
            List<PlanDomainSkillDto> skills = new ArrayList<>(competences.size());
            int fragiles = 0;
            int solides = 0;
            int nonObservees = 0;
            int aAcquerir = 0;
            int aVerifier = 0;
            for (Skill skill : competences) {
                LearningPlanObservation observation = latest.get(skill.getId());
                LearningPlanSkillStatus status = observation == null
                        ? LearningPlanSkillStatus.NOT_OBSERVED : observation.getStatus();
                switch (status) {
                    case PRIORITY, TO_REINFORCE -> fragiles++;
                    case SOLID -> solides++;
                    case NOT_OBSERVED -> nonObservees++;
                }
                PlanActionNature nature = natures.get(skill.getId());
                if (nature == PlanActionNature.A_ACQUERIR) aAcquerir++;
                if (nature == PlanActionNature.A_VERIFIER) aVerifier++;
                skills.add(new PlanDomainSkillDto(
                        skill.getId(), skill.getCode(), skill.getTitle(), skill.getSection(),
                        skill.getTaskCode(), tacheNumero(skill.getTaskCode()),
                        PlanCycleResolver.palier(skill.getTargetLevel()),
                        status, etat(observation, mastery, skill.getId()),
                        nature,
                        observation == null ? null : observation.getObservedAt(),
                        access.isSkillLocked(skill.getId())));
            }
            enrichis.add(domaine.withSkills(List.copyOf(skills), fragiles, solides, nonObservees,
                    paliers == null ? null
                            : paliers.get(PlanCycleResolver.section(domaine.epreuve())),
                    aAcquerir, aVerifier));
        }
        return List.copyOf(enrichis);
    }

    /**
     * L'etat agrege, ou {@code null}.
     *
     * <p>Le moteur rend {@code SkillMastery.NONE} pour une competence sans
     * observation exploitable, dont l'etat est deja {@code null} : on ne le
     * remplace donc par rien. La condition sur {@code observation} n'est pas
     * redondante — elle dit que sans observation <b>probante</b>, il n'y a rien
     * a agreger, et evite qu'un etat calcule sur des lignes {@code NOT_OBSERVED}
     * s'affiche a cote d'un statut « jamais observee ».
     */
    private static SkillMasteryState etat(
            LearningPlanObservation observation,
            Map<UUID, SkillMasteryEngine.SkillMastery> mastery,
            UUID skillId) {
        if (observation == null) return null;
        return mastery.getOrDefault(skillId, SkillMasteryEngine.SkillMastery.NONE).state();
    }

    /**
     * Le referentiel range par domaine, dans l'ordre d'affichage : tache puis rang
     * en expression, A2 &rarr; B1 &rarr; B2 en comprehension.
     *
     * <p>L'ordre est <b>decide par le serveur</b>, comme celui des quatre
     * domaines : aucun front ne retrie. Il est deterministe de bout en bout —
     * deux lectures rendent exactement la meme liste.
     */
    private static Map<SkillSection, List<Skill>> parSection(List<Skill> referentiel) {
        Map<SkillSection, List<Skill>> parSection = new EnumMap<>(SkillSection.class);
        for (Skill skill : referentiel) {
            if (skill.getSection() == null) continue;
            parSection.computeIfAbsent(skill.getSection(), key -> new ArrayList<>()).add(skill);
        }
        parSection.values().forEach(competences -> competences.sort(Comparator
                .comparingInt(PlanDomainSkillResolver::ordreTache)
                .thenComparingInt(PlanDomainSkillResolver::ordrePalier)
                .thenComparingInt(Skill::getDisplayOrder)));
        return parSection;
    }

    /** La comprehension n'a pas de tache : toutes ses competences sont a egalite ici. */
    private static int ordreTache(Skill skill) {
        SkillTaskCode code = skill.getTaskCode();
        return code == null ? -1 : code.ordinal();
    }

    /**
     * L'expression n'ordonne pas ses competences par palier (elles sont melees
     * dans une meme tache) : ce critere ne departage que la comprehension, ou la
     * progression est sequentielle.
     */
    private static int ordrePalier(Skill skill) {
        if (skill.getTaskCode() != null) return 0;
        TargetLevel palier = PlanCycleResolver.palier(skill.getTargetLevel());
        return palier == null ? PALIERS.size() : PALIERS.indexOf(palier);
    }

    private static Short tacheNumero(SkillTaskCode taskCode) {
        return taskCode == null ? null : (short) taskCode.getTacheNumero();
    }
}

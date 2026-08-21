package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanCycleDto;
import com.sejourfr.app.dto.PlanDomainDto;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.PlanDomainPriority;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.manager.SkillManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * <b>Ce qu'il reste a APPRENDRE</b> : les competences du palier en construction
 * que le candidat n'a jamais travaillees.
 *
 * <p>Le Plan savait <b>reparer</b> — il rendait les competences observees
 * fragiles ({@link LearningPlanPriorityResolver}). Il ne savait pas
 * <b>enseigner</b> : un candidat A2 visant le B2, six competences ecrites
 * solides et deux fragiles, se voyait proposer <b>deux</b> actions, alors qu'il
 * lui reste un palier entier a acquerir. C'est ce trou que ce selecteur comble,
 * et rien d'autre.
 *
 * <h2>🛑 Trois interdits, qui sont la raison d'etre de ce composant</h2>
 * <ol>
 *   <li><b>Une competence a acquerir n'est PAS une observation.</b> Elle n'entre
 *       ni dans {@code SkillMasteryEngine}, ni dans une moyenne, ni dans un
 *       compte de fragilites — le moteur ne la voit meme pas, puisqu'elle n'a
 *       aucune ligne dans {@code learning_plan_observations}. Son
 *       {@code masteryState} vaut {@code null}.</li>
 *   <li><b>Les plafonds ne sont pas des quotas.</b> Ce selecteur ne rend que de
 *       vraies competences du palier vise ; il ne transforme jamais une
 *       competence solide, ni une competence non observee d'un autre palier, en
 *       matiere de remplissage. Rien de vrai a servir &rarr; liste vide, et
 *       l'ecran affiche moins de cartes. C'est le comportement attendu.</li>
 *   <li><b>Aucun contenu n'est cree.</b> Les competences rendues sont celles du
 *       referentiel publie ({@code skills.target_level}), et leur exercice est
 *       choisi par l'autorite existante ({@link RecommendedExerciseSelector}).
 *       Aucun appel LLM, aucune generation : le choix est <b>deterministe</b>.</li>
 * </ol>
 *
 * <h2>Ce qui rend une competence « a acquerir »</h2>
 * <ol>
 *   <li>elle appartient au <b>palier que le cycle construit</b>
 *       ({@code PlanCycleDto.targetLevel}) en expression, ou au <b>palier
 *       bloquant de son domaine</b> ({@code PlanDomainDto.blockingLevel}) en
 *       comprehension — la ou la progression est sequentielle, on ne saute pas
 *       un prerequis ;</li>
 *   <li>son domaine a <b>deja ete mesure</b> : un domaine jamais evalue se
 *       mesure avant de s'apprendre, et cette action-la existe deja
 *       ({@code PlanDomainAssessmentDto}) ;</li>
 *   <li>le candidat n'a <b>aucune ligne d'historique</b> dessus. Une competence
 *       ne portant que des {@code NOT_OBSERVED} en est donc <b>exclue</b> : il a
 *       bien produit, c'est notre mesure qui a echoue — ce cas se traite par une
 *       evaluation ({@code PlanActionNature.A_EVALUER}), pas en lui proposant
 *       d'apprendre ce qu'il vient peut-etre de faire.</li>
 * </ol>
 *
 * <h2>L'ordre</h2>
 * Par <b>urgence du domaine</b> ({@link PlanDomainPriority}, l'ordre que le
 * serveur a deja decide pour les quatre lignes du profil), puis par l'ordre des
 * epreuves du TCF, puis par tache et rang d'affichage — l'ordre editorial du
 * referentiel. Deterministe de bout en bout : deux lectures rendent la meme
 * liste. On ne reinvente pas une urgence : {@link PlanCycleResolver} l'a deja
 * calculee, et deux classements auraient fini par se contredire a l'ecran.
 *
 * <h2>Cout</h2>
 * <b>Une requete</b>, quel que soit le nombre de competences et de paliers : les
 * competences du ou des paliers concernes sont chargees en un lot. Tout le reste
 * se decide sur des donnees deja en memoire (les domaines resolus par le cycle,
 * l'historique deja charge par le Plan).
 */
@Component
@RequiredArgsConstructor
public class PlanAcquisitionSelector {

    private final SkillManager skillManager;

    /**
     * Les competences a acquerir, deja ordonnees, au plus {@code limite}.
     *
     * @param cycle           le cycle de palier, tel que {@link PlanCycleResolver}
     *                        l'a resolu : c'est lui qui porte le palier en
     *                        construction. {@code null} ou sans palier &rarr;
     *                        rien a acquerir.
     * @param domaines        les quatre domaines, deja resolus : ils portent
     *                        l'urgence, l'etat « mesure ou non » et le palier
     *                        bloquant de la comprehension.
     * @param dejaTravaillees identifiants des competences sur lesquelles le
     *                        candidat a <b>au moins une ligne d'historique</b>,
     *                        {@code NOT_OBSERVED} comprise
     *                        ({@code LearningPlanPriorityResolver.lastActivityBySkill}).
     * @param limite          nombre maximal de competences rendues ; {@code <= 0}
     *                        rend une liste vide sans emettre de requete.
     */
    public List<Skill> select(
            PlanCycleDto cycle,
            List<PlanDomainDto> domaines,
            Set<UUID> dejaTravaillees,
            int limite) {
        if (limite <= 0 || cycle == null || cycle.targetLevel() == null) return List.of();
        if (domaines == null || domaines.isEmpty()) return List.of();

        Map<SkillSection, PlanDomainDto> parSection = new EnumMap<>(SkillSection.class);
        for (PlanDomainDto domaine : domaines) {
            if (domaine == null) continue;
            SkillSection section = section(domaine.epreuve());
            if (section != null) parSection.putIfAbsent(section, domaine);
        }

        // Les paliers a charger : celui du cycle pour l'expression, et le palier
        // BLOQUANT de chaque domaine de comprehension deja mesure — la
        // comprehension a une chaine de prerequis (A2 solide avant B1), et le
        // palier global du cycle peut la depasser.
        Set<String> paliers = new LinkedHashSet<>();
        paliers.add(cycle.targetLevel().name());
        for (Map.Entry<SkillSection, PlanDomainDto> entry : parSection.entrySet()) {
            if (!entry.getKey().isComprehension()) continue;
            PlanDomainDto domaine = entry.getValue();
            if (!acquerable(domaine) || domaine.blockingLevel() == null) continue;
            paliers.add(domaine.blockingLevel().name());
        }

        List<Skill> candidates = new ArrayList<>();
        for (Skill skill : skillManager.findActiveByTargetLevels(paliers)) {
            SkillSection section = skill.getSection();
            if (section == null) continue;
            PlanDomainDto domaine = parSection.get(section);
            if (domaine == null || !acquerable(domaine)) continue;
            if (dejaTravaillees != null && dejaTravaillees.contains(skill.getId())) continue;
            if (!palierAttendu(skill, section, domaine, cycle.targetLevel())) continue;
            candidates.add(skill);
        }

        candidates.sort(Comparator
                .comparingInt((Skill skill) -> urgence(parSection.get(skill.getSection())))
                .thenComparingInt(skill -> ordreEpreuve(skill.getSection()))
                .thenComparingInt(PlanAcquisitionSelector::ordreTache)
                .thenComparingInt(Skill::getDisplayOrder));
        return List.copyOf(candidates.subList(0, Math.min(limite, candidates.size())));
    }

    /**
     * Un domaine <b>jamais mesure</b> ne s'apprend pas encore : il se mesure. La
     * porte existe deja ({@code LearningPlanDto.domainesAEvaluer}) ; en ouvrir
     * une seconde ferait dire deux choses differentes au meme ecran.
     */
    private static boolean acquerable(PlanDomainDto domaine) {
        return domaine.evaluated() && domaine.priority() != PlanDomainPriority.A_EVALUER;
    }

    /**
     * Le palier attendu de cette competence : le palier bloquant de son domaine
     * en comprehension (progression sequentielle), celui du cycle en expression.
     */
    private static boolean palierAttendu(
            Skill skill, SkillSection section, PlanDomainDto domaine, TargetLevel duCycle) {
        TargetLevel attendu = section.isComprehension() ? domaine.blockingLevel() : duCycle;
        return attendu != null && attendu.name().equals(skill.getTargetLevel());
    }

    /** L'urgence deja decidee par le serveur pour ce domaine ; inconnu = en dernier. */
    private static int urgence(PlanDomainDto domaine) {
        return domaine == null || domaine.priority() == null
                ? PlanDomainPriority.values().length : domaine.priority().ordinal();
    }

    private static int ordreEpreuve(SkillSection section) {
        EpreuveType epreuve = epreuve(section);
        int rang = epreuve == null ? -1 : TcfDomainProfileDto.ORDRE.indexOf(epreuve);
        return rang < 0 ? TcfDomainProfileDto.ORDRE.size() : rang;
    }

    /** La comprehension n'a pas de tache : elle passe avant, a domaine egal. */
    private static int ordreTache(Skill skill) {
        SkillTaskCode code = skill.getTaskCode();
        return code == null ? -1 : code.ordinal();
    }

    private static SkillSection section(EpreuveType epreuve) {
        if (epreuve == null) return null;
        return switch (epreuve) {
            case TCF_CO -> SkillSection.CO;
            case TCF_CE -> SkillSection.CE;
            case TCF_EO -> SkillSection.EO;
            case TCF_EE -> SkillSection.EE;
            default -> null;
        };
    }

    private static EpreuveType epreuve(SkillSection section) {
        if (section == null) return null;
        return switch (section) {
            case CO -> EpreuveType.TCF_CO;
            case CE -> EpreuveType.TCF_CE;
            case EO -> EpreuveType.TCF_EO;
            case EE -> EpreuveType.TCF_EE;
        };
    }
}

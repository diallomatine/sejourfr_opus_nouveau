package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanDomainDto;
import com.sejourfr.app.dto.PlanDomainSkillDto;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.PlanActionNature;
import com.sejourfr.app.enums.PlanDomainPriority;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le rangement des competences par epreuve : il ne <b>decide</b> rien, il range
 * ce que les autorites du Plan ont deja decide. Ces tests verrouillent donc ce
 * qu'il ne doit <b>pas</b> faire — inventer un etat, une date ou une action.
 */
class PlanDomainSkillResolverTest {

    private final PlanDomainSkillResolver resolver = new PlanDomainSkillResolver();

    @Test
    @DisplayName("Sans rien d'observe : NOT_OBSERVED partout, et aucune nature fabriquee")
    void sansObservationRienNEstAffirme() {
        Skill skill = expression("EE1-C1", SkillTaskCode.EE1, "A2", 1);

        PlanDomainSkillDto rendu = premiere(resolver.attach(
                List.of(domaine(EpreuveType.TCF_EE)), List.of(skill),
                Map.of(), Map.of(), Map.of(), SkillAccessService.SkillAccess.UNLIMITED));

        assertThat(rendu.status()).isEqualTo(LearningPlanSkillStatus.NOT_OBSERVED);
        assertThat(rendu.masteryState()).isNull();
        assertThat(rendu.observedAt()).isNull();
        assertThat(rendu.nature()).isNull();
        assertThat(rendu.taskCode()).isEqualTo(SkillTaskCode.EE1);
        assertThat(rendu.tacheNumero()).isEqualTo((short) 1);
        assertThat(rendu.targetLevel()).isEqualTo(TargetLevel.A2);
        assertThat(rendu.locked()).isFalse();
    }

    /**
     * 🛑 Les quatre valeurs de {@code LearningPlanSkillStatus} sont exhaustives et
     * disjointes : la somme des trois compteurs vaut donc <b>toujours</b> la
     * taille de la liste. C'est cette egalite qui rend un « + N autres » vrai.
     */
    @Test
    @DisplayName("Les trois compteurs somment toujours a la taille de la liste")
    void lesTroisCompteursSomment() {
        Skill fragile = expression("EE1-C1", SkillTaskCode.EE1, "A2", 1);
        Skill priorite = expression("EE1-C2", SkillTaskCode.EE1, "A2", 2);
        Skill solide = expression("EE1-C3", SkillTaskCode.EE1, "A2", 3);
        Skill inconnue = expression("EE1-C4", SkillTaskCode.EE1, "A2", 4);

        PlanDomainDto domaine = resolver.attach(
                List.of(domaine(EpreuveType.TCF_EE)),
                List.of(fragile, priorite, solide, inconnue),
                Map.of(fragile.getId(), observation(fragile, LearningPlanSkillStatus.TO_REINFORCE),
                        priorite.getId(), observation(priorite, LearningPlanSkillStatus.PRIORITY),
                        solide.getId(), observation(solide, LearningPlanSkillStatus.SOLID)),
                Map.of(), Map.of(), SkillAccessService.SkillAccess.UNLIMITED).getFirst();

        assertThat(domaine.fragileSkillCount()).isEqualTo(2);
        assertThat(domaine.solidSkillCount()).isEqualTo(1);
        assertThat(domaine.notObservedSkillCount()).isEqualTo(1);
        assertThat(domaine.fragileSkillCount()
                + domaine.solidSkillCount()
                + domaine.notObservedSkillCount())
                .isEqualTo(domaine.skills().size());
    }

    /**
     * L'etat agrege n'est lu que si une observation <b>probante</b> existe : une
     * competence qui n'a que des lignes {@code NOT_OBSERVED} ne doit pas afficher
     * un etat a cote d'un statut « jamais observee ».
     */
    @Test
    @DisplayName("Sans observation probante, aucun etat de maitrise n'est affiche")
    void aucunEtatSansObservationProbante() {
        Skill skill = expression("EE1-C1", SkillTaskCode.EE1, "A2", 1);

        PlanDomainSkillDto rendu = premiere(resolver.attach(
                List.of(domaine(EpreuveType.TCF_EE)), List.of(skill), Map.of(),
                Map.of(skill.getId(), new SkillMasteryEngine.SkillMastery(
                        SkillMasteryState.SOLID, 0, 0, 0, 0, 0, false, false, false, null)),
                Map.of(), SkillAccessService.SkillAccess.UNLIMITED));

        assertThat(rendu.status()).isEqualTo(LearningPlanSkillStatus.NOT_OBSERVED);
        assertThat(rendu.masteryState()).isNull();
    }

    @Test
    @DisplayName("La nature vient des cartes du Plan, jamais d'un recalcul")
    void laNatureVientDesCartes() {
        Skill acquise = expression("EE1-C1", SkillTaskCode.EE1, "A2", 1);
        Skill muette = expression("EE1-C2", SkillTaskCode.EE1, "A2", 2);

        List<PlanDomainSkillDto> skills = resolver.attach(
                List.of(domaine(EpreuveType.TCF_EE)), List.of(acquise, muette),
                Map.of(), Map.of(), Map.of(acquise.getId(), PlanActionNature.A_ACQUERIR),
                SkillAccessService.SkillAccess.UNLIMITED).getFirst().skills();

        assertThat(skills.getFirst().nature()).isEqualTo(PlanActionNature.A_ACQUERIR);
        assertThat(skills.get(1).nature()).isNull();
    }

    @Test
    @DisplayName("La comprehension se lit A2 puis B1 puis B2, sans tache ni numero")
    void laComprehensionEstOrdonneeParPalier() {
        Skill b2 = comprehension("CO-B2", TargetLevel.B2, 3);
        Skill a2 = comprehension("CO-A2", TargetLevel.A2, 1);
        Skill b1 = comprehension("CO-B1", TargetLevel.B1, 2);

        List<PlanDomainSkillDto> skills = resolver.attach(
                List.of(domaine(EpreuveType.TCF_CO)), List.of(b2, a2, b1),
                Map.of(), Map.of(), Map.of(),
                SkillAccessService.SkillAccess.UNLIMITED).getFirst().skills();

        assertThat(skills).extracting(PlanDomainSkillDto::skillCode)
                .containsExactly("CO-A2", "CO-B1", "CO-B2");
        assertThat(skills).allSatisfy(skill -> {
            assertThat(skill.taskCode()).isNull();
            assertThat(skill.tacheNumero()).isNull();
        });
    }

    @Test
    @DisplayName("Le cadenas est celui du service d'acces, jamais une seconde regle")
    void leCadenasVientDuServiceDAcces() {
        Skill ouverte = expression("EE1-C1", SkillTaskCode.EE1, "A2", 1);
        Skill fermee = expression("EE1-C2", SkillTaskCode.EE1, "A2", 2);

        List<PlanDomainSkillDto> skills = resolver.attach(
                List.of(domaine(EpreuveType.TCF_EE)), List.of(ouverte, fermee),
                Map.of(), Map.of(), Map.of(),
                new SkillAccessService.SkillAccess(
                        false, Set.of(ouverte.getId()), Set.of())).getFirst().skills();

        assertThat(skills.getFirst().locked()).isFalse();
        assertThat(skills.get(1).locked()).isTrue();
    }

    // ------------------------------------------------------------------------
    // Fabriques
    // ------------------------------------------------------------------------

    private static PlanDomainSkillDto premiere(List<PlanDomainDto> domaines) {
        return domaines.getFirst().skills().getFirst();
    }

    private static PlanDomainDto domaine(EpreuveType epreuve) {
        return PlanDomainDto.sansCompetences(epreuve, true, null,
                PlanDomainPriority.A_TRAVAILLER, null, null, List.of(), List.of());
    }

    private static Skill expression(String code, SkillTaskCode tache, String palier, int rang) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setTitle("Compétence " + code);
        skill.setTaskCode(tache);
        skill.setSection(tache.getSection());
        skill.setTargetLevel(palier);
        skill.setDisplayOrder((short) rang);
        return skill;
    }

    private static Skill comprehension(String code, TargetLevel palier, int rang) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setTitle("Compétence " + code);
        skill.setSection(SkillSection.CO);
        skill.setTargetLevel(palier.name());
        skill.setDisplayOrder((short) rang);
        return skill;
    }

    private static LearningPlanObservation observation(Skill skill, LearningPlanSkillStatus status) {
        LearningPlanObservation observation = new LearningPlanObservation();
        observation.setSkill(skill);
        observation.setStatus(status);
        observation.setObservedAt(Instant.now());
        return observation;
    }
}

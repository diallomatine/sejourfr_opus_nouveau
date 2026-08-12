package com.sejourfr.app.service;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.manager.SkillPromptManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.access.AccessDeniedException;

import java.util.ArrayList;
import java.util.Collection;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * La regle d'acces du module Competences, telle qu'elle vaut depuis le
 * 2026-08-10 : la premiere competence de chaque tache et ses 2 premiers sujets,
 * plus la competence de la priorite n&deg;1 du Plan — et rien d'autre — pour un
 * compte sans acces TCF.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SkillAccessServiceTest {

    @Mock private SubscriptionService subscriptionService;
    @Mock private SkillManager skillManager;
    @Mock private SkillPromptManager promptManager;
    @Mock private LearningPlanPriorityResolver priorityResolver;

    private SkillAccessService service;

    private final UUID userId = UUID.randomUUID();

    /** Le catalogue de la tache EE1 : 8 competences de rang 1 a 8, 5 sujets chacune. */
    private final List<Skill> ee1 = new ArrayList<>();
    private final Map<UUID, List<SkillPrompt>> promptsBySkill = new LinkedHashMap<>();

    @BeforeEach
    void setUp() {
        service = new SkillAccessService(
                subscriptionService, skillManager, promptManager, priorityResolver);
        for (int rank = 1; rank <= 8; rank++) {
            Skill skill = skill(SkillTaskCode.EE1, rank);
            ee1.add(skill);
            List<SkillPrompt> prompts = new ArrayList<>();
            for (int order = 1; order <= 5; order++) {
                prompts.add(prompt(skill, order));
            }
            promptsBySkill.put(skill.getId(), prompts);
        }
        when(priorityResolver.currentPrioritySkillId(userId)).thenReturn(Optional.empty());
        when(skillManager.findFirstActiveIdPerTaskCode()).thenReturn(firstOfEachTask());
        when(promptManager.findActiveBySkillIds(anyCollection()))
                .thenAnswer(invocation -> {
                    Collection<UUID> ids = invocation.getArgument(0);
                    Map<UUID, List<SkillPrompt>> out = new LinkedHashMap<>();
                    for (UUID id : ids) {
                        out.put(id, promptsBySkill.getOrDefault(id, List.of()));
                    }
                    return out;
                });
    }

    // ------------------------------------------------------------------------
    // Abonne TCF
    // ------------------------------------------------------------------------

    @Test
    void unAbonneTcfNaAucunVerrouEtNeCouteAucuneRequeteDePlus() {
        when(subscriptionService.hasTcf(userId)).thenReturn(true);

        SkillAccessService.SkillAccess access = service.resolve(userId);

        assertThat(access.unlimited()).isTrue();
        for (Skill skill : ee1) {
            assertThat(access.isSkillLocked(skill.getId())).isFalse();
            for (SkillPrompt prompt : promptsBySkill.get(skill.getId())) {
                assertThat(access.isPromptLocked(prompt.getId())).isFalse();
            }
        }
        // Le court-circuit est la raison d'etre du drapeau : rien d'autre n'est lu.
        verify(skillManager, never()).findFirstActiveIdPerTaskCode();
        verify(promptManager, never()).findActiveBySkillIds(any());
        verify(priorityResolver, never()).currentPrioritySkillId(any());
    }

    // ------------------------------------------------------------------------
    // Compte gratuit
    // ------------------------------------------------------------------------

    @Test
    void sansAccesTcfSeuleLaPremiereCompetenceDeChaqueTacheEstOuverte() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        SkillAccessService.SkillAccess access = service.resolve(userId);

        assertThat(access.unlimited()).isFalse();
        assertThat(access.isSkillLocked(ee1.get(0).getId())).isFalse();
        assertThat(access.isSkillLocked(ee1.get(1).getId())).isTrue();
        assertThat(access.isSkillLocked(ee1.get(7).getId())).isTrue();
        // Une par tache, pas une de plus : 6 taches = 6 competences ouvertes.
        assertThat(access.openSkillIds()).hasSize(SkillTaskCode.values().length);
    }

    @Test
    void dansUneCompetenceOuverteSeulsLesDeuxPremiersSujetsLeSont() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        SkillAccessService.SkillAccess access = service.resolve(userId);

        List<SkillPrompt> prompts = promptsBySkill.get(ee1.get(0).getId());
        assertThat(access.isPromptLocked(prompts.get(0).getId())).isFalse();
        assertThat(access.isPromptLocked(prompts.get(1).getId())).isFalse();
        assertThat(access.isPromptLocked(prompts.get(2).getId())).isTrue();
        assertThat(access.isPromptLocked(prompts.get(3).getId())).isTrue();
        assertThat(access.isPromptLocked(prompts.get(4).getId())).isTrue();
    }

    @Test
    void lesSujetsDUneCompetenceVerrouilleeLeSontTous() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        SkillAccessService.SkillAccess access = service.resolve(userId);

        assertThat(promptsBySkill.get(ee1.get(4).getId()))
                .allSatisfy(prompt -> assertThat(access.isPromptLocked(prompt.getId())).isTrue());
    }

    /**
     * Le cas qui justifie l'exception : un diagnostic peut designer une
     * competence de rang 5. Cadenassee, l'etape n&deg;1 du Plan serait
     * inatteignable et le Plan entier deviendrait inutilisable.
     */
    @Test
    void laCompetenceDeLaPrioriteNumeroUnEstOuverteMemeAuRangCinq() {
        Skill priorite = ee1.get(4);
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(priorityResolver.currentPrioritySkillId(userId))
                .thenReturn(Optional.of(priorite.getId()));

        SkillAccessService.SkillAccess access = service.resolve(userId);

        assertThat(access.isSkillLocked(priorite.getId())).isFalse();
        assertThat(access.isSkillLocked(ee1.get(0).getId())).isFalse();
        assertThat(access.isSkillLocked(ee1.get(1).getId())).isTrue();
        // Elle s'ouvre comme les autres : ses 2 premiers sujets, pas les 5.
        List<SkillPrompt> prompts = promptsBySkill.get(priorite.getId());
        assertThat(access.isPromptLocked(prompts.get(1).getId())).isFalse();
        assertThat(access.isPromptLocked(prompts.get(2).getId())).isTrue();
        assertThat(access.openSkillIds()).hasSize(SkillTaskCode.values().length + 1);
    }

    @Test
    void unePrioriteDejaDansLeLotOuvertNAjouteRien() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(priorityResolver.currentPrioritySkillId(userId))
                .thenReturn(Optional.of(ee1.get(0).getId()));

        assertThat(service.resolve(userId).openSkillIds())
                .hasSize(SkillTaskCode.values().length);
    }

    @Test
    void uneCompetenceOuverteSansSujetActifNOuvreAucunSujetEtNeCassePas() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        promptsBySkill.put(ee1.get(0).getId(), List.of());

        SkillAccessService.SkillAccess access = service.resolve(userId);

        assertThat(access.isSkillLocked(ee1.get(0).getId())).isFalse();
        assertThat(access.openPromptIds()).isEmpty();
    }

    // ------------------------------------------------------------------------
    // Verrou opposable
    // ------------------------------------------------------------------------

    @Test
    void produireSurUnSujetVerrouilleEstRefuseAvecUnMessageDePaywall() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        SkillPrompt verrouille = promptsBySkill.get(ee1.get(0).getId()).get(2);

        assertThatThrownBy(() -> service.assertCanProduce(userId, verrouille))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage(SkillAccessService.LOCKED_MESSAGE)
                .hasMessageContaining("accès TCF");
    }

    @Test
    void produireSurUnSujetOuvertPasse() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        service.assertCanProduce(userId, promptsBySkill.get(ee1.get(0).getId()).get(1));
    }

    // ------------------------------------------------------------------------
    // Fixtures
    // ------------------------------------------------------------------------

    /** Chaque tache a sa premiere competence ; seule EE1 porte un vrai catalogue. */
    private Map<SkillTaskCode, UUID> firstOfEachTask() {
        Map<SkillTaskCode, UUID> first = new EnumMap<>(SkillTaskCode.class);
        for (SkillTaskCode code : SkillTaskCode.values()) {
            first.put(code, code == SkillTaskCode.EE1
                    ? ee1.get(0).getId() : skill(code, 1).getId());
        }
        return first;
    }

    private static Skill skill(SkillTaskCode taskCode, int rank) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setSection(taskCode.getSection());
        skill.setTaskCode(taskCode);
        skill.setCode(taskCode + "-C" + rank);
        skill.setTitle("Compétence " + rank);
        skill.setDescription("Pourquoi cet exercice.");
        skill.setGeneralCriterion("Critère général.");
        skill.setTargetLevel(taskCode.getTargetLevel());
        skill.setDisplayOrder((short) rank);
        skill.setActive(true);
        return skill;
    }

    private static SkillPrompt prompt(Skill skill, int order) {
        SkillPrompt prompt = new SkillPrompt();
        prompt.setId(UUID.randomUUID());
        prompt.setSkill(skill);
        prompt.setSection(skill.getSection());
        prompt.setCode(skill.getCode() + "-S" + order);
        prompt.setTitle("Sujet " + order);
        prompt.setContext("Contexte.");
        prompt.setInstruction("Consigne.");
        prompt.setUniqueCriterion("Critère unique.");
        prompt.setDisplayOrder((short) order);
        prompt.setActive(true);
        return prompt;
    }
}

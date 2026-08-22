package com.sejourfr.app.service;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.enums.SkillSection;
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
 * plus la competence de la <b>premiere place du Plan</b> — et rien d'autre — pour
 * un compte sans acces TCF.
 *
 * <p>Depuis le 2026-08-21, cette premiere place peut etre une competence a
 * <b>acquerir</b> (jamais travaillee) : c'est {@link PlanFocusResolver} qui la
 * designe, et ce service l'ouvre <b>sans regarder sa nature</b>.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SkillAccessServiceTest {

    @Mock private SubscriptionService subscriptionService;
    @Mock private SkillManager skillManager;
    @Mock private SkillPromptManager promptManager;
    @Mock private PlanFocusResolver focusResolver;

    private SkillAccessService service;

    private final UUID userId = UUID.randomUUID();

    /** Le catalogue de la tache EE1 : 8 competences de rang 1 a 8, 5 sujets chacune. */
    private final List<Skill> ee1 = new ArrayList<>();
    private final Map<UUID, List<SkillPrompt>> promptsBySkill = new LinkedHashMap<>();

    /** Les 3 niveaux de la comprehension orale : A2 (rang 1), B1, B2. */
    private final List<Skill> co = new ArrayList<>();
    /** Les 3 niveaux de la comprehension ecrite. */
    private final List<Skill> ce = new ArrayList<>();

    @BeforeEach
    void setUp() {
        service = new SkillAccessService(
                subscriptionService, skillManager, promptManager, focusResolver);
        for (int rank = 1; rank <= 8; rank++) {
            Skill skill = skill(SkillTaskCode.EE1, rank);
            ee1.add(skill);
            List<SkillPrompt> prompts = new ArrayList<>();
            for (int order = 1; order <= 5; order++) {
                prompts.add(prompt(skill, order));
            }
            promptsBySkill.put(skill.getId(), prompts);
        }
        String[] niveaux = {"A2", "B1", "B2"};
        for (int rank = 1; rank <= 3; rank++) {
            co.add(comprehensionSkill(SkillSection.CO, rank, niveaux[rank - 1]));
            ce.add(comprehensionSkill(SkillSection.CE, rank, niveaux[rank - 1]));
        }
        when(focusResolver.currentFocusSkillId(userId)).thenReturn(Optional.empty());
        when(skillManager.findFirstActiveIdPerTaskCode()).thenReturn(firstOfEachTask());
        when(skillManager.findFirstActiveIdPerComprehensionSection())
                .thenReturn(firstOfEachComprehensionDomain());
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
        verify(skillManager, never()).findFirstActiveIdPerComprehensionSection();
        verify(promptManager, never()).findActiveBySkillIds(any());
        verify(focusResolver, never()).currentFocusSkillId(any());
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
        // Une par tache, pas une de plus : 6 taches = 6 competences ouvertes,
        // plus le A2 de chacun des 2 domaines de comprehension.
        assertThat(access.openSkillIds()).hasSize(SkillTaskCode.values().length + 2);
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
        when(focusResolver.currentFocusSkillId(userId))
                .thenReturn(Optional.of(priorite.getId()));

        SkillAccessService.SkillAccess access = service.resolve(userId);

        assertThat(access.isSkillLocked(priorite.getId())).isFalse();
        assertThat(access.isSkillLocked(ee1.get(0).getId())).isFalse();
        assertThat(access.isSkillLocked(ee1.get(1).getId())).isTrue();
        // Elle s'ouvre comme les autres : ses 2 premiers sujets, pas les 5.
        List<SkillPrompt> prompts = promptsBySkill.get(priorite.getId());
        assertThat(access.isPromptLocked(prompts.get(1).getId())).isFalse();
        assertThat(access.isPromptLocked(prompts.get(2).getId())).isTrue();
        assertThat(access.openSkillIds()).hasSize(SkillTaskCode.values().length + 2 + 1);
    }

    /**
     * 🛑 <b>Le defaut corrige le 2026-08-21.</b> La premiere place du Plan peut
     * etre une competence « a acquerir » : jamais travaillee, donc <b>sans
     * aucune ligne d'historique</b>, donc invisible pour l'ancien
     * {@code currentPrioritySkillId}. Elle etait designee, visible… et
     * verrouillee.
     *
     * <p>Ce service n'a pas a savoir de quelle nature elle est : il ouvre
     * <b>la competence que {@link PlanFocusResolver} designe</b>, point. C'est
     * ce que le proprietaire a arbitre : « un candidat non abonne pourra
     * travailler sa priorite 1, vu qu'elle est visible ».
     */
    @Test
    void laCompetenceAAcquerirEnPremierePlaceEstOuverteCommeUneAutre() {
        Skill aAcquerir = ee1.get(6);
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(focusResolver.currentFocusSkillId(userId))
                .thenReturn(Optional.of(aAcquerir.getId()));

        SkillAccessService.SkillAccess access = service.resolve(userId);

        assertThat(access.isSkillLocked(aAcquerir.getId())).isFalse();
        // Elle s'ouvre comme les autres : 2 sujets, et rien de plus alentour.
        List<SkillPrompt> prompts = promptsBySkill.get(aAcquerir.getId());
        assertThat(access.isPromptLocked(prompts.get(1).getId())).isFalse();
        assertThat(access.isPromptLocked(prompts.get(2).getId())).isTrue();
        assertThat(access.isSkillLocked(ee1.get(5).getId())).isTrue();
        // Et le verrou serveur suit, c'est tout l'interet.
        service.assertCanProduce(userId, prompts.get(0));
        service.assertCanTrain(userId, aAcquerir.getId());
    }

    /**
     * L'appelant qui vient d'etablir la premiere place la passe : le Plan, qui la
     * connait deja. Elle est ouverte a l'identique, et le resolveur n'est
     * <b>pas</b> reinterroge — sinon le cycle de palier tournerait deux fois par
     * lecture du Plan.
     */
    @Test
    void lorsqueLAppelantConnaitDejaLaPremierePlaceElleNEstPasRecalculee() {
        Skill focus = ee1.get(4);
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        SkillAccessService.SkillAccess access = service.resolve(userId, focus.getId());

        assertThat(access.isSkillLocked(focus.getId())).isFalse();
        assertThat(access.isSkillLocked(ee1.get(1).getId())).isTrue();
        verify(focusResolver, never()).currentFocusSkillId(any());
    }

    /** Aucune premiere place : le lot ouvert est celui des rangs 1, rien de plus. */
    @Test
    void sansPremierePlaceLeLotOuvertResteCeluiDesRangsUn() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        assertThat(service.resolve(userId, null).openSkillIds())
                .hasSize(SkillTaskCode.values().length + 2);
    }

    @Test
    void unePrioriteDejaDansLeLotOuvertNAjouteRien() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(focusResolver.currentFocusSkillId(userId))
                .thenReturn(Optional.of(ee1.get(0).getId()));

        assertThat(service.resolve(userId).openSkillIds())
                .hasSize(SkillTaskCode.values().length + 2);
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
    // Comprehension (CO / CE) — ni tache, ni sujet : le verrou porte le NIVEAU
    // ------------------------------------------------------------------------

    /**
     * La regle retenue : l'entree de gamme de chaque domaine est ouverte, B1 et
     * B2 sont verrouilles. C'est le pendant exact de « la premiere competence de
     * chaque tache » la ou il n'existe ni tache ni petit sujet.
     */
    @Test
    void sansAccesTcfSeulLeNiveauLePlusBasDeChaqueDomaineDeComprehensionEstOuvert() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        SkillAccessService.SkillAccess access = service.resolve(userId);

        assertThat(access.isSkillLocked(co.get(0).getId())).isFalse();
        assertThat(access.isSkillLocked(co.get(1).getId())).isTrue();
        assertThat(access.isSkillLocked(co.get(2).getId())).isTrue();
        assertThat(access.isSkillLocked(ce.get(0).getId())).isFalse();
        assertThat(access.isSkillLocked(ce.get(1).getId())).isTrue();
        assertThat(access.isSkillLocked(ce.get(2).getId())).isTrue();
    }

    /**
     * Une competence de comprehension n'a AUCUN petit sujet : ouvrir son niveau
     * A2 ne doit donc ouvrir aucun sujet, et surtout ne pas faire de requete de
     * sujets a son propos. Le compteur de sujets ouverts reste celui de
     * l'expression.
     */
    @Test
    void ouvrirUnDomaineDeComprehensionNOuvreAucunPetitSujet() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        SkillAccessService.SkillAccess access = service.resolve(userId);

        // Seule EE1 porte un catalogue de sujets dans cette fabrique : les
        // sujets ouverts sont donc ses 2 premiers, et la comprehension — qui
        // ouvre pourtant 2 competences de plus — n'en ajoute aucun.
        assertThat(access.openPromptIds())
                .hasSize(SkillAccessService.FREE_PROMPTS_PER_SKILL)
                .containsExactlyInAnyOrder(
                        promptsBySkill.get(ee1.get(0).getId()).get(0).getId(),
                        promptsBySkill.get(ee1.get(0).getId()).get(1).getId());
    }

    /**
     * Le B2 d'un domaine reste inatteignable tant que le compte est gratuit,
     * <b>sauf</b> si le Plan en fait sa priorite n&deg;1 — meme exception que
     * pour une competence d'expression de rang 5, et pour la meme raison : un
     * Plan dont l'etape 1 est cadenassee n'a plus d'usage.
     */
    @Test
    void laPrioriteDuPlanOuvreAussiUneCompetenceDeComprehension() {
        Skill priorite = co.get(2);
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        when(focusResolver.currentFocusSkillId(userId))
                .thenReturn(Optional.of(priorite.getId()));

        SkillAccessService.SkillAccess access = service.resolve(userId);

        assertThat(access.isSkillLocked(priorite.getId())).isFalse();
        assertThat(access.isSkillLocked(co.get(1).getId())).isTrue();
    }

    @Test
    void unAbonneTcfNaAucunVerrouSurLaComprehension() {
        when(subscriptionService.hasTcf(userId)).thenReturn(true);

        SkillAccessService.SkillAccess access = service.resolve(userId);

        assertThat(access.isSkillLocked(co.get(2).getId())).isFalse();
        assertThat(access.isSkillLocked(ce.get(2).getId())).isFalse();
    }

    /**
     * Le verrou est <b>opposable au grain de la competence</b> : la
     * comprehension n'ayant pas de sujet, {@code assertCanProduce} n'a rien a
     * mordre et le refus doit exister a ce niveau-la.
     */
    @Test
    void travaillerUneCompetenceDeComprehensionVerrouilleeEstRefuse() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        assertThatThrownBy(() -> service.assertCanTrain(userId, co.get(2).getId()))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage(SkillAccessService.LOCKED_SKILL_MESSAGE)
                .hasMessageContaining("accès TCF");
    }

    @Test
    void travaillerLeNiveauOuvertDUnDomainePasse() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        service.assertCanTrain(userId, co.get(0).getId());
        service.assertCanTrain(userId, ce.get(0).getId());
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

    /** Le rang le plus bas de chaque domaine, tel que le rendrait la requete. */
    private Map<SkillSection, UUID> firstOfEachComprehensionDomain() {
        Map<SkillSection, UUID> first = new EnumMap<>(SkillSection.class);
        first.put(SkillSection.CO, co.get(0).getId());
        first.put(SkillSection.CE, ce.get(0).getId());
        return first;
    }

    /** Competence de comprehension : pas de tache, pas de sujet. */
    private static Skill comprehensionSkill(SkillSection section, int rank, String level) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setSection(section);
        skill.setTaskCode(null);
        skill.setCode(section + "-" + level);
        skill.setTitle("Compétence " + section + " " + level);
        skill.setDescription("Pourquoi cet exercice.");
        skill.setGeneralCriterion("Critère général.");
        skill.setTargetLevel(level);
        skill.setDisplayOrder((short) rank);
        skill.setActive(true);
        return skill;
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

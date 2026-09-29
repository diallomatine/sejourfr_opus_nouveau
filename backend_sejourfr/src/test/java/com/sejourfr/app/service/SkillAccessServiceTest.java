package com.sejourfr.app.service;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.access.AccessDeniedException;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

/**
 * <b>Travailler une competence est PREMIUM, sans exception</b> — arbitrage
 * <b>D-18</b> du 2026-09-18.
 *
 * <h2>Ce que ce test verrouille, et ce qu'il a cesse de verifier</h2>
 * <p>Il verifiait quatre ouvertures d'office accordees a un compte gratuit :
 * la premiere competence de chaque tache, ses 2 premiers sujets, le rang le plus
 * bas de chaque domaine de comprehension, et <b>la competence de la premiere
 * place du Plan</b>. D-18 les <b>revoque toutes</b>, ainsi que l'exemption du
 * 2026-08-21 qui les justifiait :
 * <blockquote>« un candidat non abonne pourra travailler sa priorite 1, vu
 * qu'elle est visible »</blockquote>
 *
 * <p>🛑 <b>Ce qui n'est PAS rouvert</b> : la contradiction #1 du depot. Ce
 * service pose un {@code locked}, il ne masque <b>aucune</b> donnee — le Plan,
 * les priorites, les niveaux mesures et les compteurs restent servis. C'est
 * l'<b>execution</b> qui se ferme, et {@code LearningPlanServiceTest} +
 * {@code JourneyReadServiceTest} verrouillent ce point de leur cote.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SkillAccessServiceTest {

    @Mock private SubscriptionService subscriptionService;

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
        service = new SkillAccessService(subscriptionService);
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
    }

    // ------------------------------------------------------------------------
    // Abonne TCF
    // ------------------------------------------------------------------------

    @Test
    void unAbonneTcfNaAucunVerrou() {
        when(subscriptionService.hasTcf(userId)).thenReturn(true);

        SkillAccessService.SkillAccess access = service.resolve(userId);

        assertThat(access.unlimited()).isTrue();
        for (Skill skill : ee1) {
            assertThat(access.isSkillLocked(skill.getId())).isFalse();
            for (SkillPrompt prompt : promptsBySkill.get(skill.getId())) {
                assertThat(access.isPromptLocked(prompt.getId())).isFalse();
            }
        }
        assertThat(access.isSkillLocked(co.get(2).getId())).isFalse();
        assertThat(access.isSkillLocked(ce.get(2).getId())).isFalse();
    }

    // ------------------------------------------------------------------------
    // D-18 — compte gratuit : plus rien d'ouvert
    // ------------------------------------------------------------------------

    /**
     * D-18 — la premiere competence de chaque tache <b>n'est plus ouverte</b>,
     * et ses 2 premiers sujets non plus
     * ({@code FREE_PROMPTS_PER_SKILL = 2}, supprime).
     */
    @Test
    void sansAccesTcfAucuneCompetenceDExpressionNEstOuverte_D18() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        SkillAccessService.SkillAccess access = service.resolve(userId);

        assertThat(access.unlimited()).isFalse();
        assertThat(access.openSkillIds()).isEmpty();
        assertThat(access.openPromptIds()).isEmpty();
        for (Skill skill : ee1) {
            assertThat(access.isSkillLocked(skill.getId())).isTrue();
            for (SkillPrompt prompt : promptsBySkill.get(skill.getId())) {
                assertThat(access.isPromptLocked(prompt.getId())).isTrue();
            }
        }
    }

    /**
     * D-18 — « les rangs CO/CE sont traites dans la meme passe, coherents avec
     * la meme regle » : le A2 de chaque domaine <b>n'est plus ouvert</b> non
     * plus. D-18 ne connait pas de domaine d'exception.
     */
    @Test
    void sansAccesTcfAucunNiveauDeComprehensionNEstOuvert_D18() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        SkillAccessService.SkillAccess access = service.resolve(userId);

        for (Skill niveau : co) {
            assertThat(access.isSkillLocked(niveau.getId())).isTrue();
        }
        for (Skill niveau : ce) {
            assertThat(access.isSkillLocked(niveau.getId())).isTrue();
        }
    }

    /**
     * 🛑 <b>L'exemption du 2026-08-21 est REVOQUEE</b> : la competence de la
     * premiere place du Plan n'est plus ouverte d'office, quelle que soit sa
     * nature — fragilite observee comme acquisition jamais travaillee. Et le
     * resolveur de premiere place n'est plus un collaborateur de ce service : il
     * n'y a plus rien a lui demander.
     */
    @Test
    void laPremierePlaceDuPlanNOuvrePlusRien_D18() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        Skill prioriteUn = ee1.get(4);

        SkillAccessService.SkillAccess access = service.resolve(userId);

        assertThat(access.isSkillLocked(prioriteUn.getId())).isTrue();
        assertThat(access.isPromptLocked(
                promptsBySkill.get(prioriteUn.getId()).get(0).getId())).isTrue();
    }

    // ------------------------------------------------------------------------
    // Verrou opposable — un 403 affichable, aux deux grains
    // ------------------------------------------------------------------------

    @Test
    void produireSurUnSujetEstRefuseAvecUnMessageDePaywall() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);
        SkillPrompt sujet = promptsBySkill.get(ee1.get(0).getId()).get(0);

        assertThatThrownBy(() -> service.assertCanProduce(userId, sujet))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage(SkillAccessService.LOCKED_MESSAGE)
                .hasMessageContaining("accès TCF");
    }

    /**
     * Le verrou existe aussi au grain de la <b>competence</b> : la comprehension
     * n'a pas de petit sujet, {@code assertCanProduce} n'aurait rien a mordre.
     */
    @Test
    void travaillerUneCompetenceDeComprehensionEstRefuse() {
        when(subscriptionService.hasTcf(userId)).thenReturn(false);

        assertThatThrownBy(() -> service.assertCanTrain(userId, co.get(0).getId()))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage(SkillAccessService.LOCKED_SKILL_MESSAGE)
                .hasMessageContaining("accès TCF");
    }

    @Test
    void unAbonneTcfProduitEtSEntrainePartout() {
        when(subscriptionService.hasTcf(userId)).thenReturn(true);

        service.assertCanProduce(userId, promptsBySkill.get(ee1.get(7).getId()).get(4));
        service.assertCanTrain(userId, co.get(2).getId());
        service.assertCanTrain(userId, ce.get(2).getId());
    }

    // ------------------------------------------------------------------------
    // Fixtures
    // ------------------------------------------------------------------------

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

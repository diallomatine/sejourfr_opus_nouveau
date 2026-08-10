package com.sejourfr.app.controller;

import com.sejourfr.app.dto.SkillDto;
import com.sejourfr.app.dto.SkillPromptDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.manager.SkillPromptManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

import java.util.Comparator;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * {@code GET /api/skills} tel qu'il passe sur le fil, contre le VRAI catalogue
 * seede (6 taches x 8 competences).
 *
 * <p><b>Ce que ce test protege.</b> L'ecran candidat parcourt les 3 taches d'une
 * epreuve par des pastilles, sans changer d'ecran : le filtre {@code section}
 * existe pour lui servir les 24 competences en un seul appel, deja triees par
 * tache puis par rang. Un tri qui glisse ou un filtre qui laisse fuiter l'autre
 * epreuve casserait ce regroupement sans qu'aucun test de service ne bronche.
 *
 * <p><b>Sur les totaux exacts.</b> Le compte par epreuve (24) est fige par le
 * contenu publie, pas par ce test : aucune competence n'est creee ici, donc
 * l'assertion porte bien sur les seules lignes seedees. Les tests qui inserent
 * (progression) raisonnent, eux, sur la competence qu'ils ont ciblee.
 */
class SkillControllerIT extends AbstractIntegrationTest {

    /** Contenu publie : 8 competences actives par tache, 3 taches par epreuve. */
    private static final int SKILLS_PER_SECTION = 24;

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private ObjectMapper objectMapper;
    @Autowired
    private TestData testData;
    @Autowired
    private AuthTestSupport auth;
    @Autowired
    private SkillManager skillManager;
    @Autowired
    private SkillPromptManager promptManager;

    // ------------------------------------------------------------------------
    // Filtre par epreuve
    // ------------------------------------------------------------------------

    @Test
    void sectionFilterServesTheWholeExamSortedByTaskThenRank() throws Exception {
        List<SkillDto> skills = list(testData.user(), "?section=EE");

        assertThat(skills).hasSize(SKILLS_PER_SECTION);
        assertThat(skills).extracting(SkillDto::section).containsOnly(SkillSection.EE);
        assertThat(skills).extracting(SkillDto::taskCode)
                .doesNotContain(SkillTaskCode.EO1, SkillTaskCode.EO2, SkillTaskCode.EO3);

        // Le front regroupe par pastille : l'ordre doit etre EE1 x8, EE2 x8,
        // EE3 x8, et a l'interieur de chaque tache le rang pedagogique.
        assertThat(skills).isSortedAccordingTo(
                Comparator.comparing(SkillDto::taskCode).thenComparingInt(SkillDto::displayOrder));
        assertThat(skills.stream().filter(s -> s.taskCode() == SkillTaskCode.EE1)).hasSize(8);
        assertThat(skills.stream().filter(s -> s.taskCode() == SkillTaskCode.EE3)).hasSize(8);
    }

    @Test
    void theTwoSectionsNeverLeakIntoEachOther() throws Exception {
        User user = testData.user();

        assertThat(list(user, "?section=EO")).hasSize(SKILLS_PER_SECTION)
                .extracting(SkillDto::section).containsOnly(SkillSection.EO);
    }

    // ------------------------------------------------------------------------
    // Arbitrage des deux filtres
    // ------------------------------------------------------------------------

    @Test
    void withoutAnyFilterTheRouteIsRefused() throws Exception {
        // 422 et non 200 sur les 48 competences des deux epreuves : aucun ecran
        // ne consomme le catalogue entier.
        mockMvc.perform(get("/api/skills")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(testData.user())))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.message").value(
                        containsString("Précisez l'épreuve")));
    }

    @Test
    void contradictoryFiltersAreRefusedRatherThanSilentlyEmpty() throws Exception {
        // Une liste vide se lirait cote front comme « pas encore de contenu ».
        mockMvc.perform(get("/api/skills?section=EE&taskCode=EO2")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(testData.user())))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.message").value(
                        containsString("Filtres incompatibles")));
    }

    @Test
    void consistentFiltersAreEquivalentToTheTaskCodeAlone() throws Exception {
        User user = testData.user();

        List<SkillDto> both = list(user, "?section=EE&taskCode=EE2");
        List<SkillDto> taskOnly = list(user, "?taskCode=EE2");

        assertThat(both).hasSize(8).isEqualTo(taskOnly);
        assertThat(both).extracting(SkillDto::taskCode).containsOnly(SkillTaskCode.EE2);
    }

    // ------------------------------------------------------------------------
    // Progression : le piege de l'elargissement
    // ------------------------------------------------------------------------

    @Test
    void progressionStaysAttachedToItsOwnSkillWhenWideningToTheWholeExam() throws Exception {
        User user = testData.user();
        // Une competence SEEDEE, pour ne pas ajouter de 25e ligne a l'epreuve.
        Skill target = skillManager.findActiveByTaskCode(SkillTaskCode.EE2).getFirst();
        SkillPrompt prompt = promptManager.findActiveBySkillId(target.getId()).getFirst();
        testData.userSkillAttempt(user, prompt);

        List<SkillDto> wholeExam = list(user, "?section=EE");
        SkillDto touched = wholeExam.stream()
                .filter(s -> s.id().equals(target.getId())).findFirst().orElseThrow();

        assertThat(touched.attemptedCount()).isEqualTo(1);
        assertThat(touched.promptCount()).isEqualTo(15);
        // Le lot de tentatives couvre les 3 taches : aucune ne doit deborder
        // sur une competence voisine.
        assertThat(wholeExam).filteredOn(s -> !s.id().equals(target.getId()))
                .allMatch(s -> s.attemptedCount() == 0);
        // Et le perimetre elargi doit dire exactement la meme chose que le
        // perimetre d'une seule tache.
        assertThat(list(user, "?taskCode=EE2")).contains(touched);
    }

    @Test
    void progressionIsNominativeAndNeverLeaksBetweenCandidates() throws Exception {
        User producer = testData.user();
        User other = testData.user();
        Skill target = skillManager.findActiveByTaskCode(SkillTaskCode.EE1).getFirst();
        testData.userSkillAttempt(producer, promptManager.findActiveBySkillId(target.getId()).getFirst());

        assertThat(list(other, "?section=EE")).allMatch(s -> s.attemptedCount() == 0);
    }

    // ------------------------------------------------------------------------
    // Verrou freemium (2026-08-10) : ce qui est ouvert a un compte gratuit
    // ------------------------------------------------------------------------

    @Test
    void sansAccesTcfSeuleLaPremiereCompetenceDeChaqueTacheEstOuverte() throws Exception {
        List<SkillDto> skills = list(testData.user(), "?section=EE");

        // Une seule ouverte par tache, soit 3 sur les 24 de l'epreuve.
        assertThat(skills).filteredOn(skill -> !skill.locked())
                .hasSize(3)
                .allMatch(skill -> skill.displayOrder() == 1);
        assertThat(skills).filteredOn(skill -> skill.displayOrder() > 1)
                .isNotEmpty()
                .allMatch(SkillDto::locked);
    }

    @Test
    void unAbonneTcfNaAucuneCompetenceVerrouillee() throws Exception {
        User abonne = testData.user();
        testData.userSubscription(abonne, testData.plan());

        assertThat(list(abonne, "?section=EO")).isNotEmpty().allMatch(skill -> !skill.locked());
    }

    @Test
    void dansUneCompetenceOuverteLesDeuxPremiersSujetsLeSontEtPasLeTroisieme()
            throws Exception {
        User user = testData.user();
        Skill ouverte = skillManager.findActiveByTaskCode(SkillTaskCode.EE1).getFirst();
        List<SkillPrompt> prompts = promptManager.findActiveBySkillId(ouverte.getId());

        assertThat(locked(user, prompts.get(0))).isFalse();
        assertThat(locked(user, prompts.get(1))).isFalse();
        assertThat(locked(user, prompts.get(2))).isTrue();
    }

    @Test
    void tousLesSujetsDUneCompetenceVerrouilleeLeSont() throws Exception {
        User user = testData.user();
        Skill verrouillee = skillManager.findActiveByTaskCode(SkillTaskCode.EE1).get(1);
        SkillPrompt premierSujet = promptManager.findActiveBySkillId(verrouillee.getId()).getFirst();

        assertThat(locked(user, premierSujet)).isTrue();
    }

    /**
     * L'ecran « liste des 5 sujets » est celui ou la regle des 2 sujets doit se
     * VOIR : sans {@code locked} sur la carte, le candidat ne decouvrait le
     * verrou qu'en ouvrant le sujet.
     */
    @Test
    void leDetailDUneCompetenceOuverteCadenasseLesSujetsAuDelaDesDeuxPremiers()
            throws Exception {
        User user = testData.user();
        Skill ouverte = skillManager.findActiveByTaskCode(SkillTaskCode.EE1).getFirst();

        mockMvc.perform(get("/api/skills/" + ouverte.getId())
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.skill.locked").value(false))
                .andExpect(jsonPath("$.prompts[0].locked").value(false))
                .andExpect(jsonPath("$.prompts[1].locked").value(false))
                .andExpect(jsonPath("$.prompts[2].locked").value(true))
                .andExpect(jsonPath("$.prompts[3].locked").value(true))
                .andExpect(jsonPath("$.prompts[4].locked").value(true));
    }

    @Test
    void leDetailDUnAbonneTcfNaAucunSujetCadenasse() throws Exception {
        User abonne = testData.user();
        testData.userSubscription(abonne, testData.plan());
        Skill skill = skillManager.findActiveByTaskCode(SkillTaskCode.EE1).get(3);

        mockMvc.perform(get("/api/skills/" + skill.getId())
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(abonne)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.skill.locked").value(false))
                .andExpect(jsonPath("$.prompts[0].locked").value(false))
                .andExpect(jsonPath("$.prompts[4].locked").value(false));
    }

    /** L'affichage n'est pas la garde : le serveur refuse la production. */
    @Test
    void produireSurUnSujetVerrouilleRepond403() throws Exception {
        User user = testData.user();
        Skill verrouillee = skillManager.findActiveByTaskCode(SkillTaskCode.EE1).get(1);
        SkillPrompt sujet = promptManager.findActiveBySkillId(verrouillee.getId()).getFirst();

        mockMvc.perform(post("/api/skill-attempts")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"skillPromptId\":\"" + sujet.getId()
                                + "\",\"texte\":\"Bonjour Madame, je vous écris pour vous prévenir.\","
                                + "\"requestAnalysis\":false}"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value(containsString("accès TCF")));
    }

    @Test
    void produireSurUnSujetOuvertResteAccepte() throws Exception {
        User user = testData.user();
        Skill ouverte = skillManager.findActiveByTaskCode(SkillTaskCode.EE1).getFirst();
        SkillPrompt sujet = promptManager.findActiveBySkillId(ouverte.getId()).getFirst();

        mockMvc.perform(post("/api/skill-attempts")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"skillPromptId\":\"" + sujet.getId()
                                + "\",\"texte\":\"Bonjour Madame, je vous écris pour vous prévenir.\","
                                + "\"requestAnalysis\":false}"))
                .andExpect(status().isCreated());
    }

    // ------------------------------------------------------------------------
    // Interne
    // ------------------------------------------------------------------------

    private boolean locked(User user, SkillPrompt prompt) throws Exception {
        String body = mockMvc.perform(get("/api/skill-prompts/" + prompt.getId())
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return objectMapper.readValue(body, SkillPromptDto.class).locked();
    }

    private List<SkillDto> list(User user, String query) throws Exception {
        String body = mockMvc.perform(get("/api/skills" + query)
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(user)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return objectMapper.readValue(body, new TypeReference<List<SkillDto>>() {});
    }
}

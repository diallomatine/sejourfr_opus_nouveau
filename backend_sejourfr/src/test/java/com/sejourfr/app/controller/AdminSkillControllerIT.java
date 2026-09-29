package com.sejourfr.app.controller;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.AuthTestSupport;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Le contrat tel qu'il passe sur le fil, du point de vue de la console admin :
 * forme de l'enveloppe paginee, codes de statut, et champs que le serveur
 * refuse de laisser bouger.
 *
 * <p>Ces assertions sont la moitie serveur d'un contrat dont l'autre moitie est
 * deja livree ({@code admin_sejourfr/src/api/skillsApi.ts}) : un renommage de
 * champ ou un code de statut qui glisse casserait un ecran sans qu'aucun test
 * de service ne bronche.
 */
class AdminSkillControllerIT extends AbstractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private TestData testData;
    @Autowired
    private AuthTestSupport auth;

    /**
     * L'enveloppe {@code PageResponse} maison, pas un {@code Page} Spring
     * serialise brut : la console lit {@code content} et {@code totalPages}, et
     * un {@code Page} nu exposerait {@code pageable}, {@code numberOfElements}
     * et un {@code number} au lieu de {@code page}.
     */
    @Test
    void listReturnsTheHouseholdPageEnvelope() throws Exception {
        User admin = testData.admin();

        mockMvc.perform(get("/api/admin/skills?section=EE&page=0&size=5")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(admin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isArray())
                .andExpect(jsonPath("$.page").value(0))
                .andExpect(jsonPath("$.size").value(5))
                // Seed-tolerant : 24 competences EE sont deja publiees, on ne
                // fige pas un total exact.
                .andExpect(jsonPath("$.totalElements").value(greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$.totalPages").exists())
                .andExpect(jsonPath("$.first").value(true))
                .andExpect(jsonPath("$.last").exists())
                .andExpect(jsonPath("$.content[0].generalCriterion").exists())
                .andExpect(jsonPath("$.content[0].promptCount").exists());
    }

    /**
     * Le {@code code} est immuable : le PATCH ne le declare pas, et un client
     * qui l'enverrait quand meme doit se le voir ignorer — pas appliquer. Les
     * codes des sujets et les seeds s'y adossent.
     */
    @Test
    void patchIgnoresAnAttemptToChangeTheImmutableCode() throws Exception {
        Skill skill = testData.skill(SkillTaskCode.EE1);
        User admin = testData.admin();

        mockMvc.perform(patch("/api/admin/skills/" + skill.getId())
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(admin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"title":"Titre modifié","code":"PIRATE-1",
                                 "section":"EO","taskCode":"EO3"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title").value("Titre modifié"))
                .andExpect(jsonPath("$.code").value(skill.getCode()))
                .andExpect(jsonPath("$.section").value("EE"))
                .andExpect(jsonPath("$.taskCode").value("EE1"));
    }

    /**
     * 409 et non 400 : la console traduit specifiquement ce code en « des
     * candidats ont deja travaille ce sujet, il ne peut plus etre supprime,
     * seulement desactive ».
     */
    @Test
    void deletingAPromptWithAttemptsAnswers409() throws Exception {
        SkillPrompt prompt = testData.skillPrompt();
        testData.userSkillAttempt(testData.user(), prompt);
        User admin = testData.admin();

        mockMvc.perform(delete("/api/admin/skill-prompts/" + prompt.getId())
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(admin)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").exists());
    }

    @Test
    void deletingAnUntouchedPromptAnswers204() throws Exception {
        SkillPrompt prompt = testData.skillPrompt();
        User admin = testData.admin();

        mockMvc.perform(delete("/api/admin/skill-prompts/" + prompt.getId())
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(admin)))
                .andExpect(status().isNoContent());
    }

    /**
     * Incoherence EE/EO : 422 avec un message francais, et non la violation du
     * CHECK en 500. C'est la difference entre « corrigez ce champ » et
     * « erreur interne du serveur ».
     */
    @Test
    void creatingAWrittenPromptWithoutWordBoundsAnswers422() throws Exception {
        Skill written = testData.skill(SkillTaskCode.EE1);
        User admin = testData.admin();

        mockMvc.perform(post("/api/admin/skill-prompts")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(admin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"skillId":"%s","code":"TST-WIRE-1","title":"Titre",
                                 "context":"Contexte","instruction":"Consigne",
                                 "uniqueCriterion":"Critère","recommendedMinWords":null,
                                 "recommendedMaxWords":null,"recommendedDurationSeconds":null,
                                 "difficultyLevel":"EASY","displayOrder":18,"active":true}
                                """.formatted(written.getId())))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.message").exists());
    }

    /**
     * Le corps du PUT est un OBJET enveloppe {@code {"references": [...]}}, pas
     * un tableau nu — et il exige les trois niveaux.
     */
    @Test
    void replacingReferencesRequiresTheThreeLevelsInAnEnvelope() throws Exception {
        SkillPrompt prompt = testData.skillPrompt();
        User admin = testData.admin();

        mockMvc.perform(put("/api/admin/skill-prompts/" + prompt.getId() + "/references")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(admin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"references":[
                                  {"level":"EXPECTED","text":"Attendu","pedagogicalNote":"Note"}]}
                                """))
                .andExpect(status().isUnprocessableEntity());

        mockMvc.perform(put("/api/admin/skill-prompts/" + prompt.getId() + "/references")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(admin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"references":[
                                  {"level":"INSUFFICIENT","text":"Insuffisant","pedagogicalNote":"N1"},
                                  {"level":"EXPECTED","text":"Attendu","pedagogicalNote":"N2"},
                                  {"level":"EXCELLENT","text":"Très réussi","pedagogicalNote":"N3"}]}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.references.length()").value(3))
                .andExpect(jsonPath("$.references[0].level").value("INSUFFICIENT"))
                .andExpect(jsonPath("$.references[2].level").value("EXCELLENT"));
    }

    /**
     * {@code validatedRate} est PRESENT et NUL tant que rien n'a ete analyse —
     * jamais {@code 0.0}. La console affiche « aucune analyse » ; un zero se
     * lirait « les candidats echouent », ce qui est une tout autre information.
     */
    @Test
    void statsExposeANullRateWhenNothingWasAnalysed() throws Exception {
        SkillPrompt prompt = testData.skillPrompt();
        testData.userSkillAttempt(testData.user(), prompt);
        User admin = testData.admin();
        String filter = "$[?(@.skillId=='" + prompt.getSkill().getId() + "')]";

        mockMvc.perform(get("/api/admin/skills/stats?section=EE")
                        .header(HttpHeaders.AUTHORIZATION, auth.bearer(admin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath(filter + ".attemptCount").value(contains(1)))
                .andExpect(jsonPath(filter + ".analysedCount").value(contains(0)))
                .andExpect(jsonPath(filter + ".validatedRate").value(contains(nullValue())));
    }
}

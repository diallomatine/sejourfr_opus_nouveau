package com.sejourfr.app.service;

import com.sejourfr.app.dto.AdminExamTemplateDto;
import com.sejourfr.app.dto.AdminExamTemplateRuleWriteRequest;
import com.sejourfr.app.dto.AdminExamTemplateWriteRequest;
import com.sejourfr.app.dto.ExamCompositionSuggestionDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ExamTemplateManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * CRUD admin des templates d'examen blanc + suggesteur de composition (DB réelle).
 */
class AdminExamTemplateServiceIT extends AbstractIntegrationTest {

    @Autowired AdminExamTemplateService service;
    @Autowired TestData data;
    @Autowired AttemptManager attemptManager;
    @Autowired ExamTemplateManager templateManager;

    private AdminExamTemplateWriteRequest req(String slug, List<AdminExamTemplateRuleWriteRequest> rules) {
        return new AdminExamTemplateWriteRequest(
                slug, Module.TCF, TargetLevel.B1, null,
                "Examen de test", "sous-titre", "description",
                5400, 25, 12, true, true, 0, rules);
    }

    private String uniqueSlug() {
        return "tpl-" + UUID.randomUUID().toString().substring(0, 8);
    }

    @Test
    void create_persisteTemplateEtRegles() {
        Theme theme = data.theme(Module.TCF, "tcf-theme", "TCF");
        var rule = new AdminExamTemplateRuleWriteRequest(theme.getId(), QuestionType.CE, Difficulty.B1, 5);

        AdminExamTemplateDto dto = service.create(req(uniqueSlug(), List.of(rule)));

        assertThat(dto.id()).isNotNull();
        assertThat(dto.rules()).hasSize(1);
        assertThat(dto.totalQuestions()).isEqualTo(25);
        assertThat(service.getById(dto.id()).slug()).isEqualTo(dto.slug());
    }

    @Test
    void create_slugDuplique_refuse() {
        String slug = uniqueSlug();
        service.create(req(slug, List.of()));

        assertThatThrownBy(() -> service.create(req(slug, List.of())))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void update_modifieChampsEtRemplaceRegles() {
        AdminExamTemplateDto created = service.create(req(uniqueSlug(),
                List.of(new AdminExamTemplateRuleWriteRequest(null, QuestionType.CO, Difficulty.A2, 3))));

        var newRule = new AdminExamTemplateRuleWriteRequest(null, QuestionType.CE, Difficulty.B2, 7);
        AdminExamTemplateWriteRequest update = new AdminExamTemplateWriteRequest(
                created.slug(), Module.TCF, TargetLevel.B2, null,
                "Renommé", null, null, 3600, 30, 15, false, false, 2, List.of(newRule));

        AdminExamTemplateDto updated = service.update(created.id(), update);

        assertThat(updated.name()).isEqualTo("Renommé");
        assertThat(updated.totalQuestions()).isEqualTo(30);
        assertThat(updated.published()).isFalse();
        assertThat(updated.rules()).hasSize(1);
        assertThat(updated.rules().get(0).questionType()).isEqualTo(QuestionType.CE);
    }

    @Test
    void update_versSlugDejaPris_refuse() {
        AdminExamTemplateDto a = service.create(req(uniqueSlug(), List.of()));
        AdminExamTemplateDto b = service.create(req(uniqueSlug(), List.of()));

        AdminExamTemplateWriteRequest collision = req(a.slug(), List.of());

        assertThatThrownBy(() -> service.update(b.id(), collision))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void getById_inconnu_lanceNotFound() {
        assertThatThrownBy(() -> service.getById(UUID.randomUUID()))
                .isInstanceOf(EntityNotFoundException.class);
    }

    @Test
    void delete_sansAttempt_supprime() {
        AdminExamTemplateDto created = service.create(req(uniqueSlug(), List.of()));

        service.delete(created.id());

        assertThatThrownBy(() -> service.getById(created.id()))
                .isInstanceOf(EntityNotFoundException.class);
    }

    @Test
    void delete_avecAttemptRattache_refuse() {
        AdminExamTemplateDto created = service.create(req(uniqueSlug(), List.of()));
        attemptWithTemplate(created.id());

        assertThatThrownBy(() -> service.delete(created.id()))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    private void attemptWithTemplate(UUID templateId) {
        User user = data.user();
        ExamTemplate ref = templateManager.findById(templateId).orElseThrow();
        Attempt a = new Attempt();
        a.setUser(user);
        a.setExamTemplate(ref);
        a.setType(AttemptType.MOCK_EXAM);
        a.setModule(Module.TCF);
        a.setStartedAt(Instant.now());
        attemptManager.save(a);
    }

    @Test
    void suggestComposition_civique_uneRegleParTheme() {
        ExamCompositionSuggestionDto dto = service.suggestComposition(
                Module.CIVIQUE, null, null, null);

        assertThat(dto.targetTotal()).isEqualTo(40);
        assertThat(dto.rules()).isNotEmpty();
        assertThat(dto.rules()).allMatch(r -> r.themeId() != null);
    }

    @Test
    void suggestComposition_tcf_uneSeuleRegleGenerique_etWarningNiveauIgnore() {
        ExamCompositionSuggestionDto dto = service.suggestComposition(
                Module.TCF, null, TargetLevel.B1, 30);

        assertThat(dto.targetTotal()).isEqualTo(30);
        assertThat(dto.rules()).hasSize(1);
        assertThat(dto.rules().get(0).themeId()).isNull();
        assertThat(dto.warning()).contains("ignoré");
    }
}

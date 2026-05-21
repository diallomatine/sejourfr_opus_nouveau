package com.sejourfr.app.service;

import com.sejourfr.app.dto.AdminExamTemplateDto;
import com.sejourfr.app.dto.AdminExamTemplateRuleWriteRequest;
import com.sejourfr.app.dto.AdminExamTemplateWriteRequest;
import com.sejourfr.app.dto.ExamCompositionSuggestionDto;
import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.entity.ExamTemplateRule;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ExamTemplateManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.mapper.ExamTemplateMapper;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * CRUD admin des templates d'examen blanc + suggesteur de composition.
 * La suppression est interdite si le template est rattache a au moins 1 attempt
 * (on depublie plutot — preserve l'historique).
 */
@Service
@RequiredArgsConstructor
public class AdminExamTemplateService {

    private static final int CIVIQUE_DEFAULT_TARGET = 40;
    private static final int TCF_DEFAULT_TARGET = 60;
    private static final double WARNING_RATIO = 1.5;

    private final ExamTemplateManager templateManager;
    private final ThemeManager themeManager;
    private final QuestionManager questionManager;
    private final AttemptManager attemptManager;
    private final ExamTemplateMapper mapper;

    // ------------------------------------------------------------------------
    // Lecture
    // ------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<AdminExamTemplateDto> listAll(Module module) {
        return templateManager.findAllOrdered(module).stream()
                .map(mapper::toAdminDto)
                .toList();
    }

    @Transactional(readOnly = true)
    public AdminExamTemplateDto getById(UUID id) {
        return mapper.toAdminDto(loadOrThrow(id));
    }

    // ------------------------------------------------------------------------
    // Creation / edition
    // ------------------------------------------------------------------------

    @Transactional
    public AdminExamTemplateDto create(AdminExamTemplateWriteRequest req) {
        templateManager.findBySlug(req.slug()).ifPresent(t -> {
            throw new DataIntegrityViolationException("Slug déjà utilisé : " + req.slug());
        });

        ExamTemplate t = new ExamTemplate();
        applyFields(t, req);
        replaceRules(t, req.rules());
        return mapper.toAdminDto(templateManager.save(t));
    }

    @Transactional
    public AdminExamTemplateDto update(UUID id, AdminExamTemplateWriteRequest req) {
        ExamTemplate t = loadOrThrow(id);

        if (!t.getSlug().equals(req.slug())) {
            templateManager.findBySlug(req.slug()).ifPresent(other -> {
                throw new DataIntegrityViolationException("Slug déjà utilisé : " + req.slug());
            });
        }

        applyFields(t, req);
        replaceRules(t, req.rules());
        return mapper.toAdminDto(templateManager.save(t));
    }

    @Transactional
    public void delete(UUID id) {
        ExamTemplate t = loadOrThrow(id);
        long usedBy = attemptManager.countByExamTemplateId(id);
        if (usedBy > 0) {
            throw new DataIntegrityViolationException(
                    "Ce template est rattaché à " + usedBy + " tentative(s) : dépubliez-le plutôt que de le supprimer."
            );
        }
        templateManager.delete(t);
    }

    // ------------------------------------------------------------------------
    // Suggesteur de composition
    // ------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public ExamCompositionSuggestionDto suggestComposition(
            Module module,
            TargetProcedure targetProcedure,
            TargetLevel targetLevel,
            Integer totalQuestions) {

        int target = totalQuestions != null
                ? totalQuestions
                : (module == Module.CIVIQUE ? CIVIQUE_DEFAULT_TARGET : TCF_DEFAULT_TARGET);
        long poolSize = questionManager.countActiveMatching(module, null, null, null);

        return module == Module.TCF
                ? suggestForTcf(target, poolSize, targetLevel)
                : suggestForCivique(target, poolSize, targetProcedure);
    }

    private ExamCompositionSuggestionDto suggestForCivique(int target, long poolSize, TargetProcedure tp) {
        Difficulty diff = tp == null ? null : switch (tp) {
            case CSP -> Difficulty.CSP;
            case CR -> Difficulty.CR;
            case NAT -> Difficulty.NAT;
        };

        List<Theme> themes = themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE);
        if (themes.isEmpty()) {
            return new ExamCompositionSuggestionDto(
                    target, (int) poolSize, "Aucun thème CIVIQUE en base.", List.of());
        }

        int base = target / themes.size();
        int remainder = target - base * themes.size();
        List<ExamCompositionSuggestionDto.SuggestedRule> rules = new ArrayList<>();
        for (int i = 0; i < themes.size(); i++) {
            Theme th = themes.get(i);
            int count = base + (i < remainder ? 1 : 0);
            long avail = questionManager.countActiveMatching(Module.CIVIQUE, th.getId(), diff, null);
            rules.add(new ExamCompositionSuggestionDto.SuggestedRule(
                    th.getId(), th.getName(), diff, count, avail));
        }

        return new ExamCompositionSuggestionDto(target, (int) poolSize, buildWarning(target, poolSize), rules);
    }

    private ExamCompositionSuggestionDto suggestForTcf(int target, long poolSize, TargetLevel level) {
        // Le test TCF est unique pour tous : on ne filtre jamais par strate
        // A2/B1/B2 a la composition. Le niveau atteint est calcule a la
        // finalisation a partir des bonnes reponses par strate dans les
        // questions tirees. Le parametre `level` est conserve en signature
        // pour retro-compat mais ignore.
        long avail = questionManager.countActiveMatching(Module.TCF, null, null, null);
        List<ExamCompositionSuggestionDto.SuggestedRule> rules = List.of(
                new ExamCompositionSuggestionDto.SuggestedRule(null, null, null, target, avail));

        String warning = buildWarning(target, poolSize);
        if (level != null) {
            warning = (warning == null ? "" : warning + " · ")
                    + "Le niveau cible est ignoré pour le TCF (test unique).";
        }
        return new ExamCompositionSuggestionDto(target, (int) poolSize, warning, rules);
    }

    private String buildWarning(int target, long poolSize) {
        if (poolSize >= target * WARNING_RATIO) return null;
        if (poolSize < target) {
            return "Stock insuffisant : seulement " + poolSize + " questions disponibles pour viser " + target + ".";
        }
        return "Stock juste : " + poolSize + " questions pour " + target + ". Le tirage aura peu de variation.";
    }

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------

    private ExamTemplate loadOrThrow(UUID id) {
        return templateManager.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Examen blanc introuvable"));
    }

    private void applyFields(ExamTemplate t, AdminExamTemplateWriteRequest req) {
        t.setSlug(req.slug());
        t.setModule(req.module());
        t.setTargetLevel(req.targetLevel());
        t.setTargetProcedure(req.targetProcedure());
        t.setName(req.name());
        t.setSubtitle(req.subtitle());
        t.setDescription(req.description());
        t.setDurationSeconds(req.durationSeconds());
        t.setTotalQuestions(req.totalQuestions());
        t.setPassingScore(req.passingScore());
        t.setFree(req.free());
        t.setPublished(req.published());
        t.setPosition(req.position());
    }

    private void replaceRules(ExamTemplate t, List<AdminExamTemplateRuleWriteRequest> rules) {
        // orphanRemoval=true sur ExamTemplate.rules : on vide la collection
        // pour que Hibernate supprime les rules orphelines avant d'inserer les nouvelles.
        t.getRules().clear();
        if (rules == null) return;

        for (int i = 0; i < rules.size(); i++) {
            AdminExamTemplateRuleWriteRequest r = rules.get(i);
            ExamTemplateRule rule = new ExamTemplateRule();
            rule.setExamTemplate(t);
            if (r.themeId() != null) {
                Theme th = themeManager.findById(r.themeId())
                        .orElseThrow(() -> new EntityNotFoundException("Thème introuvable : " + r.themeId()));
                rule.setTheme(th);
            }
            rule.setQuestionType(r.questionType());
            rule.setDifficulty(r.difficulty());
            rule.setQuestionCount(r.questionCount());
            rule.setPosition(i);
            t.getRules().add(rule);
        }
    }
}

package com.sejourfr.app.service;

import com.sejourfr.app.dto.AdminExamTemplateDto;
import com.sejourfr.app.dto.AdminExamTemplateRuleDto;
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
import com.sejourfr.app.repository.AttemptRepository;
import com.sejourfr.app.repository.ExamTemplateRepository;
import com.sejourfr.app.repository.QuestionRepository;
import com.sejourfr.app.repository.ThemeRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@Service
public class AdminExamTemplateService {

    private final ExamTemplateRepository examTemplateRepository;
    private final ThemeRepository themeRepository;
    private final QuestionRepository questionRepository;
    private final AttemptRepository attemptRepository;

    public AdminExamTemplateService(
            ExamTemplateRepository examTemplateRepository,
            ThemeRepository themeRepository,
            QuestionRepository questionRepository,
            AttemptRepository attemptRepository
    ) {
        this.examTemplateRepository = examTemplateRepository;
        this.themeRepository = themeRepository;
        this.questionRepository = questionRepository;
        this.attemptRepository = attemptRepository;
    }

    // ------------------------------------------------------------------------
    // Lecture
    // ------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<AdminExamTemplateDto> listAll(Module module) {
        List<ExamTemplate> all = examTemplateRepository.findAll();
        return all.stream()
                .filter(t -> module == null || t.getModule() == module)
                .sorted(Comparator
                        .comparing(ExamTemplate::getModule)
                        .thenComparingInt(ExamTemplate::getPosition))
                .map(this::toDto)
                .toList();
    }

    @Transactional(readOnly = true)
    public AdminExamTemplateDto getById(UUID id) {
        return toDto(loadOrThrow(id));
    }

    // ------------------------------------------------------------------------
    // Création / édition
    // ------------------------------------------------------------------------

    @Transactional
    public AdminExamTemplateDto create(AdminExamTemplateWriteRequest req) {
        examTemplateRepository.findBySlug(req.slug()).ifPresent(t -> {
            throw new DataIntegrityViolationException("Slug déjà utilisé : " + req.slug());
        });

        ExamTemplate t = new ExamTemplate();
        applyFields(t, req);
        replaceRules(t, req.rules());
        ExamTemplate saved = examTemplateRepository.save(t);
        return toDto(saved);
    }

    @Transactional
    public AdminExamTemplateDto update(UUID id, AdminExamTemplateWriteRequest req) {
        ExamTemplate t = loadOrThrow(id);

        if (!t.getSlug().equals(req.slug())) {
            examTemplateRepository.findBySlug(req.slug()).ifPresent(other -> {
                throw new DataIntegrityViolationException("Slug déjà utilisé : " + req.slug());
            });
        }

        applyFields(t, req);
        replaceRules(t, req.rules());
        return toDto(examTemplateRepository.save(t));
    }

    @Transactional
    public void delete(UUID id) {
        ExamTemplate t = loadOrThrow(id);
        long usedBy = attemptRepository.countByExamTemplateId(id);
        if (usedBy > 0) {
            throw new DataIntegrityViolationException(
                    "Ce template est rattaché à " + usedBy + " tentative(s) : dépubliez-le plutôt que de le supprimer."
            );
        }
        examTemplateRepository.delete(t);
    }

    // ------------------------------------------------------------------------
    // Suggesteur de composition
    // ------------------------------------------------------------------------

    @Transactional(readOnly = true)
    public ExamCompositionSuggestionDto suggestComposition(
            Module module,
            TargetProcedure targetProcedure,
            TargetLevel targetLevel,
            Integer totalQuestions
    ) {
        int target = totalQuestions != null
                ? totalQuestions
                : (module == Module.CIVIQUE ? 40 : 60);
        long poolSize = questionRepository.countActiveMatching(module, null, null);

        if (module == Module.TCF) {
            return suggestForTcf(target, poolSize, targetLevel);
        }
        return suggestForCivique(target, poolSize, targetProcedure);
    }

    private ExamCompositionSuggestionDto suggestForCivique(int target, long poolSize, TargetProcedure tp) {
        Difficulty diff = tp == null ? null : switch (tp) {
            case CSP -> Difficulty.CSP;
            case CR -> Difficulty.CR;
            case NAT -> Difficulty.NAT;
        };

        List<Theme> themes = themeRepository.findByModuleOrderByDisplayOrderAsc(Module.CIVIQUE);
        if (themes.isEmpty()) {
            return new ExamCompositionSuggestionDto(target, (int) poolSize, "Aucun thème CIVIQUE en base.", List.of());
        }

        int base = target / themes.size();
        int remainder = target - base * themes.size();
        List<ExamCompositionSuggestionDto.SuggestedRule> rules = new ArrayList<>();
        for (int i = 0; i < themes.size(); i++) {
            Theme th = themes.get(i);
            int count = base + (i < remainder ? 1 : 0);
            long avail = questionRepository.countActiveMatching(Module.CIVIQUE, th.getId(), diff);
            rules.add(new ExamCompositionSuggestionDto.SuggestedRule(
                    th.getId(), th.getName(), diff, count, avail
            ));
        }

        String warning = buildWarning(target, poolSize);
        return new ExamCompositionSuggestionDto(target, (int) poolSize, warning, rules);
    }

    private ExamCompositionSuggestionDto suggestForTcf(int target, long poolSize, TargetLevel level) {
        // Le test TCF est unique pour tous : on ne filtre jamais par strate
        // A2/B1/B2 à la composition. Le niveau atteint est calculé à la
        // finalisation à partir des bonnes réponses par strate dans les
        // questions tirées. Le paramètre `level` est conservé en signature
        // pour rétro-compat mais ignoré.
        long avail = questionRepository.countActiveMatching(Module.TCF, null, null);
        List<ExamCompositionSuggestionDto.SuggestedRule> rules = List.of(
                new ExamCompositionSuggestionDto.SuggestedRule(null, null, null, target, avail)
        );
        String warning = buildWarning(target, poolSize);
        if (level != null) {
            warning = (warning == null ? "" : warning + " · ")
                    + "Le niveau cible est ignoré pour le TCF (test unique).";
        }
        return new ExamCompositionSuggestionDto(target, (int) poolSize, warning, rules);
    }

    private String buildWarning(int target, long poolSize) {
        if (poolSize >= target * 1.5) return null;
        if (poolSize < target) {
            return "Stock insuffisant : seulement " + poolSize + " questions disponibles pour viser " + target + ".";
        }
        return "Stock juste : "  + poolSize + " questions pour " + target + ". Le tirage aura peu de variation.";
    }

    private Difficulty toDifficulty(TargetLevel level) {
        return switch (level) {
            case A2 -> Difficulty.A2;
            case B1 -> Difficulty.B1;
            case B2 -> Difficulty.B2;
        };
    }

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------

    private ExamTemplate loadOrThrow(UUID id) {
        return examTemplateRepository.findById(id)
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
        // pour que Hibernate supprime les rules orphelines avant d'insérer les nouvelles.
        t.getRules().clear();
        if (rules == null) return;

        for (int i = 0; i < rules.size(); i++) {
            AdminExamTemplateRuleWriteRequest r = rules.get(i);
            ExamTemplateRule rule = new ExamTemplateRule();
            rule.setExamTemplate(t);
            if (r.themeId() != null) {
                Theme th = themeRepository.findById(r.themeId())
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

    private AdminExamTemplateDto toDto(ExamTemplate t) {
        List<AdminExamTemplateRuleDto> rules = t.getRules().stream()
                .sorted(Comparator.comparingInt(ExamTemplateRule::getPosition))
                .map(this::toRuleDto)
                .toList();

        return new AdminExamTemplateDto(
                t.getId(),
                t.getSlug(),
                t.getModule(),
                t.getTargetLevel(),
                t.getTargetProcedure(),
                t.getName(),
                t.getSubtitle(),
                t.getDescription(),
                t.getDurationSeconds(),
                t.getTotalQuestions(),
                t.getPassingScore(),
                t.isFree(),
                t.isPublished(),
                t.getPosition(),
                t.getCreatedAt(),
                t.getUpdatedAt(),
                rules
        );
    }

    private AdminExamTemplateRuleDto toRuleDto(ExamTemplateRule r) {
        UUID themeId = r.getTheme() != null ? r.getTheme().getId() : null;
        String themeName = r.getTheme() != null ? r.getTheme().getName() : null;
        return new AdminExamTemplateRuleDto(
                r.getId(),
                themeId,
                themeName,
                r.getQuestionType(),
                r.getDifficulty(),
                r.getQuestionCount(),
                r.getPosition()
        );
    }
}

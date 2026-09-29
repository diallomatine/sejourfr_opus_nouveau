package com.sejourfr.app.service;

import com.sejourfr.app.dto.ExamTemplateSummaryResponse;
import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.manager.ExamTemplateManager;
import com.sejourfr.app.mapper.ExamTemplateMapper;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Vitrine des examens blancs publies. Sert ExamController (auth) ET
 * PublicExamController (visiteurs) — la liste est identique, seul le prefixe
 * d'URL change pour offrir aux 2 surfaces une API homogene.
 */
@Service
@RequiredArgsConstructor
public class ExamService {

    private final ExamTemplateManager templateManager;
    private final ExamTemplateMapper mapper;

    @Transactional(readOnly = true)
    public List<ExamTemplateSummaryResponse> listPublished(Module module) {
        List<ExamTemplate> templates = module != null
                ? templateManager.findPublishedByModule(module)
                : templateManager.findAllPublished();
        return templates.stream().map(mapper::toSummary).toList();
    }

    @Transactional(readOnly = true)
    public ExamTemplateSummaryResponse getPublishedBySlug(String slug) {
        ExamTemplate t = templateManager.findBySlug(slug)
                .filter(ExamTemplate::isPublished)
                .orElseThrow(() -> new EntityNotFoundException("Examen blanc introuvable"));
        return mapper.toSummary(t);
    }
}

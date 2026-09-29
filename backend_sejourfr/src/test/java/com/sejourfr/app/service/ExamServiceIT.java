package com.sejourfr.app.service;

import com.sejourfr.app.dto.ExamTemplateSummaryResponse;
import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.manager.ExamTemplateManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Vitrine des examens blancs publiés (lecture seule sur DB réelle).
 */
class ExamServiceIT extends AbstractIntegrationTest {

    @Autowired ExamService service;
    @Autowired TestData data;
    @Autowired ExamTemplateManager templateManager;



    @Test
    void listPublished_sansFiltre_inclutLesTemplatesPublies_excludLesBrouillons() {
        ExamTemplate published = data.examTemplate(); // TCF, publié
        ExamTemplate draft = data.examTemplate(Module.TCF, true, false);

        List<ExamTemplateSummaryResponse> all = service.listPublished(null);

        assertThat(all).extracting(ExamTemplateSummaryResponse::slug).contains(published.getSlug());
        assertThat(all).extracting(ExamTemplateSummaryResponse::slug).doesNotContain(draft.getSlug());
    }

    @Test
    void listPublished_filtreParModule() {
        ExamTemplate tcf = data.examTemplate();         // TCF
        ExamTemplate civ = data.examTemplate(Module.CIVIQUE, true, true);          // CIVIQUE

        List<ExamTemplateSummaryResponse> tcfOnly = service.listPublished(Module.TCF);

        assertThat(tcfOnly).extracting(ExamTemplateSummaryResponse::slug).contains(tcf.getSlug());
        assertThat(tcfOnly).extracting(ExamTemplateSummaryResponse::slug).doesNotContain(civ.getSlug());
    }

    @Test
    void getPublishedBySlug_trouve() {
        ExamTemplate published = data.examTemplate();

        ExamTemplateSummaryResponse r = service.getPublishedBySlug(published.getSlug());

        assertThat(r.slug()).isEqualTo(published.getSlug());
    }

    @Test
    void getPublishedBySlug_inconnu_lanceNotFound() {
        assertThatThrownBy(() -> service.getPublishedBySlug("slug-inexistant-xyz"))
                .isInstanceOf(EntityNotFoundException.class);
    }

    @Test
    void getPublishedBySlug_brouillon_lanceNotFound() {
        ExamTemplate draft = data.examTemplate(Module.TCF, true, false);

        assertThatThrownBy(() -> service.getPublishedBySlug(draft.getSlug()))
                .isInstanceOf(EntityNotFoundException.class);
    }
}

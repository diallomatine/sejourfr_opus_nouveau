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

    private ExamTemplate unpublished(Module module) {
        ExamTemplate t = new ExamTemplate();
        t.setSlug("unpub-" + System.nanoTime());
        t.setModule(module);
        t.setName("Brouillon");
        t.setDurationSeconds(3600);
        t.setTotalQuestions(20);
        t.setPassingScore(12);
        t.setFree(true);
        t.setPublished(false);
        t.setPosition(0);
        return templateManager.save(t);
    }

    private ExamTemplate publishedCivique() {
        ExamTemplate t = new ExamTemplate();
        t.setSlug("civ-pub-" + System.nanoTime());
        t.setModule(Module.CIVIQUE);
        t.setName("Examen civique publié");
        t.setDurationSeconds(2700);
        t.setTotalQuestions(40);
        t.setPassingScore(32);
        t.setFree(true);
        t.setPublished(true);
        t.setPosition(0);
        return templateManager.save(t);
    }

    @Test
    void listPublished_sansFiltre_inclutLesTemplatesPublies_excludLesBrouillons() {
        ExamTemplate published = data.examTemplate(); // TCF, publié
        ExamTemplate draft = unpublished(Module.TCF);

        List<ExamTemplateSummaryResponse> all = service.listPublished(null);

        assertThat(all).extracting(ExamTemplateSummaryResponse::slug).contains(published.getSlug());
        assertThat(all).extracting(ExamTemplateSummaryResponse::slug).doesNotContain(draft.getSlug());
    }

    @Test
    void listPublished_filtreParModule() {
        ExamTemplate tcf = data.examTemplate();         // TCF
        ExamTemplate civ = publishedCivique();          // CIVIQUE

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
        ExamTemplate draft = unpublished(Module.TCF);

        assertThatThrownBy(() -> service.getPublishedBySlug(draft.getSlug()))
                .isInstanceOf(EntityNotFoundException.class);
    }
}

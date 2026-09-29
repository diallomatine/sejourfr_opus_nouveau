package com.sejourfr.app.manager;

import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Note : la table {@code exam_templates} est pré-remplie par la migration V110
 * (40 gabarits). Les assertions filtrent donc sur les IDs créés par le test pour
 * rester déterministes malgré le seed.
 */
class ExamTemplateManagerIT extends AbstractIntegrationTest {

    @Autowired
    private ExamTemplateManager manager;

    @Autowired
    private TestData testData;

    private ExamTemplate template(Module module, int position, boolean published) {
        ExamTemplate t = testData.examTemplate();
        t.setModule(module);
        t.setPosition(position);
        t.setPublished(published);
        return manager.save(t);
    }

    private static List<UUID> retain(List<ExamTemplate> result, Set<UUID> mine) {
        return result.stream().map(ExamTemplate::getId).filter(mine::contains).toList();
    }

    @Test
    void findByIdAbsentReturnsEmpty() {
        assertThat(manager.findById(UUID.randomUUID())).isEmpty();
    }

    @Test
    void findBySlug() {
        ExamTemplate saved = testData.examTemplate();

        assertThat(manager.findBySlug(saved.getSlug()))
                .get()
                .extracting(ExamTemplate::getId)
                .isEqualTo(saved.getId());
        assertThat(manager.findBySlug("slug-absent-" + UUID.randomUUID())).isEmpty();
    }

    @Test
    void findPublishedByModuleFiltersAndOrders() {
        ExamTemplate tcfSecond = template(Module.TCF, 102, true);
        ExamTemplate tcfFirst = template(Module.TCF, 101, true);
        ExamTemplate tcfUnpublished = template(Module.TCF, 100, false);
        ExamTemplate civique = template(Module.CIVIQUE, 101, true);

        List<ExamTemplate> result = manager.findPublishedByModule(Module.TCF);

        assertThat(result).allMatch(t -> t.getModule() == Module.TCF && t.isPublished());
        assertThat(retain(result, Set.of(
                tcfFirst.getId(), tcfSecond.getId(), tcfUnpublished.getId(), civique.getId())))
                .containsExactly(tcfFirst.getId(), tcfSecond.getId());
    }

    @Test
    void findAllPublishedOrdersByModuleThenPosition() {
        ExamTemplate tcf = template(Module.TCF, 103, true);
        ExamTemplate civiqueSecond = template(Module.CIVIQUE, 102, true);
        ExamTemplate civiqueFirst = template(Module.CIVIQUE, 101, true);
        ExamTemplate unpublished = template(Module.TCF, 100, false);

        List<ExamTemplate> result = manager.findAllPublished();

        assertThat(result).allMatch(ExamTemplate::isPublished);
        assertThat(retain(result, Set.of(
                tcf.getId(), civiqueFirst.getId(), civiqueSecond.getId(), unpublished.getId())))
                .containsExactly(civiqueFirst.getId(), civiqueSecond.getId(), tcf.getId());
    }

    @Test
    void findAllOrderedFiltersByModuleAndIncludesUnpublished() {
        ExamTemplate tcfPublished = template(Module.TCF, 101, true);
        ExamTemplate tcfUnpublished = template(Module.TCF, 100, false);
        ExamTemplate civique = template(Module.CIVIQUE, 100, true);

        List<ExamTemplate> tcfOnly = manager.findAllOrdered(Module.TCF);
        assertThat(tcfOnly).allMatch(t -> t.getModule() == Module.TCF);
        assertThat(retain(tcfOnly, Set.of(
                tcfPublished.getId(), tcfUnpublished.getId(), civique.getId())))
                .containsExactly(tcfUnpublished.getId(), tcfPublished.getId());

        List<ExamTemplate> all = manager.findAllOrdered(null);
        assertThat(all)
                .extracting(ExamTemplate::getId)
                .contains(tcfPublished.getId(), tcfUnpublished.getId(), civique.getId());
    }

    @Test
    void deleteRemovesRow() {
        ExamTemplate saved = testData.examTemplate();
        UUID id = saved.getId();

        manager.delete(saved);

        assertThat(manager.findById(id)).isEmpty();
    }
}

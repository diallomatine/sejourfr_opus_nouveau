package com.sejourfr.app.manager;

import com.sejourfr.app.entity.ProductionExample;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.ExampleAudioStatus;
import com.sejourfr.app.repository.ProductionTaskRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Les tables {@code production_tasks} (V700+) et {@code production_examples}
 * (V760/V761) sont pré-remplies par Flyway pour les niveaux A2/B1/B2 et les
 * tâches 1 à 3. Les CHECK constraints (V011) imposant des valeurs légales
 * (niveau ∈ {A2,B1,B2}, tâche ∈ 1..3, cohérence mots/durée par épreuve), les
 * lignes créées ici coexistent avec les lignes seedées. Chaque assertion est
 * donc <b>seed-tolérante</b> : on filtre le résultat sur les ids créés dans le
 * test (pour l'ordre/l'exclusion) ou on capture un baseline (pour les comptes).
 */
class ProductionTaskManagerIT extends AbstractIntegrationTest {

    private static final String NIVEAU = "B2";

    @Autowired
    private ProductionTaskManager manager;

    @Autowired
    private ProductionTaskRepository taskRepository;

    @Autowired
    private TestData testData;

    private ProductionTask task(EpreuveType epreuve, String niveau, short tache, boolean active, long createdAgoSec) {
        ProductionTask t = new ProductionTask();
        t.setEpreuve(epreuve);
        t.setNiveauCible(niveau);
        t.setTacheNumero(tache);
        t.setConsigne("Consigne " + UUID.randomUUID());
        t.setActive(active);
        // Contrainte chk_prod_task_audio_text_coherence (V011) : TCF_EO porte une
        // durée (mots NULL), TCF_EE porte une fourchette de mots (durée NULL).
        if (epreuve == EpreuveType.TCF_EO) {
            t.setDureeMinSec(60);
            t.setDureeMaxSec(180);
        } else {
            t.setMotsMin(120);
            t.setMotsMax(180);
        }
        t.setCreatedAt(Instant.now().minus(createdAgoSec, ChronoUnit.SECONDS));
        return taskRepository.save(t);
    }

    /** Ids des tâches créées dans le test, dans l'ordre où elles apparaissent dans {@code result}. */
    private static List<UUID> mineInOrder(List<ProductionTask> result, ProductionTask... mine) {
        Set<UUID> ids = Arrays.stream(mine).map(ProductionTask::getId).collect(Collectors.toSet());
        return result.stream().map(ProductionTask::getId).filter(ids::contains).toList();
    }

    /** Ids des exemples créés dans le test, dans l'ordre où ils apparaissent dans {@code result}. */
    private static List<UUID> mineExamplesInOrder(List<ProductionExample> result, ProductionExample... mine) {
        Set<UUID> ids = Arrays.stream(mine).map(ProductionExample::getId).collect(Collectors.toSet());
        return result.stream().map(ProductionExample::getId).filter(ids::contains).toList();
    }

    @Test
    void findByIdAbsentReturnsEmpty() {
        assertThat(manager.findById(UUID.randomUUID())).isEmpty();
    }

    @Test
    void findActiveByIdFiltersInactive() {
        ProductionTask active = task(EpreuveType.TCF_EE, NIVEAU, (short) 1, true, 0);
        ProductionTask inactive = task(EpreuveType.TCF_EE, NIVEAU, (short) 1, false, 0);

        assertThat(manager.findActiveById(active.getId())).isPresent();
        assertThat(manager.findActiveById(inactive.getId())).isEmpty();
    }

    @Test
    void findActiveByEpreuveNiveauTacheOrdersByCreatedAt() {
        ProductionTask first = task(EpreuveType.TCF_EE, NIVEAU, (short) 1, true, 20);
        ProductionTask second = task(EpreuveType.TCF_EE, NIVEAU, (short) 1, true, 10);
        ProductionTask inactive = task(EpreuveType.TCF_EE, NIVEAU, (short) 1, false, 5);
        ProductionTask otherTache = task(EpreuveType.TCF_EE, NIVEAU, (short) 2, true, 1);

        List<ProductionTask> result = manager.findActive(EpreuveType.TCF_EE, NIVEAU, (short) 1);

        // Ordre createdAt ASC parmi nos lignes (seed-tolérant : on ignore les lignes Flyway).
        assertThat(mineInOrder(result, first, second, inactive, otherTache))
                .containsExactly(first.getId(), second.getId());
        assertThat(result)
                .extracting(ProductionTask::getId)
                .doesNotContain(inactive.getId(), otherTache.getId());
    }

    @Test
    void findActiveByEpreuveNiveauOrdersByTacheNumero() {
        ProductionTask tache1 = task(EpreuveType.TCF_EE, NIVEAU, (short) 1, true, 10);
        ProductionTask tache2 = task(EpreuveType.TCF_EE, NIVEAU, (short) 2, true, 5);
        ProductionTask inactive = task(EpreuveType.TCF_EE, NIVEAU, (short) 1, false, 1);

        List<ProductionTask> result = manager.findActive(EpreuveType.TCF_EE, NIVEAU, null);

        // Ordre tacheNumero ASC parmi nos lignes.
        assertThat(mineInOrder(result, tache1, tache2, inactive))
                .containsExactly(tache1.getId(), tache2.getId());
        assertThat(result)
                .extracting(ProductionTask::getId)
                .doesNotContain(inactive.getId());
    }

    @Test
    void findActiveByEpreuveAndTacheAllNiveaux() {
        ProductionTask active = task(EpreuveType.TCF_EE, NIVEAU, (short) 1, true, 5);
        ProductionTask inactive = task(EpreuveType.TCF_EE, NIVEAU, (short) 1, false, 5);

        List<ProductionTask> result = manager.findActive(EpreuveType.TCF_EE, null, (short) 1);

        assertThat(result)
                .extracting(ProductionTask::getId)
                .contains(active.getId())
                .doesNotContain(inactive.getId());
        assertThat(result).allMatch(t -> t.getEpreuve() == EpreuveType.TCF_EE && t.getTacheNumero() == (short) 1);
    }

    @Test
    void findActiveByEpreuveOnlyExcludesInactive() {
        ProductionTask active = task(EpreuveType.TCF_EE, NIVEAU, (short) 1, true, 5);
        ProductionTask inactive = task(EpreuveType.TCF_EE, NIVEAU, (short) 1, false, 5);

        List<ProductionTask> result = manager.findActive(EpreuveType.TCF_EE, null, null);

        assertThat(result)
                .extracting(ProductionTask::getId)
                .contains(active.getId())
                .doesNotContain(inactive.getId());
        assertThat(result).allMatch(ProductionTask::isActive);
    }

    @Test
    void findAllActiveExcludesInactive() {
        ProductionTask active = task(EpreuveType.TCF_EE, NIVEAU, (short) 1, true, 5);
        ProductionTask inactive = task(EpreuveType.TCF_EE, NIVEAU, (short) 1, false, 5);

        List<ProductionTask> result = manager.findAllActive();

        assertThat(result)
                .extracting(ProductionTask::getId)
                .contains(active.getId())
                .doesNotContain(inactive.getId());
        assertThat(result).allMatch(ProductionTask::isActive);
    }

    @Test
    void findExamplesByEpreuveAndTacheOrdersByDisplayOrder() {
        ProductionTask task = task(EpreuveType.TCF_EE, NIVEAU, (short) 1, true, 0);
        ProductionExample e0 = testData.productionExample(task);
        ProductionExample e1 = testData.productionExample(task);
        e1.setDisplayOrder(1);
        manager.saveExample(e1);
        ProductionTask otherTask = task(EpreuveType.TCF_EE, NIVEAU, (short) 2, true, 0);
        ProductionExample otherExample = testData.productionExample(otherTask);

        List<ProductionExample> result = manager.findExamplesByEpreuveAndTache(EpreuveType.TCF_EE, (short) 1);

        // Ordre displayOrder ASC parmi nos exemples (seed-tolérant).
        assertThat(mineExamplesInOrder(result, e0, e1, otherExample))
                .containsExactly(e0.getId(), e1.getId());
        assertThat(result)
                .extracting(ProductionExample::getId)
                .doesNotContain(otherExample.getId());
    }

    @Test
    void findExampleById() {
        ProductionTask task = task(EpreuveType.TCF_EE, NIVEAU, (short) 1, true, 0);
        ProductionExample example = testData.productionExample(task);

        assertThat(manager.findExampleById(example.getId()))
                .get()
                .extracting(ProductionExample::getId)
                .isEqualTo(example.getId());
        assertThat(manager.findExampleById(UUID.randomUUID())).isEmpty();
    }

    @Test
    void saveExamplePersists() {
        ProductionTask task = task(EpreuveType.TCF_EO, NIVEAU, (short) 1, true, 0);
        ProductionExample e = new ProductionExample();
        e.setTaskId(task.getId());
        e.setTitre("Modèle EO");
        e.setContenu("Contenu modèle.");
        e.setDisplayOrder(0);

        ProductionExample saved = manager.saveExample(e);

        assertThat(saved.getId()).isNotNull();
        assertThat(manager.findExampleById(saved.getId())).isPresent();
    }

    @Test
    void eoExamplesNeedingAudioCountAndList() {
        Set<ExampleAudioStatus> statuses = Set.of(ExampleAudioStatus.PENDING);
        long baseline = manager.countEoExamplesNeedingAudio(statuses);

        ProductionTask task = task(EpreuveType.TCF_EO, NIVEAU, (short) 1, true, 0);
        ProductionExample pending1 = pendingExample(task, null);
        ProductionExample pending2 = pendingExample(task, null);
        ProductionExample alreadyHasAudio = pendingExample(task, "https://cdn/audio.mp3");

        assertThat(manager.countEoExamplesNeedingAudio(statuses)).isEqualTo(baseline + 2);

        List<ProductionExample> needing = manager.findEoExamplesNeedingAudio(statuses, 100);
        assertThat(needing)
                .extracting(ProductionExample::getId)
                .contains(pending1.getId(), pending2.getId())
                .doesNotContain(alreadyHasAudio.getId());
    }

    @Test
    void eoExamplesNeedingAudioRespectsLimit() {
        ProductionTask task = task(EpreuveType.TCF_EO, NIVEAU, (short) 1, true, 0);
        pendingExample(task, null);
        pendingExample(task, null);
        pendingExample(task, null);

        // On seede 3 exemples > limite 2 : le cap doit tenir quelle que soit la
        // quantité de lignes seedées présentes en base.
        List<ProductionExample> result =
                manager.findEoExamplesNeedingAudio(Set.of(ExampleAudioStatus.PENDING), 2);

        assertThat(result).hasSize(2);
    }

    @Test
    void findEoExamplesByAudioStatus() {
        ProductionTask task = task(EpreuveType.TCF_EO, NIVEAU, (short) 1, true, 0);
        ProductionExample generating = testData.productionExample(task);
        generating.setAudioStatus(ExampleAudioStatus.GENERATING);
        manager.saveExample(generating);
        ProductionExample none = testData.productionExample(task);

        List<ProductionExample> result = manager.findEoExamplesByAudioStatus(ExampleAudioStatus.GENERATING);

        assertThat(result)
                .extracting(ProductionExample::getId)
                .contains(generating.getId())
                .doesNotContain(none.getId());
        assertThat(result).allMatch(e -> e.getAudioStatus() == ExampleAudioStatus.GENERATING);
    }

    private ProductionExample pendingExample(ProductionTask task, String audioUrl) {
        ProductionExample e = testData.productionExample(task);
        e.setAudioStatus(ExampleAudioStatus.PENDING);
        e.setAudioUrl(audioUrl);
        return manager.saveExample(e);
    }
}

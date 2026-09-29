package com.sejourfr.app.service;

import com.sejourfr.app.dto.AdminProductionTaskDto;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Edition du titre editorial d'un sujet depuis la console. Test d'integration
 * et non unitaire : l'invariant qui compte ici est en base — la contrainte
 * {@code chk_prod_task_titre} (V028) refuse une chaine blanche, donc « effacer
 * le titre » ne peut se dire qu'en NULL. Un mock ne le prouverait pas.
 */
class AdminProductionTaskServiceIT extends AbstractIntegrationTest {

    @Autowired
    private AdminProductionTaskService service;
    @Autowired
    private TestData testData;
    @Autowired
    private JdbcTemplate jdbc;
    @Autowired
    private EntityManager em;

    @Test
    void aFreshSubjectHasNoTitleAndThatIsNotAnError() {
        ProductionTask task = testData.productionTask(EpreuveType.TCF_EE);

        AdminProductionTaskDto dto = trouve(task.getId());

        assertThat(dto.titre()).isNull();
        assertThat(dto.consigne()).isEqualTo(task.getConsigne());
        assertThat(dto.active()).isTrue();
    }

    @Test
    void settingATitleTrimsItAndPersistsIt() {
        ProductionTask task = testData.productionTask(EpreuveType.TCF_EE);

        AdminProductionTaskDto dto = service.updateTitre(task.getId(), "  Invitation a un pique-nique  ");

        assertThat(dto.titre()).isEqualTo("Invitation a un pique-nique");
        assertThat(titreEnBase(task.getId())).isEqualTo("Invitation a un pique-nique");
    }

    /**
     * « Pas de titre » se dit NULL, jamais par une chaine vide : c'est ce qui
     * rend le repli « Sujet N » des fronts atteignable, et c'est aussi la seule
     * valeur que la contrainte accepte.
     */
    @Test
    void clearingATitleWritesNullRatherThanAnEmptyString() {
        ProductionTask task = testData.productionTask(EpreuveType.TCF_EE);
        service.updateTitre(task.getId(), "Un titre pose par erreur");

        assertThat(service.updateTitre(task.getId(), "   ").titre()).isNull();
        assertThat(titreEnBase(task.getId())).isNull();

        service.updateTitre(task.getId(), "Un autre titre");
        assertThat(service.updateTitre(task.getId(), null).titre()).isNull();
        assertThat(titreEnBase(task.getId())).isNull();
    }

    /** L'invariant que la normalisation du service protege, vu depuis le SQL. */
    @Test
    void theDatabaseItselfRefusesABlankTitle() {
        ProductionTask task = testData.productionTask(EpreuveType.TCF_EE);
        em.flush();

        assertThatThrownBy(() -> jdbc.update(
                "UPDATE production_tasks SET titre = '   ' WHERE id = ?", task.getId()))
                .hasMessageContaining("chk_prod_task_titre");
    }

    @Test
    void aTitleLongerThanTheColumnIsRefusedBeforeItReachesTheDatabase() {
        ProductionTask task = testData.productionTask(EpreuveType.TCF_EE);

        assertThatThrownBy(() -> service.updateTitre(task.getId(), "x".repeat(81)))
                .isInstanceOf(BusinessException.class);

        assertThat(titreEnBase(task.getId())).isNull();
    }

    @Test
    void anUnknownSubjectIsANotFound() {
        assertThatThrownBy(() -> service.updateTitre(UUID.randomUUID(), "Titre"))
                .isInstanceOf(NotFoundException.class);
    }

    /**
     * La console doit voir ce qu'elle edite, y compris un sujet depublie : la
     * vue candidat, elle, ne rend que les actifs.
     */
    @Test
    void theConsoleListIncludesDeactivatedSubjects() {
        ProductionTask task = testData.productionTask(EpreuveType.TCF_EE);
        task.setActive(false);
        em.flush();
        em.clear();

        AdminProductionTaskDto dto = trouve(task.getId());

        assertThat(dto.active()).isFalse();
    }

    @Test
    void theTacheFilterNarrowsTheList() {
        ProductionTask t1 = testData.productionTask(EpreuveType.TCF_EE); // tache 1

        List<AdminProductionTaskDto> tache2 = service.list(EpreuveType.TCF_EE, (short) 2);

        assertThat(tache2).noneMatch(d -> d.id().equals(t1.getId()));
        assertThat(tache2).allMatch(d -> d.tacheNumero() == 2);
    }

    @Test
    void onlyProductionEpreuvesAreAccepted() {
        assertThatThrownBy(() -> service.list(EpreuveType.TCF_CO, null))
                .isInstanceOf(BusinessException.class);
        assertThatThrownBy(() -> service.list(EpreuveType.TCF_EE, (short) 4))
                .isInstanceOf(BusinessException.class);
    }

    private AdminProductionTaskDto trouve(UUID id) {
        return service.list(EpreuveType.TCF_EE, null).stream()
                .filter(d -> d.id().equals(id))
                .findFirst()
                .orElseThrow();
    }

    /**
     * Lit la colonne en SQL. {@code flush()} d'abord : {@code repository.save}
     * ne pousse rien tout seul, et JdbcTemplate ne voit pas le contexte de
     * persistance (piege documente dans {@code docs/plan-tests-backend.md}).
     */
    private String titreEnBase(UUID id) {
        em.flush();
        return jdbc.queryForObject("SELECT titre FROM production_tasks WHERE id = ?", String.class, id);
    }
}

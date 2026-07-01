package com.sejourfr.app.service;

import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.ProductionAttemptStartRequest;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;

import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Attempts d'épreuves productives (EO / EE / conteneur TCF_COMPLET) : pas de
 * QCM, validations d'épreuve/module, résolution de parent, budget freemium
 * d'examen blanc production. DB réelle.
 */
class AttemptServiceProductionIT extends AbstractIntegrationTest {

    @Autowired AttemptService service;
    @Autowired TestData data;
    @Autowired AttemptManager attemptManager;

    private ProductionAttemptStartRequest req(EpreuveType epreuve, UUID parentId, Boolean exam, Integer slot) {
        return new ProductionAttemptStartRequest(Module.TCF, epreuve, parentId, exam, slot);
    }

    private Attempt completParent(User user) {
        Attempt p = new Attempt();
        p.setUser(user);
        p.setType(AttemptType.MOCK_EXAM);
        p.setModule(Module.TCF);
        p.setEpreuve(EpreuveType.TCF_COMPLET);
        p.setStartedAt(Instant.now());
        return attemptManager.save(p);
    }

    @Test
    void startProduction_eeEntrainement_creeAttemptVide() {
        User user = data.user();

        AttemptResponse r = service.startProductionAttempt(user.getId(), req(EpreuveType.TCF_EE, null, null, null));

        assertThat(r.type()).isEqualTo(AttemptType.TRAINING);
        assertThat(r.module()).isEqualTo(Module.TCF);
        assertThat(r.totalQuestions()).isNull();
        assertThat(r.questions()).isEmpty();
        assertThat(r.timeLimitSeconds()).isNull();

        Attempt persisted = attemptManager.findById(r.id()).orElseThrow();
        assertThat(persisted.getEpreuve()).isEqualTo(EpreuveType.TCF_EE);
        assertThat(persisted.getParentAttempt()).isNull();
        assertThat(persisted.getSlotNumber()).isNull();
    }

    @Test
    void startProduction_eeExamen_poseSlotEtChrono30min() {
        User user = data.user();

        AttemptResponse r = service.startProductionAttempt(user.getId(), req(EpreuveType.TCF_EE, null, true, 2));

        assertThat(r.timeLimitSeconds()).isEqualTo(30 * 60);
        Attempt persisted = attemptManager.findById(r.id()).orElseThrow();
        assertThat(persisted.getSlotNumber()).isEqualTo(2);
    }

    @Test
    void startProduction_eoExamen_pasDeChronoEpreuve() {
        User user = data.user();

        AttemptResponse r = service.startProductionAttempt(user.getId(), req(EpreuveType.TCF_EO, null, true, 1));

        // EO : pas de chrono d'épreuve (temps borné par tâche).
        assertThat(r.timeLimitSeconds()).isNull();
        Attempt persisted = attemptManager.findById(r.id()).orElseThrow();
        assertThat(persisted.getSlotNumber()).isEqualTo(1);
    }

    @Test
    void startProduction_epreuveNonProductive_refuse() {
        User user = data.user();

        assertThatThrownBy(() -> service.startProductionAttempt(user.getId(), req(EpreuveType.TCF_CO, null, null, null)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void startProduction_moduleNonTcf_refuse() {
        User user = data.user();
        var bad = new ProductionAttemptStartRequest(Module.CIVIQUE, EpreuveType.TCF_EE, null, null, null);

        assertThatThrownBy(() -> service.startProductionAttempt(user.getId(), bad))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void startProduction_slotHorsBorne_refuse() {
        User user = data.user();

        assertThatThrownBy(() -> service.startProductionAttempt(user.getId(), req(EpreuveType.TCF_EE, null, true, 99)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void startProduction_parentIntrouvable_lanceNotFound() {
        User user = data.user();

        assertThatThrownBy(() -> service.startProductionAttempt(
                user.getId(), req(EpreuveType.TCF_EE, UUID.randomUUID(), null, null)))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void startProduction_parentPasComplet_refuse() {
        User user = data.user();
        Attempt notComplet = data.attempt(user); // épreuve CIVIQUE

        assertThatThrownBy(() -> service.startProductionAttempt(
                user.getId(), req(EpreuveType.TCF_EE, notComplet.getId(), null, null)))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void startProduction_parentAutreUtilisateur_lanceAccessDenied() {
        User user = data.user();
        User other = data.user();
        Attempt parent = completParent(other);

        assertThatThrownBy(() -> service.startProductionAttempt(
                user.getId(), req(EpreuveType.TCF_EE, parent.getId(), null, null)))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void startProduction_parentCompletValide_relieLeSousAttempt() {
        User user = data.user();
        Attempt parent = completParent(user);

        AttemptResponse r = service.startProductionAttempt(
                user.getId(), req(EpreuveType.TCF_EE, parent.getId(), null, null));

        Attempt persisted = attemptManager.findById(r.id()).orElseThrow();
        assertThat(persisted.getParentAttempt()).isNotNull();
        assertThat(persisted.getParentAttempt().getId()).isEqualTo(parent.getId());
    }

    @Test
    void startProduction_examen_budgetGratuitDepasse_refuse() {
        User user = data.user();
        ProductionTask task = data.productionTask(EpreuveType.TCF_EE);

        // 2 sessions d'examen production avec ≥ 1 soumission chacune → budget consommé.
        for (int i = 0; i < 2; i++) {
            AttemptResponse session = service.startProductionAttempt(
                    user.getId(), req(EpreuveType.TCF_EE, null, true, 1));
            Attempt attempt = attemptManager.findById(session.id()).orElseThrow();
            data.productionSubmission(attempt, task, user);
        }

        assertThatThrownBy(() -> service.startProductionAttempt(
                user.getId(), req(EpreuveType.TCF_EE, null, true, 1)))
                .isInstanceOf(AccessDeniedException.class);
    }
}

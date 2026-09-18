package com.sejourfr.app.service;

import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.ProductionAttemptStartRequest;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.FreeEntitlementCode;
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
    void startProduction_eoExamen_poseSlotMaisAucunChronoDepreuve() {
        User user = data.user();

        AttemptResponse r = service.startProductionAttempt(user.getId(), req(EpreuveType.TCF_EO, null, true, 1));

        // L'expression orale se chronomètre PAR TÂCHE, au lancement de chaque
        // tâche (production_tasks.duree_max_sec), jamais par un compte à rebours
        // d'épreuve. Le seul plafond restant est le garde-fou de session
        // (DureeEpreuve.EO_GARDE_SESSION_SECONDS), opposé par
        // ProductionAccessService et JAMAIS persisté ni exposé : un
        // timeLimitSeconds non nul ici referait apparaître un chrono d'examen
        // sur les 3 fronts.
        assertThat(r.timeLimitSeconds()).isNull();
        Attempt persisted = attemptManager.findById(r.id()).orElseThrow();
        assertThat(persisted.getTimeLimitSeconds()).isNull();
        assertThat(persisted.getSlotNumber()).isEqualTo(1);
    }

    @Test
    void startProduction_eeSousAttemptDexamenComplet_porteSonChrono30min() {
        User user = data.user();
        Attempt parent = completParent(user);

        AttemptResponse r = service.startProductionAttempt(
                user.getId(), req(EpreuveType.TCF_EE, parent.getId(), null, null));

        // Une épreuve a la même durée où qu'elle soit jouée : l'EE d'un examen
        // complet vaut 30 min comme l'EE isolée. Son décompte ne part qu'au
        // lancement réel (timer_started_at), cf. AttemptChrono.
        assertThat(r.timeLimitSeconds()).isEqualTo(30 * 60);
        Attempt persisted = attemptManager.findById(r.id()).orElseThrow();
        assertThat(persisted.getTimeLimitSeconds()).isEqualTo(30 * 60);
        assertThat(persisted.getTimerStartedAt()).isNull();
    }

    @Test
    void startProduction_eoSousAttemptDexamenComplet_aucunChrono() {
        User user = data.user();
        Attempt parent = completParent(user);

        AttemptResponse r = service.startProductionAttempt(
                user.getId(), req(EpreuveType.TCF_EO, parent.getId(), null, null));

        assertThat(r.timeLimitSeconds()).isNull();
    }

    @Test
    void startProduction_eoEntrainement_pasDeChrono() {
        User user = data.user();

        AttemptResponse r = service.startProductionAttempt(user.getId(), req(EpreuveType.TCF_EO, null, null, null));

        // Entraînement libre : temps borné par tâche, pas de chrono d'épreuve.
        assertThat(r.timeLimitSeconds()).isNull();
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

    /**
     * 🛑 <b>D-17 bis (2026-09-18) — le REJEU d'un examen blanc est OUVERT.</b> Ce
     * test verifiait l'ancien seuil « 2 sessions d'examen, EE+EO confondues »
     * ({@code countProductionExamSessions >= 2}), qui refusait le demarrage : il
     * est <b>revoque</b>. Repasser l'epreuve n'est plus interdit ; ce qui est
     * ferme, c'est l'<b>analyse IA</b> du second passage
     * ({@code ProductionAccessService.enforceQuota}, refus avant Whisper).
     *
     * <p>A l'ECRIT, le texte reste sous les yeux du candidat : le rejeu y est
     * honnete, donc le demarrage passe, gratuite consommee ou non.
     */
    @Test
    void startProduction_examenEcrit_rejeuOuvertMemeGratuiteConsommee_D17bis() {
        User user = data.user();
        data.freeEntitlementUsage(user, FreeEntitlementCode.EXAM_BLANC_EE);

        AttemptResponse rejeu = service.startProductionAttempt(
                user.getId(), req(EpreuveType.TCF_EE, null, true, 2));

        assertThat(rejeu.id()).isNotNull();
    }

    /**
     * 🛑 <b>Sauf a l'ORAL, et c'est l'arbitrage rendu.</b> Sans Whisper, un rejeu
     * EO ne laisse <b>rien</b> a lire : ni transcription, ni note, ni trace —
     * l'audio d'un candidat n'est jamais conserve. Faire produire dans le vide
     * est un mauvais geste : le paywall se presente donc au demarrage.
     */
    @Test
    void startProduction_examenOral_rejeuRefuseAuDemarrage_D17bis() {
        User user = data.user();
        data.freeEntitlementUsage(user, FreeEntitlementCode.EXAM_BLANC_EO);

        assertThatThrownBy(() -> service.startProductionAttempt(
                user.getId(), req(EpreuveType.TCF_EO, null, true, 2)))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageContaining("jamais conservé");
    }

    /** Les deux gratuites sont NOMINATIVES : celle d'EE ne ferme pas l'oral. */
    @Test
    void startProduction_lesDeuxGratuitesSontNominatives_D17bis() {
        User user = data.user();
        data.freeEntitlementUsage(user, FreeEntitlementCode.EXAM_BLANC_EE);

        AttemptResponse oral = service.startProductionAttempt(
                user.getId(), req(EpreuveType.TCF_EO, null, true, 1));

        assertThat(oral.id()).isNotNull();
    }
}

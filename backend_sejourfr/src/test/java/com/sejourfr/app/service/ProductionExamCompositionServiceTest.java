package com.sejourfr.app.service;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.ProductionTaskManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyShort;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Composition déterministe des examens blancs production : bandes de
 * difficulté par slot (1-3 A2, 4-6 B1, 7-10 B2), sujet = n-ième du pool en
 * ordre stable, et mode examen complet (niveau cible + slot du parent).
 */
class ProductionExamCompositionServiceTest {

    private ProductionTaskManager taskManager;
    private ProductionExamCompositionService service;

    /** 6 sujets par (tâche, niveau) pour EE — assez pour toutes les bandes. */
    @BeforeEach
    void setUp() {
        taskManager = mock(ProductionTaskManager.class);
        service = new ProductionExamCompositionService(taskManager);
        for (short tache = 1; tache <= 3; tache++) {
            for (String niveau : List.of("A2", "B1", "B2")) {
                when(taskManager.findActive(eq(EpreuveType.TCF_EE), eq(niveau), eq(tache)))
                        .thenReturn(pool(tache, niveau, 6));
            }
        }
    }

    /** Pool stable : consigne = "T{tache}-{niveau}-{index}" pour tracer le choix. */
    private static List<ProductionTask> pool(short tache, String niveau, int size) {
        List<ProductionTask> out = new ArrayList<>();
        for (int i = 0; i < size; i++) {
            ProductionTask t = new ProductionTask();
            t.setId(new UUID(0, (long) tache * 1000 + niveau.hashCode() % 100 * 10 + i));
            t.setEpreuve(EpreuveType.TCF_EE);
            t.setTacheNumero(tache);
            t.setNiveauCible(niveau);
            t.setConsigne("T" + tache + "-" + niveau + "-" + i);
            t.setCreatedAt(Instant.ofEpochSecond(i));
            out.add(t);
        }
        return out;
    }

    private static Attempt examAttempt(int slot) {
        Attempt a = new Attempt();
        a.setEpreuve(EpreuveType.TCF_EE);
        a.setSlotNumber(slot);
        return a;
    }

    @Test
    void slot_1_compose_les_premiers_sujets_A2() {
        List<ProductionTask> tasks = service.composeFor(examAttempt(1));
        assertThat(tasks).extracting(ProductionTask::getConsigne)
                .containsExactly("T1-A2-0", "T2-A2-0", "T3-A2-0");
    }

    @Test
    void slot_5_compose_les_deuxiemes_sujets_B1() {
        // Bande B1 = slots 4-6 → slot 5 = index 1 du pool B1.
        List<ProductionTask> tasks = service.composeFor(examAttempt(5));
        assertThat(tasks).extracting(ProductionTask::getConsigne)
                .containsExactly("T1-B1-1", "T2-B1-1", "T3-B1-1");
    }

    @Test
    void slot_10_compose_les_quatriemes_sujets_B2() {
        // Bande B2 = slots 7-10 → slot 10 = index 3 du pool B2.
        List<ProductionTask> tasks = service.composeFor(examAttempt(10));
        assertThat(tasks).extracting(ProductionTask::getConsigne)
                .containsExactly("T1-B2-3", "T2-B2-3", "T3-B2-3");
    }

    @Test
    void meme_slot_donne_toujours_la_meme_composition() {
        assertThat(service.composeFor(examAttempt(7)))
                .extracting(ProductionTask::getConsigne)
                .isEqualTo(service.composeFor(examAttempt(7))
                        .stream().map(ProductionTask::getConsigne).toList());
    }

    @Test
    void pool_plus_petit_que_la_bande_boucle_par_modulo() {
        // Pool B2 de taille 1 (cas EO T1 « se présenter ») : slots 7-10 → toujours le même sujet.
        for (short tache = 1; tache <= 3; tache++) {
            when(taskManager.findActive(eq(EpreuveType.TCF_EE), eq("B2"), eq(tache)))
                    .thenReturn(pool(tache, "B2", 1));
        }
        assertThat(service.composeFor(examAttempt(9)))
                .extracting(ProductionTask::getConsigne)
                .containsExactly("T1-B2-0", "T2-B2-0", "T3-B2-0");
    }

    @Test
    void sous_attempt_examen_complet_utilise_niveau_cible_et_slot_parent() {
        User user = new User();
        user.setTargetLevel(TargetLevel.B1);
        Attempt parent = new Attempt();
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        parent.setSlotNumber(3); // sujet index (3-1) % 6 = 2 du pool B1
        Attempt sub = new Attempt();
        sub.setEpreuve(EpreuveType.TCF_EE);
        sub.setParentAttempt(parent);
        sub.setUser(user);

        assertThat(service.composeFor(sub))
                .extracting(ProductionTask::getConsigne)
                .containsExactly("T1-B1-2", "T2-B1-2", "T3-B1-2");
    }

    @Test
    void entrainement_libre_refuse_la_composition() {
        Attempt training = new Attempt();
        training.setEpreuve(EpreuveType.TCF_EE);
        assertThatThrownBy(() -> service.composeFor(training))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void pool_de_bande_vide_retombe_sur_toutes_les_bandes() {
        for (short tache = 1; tache <= 3; tache++) {
            when(taskManager.findActive(eq(EpreuveType.TCF_EE), eq("A2"), eq(tache)))
                    .thenReturn(List.of());
            when(taskManager.findActive(eq(EpreuveType.TCF_EE), eq((String) null), eq(tache)))
                    .thenReturn(pool(tache, "B1", 2));
        }
        assertThat(service.composeFor(examAttempt(2)))
                .extracting(ProductionTask::getConsigne)
                .containsExactly("T1-B1-1", "T2-B1-1", "T3-B1-1");
    }

    @Test
    void aucun_sujet_du_tout_leve_une_erreur() {
        when(taskManager.findActive(any(), any(), any())).thenReturn(List.of());
        assertThatThrownBy(() -> service.composeFor(examAttempt(1)))
                .isInstanceOf(BusinessException.class);
    }
}

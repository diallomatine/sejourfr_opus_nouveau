package com.sejourfr.app.service;

import com.sejourfr.app.dto.LotDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.QuestionManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Découpage des lots (TCF par questionType+difficulty, Civique par thème).
 * Unitaire pur : on pilote le compte du pool ({@code countActiveMatching}) et
 * la map des derniers attempts pour vérifier le nombre de lots et la résolution
 * de fenêtre — pas de DB.
 */
class LotServiceTest {

    private QuestionManager questionManager;
    private AttemptManager attemptManager;
    private LotService service;

    private final UUID userId = UUID.randomUUID();
    private final UUID themeId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        questionManager = mock(QuestionManager.class);
        attemptManager = mock(AttemptManager.class);
        service = new LotService(questionManager, attemptManager);
    }

    // ---- TCF : list ----

    @Test
    void listTcf_poolVide_renvoieAucunLot() {
        when(questionManager.countActiveMatching(Module.TCF, null, Difficulty.B1, QuestionType.CE)).thenReturn(0L);

        assertThat(service.list(userId, Module.TCF, QuestionType.CE, Difficulty.B1)).isEmpty();
    }

    @Test
    void listTcf_poolPartiel_renvoieUnLotPartiel() {
        // 12 < lotSize 20 → un seul lot partiel de 12.
        when(questionManager.countActiveMatching(Module.TCF, null, Difficulty.B1, QuestionType.CE)).thenReturn(12L);
        when(attemptManager.findLastFinishedByLots(userId, Module.TCF, QuestionType.CE, Difficulty.B1))
                .thenReturn(Map.of());

        var lots = service.list(userId, Module.TCF, QuestionType.CE, Difficulty.B1);

        assertThat(lots).hasSize(1);
        assertThat(lots.get(0).numero()).isEqualTo(1);
        assertThat(lots.get(0).totalQuestions()).isEqualTo(12);
        assertThat(lots.get(0).difficulty()).isEqualTo(Difficulty.B1);
    }

    @Test
    void listTcf_poolComplet_decoupeEnLotsDeTailleStandard_etEnrichitDernierScore() {
        // 45 / 20 = 2 lots complets (le reste 5 est ignoré).
        when(questionManager.countActiveMatching(Module.TCF, null, Difficulty.B1, QuestionType.CE)).thenReturn(45L);
        Attempt last = new Attempt();
        last.setScore(17);
        last.setFinishedAt(Instant.now());
        when(attemptManager.findLastFinishedByLots(userId, Module.TCF, QuestionType.CE, Difficulty.B1))
                .thenReturn(Map.of(2, last));

        var lots = service.list(userId, Module.TCF, QuestionType.CE, Difficulty.B1);

        assertThat(lots).hasSize(2);
        assertThat(lots).allMatch(l -> l.totalQuestions() == 20);
        assertThat(lots.get(0).lastScore()).isNull();
        assertThat(lots.get(1).numero()).isEqualTo(2);
        assertThat(lots.get(1).lastScore()).isEqualTo(17);
    }

    @Test
    void listTcf_userNull_neRequetePasLesDerniersAttempts() {
        when(questionManager.countActiveMatching(Module.TCF, null, Difficulty.A2, QuestionType.CO)).thenReturn(20L);

        var lots = service.list(null, Module.TCF, QuestionType.CO, Difficulty.A2);

        assertThat(lots).hasSize(1);
        assertThat(lots.get(0).lastScore()).isNull();
    }

    @Test
    void listTcf_moduleNonTcf_refuse() {
        assertThatThrownBy(() -> service.list(userId, Module.CIVIQUE, QuestionType.CE, Difficulty.B1))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void listTcf_difficultyNull_refuse() {
        assertThatThrownBy(() -> service.list(userId, Module.TCF, QuestionType.CE, null))
                .isInstanceOf(BusinessException.class);
    }

    // ---- TCF : resolveLotSize ----

    @Test
    void resolveLotSize_poolComplet_renvoieTailleStandard() {
        when(questionManager.countActiveMatching(Module.TCF, null, Difficulty.B2, QuestionType.CE)).thenReturn(60L);

        assertThat(service.resolveLotSize(Module.TCF, QuestionType.CE, Difficulty.B2, 3)).isEqualTo(20);
    }

    @Test
    void resolveLotSize_poolPartiel_lot1_renvoieToutLePool() {
        when(questionManager.countActiveMatching(Module.TCF, null, Difficulty.B1, QuestionType.CE)).thenReturn(7L);

        assertThat(service.resolveLotSize(Module.TCF, QuestionType.CE, Difficulty.B1, 1)).isEqualTo(7);
    }

    @Test
    void resolveLotSize_poolPartiel_lotAutreQue1_refuse() {
        when(questionManager.countActiveMatching(Module.TCF, null, Difficulty.B1, QuestionType.CE)).thenReturn(7L);

        assertThatThrownBy(() -> service.resolveLotSize(Module.TCF, QuestionType.CE, Difficulty.B1, 2))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void resolveLotSize_lotHorsBorne_refuse() {
        when(questionManager.countActiveMatching(Module.TCF, null, Difficulty.B1, QuestionType.CE)).thenReturn(45L);

        assertThatThrownBy(() -> service.resolveLotSize(Module.TCF, QuestionType.CE, Difficulty.B1, 3))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void resolveLotSize_lotInferieurA1_refuse() {
        assertThatThrownBy(() -> service.resolveLotSize(Module.TCF, QuestionType.CE, Difficulty.B1, 0))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void resolveLotSize_poolVide_refuse() {
        when(questionManager.countActiveMatching(Module.TCF, null, Difficulty.B1, QuestionType.CE)).thenReturn(0L);

        assertThatThrownBy(() -> service.resolveLotSize(Module.TCF, QuestionType.CE, Difficulty.B1, 1))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void lotSizeFor_niveauNonTcf_refuse() {
        assertThatThrownBy(() -> LotService.lotSizeFor(Difficulty.CSP))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void lotSizeFor_niveauxTcf_renvoie20() {
        assertThat(LotService.lotSizeFor(Difficulty.A2)).isEqualTo(20);
        assertThat(LotService.lotSizeFor(Difficulty.B1)).isEqualTo(20);
        assertThat(LotService.lotSizeFor(Difficulty.B2)).isEqualTo(20);
    }

    // ---- Civique ----

    @Test
    void listCivique_themeIdNull_refuse() {
        assertThatThrownBy(() -> service.listCivique(userId, null))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void listCivique_poolVide_renvoieAucunLot() {
        when(questionManager.countActiveMatching(Module.CIVIQUE, themeId, null, null)).thenReturn(0L);

        assertThat(service.listCivique(userId, themeId)).isEmpty();
    }

    @Test
    void listCivique_poolComplet_decoupe() {
        when(questionManager.countActiveMatching(Module.CIVIQUE, themeId, null, null)).thenReturn(40L);
        when(attemptManager.findLastFinishedByLotsCivique(userId, themeId)).thenReturn(Map.of());

        var lots = service.listCivique(userId, themeId);

        assertThat(lots).hasSize(2);
        assertThat(lots).allMatch(l -> l.totalQuestions() == 20);
        assertThat(lots).allMatch(l -> l.difficulty() == null);
    }

    @Test
    void resolveLotSizeCivique_poolPartiel_lot1() {
        when(questionManager.countActiveMatching(Module.CIVIQUE, themeId, null, null)).thenReturn(9L);

        assertThat(service.resolveLotSizeCivique(themeId, 1)).isEqualTo(9);
    }

    @Test
    void resolveLotSizeCivique_lotHorsBorne_refuse() {
        when(questionManager.countActiveMatching(Module.CIVIQUE, themeId, null, null)).thenReturn(40L);

        assertThatThrownBy(() -> service.resolveLotSizeCivique(themeId, 5))
                .isInstanceOf(BusinessException.class);
    }
}

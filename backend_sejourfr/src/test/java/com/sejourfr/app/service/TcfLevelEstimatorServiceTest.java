package com.sejourfr.app.service;

import com.sejourfr.app.dto.QcmAnswerResult;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.NiveauCecrl;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Math CECRL TCF (cf. {@link TcfLevelEstimatorService}). Test unitaire pur :
 * aucune dependance, on verrouille les bandes du score calibre (corrige du
 * hasard), le plafonnement B2 et le plancher d'epreuve.
 */
class TcfLevelEstimatorServiceTest {

    private final TcfLevelEstimatorService service = new TcfLevelEstimatorService();

    private static QcmAnswerResult ans(Difficulty d, boolean correct) {
        return new QcmAnswerResult(UUID.randomUUID(), d, correct);
    }

    // ------------------------------------------------------------------------
    // calibratedScore(weighted, maxWeighted)
    // ------------------------------------------------------------------------

    @Test
    void calibratedScore_null_ou_maxNul_retourne_base_100() {
        assertThat(service.calibratedScore(null, 10)).isEqualTo(100);
        assertThat(service.calibratedScore(5, null)).isEqualTo(100);
        assertThat(service.calibratedScore(5, 0)).isEqualTo(100);
        assertThat(service.calibratedScore(5, -3)).isEqualTo(100);
    }

    @Test
    void calibratedScore_au_niveau_du_hasard_retombe_a_100() {
        // ratio = 0.25 exactement → net = 0 → 100 (« A1 non atteint »).
        assertThat(service.calibratedScore(25, 100)).isEqualTo(100);
        // ratio < 0.25 → net borne a 0.
        assertThat(service.calibratedScore(10, 100)).isEqualTo(100);
        assertThat(service.calibratedScore(0, 100)).isEqualTo(100);
    }

    @Test
    void calibratedScore_sans_faute_atteint_le_plafond_499() {
        assertThat(service.calibratedScore(100, 100)).isEqualTo(499);
        assertThat(service.calibratedScore(6, 6)).isEqualTo(499);
    }

    @Test
    void calibratedScore_au_dela_de_un_est_borne() {
        // weighted > maxWeighted ne doit pas depasser 499 (ratio borne a 1).
        assertThat(service.calibratedScore(150, 100)).isEqualTo(499);
    }

    @Test
    void calibratedScore_milieu_de_gamme() {
        // ratio = 0.5 → net = (0.5-0.25)/0.75 = 0.3333 → 100 + 0.3333*399 ≈ 233.
        assertThat(service.calibratedScore(50, 100)).isEqualTo(233);
    }

    // ------------------------------------------------------------------------
    // levelByScore (via estimateQcm / levelFromWeighted)
    // ------------------------------------------------------------------------

    @Test
    void estimateQcm_liste_vide_ou_null_est_A1_non_atteint() {
        assertThat(service.estimateQcm(null)).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
        assertThat(service.estimateQcm(List.of())).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
    }

    @Test
    void estimateQcm_sans_faute_donne_B2() {
        List<QcmAnswerResult> all = List.of(
                ans(Difficulty.A2, true),
                ans(Difficulty.B1, true),
                ans(Difficulty.B2, true));
        assertThat(service.estimateQcm(all)).isEqualTo(NiveauCecrl.B2);
    }

    @Test
    void estimateQcm_tout_faux_est_A1_non_atteint() {
        List<QcmAnswerResult> none = List.of(
                ans(Difficulty.A2, false),
                ans(Difficulty.B1, false),
                ans(Difficulty.B2, false));
        assertThat(service.estimateQcm(none)).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
    }

    @Test
    void estimateQcm_milieu_donne_A2() {
        // gotW = 3 (B2 correct), maxW = 6 (A2+B1+B2) → ratio 0.5 → score 233 → A2.
        List<QcmAnswerResult> mixed = List.of(
                ans(Difficulty.B2, true),
                ans(Difficulty.B1, false),
                ans(Difficulty.A2, false));
        assertThat(service.estimateQcm(mixed)).isEqualTo(NiveauCecrl.A2);
    }

    @Test
    void levelFromWeighted_couvre_chaque_bande() {
        // 233 → A2 (≥200), 339 → B1 (≥300), 446 → B2 (≥400).
        assertThat(service.levelFromWeighted(50, 100)).isEqualTo(NiveauCecrl.A2);   // 233
        assertThat(service.levelFromWeighted(70, 100)).isEqualTo(NiveauCecrl.B1);   // 339
        assertThat(service.levelFromWeighted(90, 100)).isEqualTo(NiveauCecrl.B2);   // 446
    }

    @Test
    void levelFromWeighted_entrees_invalides_donnent_null() {
        assertThat(service.levelFromWeighted(null, 100)).isNull();
        assertThat(service.levelFromWeighted(50, null)).isNull();
        assertThat(service.levelFromWeighted(50, 0)).isNull();
    }

    // ------------------------------------------------------------------------
    // capB2
    // ------------------------------------------------------------------------

    @Test
    void capB2_plafonne_C1_C2_a_B2_et_laisse_le_reste() {
        assertThat(service.capB2(NiveauCecrl.C1)).isEqualTo(NiveauCecrl.B2);
        assertThat(service.capB2(NiveauCecrl.C2)).isEqualTo(NiveauCecrl.B2);
        assertThat(service.capB2(NiveauCecrl.B2)).isEqualTo(NiveauCecrl.B2);
        assertThat(service.capB2(NiveauCecrl.B1)).isEqualTo(NiveauCecrl.B1);
        assertThat(service.capB2(NiveauCecrl.A1_NON_ATTEINT)).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
        assertThat(service.capB2(null)).isNull();
    }

    // ------------------------------------------------------------------------
    // min / floor
    // ------------------------------------------------------------------------

    @Test
    void min_tolere_les_null_et_prend_le_plus_faible() {
        assertThat(service.min(null, NiveauCecrl.B1)).isEqualTo(NiveauCecrl.B1);
        assertThat(service.min(NiveauCecrl.A2, null)).isEqualTo(NiveauCecrl.A2);
        assertThat(service.min(NiveauCecrl.A2, NiveauCecrl.B1)).isEqualTo(NiveauCecrl.A2);
        // min n'applique PAS le plafond B2.
        assertThat(service.min(NiveauCecrl.C1, NiveauCecrl.C2)).isEqualTo(NiveauCecrl.C1);
    }

    @Test
    void floor_prend_le_plancher_en_ignorant_les_null_et_plafonne_B2() {
        assertThat(service.floor(List.of(NiveauCecrl.B1, NiveauCecrl.A2, NiveauCecrl.B2)))
                .isEqualTo(NiveauCecrl.A2);
        assertThat(service.floor(Arrays.asList(null, NiveauCecrl.B1)))
                .isEqualTo(NiveauCecrl.B1);
        // Plancher C1 plafonne a B2.
        assertThat(service.floor(List.of(NiveauCecrl.C1, NiveauCecrl.C2)))
                .isEqualTo(NiveauCecrl.B2);
    }

    @Test
    void floor_liste_vide_ou_que_des_null_donne_null() {
        assertThat(service.floor(List.of())).isNull();
        assertThat(service.floor(Arrays.asList((NiveauCecrl) null, null))).isNull();
    }
}

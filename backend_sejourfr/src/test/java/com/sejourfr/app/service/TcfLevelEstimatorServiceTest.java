package com.sejourfr.app.service;

import com.sejourfr.app.dto.LigneStrateQcm;
import com.sejourfr.app.dto.QcmAnswerResult;
import com.sejourfr.app.dto.StrateQcm;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.manager.AttemptQuestionManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * 🛑 <b>Le test qui GELE la regle du niveau QCM</b> (cf.
 * {@link TcfLevelEstimatorService} et {@code docs/regles/qcm.md}).
 *
 * <p><b>Il remplace le gel de l'ancienne formule</b> — bandes du score calibre
 * (frontieres 43/44, 62/63, 81/82) et plancher A1 « au moins une bonne
 * reponse ». Ces deux regles n'existent plus : la bande A2 y etait
 * <b>inatteignable par un candidat A2</b> (8 items A2 sur 50 points ponderes =
 * 16 %, donc sous la ligne de hasard de 25 %), et le plancher A1 n'en traitait
 * que le symptome.
 *
 * <p>Ce qui reste gele de l'ancien monde : la <b>formule</b> du score 100-499
 * (100 / 233 / 499 aux memes entrees). Ce qui a disparu : toute conversion
 * « score → palier ». Le score est un score de <b>progression</b>.
 */
class TcfLevelEstimatorServiceTest {

    private final AttemptQuestionManager attemptQuestionManager =
            mock(AttemptQuestionManager.class);
    private final TcfLevelEstimatorService service =
            new TcfLevelEstimatorService(attemptQuestionManager);

    private static QcmAnswerResult ans(Difficulty d, boolean correct) {
        return new QcmAnswerResult(UUID.randomUUID(), d, correct);
    }

    /** {@code n} items d'un palier dont {@code bons} sont reussis. */
    private static List<QcmAnswerResult> strate(Difficulty d, int n, int bons) {
        List<QcmAnswerResult> out = new ArrayList<>(n);
        for (int i = 0; i < n; i++) out.add(ans(d, i < bons));
        return out;
    }

    private static List<QcmAnswerResult> examen(int a2bons, int b1bons, int b2bons) {
        List<QcmAnswerResult> out = new ArrayList<>(25);
        out.addAll(strate(Difficulty.A2, 10, a2bons));
        out.addAll(strate(Difficulty.B1, 8, b1bons));
        out.addAll(strate(Difficulty.B2, 7, b2bons));
        return out;
    }

    // ════════════════════════════════════════════════════════════════════
    //  LA REGLE : le plus haut palier MAITRISE, sans saut
    // ════════════════════════════════════════════════════════════════════

    /**
     * 🛑 <b>Le defaut que cette regle repare.</b> Un candidat qui maitrise tout
     * l'A2 et rien d'autre est A2. L'ancienne formule le rendait
     * « A1 non atteint » : 10 points ponderes sur 47, soit 21 %, donc SOUS la
     * ligne de hasard — score 100/499, bande la plus basse.
     */
    @Test
    @DisplayName("tout l'A2 et rien d'autre => A2 (l'ancienne formule rendait A1_NON_ATTEINT)")
    void toute_la_strate_A2_et_rien_dautre_donne_A2() {
        List<QcmAnswerResult> examen = examen(10, 0, 0);
        assertThat(service.estimateQcm(examen)).isEqualTo(NiveauCecrl.A2);
        // Le score de progression, lui, reste bas — et c'est normal : il mesure
        // l'avancee, pas le palier. 10/47 pondere = 21 %, sous le hasard.
        assertThat(service.calibratedScore(examen)).isEqualTo(100);
    }

    /**
     * 🛑 <b>Le seuil : 60 %, arrondi a l'entier SUPERIEUR.</b> Sur la
     * composition 10 A2 / 8 B1 / 7 B2, cela fait <b>6/10</b>, <b>5/8</b> et
     * <b>5/7</b> — les trois chiffres que le propriétaire a arbitrés sur la
     * probabilité de decrocher le palier en cliquant au hasard (1,97 %, 2,73 %
     * et 1,29 %). A 5/10 (50 %) elle serait de 7,5 %, soit une fois sur treize.
     */
    @Test
    @DisplayName("la strate bascule a 6/10, 5/8 et 5/7 — 60 % arrondi au superieur")
    void seuil_de_maitrise_a_60_pourcent_arrondi_au_superieur() {
        assertThat(TcfLevelEstimatorService.itemsRequis(10)).isEqualTo(6);
        assertThat(TcfLevelEstimatorService.itemsRequis(8)).isEqualTo(5);
        assertThat(TcfLevelEstimatorService.itemsRequis(7)).isEqualTo(5);

        assertThat(service.estimateQcm(examen(5, 0, 0))).isEqualTo(NiveauCecrl.A1);
        assertThat(service.estimateQcm(examen(6, 0, 0))).isEqualTo(NiveauCecrl.A2);
        assertThat(service.estimateQcm(examen(6, 4, 0))).isEqualTo(NiveauCecrl.A2);
        assertThat(service.estimateQcm(examen(6, 5, 0))).isEqualTo(NiveauCecrl.B1);
        assertThat(service.estimateQcm(examen(6, 5, 4))).isEqualTo(NiveauCecrl.B1);
        assertThat(service.estimateQcm(examen(6, 5, 5))).isEqualTo(NiveauCecrl.B2);
    }

    /** 🛑 Pas de saut de palier : un B1 tenu sans l'A2 ne rend pas B1. */
    @Test
    @DisplayName("B1 maitrise mais A2 rate => A1, jamais B1")
    void pas_de_saut_de_palier() {
        assertThat(service.estimateQcm(examen(2, 8, 7))).isEqualTo(NiveauCecrl.A1);
        assertThat(service.estimateQcm(examen(10, 2, 7))).isEqualTo(NiveauCecrl.A2);
        assertThat(service.estimateQcm(examen(10, 8, 2))).isEqualTo(NiveauCecrl.B1);
        assertThat(service.estimateQcm(examen(10, 8, 7))).isEqualTo(NiveauCecrl.B2);
    }

    /**
     * {@code A1} est le plancher REEL ; {@code A1_NON_ATTEINT} est reserve au
     * cas « zero bonne reponse sur l'epreuve entiere », devenu quasi theorique.
     */
    @Test
    @DisplayName("A1_NON_ATTEINT est reserve a ZERO bonne reponse sur l'epreuve entiere")
    void plancher_bas_de_la_regle() {
        assertThat(service.estimateQcm(examen(0, 0, 0))).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
        assertThat(service.estimateQcm(examen(1, 0, 0))).isEqualTo(NiveauCecrl.A1);
        assertThat(service.estimateQcm(examen(0, 0, 1))).isEqualTo(NiveauCecrl.A1);
    }

    /**
     * 🛑 <b>Deux situations distinctes, un seul verdict — et c'est le
     * comportement d'AVANT, pas un arbitrage.</b> « Le candidat a repondu, tout
     * est faux » et « aucune reponse n'a jamais ete donnee » (session ouverte
     * puis abandonnee) valent tous deux {@code A1_NON_ATTEINT}. La donnee les
     * distingue desormais ({@code StrateQcm.repondus}) pour qu'un futur
     * arbitrage n'ait pas a la reconstruire ; ce test PIN le comportement
     * actuel, il ne le justifie pas.
     */
    @Test
    @DisplayName("« tout faux » et « aucune reponse donnee » : distingues dans la donnee, meme verdict")
    void zero_bonne_reponse_et_zero_reponse_donnee_sont_distingues_mais_pas_arbitres() {
        List<StrateQcm> toutFaux = List.of(
                StrateQcm.mesuree(Difficulty.A2, 10, 0),
                StrateQcm.mesuree(Difficulty.B1, 8, 0),
                StrateQcm.mesuree(Difficulty.B2, 7, 0));
        List<StrateQcm> abandon = List.of(
                new StrateQcm(Difficulty.A2, 10, 0, 0),
                new StrateQcm(Difficulty.B1, 8, 0, 0),
                new StrateQcm(Difficulty.B2, 7, 0, 0));

        assertThat(toutFaux).allSatisfy(st -> assertThat(st.repondus()).isPositive());
        assertThat(abandon).allSatisfy(st -> assertThat(st.repondus()).isZero());

        assertThat(service.niveauParStrates(toutFaux)).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
        assertThat(service.niveauParStrates(abandon)).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
    }

    /** 🛑 {@code null} = inconnu, jamais mauvais : rien de pose ⇒ aucun niveau. */
    @Test
    @DisplayName("rien de pose => null (inconnu), pas A1_NON_ATTEINT")
    void rien_de_pose_est_inconnu() {
        assertThat(service.estimateQcm(null)).isNull();
        assertThat(service.estimateQcm(List.of())).isNull();
        assertThat(service.niveauParStrates(List.of())).isNull();
        assertThat(service.niveauParStrates(null)).isNull();
        // Des items civiques (CSP/CR/NAT) ne sont pas des paliers CECRL.
        assertThat(service.estimateQcm(List.of(ans(Difficulty.CSP, true)))).isNull();
    }

    /** Une strate sans item n'est pas maitrisee : la montee s'y arrete. */
    @Test
    @DisplayName("strate absente => la montee s'arrete (un garde-fou ne peut qu'abaisser)")
    void strate_absente_arrete_la_montee() {
        assertThat(service.niveauParStrates(List.of(
                StrateQcm.mesuree(Difficulty.B1, 8, 8),
                StrateQcm.mesuree(Difficulty.B2, 7, 7)))).isEqualTo(NiveauCecrl.A1);
    }

    /** Les strates se CUMULENT : c'est ce qui permet de moyenner 3 examens. */
    @Test
    @DisplayName("deux mesures du meme palier se cumulent avant le seuil")
    void les_strates_se_cumulent() {
        // 20 items A2 cumules : il en faut 12 (60 % arrondi au superieur).
        assertThat(service.niveauParStrates(List.of(
                StrateQcm.mesuree(Difficulty.A2, 10, 6),
                StrateQcm.mesuree(Difficulty.A2, 10, 6),
                StrateQcm.mesuree(Difficulty.B1, 8, 0)))).isEqualTo(NiveauCecrl.A2); // 12/20
        assertThat(service.niveauParStrates(List.of(
                StrateQcm.mesuree(Difficulty.A2, 10, 6),
                StrateQcm.mesuree(Difficulty.A2, 10, 5),
                StrateQcm.mesuree(Difficulty.B1, 8, 0)))).isEqualTo(NiveauCecrl.A1); // 11/20
    }

    /** Plusieurs epreuves dans une meme session : plancher, regle TCF IRN. */
    @Test
    @DisplayName("niveauParEpreuves prend le plancher des epreuves")
    void niveau_par_epreuves_prend_le_plancher() {
        assertThat(service.niveauParEpreuves(java.util.Map.of(
                QuestionType.CO, List.of(StrateQcm.mesuree(Difficulty.A2, 10, 10),
                        StrateQcm.mesuree(Difficulty.B1, 8, 8), StrateQcm.mesuree(Difficulty.B2, 7, 7)),
                QuestionType.CE, List.of(StrateQcm.mesuree(Difficulty.A2, 10, 2)))))
                .isEqualTo(NiveauCecrl.A1);
    }

    // ════════════════════════════════════════════════════════════════════
    //  LECTURE — derivee des reponses, en UNE requete
    // ════════════════════════════════════════════════════════════════════

    /**
     * 🛑 La forme de liste demande TOUTES les tentatives d'un coup, et
     * {@code CO_IMAGE} se replie sous {@code CO} (c'est la meme epreuve).
     */
    @Test
    @DisplayName("niveauxQcm derive chaque tentative des reponses, en une passe")
    void niveaux_qcm_en_une_passe() {
        UUID a = UUID.randomUUID();
        UUID b = UUID.randomUUID();
        when(attemptQuestionManager.stratesParAttempt(anyCollection())).thenReturn(List.of(
                new LigneStrateQcm(a, QuestionType.CO, StrateQcm.mesuree(Difficulty.A2, 5, 5)),
                new LigneStrateQcm(a, QuestionType.CO_IMAGE, StrateQcm.mesuree(Difficulty.A2, 5, 2)),
                new LigneStrateQcm(a, QuestionType.CO, StrateQcm.mesuree(Difficulty.B1, 8, 0)),
                new LigneStrateQcm(b, QuestionType.CE, StrateQcm.mesuree(Difficulty.A2, 10, 0))));

        // a : CO et CO_IMAGE repliees ensemble → 7/10 A2 = 70 % → A2, B1 rate.
        assertThat(service.niveauxQcm(List.of(a, b)))
                .containsEntry(a, NiveauCecrl.A2)
                .containsEntry(b, NiveauCecrl.A1_NON_ATTEINT);
    }

    /** Une tentative sans item exploitable est ABSENTE de la map : inconnu. */
    @Test
    @DisplayName("une tentative sans strate n'a pas de niveau, elle n'a pas A1_NON_ATTEINT")
    void tentative_sans_strate_est_absente() {
        when(attemptQuestionManager.stratesParAttempt(anyCollection())).thenReturn(List.of());
        Attempt vide = new Attempt();
        vide.setId(UUID.randomUUID());
        assertThat(service.niveauxQcm(List.of(vide.getId()))).isEmpty();
        assertThat(service.niveauEpreuveQcm(vide)).isNull();
        assertThat(service.niveauEpreuveQcm(null)).isNull();
    }

    // ════════════════════════════════════════════════════════════════════
    //  SCORE DE PROGRESSION — la formule ne bouge pas, mais elle ne CLASSE plus
    // ════════════════════════════════════════════════════════════════════

    @Test
    void calibratedScore_null_ou_maxNul_retourne_base_100() {
        assertThat(service.calibratedScore(null, 10)).isEqualTo(100);
        assertThat(service.calibratedScore(5, null)).isEqualTo(100);
        assertThat(service.calibratedScore(5, 0)).isEqualTo(100);
        assertThat(service.calibratedScore(5, -3)).isEqualTo(100);
    }

    /**
     * La <b>formule</b> 100-499 corrigee du hasard est inchangee — c'est la
     * seule chose que l'ancien gel avait raison de figer. Les frontieres
     * 43/44, 62/63 et 81/82 ne sont plus verrouillees : elles delimitaient des
     * <b>bandes de palier</b>, et il n'existe plus de bande.
     */
    @Test
    @DisplayName("la formule du score de progression ne bouge pas")
    void la_formule_du_score_ne_bouge_pas() {
        assertThat(service.calibratedScore(0, 100)).isEqualTo(100);
        assertThat(service.calibratedScore(25, 100)).isEqualTo(100);   // hasard pur
        assertThat(service.calibratedScore(10, 100)).isEqualTo(100);   // sous le hasard
        assertThat(service.calibratedScore(50, 100)).isEqualTo(233);
        assertThat(service.calibratedScore(100, 100)).isEqualTo(499);
        assertThat(service.calibratedScore(150, 100)).isEqualTo(499);  // borne a 1
        assertThat(service.calibratedScore(6, 6)).isEqualTo(499);
    }

    /**
     * 🛑 <b>Aucune methode ne convertit un score en palier.</b> C'est la
     * propriete qui empeche la bande A2 morte de revenir par une autre porte :
     * si quelqu'un reintroduit une table « score → niveau », ce test le dit.
     */
    @Test
    @DisplayName("aucune conversion score → palier n'existe plus")
    void aucune_conversion_score_vers_palier() {
        assertThat(TcfLevelEstimatorService.class.getMethods())
                .noneMatch(m -> m.getReturnType() == NiveauCecrl.class
                        && m.getParameterCount() >= 1
                        && Arrays.stream(m.getParameterTypes())
                                .anyMatch(t -> t == Integer.class || t == int.class));
    }

    // ════════════════════════════════════════════════════════════════════
    //  ALGEBRE DES PALIERS
    // ════════════════════════════════════════════════════════════════════

    @Test
    void capB2_plafonne_C1_C2_a_B2_et_laisse_le_reste() {
        assertThat(service.capB2(NiveauCecrl.C1)).isEqualTo(NiveauCecrl.B2);
        assertThat(service.capB2(NiveauCecrl.C2)).isEqualTo(NiveauCecrl.B2);
        assertThat(service.capB2(NiveauCecrl.B2)).isEqualTo(NiveauCecrl.B2);
        assertThat(service.capB2(NiveauCecrl.B1)).isEqualTo(NiveauCecrl.B1);
        assertThat(service.capB2(NiveauCecrl.A1_NON_ATTEINT)).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
        assertThat(service.capB2(null)).isNull();
    }

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
        assertThat(service.floor(List.of(NiveauCecrl.C1, NiveauCecrl.C2)))
                .isEqualTo(NiveauCecrl.B2);
    }

    @Test
    void floor_liste_vide_ou_que_des_null_donne_null() {
        assertThat(service.floor(List.of())).isNull();
        assertThat(service.floor(Arrays.asList((NiveauCecrl) null, null))).isNull();
    }
}

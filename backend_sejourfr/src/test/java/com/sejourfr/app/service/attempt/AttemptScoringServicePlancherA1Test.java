package com.sejourfr.app.service.attempt;

import com.sejourfr.app.entity.Answer;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.service.TcfLevelEstimatorService;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Verrouille le <b>plancher produit SejourFR</b> — « au moins une bonne reponse
 * ⇒ au moins A1 » — la ou il est reellement PERSISTE : la finalisation d'un
 * attempt QCM ecrit {@code attempts.cecrl_level} depuis
 * {@link AttemptScoringService#estimatePerEpreuveFloor}.
 *
 * <p>Le plancher vit dans {@link TcfLevelEstimatorService#plancherA1SiUneBonneReponse}
 * — autorite unique, jamais recopiee. On verifie ici qu'il traverse bien le
 * chemin de scoring, pour les <b>trois</b> epreuves QCM (CO / CE / STRUCTURE),
 * et qu'il ne touche a rien d'autre.
 *
 * <p>Unitaire pur : {@link TcfLevelEstimatorService} est utilise REEL (sans
 * dependance, c'est la math CECRL elle-meme).
 */
class AttemptScoringServicePlancherA1Test {

    private final AttemptScoringService scoring =
            new AttemptScoringService(new TcfLevelEstimatorService());

    /**
     * Composition d'un examen module TCF : 8 A2 + 9 B1 + 8 B2, poids
     * 8×1 + 9×2 + 8×3 = 50. {@code bonnes} designe le nombre de questions A2
     * repondues juste, en partant du debut.
     */
    private static List<AttemptQuestion> epreuve(QuestionType type, int bonnesA2) {
        List<AttemptQuestion> aqs = new ArrayList<>();
        int posee = 0;
        for (Difficulty d : List.of(Difficulty.A2, Difficulty.B1, Difficulty.B2)) {
            int n = d == Difficulty.B1 ? 9 : 8;
            for (int i = 0; i < n; i++) {
                boolean correct = d == Difficulty.A2 && posee++ < bonnesA2;
                aqs.add(aq(type, d, correct));
            }
        }
        return aqs;
    }

    private static AttemptQuestion aq(QuestionType type, Difficulty d, boolean correct) {
        Question q = new Question();
        q.setId(UUID.randomUUID());
        q.setQuestionType(type);
        q.setDifficulty(d);

        AttemptQuestion a = new AttemptQuestion();
        a.setId(UUID.randomUUID());
        a.setQuestion(q);

        Answer ans = new Answer();
        ans.setCorrect(correct);
        a.setAnswer(ans);
        return a;
    }

    /** Aucune reponse enregistree du tout — a distinguer de « toutes fausses ». */
    private static List<AttemptQuestion> epreuveSansAucuneReponse(QuestionType type) {
        List<AttemptQuestion> aqs = epreuve(type, 0);
        aqs.forEach(a -> a.setAnswer(null));
        return aqs;
    }

    // ------------------------------------------------------------ zero bonne

    @Test
    void zeroBonneReponse_reste_A1_non_atteint_sur_les_trois_epreuves() {
        for (QuestionType type : List.of(QuestionType.CO, QuestionType.CE, QuestionType.STRUCTURE)) {
            assertThat(scoring.estimatePerEpreuveFloor(epreuve(type, 0)))
                    .as("epreuve %s, tout faux", type)
                    .isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
        }
    }

    /**
     * « Aucune reponse donnee » n'est pas un cas separe : c'est aussi zero
     * bonne reponse, donc {@code A1_NON_ATTEINT}. Le candidat a bien ouvert
     * l'epreuve (sinon elle n'aurait pas de niveau du tout — cf.
     * {@code FullTcfExamResponseBuilder}), il n'y a simplement rien reussi.
     */
    @Test
    void aucuneReponseDonnee_reste_A1_non_atteint() {
        for (QuestionType type : List.of(QuestionType.CO, QuestionType.CE, QuestionType.STRUCTURE)) {
            assertThat(scoring.estimatePerEpreuveFloor(epreuveSansAucuneReponse(type)))
                    .as("epreuve %s, aucune reponse", type)
                    .isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
        }
    }

    // ------------------------------------------------------- une bonne reponse

    /**
     * LE cas de la regle : 1 bonne reponse sur 25 pese 1/50, soit 2 % — bien
     * sous la ligne du hasard (25 %), donc score calibre a sa borne basse
     * (100/499) et bande {@code A1_NON_ATTEINT}. Le plancher rend {@code A1}.
     */
    @Test
    void uneSeuleBonneReponse_donne_A1_sur_les_trois_epreuves() {
        for (QuestionType type : List.of(QuestionType.CO, QuestionType.CE, QuestionType.STRUCTURE)) {
            assertThat(scoring.estimatePerEpreuveFloor(epreuve(type, 1)))
                    .as("epreuve %s, une bonne reponse", type)
                    .isEqualTo(NiveauCecrl.A1);
            // Le score pondere, lui, ne bouge pas d'un point.
            assertThat(scoring.computeWeightedScore(epreuve(type, 1), true)).isEqualTo(1);
            assertThat(scoring.computeWeightedScore(epreuve(type, 1), false)).isEqualTo(50);
        }
    }

    /**
     * Le plancher ne releve que depuis {@code A1_NON_ATTEINT} : des que la
     * bande vaut deja A2, il n'a plus aucun effet. 8 A2 justes = 8/50 = 16 %,
     * toujours sous le hasard ⇒ A1 ; il faut aller chercher les strates
     * ponderees pour sortir de la borne basse.
     */
    @Test
    void un_score_qui_vaut_deja_A2_nest_pas_touche() {
        List<AttemptQuestion> aqs = new ArrayList<>();
        // 8 A2 + 9 B1 justes = 8 + 18 = 26/50 = 52 % → calibre 244 → A2.
        for (int i = 0; i < 8; i++) aqs.add(aq(QuestionType.CO, Difficulty.A2, true));
        for (int i = 0; i < 9; i++) aqs.add(aq(QuestionType.CO, Difficulty.B1, true));
        for (int i = 0; i < 8; i++) aqs.add(aq(QuestionType.CO, Difficulty.B2, false));

        assertThat(new TcfLevelEstimatorService().calibratedScore(26, 50)).isEqualTo(244);
        assertThat(scoring.estimatePerEpreuveFloor(aqs)).isEqualTo(NiveauCecrl.A2);
    }

    /**
     * Le plancher s'applique <b>epreuve par epreuve</b>, avant le plancher
     * ordinal entre epreuves : un examen template CO→CE dont la CO est parfaite
     * et la CE a une seule bonne reponse sort en A1, jamais en A1_NON_ATTEINT.
     */
    @Test
    void le_plancher_sapplique_par_epreuve_avant_le_plancher_entre_epreuves() {
        List<AttemptQuestion> aqs = new ArrayList<>();
        aqs.addAll(epreuve(QuestionType.CO, 8));  // CO : les 8 A2 justes
        for (AttemptQuestion a : aqs) {
            if (a.getQuestion().getDifficulty() != Difficulty.A2) a.getAnswer().setCorrect(true);
        }
        aqs.addAll(epreuve(QuestionType.CE, 1));  // CE : une seule bonne reponse

        assertThat(scoring.estimatePerEpreuveFloor(aqs)).isEqualTo(NiveauCecrl.A1);
    }

    /** CO_IMAGE est regroupee sous CO : la regle vaut aussi pour ce format. */
    @Test
    void coImage_est_regroupee_sous_CO_et_suit_la_meme_regle() {
        List<AttemptQuestion> aqs = epreuve(QuestionType.CO, 1);
        aqs.getFirst().getQuestion().setQuestionType(QuestionType.CO_IMAGE);
        assertThat(scoring.estimatePerEpreuveFloor(aqs)).isEqualTo(NiveauCecrl.A1);
    }
}

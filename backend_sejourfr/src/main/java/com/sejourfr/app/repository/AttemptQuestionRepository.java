package com.sejourfr.app.repository;

import com.sejourfr.app.entity.AttemptQuestion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AttemptQuestionRepository extends JpaRepository<AttemptQuestion, UUID> {

    List<AttemptQuestion> findByAttemptIdOrderByPositionAsc(UUID attemptId);

    /**
     * Items poses et items reussis d'un attempt, <b>ventiles par palier</b>
     * ({@code questions.difficulty}). Une ligne par palier :
     * {@code [Difficulty, posés, réussis]}.
     *
     * <p>C'est le denominateur reel du calcul de niveau du diagnostic
     * ({@code TcfDiagnosticLevelResolver}) : le taux se lit palier par palier,
     * jamais sur le total — 10 bonnes reponses sur 15 ne disent rien tant qu'on
     * ignore lesquelles.
     *
     * <p>Une question sans reponse compte comme <b>posee et non reussie</b> :
     * dans une section chronometree qu'on termine d'une traite, ne pas repondre
     * est une reponse. Le {@code LEFT JOIN} le garantit — {@code COUNT(aq)} ne
     * bouge pas, la somme ajoute zero.
     *
     * <p>🔴 <b>La justesse se lit sur {@code answers.is_correct}, JAMAIS sur
     * {@code attempt_questions.is_correct}</b> (corrige le 2026-09-11). La
     * seconde colonne existe en base mais <b>aucun code ne l'ecrit</b> : le seul
     * point d'ecriture de la correction d'un QCM est
     * {@code AttemptInteractionService.doSubmitAnswer}, et il pose
     * {@code answer.setCorrect(...)}. Mesure sur la base de developpement :
     * <b>0 ligne renseignee sur 9 441</b> cote {@code attempt_questions},
     * 2 161 cote {@code answers}. Ces deux agregats etaient donc les
     * <b>seuls</b> lecteurs de la colonne morte — tout le reste du depot passe
     * deja par {@code aq.getAnswer().getCorrect()}
     * ({@code AttemptScoringService}, {@code AttemptMapper}).
     *
     * <p>🛑 <b>Ce que ca cassait</b> : les trois diagnostics civiques reels de
     * la base valaient 23, 11 et 10 bonnes reponses sur 40 — et l'ecran de
     * resultat annoncait <b>0/40</b> aux trois, donc tous les themes
     * {@code FAIBLE}, tous priorites, et un plan civique entierement bati sur
     * une mesure fausse. C'est la confusion que le depot paie deja cher ailleurs
     * (V040/V041/V042) : une absence de donnee devenue le verdict le plus bas.
     *
     * <p>⚠️ {@code attempt_questions.is_correct} reste en place, non ecrite et
     * desormais non lue — regle du depot : une colonne legacy cesse d'etre
     * ecrite et mappee, elle ne se supprime pas.
     */
    @Query("""
            SELECT aq.question.difficulty,
                   COUNT(aq),
                   SUM(CASE WHEN a.correct = true THEN 1 ELSE 0 END)
            FROM AttemptQuestion aq
                     LEFT JOIN aq.answer a
            WHERE aq.attempt.id = :attemptId
            GROUP BY aq.question.difficulty
            """)
    List<Object[]> aggregateByDifficulty(@Param("attemptId") UUID attemptId);

    /**
     * Agregat par THEME et par type de question, pour le diagnostic civique
     * (L9) : {@code [themeId, QuestionType, poses, reussis]}.
     *
     * <p>Le type est dans le regroupement parce que 20_ §4.5 compte les
     * <b>mises en situation a part</b> : appliquer une regle a un cas concret
     * est une competence distincte de la restituer, et l'ecran le dit.
     *
     * <p>🛑 <b>Une question sans reponse compte comme posee et non reussie</b>,
     * comme au TCF : dans un diagnostic qu'on termine d'une traite, ne pas
     * repondre est une reponse. C'est different d'un theme jamais TIRE, qui lui
     * n'apparait pas du tout ici et ressort « non evalue ». Le {@code LEFT JOIN}
     * le garantit — {@code COUNT(aq)} ne bouge pas, la somme ajoute zero.
     *
     * <p>🔴 <b>Meme correction que {@link #aggregateByDifficulty} le
     * 2026-09-11, et meme cause</b> : la justesse se lit sur
     * {@code answers.is_correct}. Voir le detail la-bas.
     */
    @Query("""
            SELECT aq.question.theme.id,
                   aq.question.questionType,
                   COUNT(aq),
                   SUM(CASE WHEN a.correct = true THEN 1 ELSE 0 END)
            FROM AttemptQuestion aq
                     LEFT JOIN aq.answer a
            WHERE aq.attempt.id = :attemptId
            GROUP BY aq.question.theme.id, aq.question.questionType
            """)
    List<Object[]> aggregateByThemeAndType(@Param("attemptId") UUID attemptId);
}

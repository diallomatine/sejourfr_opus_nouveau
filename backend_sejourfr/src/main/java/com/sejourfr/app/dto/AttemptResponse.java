package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.TargetLevel;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Une session QCM / production, telle que les fronts la lisent.
 *
 * <p>🛑 <b>{@link #mode} dit le REGIME DE PASSATION, et il est SERVI</b> : un
 * front ne le deduit ni d'une route, ni d'un parametre d'URL, ni du
 * {@link #type}. Voir le champ.
 */
public record AttemptResponse(
        UUID id,
        AttemptType type,
        /**
         * <b>Le REGIME DE PASSATION de cette session</b> — le seul fait qui dise
         * si le candidat voit les corrections pendant qu'il joue.
         *
         * <table>
         *   <tr><th>{@code mode}</th><th>Pendant la session</th><th>Audio (CO)</th></tr>
         *   <tr><td>{@code ENTRAINEMENT}</td>
         *       <td>correction immediate apres chaque reponse</td>
         *       <td>reecoutable</td></tr>
         *   <tr><td>{@code EXAMEN}</td>
         *       <td><b>aucune</b> correction : ni bonne reponse, ni explication</td>
         *       <td><b>joue une seule fois</b></td></tr>
         *   <tr><td>{@code REVISION}</td>
         *       <td>aucune correction en cours de session</td>
         *       <td>reecoutable</td></tr>
         * </table>
         *
         * <h3>🛑 Pourquoi ce champ, et pas {@code type}</h3>
         * <p>Depuis le 2026-09-20, une <b>serie lancee depuis une carte d'etape
         * du Plan</b> reste un {@code AttemptType.TRAINING} — pour ne rien
         * changer au freemium ni a l'historique — mais se joue <b>comme un
         * examen</b> : sans correction, audio joue une fois. Le {@code type} ne
         * suffit donc plus a repondre, et c'est exactement le genre de fait
         * qu'un front ne peut pas deviner. {@code attempts.mode} existait deja
         * en base, {@code NOT NULL}, sans <b>aucun</b> lecteur : il devient le
         * porteur de cette question, plutot qu'un second champ qui dirait la
         * meme chose.
         *
         * <p>🛑 <b>C'est la MEME valeur que le serveur oppose</b> :
         * {@code AttemptInteractionService.doSubmitAnswer} ne renvoie la
         * correction que pour {@code ENTRAINEMENT}. L'ecran et le refus ne
         * peuvent donc pas diverger.
         */
        AttemptMode mode,
        Module module,
        UUID examTemplateId,
        String examTemplateSlug,
        String examTemplateName,
        Integer totalQuestions,
        Integer timeLimitSeconds,
        Integer passThreshold,
        Instant startedAt,
        Instant finishedAt,
        Integer score,
        TargetLevel levelAchieved,
        // Non-null quand l'attempt est un examen module TCF (CO ou CE) — sert
        // au mobile pour appliquer les conditions strictes (audio auto-play
        // 2s, pas de pause, lecture unique, soumission auto à la fin du temps).
        QuestionType moduleExamQuestionType,
        // Thème civique scopé (lotThemeId) — non-null pour les séries et
        // examens thématiques civiques. Sert au web à retrouver l'écran
        // d'origine (retour de session vers /entrainement/civique/{themeId}).
        UUID themeId,
        // Score calibré 100-499 (examens module TCF) + niveau CECRL estimé.
        // Affichage façon relevé TCF (X/499 + niveau) à la place du X/50 interne.
        // Null hors examen module TCF.
        Integer calibratedScore,
        NiveauCecrl cecrlLevel,
        // Détail par épreuve d'un examen TCF stratifié fini (CO/CE…) — le
        // cecrlLevel global ci-dessus est le plancher de ces niveaux, comme
        // au TCF IRN. Vide hors examen TCF ou tant que l'attempt court.
        List<AttemptEpreuveResult> epreuveResults,
        List<AttemptQuestionResponse> questions
) {}

package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

/**
 * Payload pour POST /api/attempts.
 *
 * Modes de démarrage (ordre de priorité) :
 *   0. skillId fourni → SÉRIE CIBLÉE d'une compétence de COMPRÉHENSION (CO / CE) :
 *      20 questions du domaine et du niveau de la compétence. Le client n'envoie
 *      QUE la compétence — questionType, difficulty et size sont dérivés côté
 *      serveur et tout autre filtre est ignoré. Le verrou freemium est opposable
 *      (SkillAccessService.assertCanTrain).
 *   1. examTemplateId fourni → MOCK_EXAM piloté par un ExamTemplate.
 *      Les autres filtres (themeId, difficulty, questionType, size, lotNumero,
 *      moduleExamQuestionType) sont ignorés au profit des ExamTemplateRule.
 *   2. lotNumero fourni → TRAINING sur un lot précis (voir {@link com.sejourfr.app.service.LotService}).
 *      module + difficulty (A2/B1/B2) + questionType (CO/CE) déterminent le pool ;
 *      la fenêtre est ((lotNumero - 1) * lotSize, lotNumero * lotSize). size est ignoré.
 *   3. moduleExamQuestionType fourni → MOCK_EXAM scopé à une épreuve TCF QCM
 *      (CO, CE ou STRUCTURE). Tire 8 A2 + 9 B1 + 8 B2 dans le pool filtré, en
 *      20 min (CO), 35 min (CE) ou 20 min (STRUCTURE, entraînement bonus hors
 *      TCF IRN). Score pondéré par niveau à la finalisation
 *      (cf. {@link com.sejourfr.app.service.AttemptService#startModuleExam}).
 *   4. ni l'un ni l'autre → comportement historique :
 *      - TRAINING / REVIEW : tirage filtré (themeId/difficulty/questionType/size)
 *      - MOCK_EXAM         : tirage aléatoire dans le module avec config par
 *                            défaut (40 questions CIVIQUE, 60 questions TCF).
 */
public record StartAttemptRequest(
        @NotNull AttemptType type,
        @NotNull Module module,
        UUID examTemplateId,
        UUID themeId,
        Difficulty difficulty,
        QuestionType questionType,
        Integer size,
        Integer lotNumero,
        QuestionType moduleExamQuestionType,
        /**
         * Slot d'examen blanc visé dans la grille UI (1..10). Optionnel ;
         * ne s'applique qu'aux MOCK_EXAM (ignoré pour TRAINING / REVIEW).
         * Permet de stabiliser la numérotation côté liste examens : refaire
         * « l'examen N » crée un nouvel attempt avec le même slot_number=N,
         * l'UI prend le plus récent par slot — au lieu de l'ancien LIFO qui
         * faisait glisser les essais d'un cran. Cf. migration V110.
         */
        Integer slotNumber,
        /**
         * Compétence de COMPRÉHENSION (CO / CE) à travailler. Fournie, elle
         * l'emporte sur tous les autres filtres : la série de 20 questions est
         * composée à partir du domaine ({@code skills.section}) et du niveau
         * ({@code skills.target_level}) de la compétence.
         *
         * <p>Une seule valeur plutôt qu'un couple (questionType, difficulty) :
         * les résultats QCM alimentant le Plan par le niveau RÉEL des questions,
         * un couple reçu du client aurait pu contredire la compétence affichée
         * et faire progresser une autre compétence que celle travaillée.
         *
         * <p>Refusée (422) sur une compétence d'expression, qui s'entraîne sur
         * ses petits sujets et non sur des questions.
         */
        UUID skillId
) {}

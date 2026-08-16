package com.sejourfr.app.service.attempt;

import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.entity.ExamTemplateRule;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.ThemeManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Composition / tirage des questions d'un attempt. Extrait d'AttemptService —
 * concentre les stratégies de pioche (examen module TCF, examen civique
 * complet, templates d'examen blanc), consommées par les chemins de start.
 */
@Service
@RequiredArgsConstructor
public class AttemptCompositionService {

    // Composition d'un examen module TCF QCM : 8 A2 + 9 B1 + 8 B2 = 25 questions
    // progressives. Cf. StartAttemptRequest doc + AttemptService.startModuleExam.
    private static final int MODULE_EXAM_A2 = 8;
    private static final int MODULE_EXAM_B1 = 9;
    private static final int MODULE_EXAM_B2 = 8;
    private static final int MODULE_EXAM_TOTAL = MODULE_EXAM_A2 + MODULE_EXAM_B1 + MODULE_EXAM_B2;

    private final QuestionManager questionManager;
    private final ThemeManager themeManager;

    /**
     * Compose la liste des 25 questions d'un examen module en suivant les
     * proportions A2/B1/B2 et en evitant les doublons. Tire aleatoirement
     * dans chaque strate, puis complete par un tirage libre si une strate
     * est sous-dotee (fallback).
     *
     * @param deterministic si vrai, ordre stable {@code created_at ASC, id ASC}
     *                      au lieu de {@code random()} — meme convention que
     *                      {@link #pickQuestionsForTemplate}. Utilise pour
     *                      l'examen 1 joue sans compte : rejouer redonne
     *                      toujours le meme examen (conversion, pas
     *                      entrainement — cf. AttemptService.startGuestDemo).
     */
    public List<Question> composeModuleExam(Module module, QuestionType questionType, boolean deterministic) {
        LinkedHashSet<Question> picked = new LinkedHashSet<>();
        List<UUID> exclude = new ArrayList<>();
        addStrata(picked, exclude, module, questionType, Difficulty.A2, MODULE_EXAM_A2, deterministic);
        addStrata(picked, exclude, module, questionType, Difficulty.B1, MODULE_EXAM_B1, deterministic);
        addStrata(picked, exclude, module, questionType, Difficulty.B2, MODULE_EXAM_B2, deterministic);

        int missing = MODULE_EXAM_TOTAL - picked.size();
        if (missing > 0) {
            // Fallback : on complete sans contrainte de niveau si une strate
            // etait sous-dotee. Garantit qu'on serve quand meme un examen
            // utile plutot que d'en refuser le demarrage.
            List<Question> extra = deterministic
                    ? questionManager.findOrderedExcluding(
                            module, null, null, questionType, exclude, missing)
                    : questionManager.findRandomExcluding(
                            module, null, null, questionType, exclude, missing);
            for (Question q : extra) {
                if (picked.add(q)) exclude.add(q.getId());
            }
        }
        return new ArrayList<>(picked);
    }

    private void addStrata(
            LinkedHashSet<Question> picked, List<UUID> exclude,
            Module module, QuestionType questionType, Difficulty difficulty, int count,
            boolean deterministic) {
        List<Question> drawn = deterministic
                ? questionManager.findOrderedExcluding(
                        module, null, difficulty, questionType, exclude, count)
                : questionManager.findRandomExcluding(
                        module, null, difficulty, questionType, exclude, count);
        for (Question q : drawn) {
            if (picked.add(q)) exclude.add(q.getId());
        }
    }

    /**
     * Composition d'un examen civique complet (40 Q hors template) :
     * stratifiée sur les thèmes officiels (size / nbThèmes questions par
     * thème, ex. 8 × 5), complétée par un tirage global si un pool de thème
     * est trop petit pour la difficulté visée, puis mélangée. Garantit que
     * l'examen couvre tous les thèmes — comme l'examen réel et les templates.
     */
    public List<Question> composeCiviqueFullExam(Difficulty difficulty, int size) {
        List<Theme> themes = themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE);
        List<Question> picked = new ArrayList<>(size);
        Set<UUID> pickedIds = new HashSet<>();

        if (!themes.isEmpty()) {
            int perTheme = Math.max(1, size / themes.size());
            for (Theme theme : themes) {
                if (picked.size() >= size) break;
                List<Question> qs = questionManager.findRandom(
                        Module.CIVIQUE, theme.getId(), difficulty, null,
                        Math.min(perTheme, size - picked.size()));
                for (Question q : qs) {
                    if (pickedIds.add(q.getId())) picked.add(q);
                }
            }
        }

        if (picked.size() < size) {
            List<Question> extra = questionManager.findRandomExcluding(
                    Module.CIVIQUE, null, difficulty, null, pickedIds, size - picked.size());
            for (Question q : extra) {
                if (pickedIds.add(q.getId())) picked.add(q);
            }
        }

        // Remélange : sans ça l'examen enchaînerait les questions thème par thème.
        Collections.shuffle(picked);
        return picked;
    }

    /**
     * Pioche les questions d'un ExamTemplate en suivant ses regles.
     *
     * @param deterministic si vrai, ordre stable {@code created_at ASC, id ASC}
     *                      au lieu de {@code random()} — utilise pour la demo
     *                      (guest ou non-premium sur template free) afin que
     *                      rejouer redonne toujours la meme serie.
     */
    public List<Question> pickQuestionsForTemplate(ExamTemplate template, boolean deterministic) {
        LinkedHashSet<Question> picked = new LinkedHashSet<>();
        List<UUID> exclude = new ArrayList<>();

        // Regles ordonnees par position (@OrderBy porte par l'entite).
        for (ExamTemplateRule rule : template.getRules()) {
            int needed = rule.getQuestionCount();
            if (needed <= 0) continue;

            UUID themeId = rule.getTheme() != null ? rule.getTheme().getId() : null;

            if (template.getModule() == Module.TCF && themeId == null
                    && rule.getQuestionType() == null && rule.getDifficulty() == null) {
                // Regle generique d'un diagnostic TCF (tcf-diagnostic / tcf-mix-*) :
                // composition sectionnee comme l'examen reel — comprehension
                // orale puis ecrite, chacune stratifiee A2/B1/B2 (memes
                // proportions que les examens module). Pas de STRUCTURE : le
                // TCF IRN n'a que CO et CE en QCM.
                int coCount = needed - needed / 2;
                drawTcfEpreuveStrata(picked, exclude, QuestionType.CO, coCount, deterministic);
                drawTcfEpreuveStrata(picked, exclude, QuestionType.CE, needed / 2, deterministic);
                continue;
            }

            List<Question> drawn = deterministic
                    ? questionManager.findOrderedExcluding(
                            template.getModule(), themeId, rule.getDifficulty(),
                            rule.getQuestionType(), exclude, needed)
                    : questionManager.findRandomExcluding(
                            template.getModule(), themeId, rule.getDifficulty(),
                            rule.getQuestionType(), exclude, needed);
            for (Question q : drawn) {
                if (picked.add(q)) exclude.add(q.getId());
            }
        }

        // Fallback : si les regles n'ont pas comble totalQuestions (stock faible),
        // on complete sans contrainte autre que le module, en evitant les doublons.
        int missing = template.getTotalQuestions() - picked.size();
        if (missing > 0) {
            List<Question> extra = deterministic
                    ? questionManager.findOrderedExcluding(
                            template.getModule(), null, null, null, exclude, missing)
                    : questionManager.findRandomExcluding(
                            template.getModule(), null, null, null, exclude, missing);
            for (Question q : extra) {
                if (picked.add(q)) exclude.add(q.getId());
            }
        }
        List<Question> result = new ArrayList<>(picked);
        if (template.getModule() == Module.TCF) {
            // L'examen TCF reel est sectionne par epreuve, pas entremele :
            // comprehension orale → ecrite → structures. Tri stable, donc la
            // demo deterministe (guest) le reste.
            result.sort(Comparator.comparingInt(q -> tcfEpreuveRank(q.getQuestionType())));
        }
        return result;
    }

    /**
     * Pioche une epreuve d'un diagnostic TCF : {@code count} questions du
     * {@code type} donne, stratifiees A2/B1/B2 (reste distribue a B1 puis A2,
     * comme le 8+9+8 des examens module), dans l'ordre progressif A2 → B2.
     * Si une strate est sous-dotee, complete au sein de la meme epreuve sans
     * contrainte de niveau.
     */
    private void drawTcfEpreuveStrata(
            LinkedHashSet<Question> picked, List<UUID> exclude,
            QuestionType type, int count, boolean deterministic) {
        int before = picked.size();
        int base = count / 3;
        int rem = count % 3;
        drawForTemplate(picked, exclude, type, Difficulty.A2, base + (rem == 2 ? 1 : 0), deterministic);
        drawForTemplate(picked, exclude, type, Difficulty.B1, base + (rem >= 1 ? 1 : 0), deterministic);
        drawForTemplate(picked, exclude, type, Difficulty.B2, base, deterministic);
        int missing = count - (picked.size() - before);
        if (missing > 0) {
            drawForTemplate(picked, exclude, type, null, missing, deterministic);
        }
    }

    private void drawForTemplate(
            LinkedHashSet<Question> picked, List<UUID> exclude,
            QuestionType type, Difficulty difficulty, int count, boolean deterministic) {
        if (count <= 0) return;
        List<Question> drawn = deterministic
                ? questionManager.findOrderedExcluding(Module.TCF, null, difficulty, type, exclude, count)
                : questionManager.findRandomExcluding(Module.TCF, null, difficulty, type, exclude, count);
        for (Question q : drawn) {
            if (picked.add(q)) exclude.add(q.getId());
        }
    }

    /** Ordre des epreuves d'un examen TCF mixte (cf. pickQuestionsForTemplate). */
    private static int tcfEpreuveRank(QuestionType type) {
        return switch (type) {
            case CO, CO_IMAGE -> 0;
            case CE -> 1;
            case STRUCTURE -> 2;
            default -> 3;
        };
    }
}

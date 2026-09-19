package com.sejourfr.app.service.attempt;

import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.entity.ExamTemplateRule;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.service.examencivique.CivicExamCompositionService;
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
    /**
     * Questions d'un examen blanc d'epreuve QCM. <b>Public</b> parce que le Plan
     * en a besoin comme denominateur : il ramene la duree officielle d'une
     * epreuve au prorata des questions d'une serie ciblee
     * ({@code ExerciseDuration.comprehension}). Le recopier ailleurs ferait
     * exister un second « 25 » dans le depot.
     */
    public static final int MODULE_EXAM_TOTAL = MODULE_EXAM_A2 + MODULE_EXAM_B1 + MODULE_EXAM_B2;

    private final QuestionManager questionManager;
    private final CivicExamCompositionService civicExamComposition;
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

    /**
     * Compose une section de COMPREHENSION du diagnostic TCF : {@code perLevel}
     * items par palier, soit 8 A2 + 8 B1 + 8 B2 = 24 par defaut — le volume de
     * l'epreuve reelle (25), le diagnostic complet devant en etre l'equivalent
     * (demande du proprietaire, 2026-09-13).
     *
     * <p>🛑 <b>Ce n'est pas un examen blanc raccourci.</b> La repartition est
     * EGALE entre paliers, la ou l'examen module suit 8/9/8 : le niveau du
     * diagnostic se lit sur un <b>taux par palier</b>
     * ({@code TcfDiagnosticLevelResolver}), et un palier sous-dote rendrait son
     * taux beaucoup plus sensible a une seule erreur.
     *
     * <p>🛑 <b>Aucun repli hors palier.</b> {@code composeModuleExam} complete
     * une strate creuse par un tirage libre, parce qu'un examen doit faire son
     * compte. Ici ce serait nuisible : une question dont on ignore le palier ne
     * peut entrer dans aucun taux. Le diagnostic sert donc <b>ce qui existe</b>,
     * et le calcul ajuste ses denominateurs — c'est le mode degrade de 10_ §9,
     * silencieux pour le candidat.
     *
     * @param deterministic tirage stable plutot qu'aleatoire (tests, rejeu)
     */
    public List<Question> composeDiagnosticComprehension(
            QuestionType questionType, int perLevel, boolean deterministic) {
        if (questionType != QuestionType.CO && questionType != QuestionType.CE) {
            throw new IllegalArgumentException(
                    "Le diagnostic ne tire que CO ou CE, pas " + questionType + ".");
        }
        LinkedHashSet<Question> picked = new LinkedHashSet<>();
        List<UUID> exclude = new ArrayList<>();
        for (Difficulty palier : List.of(Difficulty.A2, Difficulty.B1, Difficulty.B2)) {
            addStrata(picked, exclude, Module.TCF, questionType, palier, perLevel, deterministic);
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
     * 🛑 <b>SUPPRIMEE</b> — la composition d'un examen civique complet vit
     * desormais dans {@code CivicExamCompositionService.composerExamenConforme()}
     * (P8.A, D-29).
     *
     * <p>Ce qu'elle faisait, et pourquoi c'etait faux : {@code perTheme =
     * max(1, size / nbThemes)}, soit <b>8 / 8 / 8 / 8 / 8</b>, la ou l'arrete du
     * 10 octobre 2025 exige <b>11 / 6 / 11 / 8 / 4</b>. Elle passait
     * {@code questionType} a {@code null}, donc elle ne tenait ni les 12 mises en
     * situation ni leur placement. Et elle prenait {@code difficulty} et
     * {@code size} en parametres — les deux libertes que l'arrete ne donne pas.
     *
     * <p>Mesure sur les 33 examens de 40 questions deja passes : <b>0 conforme</b>.
     */

    /**
     * Pioche les questions d'un ExamTemplate en suivant ses regles.
     *
     * @param deterministic si vrai, ordre stable {@code created_at ASC, id ASC}
     *                      au lieu de {@code random()} — utilise pour la demo
     *                      (guest ou non-premium sur template free) afin que
     *                      rejouer redonne toujours la meme serie.
     */
    public List<Question> pickQuestionsForTemplate(ExamTemplate template, boolean deterministic) {
        // ════════════════════════════════════════════════════════════════════
        // 🛑 UN TEMPLATE CIVIQUE SANS REGLES EST UNE FICHE D'OFFRE, PAS UNE
        //    RECETTE — sa composition vient du programme officiel (D-45, option B)
        // ════════════════════════════════════════════════════════════════════
        // `civique-decouverte` est gratuit et affiche, et c'est une promesse
        // PUBLIQUE. Ses 5 regles a 8 questions par theme etaient non conformes
        // (l'arrete exige 11/6/11/8/4), et les rendre conformes aurait demande une
        // colonne d'unite sur `exam_template_rules` -- donc la loi ecrite a DEUX
        // endroits. On lui a donc RETIRE ses regles et garde sa ligne : le slug,
        // `is_free`, les libelles et les chiffres affiches sont de l'OFFRE ; seules
        // les regles etaient de la composition.
        //
        // 🛑 LE GARDE VERIFIE LE MODULE, ET CE N'EST PAS UNE PRECAUTION DE STYLE.
        // Un template TCF sans regles est une ERREUR DE SAISIE, pas une intention :
        // le TCF a sa composition stratifiee par epreuve, et il ne doit JAMAIS
        // retomber silencieusement sur un « format officiel » qui n'existe pas chez
        // lui. Il echoue donc bruyamment, au meme titre que le fallback ci-dessous.
        if (template.getRules() == null || template.getRules().isEmpty()) {
            if (template.getModule() != Module.CIVIQUE) {
                throw new IllegalStateException(
                        "Template « " + template.getSlug() + " » (module " + template.getModule()
                                + ") n'a AUCUNE regle de composition. Seul un template CIVIQUE peut "
                                + "s'en passer -- sa composition vient alors du programme officiel. "
                                + "Un template TCF sans regle est une erreur de saisie : le TCF a sa "
                                + "composition stratifiee par epreuve.");
            }
            return civicExamComposition.composerExamenConforme();
        }

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

        // ════════════════════════════════════════════════════════════════════
        // 🛑 LE FALLBACK EST ENCADRE : IL NE COMPLETE PLUS EN SILENCE (D-29 § 3)
        // ════════════════════════════════════════════════════════════════════
        // C'est le defaut le plus grave releve par l'audit du 2026-09-19, parce
        // qu'il rendait TOUTE REGLE FUTURE INOPERANTE SANS LE DIRE : si les regles
        // ne remplissaient pas `totalQuestions`, il completait par un tirage libre
        // dans le module, `themeId`/`difficulty`/`questionType` tous a `null`.
        // Un stock faible desactivait donc silencieusement le template entier --
        // et c'est ce qui a produit, dans les mesures, un examen « 40 questions »
        // dont 38 venaient d'une seule thematique.
        //
        // Desormais : un examen dont les regles ne sont pas satisfaites ECHOUE.
        // On le DIT, on ne rend pas un examen presque conforme.
        int missing = template.getTotalQuestions() - picked.size();
        if (missing > 0) {
            throw new IllegalStateException(
                    "Examen blanc « " + template.getSlug() + " » non composable : ses regles "
                            + "fournissent " + picked.size() + " question(s) sur les "
                            + template.getTotalQuestions() + " annoncees, il en manque " + missing
                            + ". 🛑 Le completement hors regles est INTERDIT (D-29) : il rendait "
                            + "toute regle inoperante sans le dire. Il manque du contenu, ou une "
                            + "regle vise un pool vide -- ce n'est pas au tirage de le masquer.");
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

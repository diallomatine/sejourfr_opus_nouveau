package com.sejourfr.app.service.journey;

import com.sejourfr.app.config.CivicPlanProperties;
import com.sejourfr.app.config.LearningPlanProperties;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.DureeEpreuve;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.service.AttemptService;
import com.sejourfr.app.service.attempt.AttemptCompositionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/**
 * <b>« Cette serie est-elle REUSSIE ? » — l'autorite unique</b> (2026-09-20).
 *
 * <p>Elle est partagee par la <b>lecture</b> (l'ecran d'etape, qui sert
 * {@code validee} et {@code dernierScore}) et par l'<b>ecriture</b> (la cloture
 * d'une etape, {@code JourneyService.onTrainingProgress}). C'est le seul moyen
 * qu'une etape ne se close jamais sur une regle differente de celle qui
 * l'affiche.
 *
 * <h2>🛑 Le « 16/20 » est LITTERAL, et il n'est ecrit nulle part</h2>
 * <p>Jusqu'au 2026-09-20, « reussie » se lisait sur
 * {@code learning_plan_observations.status = SOLID} : un verdict calcule sur les
 * <b>seules questions du palier vise</b> tombees dans la serie, qui pouvait
 * sortir {@code NOT_OBSERVED} sur une serie pourtant jouee entierement. Le
 * proprietaire a tranche : <b>16 bonnes reponses sur les 20 de la serie</b>, lues
 * sur l'attempt.
 *
 * <p>🛑 <b>Ce n'est pas une 8<sup>e</sup> declaration de 0,80.</b> Le seuil se
 * <b>derive</b> de deux autorites qui existent deja :
 * <ul>
 *   <li>{@code learning-plan.comprehension.solid-ratio} (0,80) — le ratio de
 *       reussite d'une serie de comprehension, celui-la meme qui qualifie les
 *       observations ;</li>
 *   <li>la <b>taille de la serie</b> : {@link AttemptService#COMPREHENSION_SERIES_SIZE}
 *       cote TCF, {@code civic-plan.questions-par-serie} cote civique.</li>
 * </ul>
 * 0,80 x 20 = 16. Changer le ratio change le seuil, l'ecran et la cloture
 * <b>ensemble</b>, sans migration ni recompilation d'une constante.
 *
 * <h2>🛑 Le seuil porte sur la taille NOMINALE, pas sur ce qui a ete tire</h2>
 * <p>Une banque trop mince peut rendre une serie de 18 questions
 * ({@code AttemptService} le journalise comme une anomalie de catalogue). Le
 * seuil reste alors <b>16</b>, pas {@code ceil(0.8 x 18) = 15} : c'est la
 * lecture la plus stricte, c'est le chiffre <b>servi</b> au candidat avant qu'il
 * ne commence ({@code seuilReussite}), et un seuil qui varierait avec le tirage
 * ferait dire deux choses differentes a deux essais de la meme carte.
 *
 * <h2>Un attempt non termine n'est jamais reussi</h2>
 * <p>{@code score} est ecrit a la finalisation. Une session en cours n'a donc
 * pas de verdict — et <b>pas d'echec</b> non plus : {@code null} = inconnu,
 * jamais mauvais.
 */
@Component
@RequiredArgsConstructor
public class JourneySerieVerdict {

    private final LearningPlanProperties learningPlanProperties;
    private final CivicPlanProperties civicPlanProperties;

    /**
     * La taille <b>nominale</b> d'une serie de ce module — le denominateur servi
     * dans {@code questionsParSerie}.
     *
     * <p>🛑 Deux autorites, aucune copie : cote TCF une constante assumee
     * ({@code « le laisser choisir au client ferait varier ce que reussi veut
     * dire »}), cote civique un reglage deja existant dont la <b>duree
     * annoncee</b> se derive.
     */
    public int questionsParSerie(Module module) {
        return module == Module.CIVIQUE
                ? civicPlanProperties.getQuestionsParSerie()
                : AttemptService.COMPREHENSION_SERIES_SIZE;
    }

    /**
     * Le nombre de bonnes reponses qui rend une serie de ce module <b>reussie</b>
     * — 16 sur 20 avec les valeurs en vigueur.
     */
    public int seuilReussite(Module module) {
        return seuil(questionsParSerie(module));
    }

    /**
     * Cette session est-elle une serie <b>reussie</b> ?
     *
     * @param attempt la session liee a la carte, <b>deja chargee</b>
     */
    public boolean reussie(Attempt attempt) {
        if (attempt == null || attempt.getFinishedAt() == null) return false;
        Integer score = attempt.getScore();
        return score != null && score >= seuilReussite(attempt.getModule());
    }

    /**
     * Le score du dernier essai, <b>ou {@code null} tant qu'il n'y en a pas</b>
     * (session en cours comprise : elle n'a pas encore de score, et un zero
     * serait un mensonge).
     */
    public Integer score(Attempt attempt) {
        return attempt == null || attempt.getFinishedAt() == null ? null : attempt.getScore();
    }

    /**
     * La duree annoncee d'une serie, en minutes — <b>un ordre de grandeur, jamais
     * un chrono</b> : rien ne chronometre une serie d'entrainement.
     *
     * <p>🛑 <b>Derivee, jamais posee.</b> Cote <b>TCF</b>, de la <b>donnee
     * officielle</b> : une epreuve de comprehension dure
     * {@link DureeEpreuve} secondes pour
     * {@link AttemptCompositionService#MODULE_EXAM_TOTAL} questions — 20 min pour
     * 25 questions en CO, soit 48 s par question, donc <b>16 min</b> pour une
     * serie de 20. Cote <b>civique</b>, de {@code civic-plan.secondes-par-question},
     * l'autorite qui porte deja le « ~6 min » du plan derive.
     *
     * <p>{@code null} quand rien ne permet de la calculer — une epreuve sans
     * duree opposable (l'expression orale) ou une etape sans epreuve. <b>Le
     * contrat le prevoit</b> : « null si non calculable ».
     */
    public Integer dureeEstimeeMin(Module module, EpreuveType epreuve) {
        int questions = questionsParSerie(module);
        if (module == Module.CIVIQUE) {
            return minutes(questions * civicPlanProperties.getSecondesParQuestion());
        }
        Integer secondesDeLEpreuve = DureeEpreuve.secondes(epreuve);
        if (secondesDeLEpreuve == null) return null;
        return minutes(
                questions * secondesDeLEpreuve / AttemptCompositionService.MODULE_EXAM_TOTAL);
    }

    /**
     * 🛑 <b>Arrondi au SUPERIEUR</b>, et ce n'est pas un detail : avec un ratio
     * de 0,80 sur 20 questions, {@code 16.000000000000004} en virgule flottante
     * tronque a 16 mais un {@code (int)} sur {@code 0.78 x 20 = 15,6} rendrait
     * 15 — soit un seuil <b>plus permissif</b> que le ratio declare. Un
     * garde-fou ne peut qu'abaisser, jamais une exigence.
     */
    private int seuil(int questionsParSerie) {
        double ratio = learningPlanProperties.getComprehension().getSolidRatio();
        return (int) Math.ceil(ratio * questionsParSerie - 1e-9);
    }

    private static Integer minutes(int secondes) {
        return secondes <= 0 ? null : Math.max(1, Math.round(secondes / 60f));
    }
}

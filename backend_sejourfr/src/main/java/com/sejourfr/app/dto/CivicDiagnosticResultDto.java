package com.sejourfr.app.dto;

import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.enums.Difficulty;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * L'ecran de resultat du diagnostic civique (20_ §4.5).
 *
 * <p>🛑 <b>Le constat est INTEGRALEMENT gratuit</b>, comme au TCF : ce DTO ne
 * porte aucun {@code locked}. Le paywall porte sur l'accompagnement, jamais sur
 * ce que le candidat vient de mesurer.
 *
 * <p>🛑 <b>{@code projection40} est calculee ICI et nulle part ailleurs</b>
 * (20_ §4.4). Ni ecrite en dur dans une maquette, ni recalculee par un front :
 * deux calculs de la meme chose finissent par afficher deux nombres. Et c'est
 * une <b>projection</b>, jamais un pronostic de reussite.
 *
 * @param bonnes        bonnes reponses
 * @param posees        questions reellement posees (24 en regime normal, moins
 *                      en mode degrade)
 * @param projection40  le report sur l'echelle de l'examen reel.
 *                      🛑 {@code null} si rien n'a ete pose — « on n'a rien
 *                      mesure » ne se dit pas « vous auriez 0 sur 40 »
 * @param seuilReussite    32, la regle de l'epreuve. Servi pour que l'ecran le
 *                         DISE sans le connaitre
 * @param formatQuestions  40, le nombre de questions de l'epreuve reelle.
 *                         🛑 Servi lui aussi, et pour une raison precise :
 *                         quand {@code posees == formatQuestions}, le score EST
 *                         le resultat et l'ecran doit le dire tel quel. En mode
 *                         degrade il faut projeter, et l'ecran doit alors le
 *                         dire aussi. Sans ce nombre, le front devrait ecrire
 *                         « 40 » en dur pour trancher
 * @param themes        les 5 themes, <b>tous</b>, y compris ceux qu'aucune
 *                      question n'a touches — un theme absent de la liste
 *                      disparaitrait de l'ecran au lieu de se dire « non
 *                      evalue »
 * @param situations    les mises en situation, comptees a part : appliquer une
 *                      regle a un cas concret est une competence distincte, et
 *                      c'est souvent ce qui fait la difference a l'examen
 * @param priorites     ce qui coute le plus de points, du plus couteux au
 *                      moins. Au niveau THEME tant que le tagging des notions
 *                      n'est pas fait (20_ §3.4, mode degrade assume)
 */
public record CivicDiagnosticResultDto(
        UUID sessionId,
        Difficulty mention,
        int bonnes,
        int posees,
        Integer projection40,
        int seuilReussite,
        int formatQuestions,
        List<ThemeResultat> themes,
        Situations situations,
        List<PrioriteTheme> priorites,
        Instant completedAt
) {
    /**
     * Un theme et son etat.
     *
     * @param taux {@code null} = non evalue. Jamais {@code 0.0} : une barre a
     *             zero se lit « tout faux » alors que rien n'a ete pose
     */
    public record ThemeResultat(
            UUID themeId,
            String code,
            String label,
            CivicThemeState etat,
            int bonnes,
            int posees,
            Double taux) {
    }

    /**
     * Les mises en situation. {@code posees == 0} est un etat normal en mode
     * degrade : le catalogue peut ne pas en avoir sur cette mention.
     */
    public record Situations(int reussies, int posees) {
    }

    /**
     * Un theme qui coute des points.
     *
     * <p>🛑 <b>Le rang n'est pas un score.</b> Il ordonne, il ne quantifie pas :
     * exposer le nombre de points perdus inviterait a comparer deux diagnostics
     * dont les tirages n'ont rien de commun.
     */
    public record PrioriteTheme(
            int rang,
            UUID themeId,
            String code,
            String label,
            CivicThemeState etat,
            int manques) {
    }
}

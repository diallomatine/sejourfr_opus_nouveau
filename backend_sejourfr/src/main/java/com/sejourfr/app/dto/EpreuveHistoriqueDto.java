package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SourceEvaluation;

import java.time.Instant;
import java.util.List;

/**
 * <b>« D'où sort mon niveau ? »</b> — les dernières <b>évaluations
 * qualifiantes</b> d'une épreuve TCF, celles-là mêmes qui alimentent
 * {@code ProgressDto.Epreuve.niveau} et son {@code evolution}.
 *
 * <h2>Pourquoi un endpoint à part, et pas un champ de {@code ProgressDto}</h2>
 * <p>🛑 {@code ProgressDto} <b>refuse</b> de porter une liste d'historique, et
 * sa raison tient toujours : « le redupliquer ici créerait une seconde
 * vérité ». Ce DTO n'est pas cette seconde vérité — il est le <b>détail d'une
 * seule ligne</b> de l'écran, demandé à la demande, et il ne sert que ce que
 * {@code TcfProfileService} a déjà retenu. L'écran d'accueil reste servi par un
 * seul appel ; celui-ci ne part que lorsque le candidat ouvre une carte.
 *
 * <h2>Ce que « qualifiante » veut dire, et ce que ça exclut</h2>
 * <ul>
 *   <li><b>CO / CE</b> : la définition est celle de
 *       {@code AttemptRepository.findQcmEpreuvesPassees} — examen blanc fini
 *       portant au moins une réponse, quelle que soit sa provenance (seule,
 *       dans un examen complet, ou comme sous-épreuve du diagnostic complet).
 *       <b>La même requête</b>, pas une seconde version.</li>
 *   <li><b>EE / EO</b> : une <b>épreuve complète</b> de production avec son
 *       résultat agrégé ({@code ProductionBilanService}), plus la baseline du
 *       <b>diagnostic rapide</b>. 🛑 Les <b>petits sujets de compétence</b>
 *       ({@code user_skill_attempts}) n'en sont pas : ils ne portent aucun
 *       niveau CECRL et n'alimentent pas le profil.</li>
 * </ul>
 *
 * <h2>Rien n'est inventé</h2>
 * <p>🛑 <b>Jamais 404, jamais 204 pour un candidat sans mesure</b> :
 * {@code evaluations} est alors <b>vide</b>. Une absence de mesure n'est pas
 * une erreur, et l'écran doit pouvoir le dire au candidat.
 *
 * @param epreuve     l'épreuve demandée, réexposée pour que l'écran n'ait pas à
 *                    faire confiance à sa propre requête
 * @param evaluations de la <b>plus récente à la plus ancienne</b>, plafonnées
 *                    par le serveur ({@code MAX_EVALUATIONS}). 🛑 Un plafond
 *                    d'AFFICHAGE : rien de ce qui est mesuré n'est perdu, la
 *                    liste ne montre que le haut
 */
public record EpreuveHistoriqueDto(
        EpreuveType epreuve,
        List<Evaluation> evaluations
) {

    /**
     * Une évaluation qualifiante : quand, d'où, et quel palier.
     *
     * @param mesureA la date de la mesure — la fin de l'épreuve pour une
     *                épreuve passée, la date d'analyse pour une production du
     *                diagnostic rapide
     * @param source  🛑 <b>brut</b> : le front pose le libellé, il ne le déduit
     *                d'aucun autre champ
     * @param niveau  le palier obtenu. Jamais {@code null} — une évaluation
     *                sans niveau n'est pas une évaluation qualifiante, elle est
     *                simplement absente de la liste
     */
    public record Evaluation(
            Instant mesureA,
            SourceEvaluation source,
            NiveauCecrl niveau
    ) {
    }
}

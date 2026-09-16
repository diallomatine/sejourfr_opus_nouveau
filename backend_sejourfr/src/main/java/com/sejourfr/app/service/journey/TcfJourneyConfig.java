package com.sejourfr.app.service.journey;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.sejourfr.app.enums.JourneyLotSelectionStrategy;

/**
 * <b>La configuration versionnee du PARCOURS TCF</b> — image en memoire de
 * {@code plan/tcf-journey-config-vN.json}.
 *
 * <p>🛑 <b>Aucune valeur metier n'est ecrite dans ce fichier Java</b> : pas de
 * defaut, pas de constante de repli, pas de {@code ?:}. Une cle absente du JSON
 * est une erreur de demarrage, jamais un zero silencieux. Meme doctrine que
 * {@code PlanConfig} et {@code ProgressionConfig}, pour la meme raison — un
 * plafond qui vaudrait zero par accident viderait la file de tout le monde sans
 * que rien n'echoue.
 *
 * <h2>Ce qui n'est PAS ici, et ne doit jamais y entrer</h2>
 * <ul>
 *   <li><b>Le quota d'etape d'EXPRESSION.</b> Il <b>est</b>
 *       {@code LearningPlanStep.PROMPTS_PAR_ETAPE} (5), et c'est son unique
 *       autorite : ce chiffre est deja servi aux deux fronts dans
 *       {@code progress.quota}. Le declarer ici en ferait la 2<sup>e</sup> copie,
 *       et un jour l'ecran annoncerait « 2/5 » pendant que le moteur en
 *       exigerait 6.</li>
 *   <li><b>L'ordre des epreuves.</b> Il <b>est</b>
 *       {@code TcfDomainProfileDto.ORDRE} ({@code CO, CE, EO, EE} — arbitrage
 *       D-9), deja a l'ecran. Un second ordre configurable ferait diverger la
 *       file et « Completer mon profil ».</li>
 *   <li><b>Tout ce qui touche a la MAITRISE</b> : seuils, poids, fenetres,
 *       tolerance. Ils vivent dans {@code progression-config-vN.json}, dont le
 *       rejeu doit rester intact.</li>
 * </ul>
 *
 * @param maxPrioritiesPerLot combien de priorites une evaluation retient par
 *                            epreuve (R2). 🛑 C'est un <b>budget de file</b>,
 *                            assume : les priorites au-dela ne sont ni stockees
 *                            ni mises en attente, et le prochain examen les
 *                            fera remonter si elles persistent.
 * @param trainSeriesQuota    series ciblees terminees qui closent une etape de
 *                            <b>comprehension</b> (R8, arbitrage D-5). Les
 *                            competences CO/CE n'ont ni tache ni petit sujet :
 *                            leur grain d'entrainement est la serie.
 */
@JsonIgnoreProperties(ignoreUnknown = false)
public record TcfJourneyConfig(
        int journeyConfigVersion,
        int maxPrioritiesPerLot,
        JourneyLotSelectionStrategy lotSelectionStrategy,
        int trainSeriesQuota,
        Display display
) {

    /**
     * Les plafonds d'<b>affichage</b> de la timeline (§14). 🛑 Ce sont des
     * maximums, <b>jamais des quotas</b> : rien n'est fabrique pour les
     * atteindre, et ils ne bornent <b>jamais</b> ce que la file contient.
     *
     * @param recentCompletedVisible etapes deja closes republiees avant l'etape
     *                               courante
     * @param upcomingVisible        etapes a venir montrees avant le repli
     *                               « Voir les etapes suivantes »
     */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record Display(
            int recentCompletedVisible,
            int upcomingVisible
    ) {}
}

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
 * @param trainSeriesQuota    series ciblees <b>REUSSIES</b> qui closent une etape
 *                            de <b>comprehension</b> (R8, arbitrage D-16). Les
 *                            competences CO/CE n'ont ni tache ni petit sujet :
 *                            leur grain d'entrainement est la serie. 🛑 Le nom
 *                            de la cle est <b>conserve</b>, seule sa semantique
 *                            change — D-16 revoque « series terminees » (D-5).
 *                            « Reussie » se lit chez l'autorite qui rend deja ce
 *                            verdict, jamais par un ratio recalcule ici :
 *                            {@code learning_plan_observations.status = SOLID},
 *                            pose par {@code ComprehensionObservationService} a
 *                            partir de {@code learning-plan.comprehension.solid-ratio}.
 * @param trainSeriesFallbackQuota series ciblees <b>TERMINEES</b>, reussite
 *                            indifferente, qui closent la meme etape —
 *                            l'echappatoire de D-16. Elle existe pour une raison
 *                            nommee : <b>un candidat faible ne doit jamais rester
 *                            bloque</b> sur une etape. 🛑 <b>Cle distincte, et
 *                            c'est le point</b> : un seul nombre pour deux sens
 *                            est exactement ce que le depot paie cher ailleurs.
 *                            Elle ne peut pas etre <b>inferieure</b> a
 *                            {@code trainSeriesQuota} — le chemin de la reussite
 *                            deviendrait inatteignable, et l'echappatoire
 *                            l'unique regle.
 *                            <p>⚠️ <b>C'est ainsi que v1 reste chargeable</b> :
 *                            {@code plan/tcf-journey-config-v1.json} porte
 *                            {@code trainSeriesFallbackQuota = 2}, egal a son
 *                            {@code trainSeriesQuota}. Comme les reussies sont
 *                            toujours un sous-ensemble des terminees, la regle
 *                            « 2 reussies OU 2 terminees » <b>est</b> mot pour
 *                            mot l'ancienne regle « 2 terminees » de D-5. Un
 *                            retour arriere est donc bien une variable
 *                            d'environnement, pas une migration.
 */
@JsonIgnoreProperties(ignoreUnknown = false)
public record TcfJourneyConfig(
        int journeyConfigVersion,
        int maxPrioritiesPerLot,
        JourneyLotSelectionStrategy lotSelectionStrategy,
        int trainSeriesQuota,
        int trainSeriesFallbackQuota,
        Display display
) {

    /**
     * Les plafonds d'<b>affichage</b> de l'ancienne timeline (§14). 🛑 Ce sont
     * des maximums, <b>jamais des quotas</b> : rien n'a jamais ete fabrique
     * pour les atteindre, et ils ne bornaient <b>jamais</b> ce que la file
     * contient.
     *
     * <h2>⚠️ Ce bloc n'a PLUS AUCUN LECTEUR depuis P6 (2026-09-18)</h2>
     * <p>Son unique lecteur etait {@code JourneyReadService.filtrer(...)}, le
     * fenetrage qui alimentait {@code JourneyDto.steps} et
     * {@code hiddenUpcomingCount}. Les deux champs ont disparu avec la bascule
     * des fronts sur {@code blocs}, et le fenetrage avec eux : les blocs
     * portent <b>toutes</b> les etapes non obsoletes, sans plafond.
     *
     * <p>🛑 <b>Il reste declare, et ce n'est pas un oubli.</b>
     * {@code plan/tcf-journey-config-v1.json} <b>et</b> {@code -v2.json}
     * portent la cle {@code display}, et {@code TcfJourneyConfigLoader} refuse
     * toute <b>cle inconnue</b> ({@code @JsonIgnoreProperties(ignoreUnknown =
     * false)}). La retirer du record ferait echouer le <b>demarrage</b> sur les
     * deux versions publiees — donc rendrait impossible le retour arriere par
     * variable d'environnement, qui est la doctrine du depot (« un retour
     * arriere est un changement de variable d'environnement, pas une
     * migration »). Le supprimer demanderait de reecrire deux fichiers de
     * configuration <b>deja livres</b> : on ne reecrit pas un contrat livre, on
     * versionne.
     *
     * @param recentCompletedVisible etapes deja closes republiees avant l'etape
     *                               courante. <b>Sans lecteur.</b>
     * @param upcomingVisible        etapes a venir montrees avant le repli
     *                               « Voir les etapes suivantes ». <b>Sans
     *                               lecteur.</b>
     */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record Display(
            int recentCompletedVisible,
            int upcomingVisible
    ) {}
}

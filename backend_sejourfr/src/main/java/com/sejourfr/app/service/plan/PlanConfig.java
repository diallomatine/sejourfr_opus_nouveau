package com.sejourfr.app.service.plan;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanActionNature;
import com.sejourfr.app.enums.PlanDomainPriority;

import java.util.Map;

/**
 * <b>La configuration versionnee du PLAN</b> — image en memoire de
 * {@code plan-config-vN.json}.
 *
 * <p>🛑 <b>Aucune valeur metier n'est ecrite dans ce fichier Java</b> : pas de
 * defaut, pas de constante de repli, pas de {@code ?:}. Une cle absente du JSON
 * est une erreur de demarrage, jamais un zero silencieux. Meme doctrine que
 * {@code ProgressionConfig}, pour la meme raison — un plafond qui vaudrait zero
 * par accident viderait la seance de tout le monde sans que rien n'echoue.
 *
 * <p>🛑 <b>Ce fichier ne peut RIEN influencer du calcul de maitrise</b>
 * (arbitrage du proprietaire, 2026-08-26). Il ne porte que de la <b>selection</b>
 * et de l'<b>affichage</b> : ce qu'on montre d'un pool deja calcule, et dans
 * quel ordre. Les preuves, les seuils et les etats restent l'affaire de
 * {@code progression-config-vN.json}, dont le rejeu doit rester intact quand on
 * regle un rideau ou une composition de seance.
 */
@JsonIgnoreProperties(ignoreUnknown = false)
public record PlanConfig(
        int planConfigVersion,
        Display display,
        Ranking ranking
) {

    /**
     * Les plafonds d'<b>affichage</b>. 🛑 Ce sont des maximums, <b>jamais des
     * quotas</b> : rien n'est fabrique pour les atteindre.
     *
     * @param todayMaxActions                 entrainements d'une seance
     * @param todayMaxSecondaryDomainActions  parmi eux, combien peuvent venir
     *                                        d'un domaine <b>secondaire</b> —
     *                                        la borne qui empeche « Aujourd'hui »
     *                                        de devenir une liste de courses
     * @param prioritiesMaxActions            lignes de « Mes priorites »
     */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record Display(
            int todayMaxActions,
            int todayMaxSecondaryDomainActions,
            int prioritiesMaxActions
    ) {}

    /**
     * Les poids du classement. Additifs, entiers, <b>sans horloge</b> : la
     * recence ne peut pas etre un poids ici, parce que le Plan ne lit jamais
     * l'heure courante (cf. {@code PlanSeanceBuilder}, § stickiness). Elle
     * reste un <b>departage</b>, sur la date d'observation deja portee par
     * l'historique.
     *
     * @param natureWeights         ce qu'on fait passer devant : mesurer, puis
     *                              reparer, puis verifier, puis apprendre —
     *                              l'ordre de declaration de
     *                              {@link PlanActionNature}
     * @param domainPriorityWeights l'urgence deja decidee par le serveur pour ce
     *                              domaine, <b>jamais recalculee ici</b>
     * @param confidenceWeights     a nature egale, la fragilite la mieux etablie
     *                              d'abord
     * @param levelGapWeight        par cran d'ecart entre le niveau du domaine et
     *                              l'objectif : deux paliers de retard pesent
     *                              plus qu'un
     */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record Ranking(
            Map<PlanActionNature, Integer> natureWeights,
            Map<PlanDomainPriority, Integer> domainPriorityWeights,
            Map<ObservationConfidence, Integer> confidenceWeights,
            int levelGapWeight
    ) {}
}

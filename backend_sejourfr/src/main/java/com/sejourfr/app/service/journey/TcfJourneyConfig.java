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
 * <p>⚠️ <b>Deux cles font exception, et elles n'ont AUCUN nombre de repli</b>
 * ({@link #trainSeriesFallbackQuota}, {@link #finDeCycleExamenRatio}) : leur
 * <b>absence</b> est une regle a part entiere — « aucune echappatoire », « aucun
 * deblocage anticipe » — et cette regle ne se traduit par aucun chiffre ecrit
 * ici. C'est ce qui permet a v1 et v2, publiees avant elles, de rester
 * chargeables <b>a l'identique</b> sans qu'on les reecrive : un retour arriere
 * est un changement de variable d'environnement, jamais une migration.
 *
 * <h2>Ce qui n'est PAS ici, et ne doit jamais y entrer</h2>
 * <ul>
 *   <li><b>Le quota d'etape d'EXPRESSION.</b> Il <b>est</b>
 *       {@code LearningPlanStep.PROMPTS_PAR_ETAPE} (5), et c'est son unique
 *       autorite : ce chiffre est deja servi aux deux fronts dans
 *       {@code progress.quota}. Le declarer ici en ferait la 2<sup>e</sup> copie,
 *       et un jour l'ecran annoncerait « 2/5 » pendant que le moteur en
 *       exigerait 6.</li>
 *   <li><b>La TAILLE d'une serie et son SEUIL de reussite.</b> La taille est
 *       {@code AttemptService.COMPREHENSION_SERIES_SIZE} (TCF) ou
 *       {@code civic-plan.questions-par-serie} (civique) ; le seuil se
 *       <b>derive</b> de {@code learning-plan.comprehension.solid-ratio} x la
 *       taille ({@code JourneySerieVerdict}). Ecrire « 16 » ici en ferait la
 *       8<sup>e</sup> declaration de 0,80.</li>
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
 *                            assume : ce qui depasse part dans le cycle en
 *                            attente (D-13).
 * @param trainSeriesQuota    series <b>REUSSIES</b> qui closent une etape de
 *                            <b>comprehension</b> — et, depuis le 2026-09-20,
 *                            le nombre de <b>cartes</b> que l'ecran d'etape
 *                            montre. Les competences CO/CE et les unites
 *                            civiques n'ont ni tache ni petit sujet : leur grain
 *                            d'entrainement est la serie.
 *                            <p>« Reussie » a <b>une</b> autorite,
 *                            {@code JourneySerieVerdict} : 16 bonnes reponses
 *                            sur les 20 de la serie, lues sur l'attempt.</p>
 * @param trainSeriesFallbackQuota series <b>TERMINEES</b>, reussite indifferente,
 *                            qui closaient la meme etape — l'echappatoire de
 *                            D-16. 🛑 <b>{@code null} = AUCUNE echappatoire</b>,
 *                            et c'est ce que dit v3 : le proprietaire a
 *                            <b>supprime le filet</b> le 2026-09-20.
 *                            <p><b>Consequence assumee et validee</b> : un
 *                            candidat qui ne passe jamais le seuil reste sur sa
 *                            competence. C'etait exactement ce que le filet
 *                            evitait (D-16, « un candidat faible ne doit jamais
 *                            rester bloque ») ; l'arbitrage a ete rendu contre,
 *                            en connaissance de cause.</p>
 *                            <p>⚠️ Quand elle est <b>presente</b>, elle ne peut
 *                            pas etre inferieure a {@code trainSeriesQuota} — un
 *                            filet sous la regle deviendrait la regle. C'est
 *                            ainsi que v1 ({@code = 2}) et v2 ({@code = 4})
 *                            restent chargeables a l'identique.</p>
 * @param finDeCycleExamenRatio part des etapes du cycle qui doivent etre
 *                            terminees pour que l'<b>examen de fin de cycle</b>
 *                            (« Passer l'examen blanc complet ») s'ouvre — 0,80
 *                            en v3, arbitrage du proprietaire du 2026-09-20.
 *                            🛑 <b>{@code null} = l'ancienne regle</b> : le cycle
 *                            entier, aucune etape ouverte. C'est ce que v1 et v2
 *                            continuent de dire sans porter la cle.
 *                            <p>🛑 <b>Il ne concerne QUE l'examen qui CLOT le
 *                            cycle</b>, jamais le {@code SECTION_EXAM} d'un bloc,
 *                            qui garde son verrou a lui (D-15).</p>
 *                            <p>⚠️ Regle <b>non figee</b>, annoncee comme
 *                            appelee a bouger : c'est precisement pourquoi elle
 *                            vit en configuration versionnee et pas dans le
 *                            Java.</p>
 */
@JsonIgnoreProperties(ignoreUnknown = false)
public record TcfJourneyConfig(
        int journeyConfigVersion,
        int maxPrioritiesPerLot,
        JourneyLotSelectionStrategy lotSelectionStrategy,
        int trainSeriesQuota,
        Integer trainSeriesFallbackQuota,
        Double finDeCycleExamenRatio,
        Display display
) {

    /**
     * <b>Le quota d'une etape de serie est-il atteint ?</b> — la regle R8, ecrite
     * <b>une</b> fois, pour une competence TCF comme pour une unite civique.
     *
     * <p>🛑 L'echappatoire n'est lue que si elle <b>existe</b> : en v3 elle est
     * absente, et seule la reussite clot une etape.
     *
     * @param reussies series reussies depuis la creation de l'etape
     * @param jouees   series jouees jusqu'au bout, reussite indifferente —
     *                 ignorees quand il n'y a plus de filet
     */
    public boolean quotaDeSerieAtteint(int reussies, int jouees) {
        if (reussies >= trainSeriesQuota) return true;
        return trainSeriesFallbackQuota != null && jouees >= trainSeriesFallbackQuota;
    }

    /**
     * <b>L'examen de FIN DE CYCLE est-il ouvert ?</b>
     *
     * <p>🛑 <b>Aucun nombre de repli en Java.</b> Sans ratio, la regle est
     * exactement celle d'avant v3 — {@code complete}, c'est-a-dire « plus aucune
     * etape ouverte » —, et ce n'est pas un chiffre, c'est un fait deja calcule.
     *
     * <p>Un cycle <b>vide</b> ({@code total = 0}) n'ouvre rien par le ratio :
     * 0 sur 0 n'est pas 80 %. Il reste couvert par {@code complete}, qui est vrai
     * pour lui — c'est la meme reponse qu'avant, par le meme chemin.
     */
    public boolean examenDeFinDeCycleOuvert(int terminees, int total, boolean complete) {
        if (complete) return true;
        if (finDeCycleExamenRatio == null || total <= 0) return false;
        return terminees >= finDeCycleExamenRatio * total;
    }

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
     * versions publiees — donc rendrait impossible le retour arriere par
     * variable d'environnement, qui est la doctrine du depot (« un retour
     * arriere est un changement de variable d'environnement, pas une
     * migration »). Le supprimer demanderait de reecrire des fichiers de
     * configuration <b>deja livres</b> : on ne reecrit pas un contrat livre, on
     * versionne. v3 le porte donc aussi, aux memes valeurs.
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

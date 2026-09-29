package com.sejourfr.app.dto;

import java.time.LocalDate;
import java.util.List;

/**
 * <b>Ce que l'IA a coûté</b>, sur une fenêtre choisie (lot L12, {@code 00_}
 * §8.4).
 *
 * <p>Tout vient de la vue {@code v_ai_usage} (V048), qui <b>lit</b> les quatre
 * endroits où le dépôt écrit déjà ce coût — elle n'en recopie aucun. Il n'y a
 * donc pas de cinquième vérité à tenir à jour.
 *
 * <h2>🛑 Deux colonnes de coût, JAMAIS additionnées</h2>
 * <p>{@code coutMicroUsd} est en millionièmes de <b>dollar</b>, écrit par les
 * pipelines actuels. {@code coutLegacyCentimes} est en centimes d'<b>euro</b>,
 * plus jamais écrit, présent sur les lignes anciennes. Deux unités, deux
 * devises, deux époques : les sommer produirait un nombre qui ne veut rien
 * dire. Ils voyagent côte à côte jusqu'à l'écran, qui les affiche côte à côte.
 *
 * <h2>🛑 Un coût inconnu vaut {@code null}, jamais zéro</h2>
 * <p>Une ligne peut n'avoir <b>ni</b> l'un <b>ni</b> l'autre : appel ancien,
 * fournisseur qui n'a pas rendu son décompte, écriture interrompue.
 * {@code lignesSansCout} les compte explicitement. Sans ce nombre, un total bas
 * se lit « l'IA ne coûte presque rien » alors qu'il se lit « on ne sait pas ce
 * qu'elle a coûté » — c'est exactement l'erreur que la vue V048 documente.
 *
 * @param from             borne appliquée par le serveur (incluse)
 * @param to               borne appliquée par le serveur (incluse)
 * @param total            l'ensemble de la fenêtre, toutes familles confondues
 * @param parFamille       nature de l'appel : correction de production,
 *                         transcription, analyse de compétence, analyse de
 *                         diagnostic
 * @param parSource        le grain fin ({@code TASK_TCF_EE},
 *                         {@code DIAGNOSTIC_TRANSCRIPTION}, {@code MICRO_EE}…),
 *                         trié du plus cher au moins cher
 * @param parModele        quel modèle a consommé quoi — c'est ce qui rend un
 *                         changement de fournisseur lisible dans la facture
 * @param diagnosticComplet coût moyen d'un diagnostic <b>mené à terme</b> ;
 *                         {@code null} tant qu'aucun n'a été clos sur la
 *                         fenêtre
 */
public record AdminAiCostResponse(
        LocalDate from,
        LocalDate to,
        Ligne total,
        List<Ligne> parFamille,
        List<Ligne> parSource,
        List<Ligne> parModele,
        CoutMoyen diagnosticComplet
) {
    /**
     * Un agrégat de coût. {@code cle} est {@code null} sur le total.
     *
     * @param appels             nombre d'appels, coût connu ou non
     * @param lignesSansCout     🛑 appels dont le coût est <b>inconnu</b> —
     *                           ni micro-USD ni centimes. Jamais comptés zéro
     * @param tokensInput        {@code null} sur une transcription : Whisper
     *                           facture à la DURÉE, pas au token. Ce n'est pas
     *                           une donnée manquante
     * @param coutMicroUsd       somme des coûts en millionièmes de dollar
     * @param coutLegacyCentimes somme des coûts anciens, en centimes d'euro
     */
    public record Ligne(
            String cle,
            long appels,
            long lignesSansCout,
            Long tokensInput,
            Long tokensOutput,
            Long tokensInputCacheHit,
            Long coutMicroUsd,
            Long coutLegacyCentimes
    ) {}

    /**
     * Le coût moyen d'un parcours mené à terme.
     *
     * @param sessions        combien de diagnostics clos entrent dans la moyenne
     * @param moyenneMicroUsd {@code null} si aucune de leurs lignes ne porte de
     *                        coût en micro-USD — inconnu, jamais zéro
     */
    public record CoutMoyen(long sessions, Long moyenneMicroUsd, Long totalMicroUsd) {}
}

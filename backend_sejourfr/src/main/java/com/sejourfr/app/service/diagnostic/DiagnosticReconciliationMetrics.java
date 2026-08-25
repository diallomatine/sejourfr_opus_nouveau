package com.sejourfr.app.service.diagnostic;

import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.LongAdder;

/**
 * CE QUE LE SERVEUR RÉCONCILIE SUR UNE SORTIE DIAGNOSTIC, avant de la juger —
 * et ce qu'il <b>supplée</b> quand elle est incomplète, à l'assemblage des deux
 * productions.
 *
 * <p>Famille de compteurs <b>distincte</b> des autres, et il ne faut pas les
 * mélanger :
 * <ul>
 *   <li>un <b>refus</b> ({@code EvaluationRefusalMetrics}) rejette la sortie et
 *       peut coûter la tâche au candidat ;</li>
 *   <li>une <b>purge</b> ({@code EvaluationPurgeMetrics}) retire une phrase du
 *       rapport ;</li>
 *   <li>un <b>abaissement de niveau</b> ({@code CompetenceLevelDowngradeMetrics})
 *       change le palier affiché ;</li>
 *   <li>une <b>réconciliation</b> (ici) ne rejette rien et ne touche à aucun
 *       niveau : elle recalcule des champs <b>dérivés</b> ({@code priority},
 *       la confiance d'une compétence non observée) et applique les plafonds
 *       du contrat par troncature — nombre de priorités, longueur d'un texte,
 *       nombre d'items d'une liste. Elle ne retire jamais une phrase parce
 *       qu'elle serait infondée (ça, c'est une purge) : seulement parce
 *       qu'elle dépasse un plafond déjà déclaré au tool-schema.</li>
 * </ul>
 *
 * <p>Sans ces compteurs, la réconciliation serait invisible : on ne saurait pas
 * si le correcteur pose des {@code priority} incohérents une fois par an ou sur
 * une analyse sur deux, donc on ne pourrait ni justifier de retirer le champ du
 * contrat en v2, ni mesurer ce que la troncature déplace.
 */
@Component
public class DiagnosticReconciliationMetrics {

    /** Ce que le serveur a dû recalculer. */
    public enum Motif {
        /** {@code status=PRIORITY} annoncé avec {@code priority=false} : posé à true. */
        PRIORITE_DERIVEE_POSEE,
        /** {@code priority=true} sans {@code status=PRIORITY} (ou non observée) : remis à false. */
        PRIORITE_DERIVEE_RETIREE,
        /**
         * Au-delà du plafond par production : la priorité surnuméraire est
         * abaissée d'un cran, {@code PRIORITY -> TO_REINFORCE}. Le serveur
         * n'abaisse jamais qu'un cran et ne relève jamais.
         */
        PRIORITE_TRONQUEE,
        /**
         * Le correcteur n'a désigné aucune priorité sur cette production : une
         * <b>faiblesse observée</b> ({@code TO_REINFORCE}) en tient lieu, la
         * mieux classée d'abord.
         *
         * <p>Compté à l'assemblage ({@code DiagnosticSessionCoordinator}), pas à
         * la réconciliation d'une sortie : c'est la même nature de décision — le
         * serveur supplée une sortie LLM incomplète — donc la même famille de
         * compteurs, pas une famille de plus. Sans lui, on ne saurait pas si la
         * dérivation sert une fois sur cent ou sur tous les diagnostics, donc on
         * ne pourrait pas juger s'il faut, un jour, contraindre le contrat.
         */
        PRIORITE_DERIVEE_DE_FAIBLESSE,
        /**
         * {@code summary} au-delà de {@link DiagnosticAnalysisValidator#MAX_SUMMARY_LENGTH} :
         * coupé sur une limite de mot. Ce compteur dit combien de fois le
         * fournisseur ignore le {@code maxLength} du tool-schema — c'est lui
         * qui justifiera, ou non, de resserrer la consigne des rubriques.
         */
        SYNTHESE_TRONQUEE,
        /** Un item de {@code strengths} / {@code weaknesses} ou une {@code explanation} trop long : coupé. */
        TEXTE_TRONQUE,
        /** Plus de trois items dans {@code strengths} / {@code weaknesses} : surplus retiré. */
        LISTE_TRONQUEE,
        /**
         * {@code observed=false} avec une confiance autre que {@code LOW} :
         * ramenée à {@code LOW}. Une compétence non observée ne dit rien du
         * candidat, il n'y a donc aucune confiance à graduer.
         */
        CONFIANCE_NON_OBSERVEE_DERIVEE
    }

    private final Map<String, LongAdder> compteurs = new ConcurrentHashMap<>();

    public void enregistrer(Motif motif) {
        compteurs.computeIfAbsent(motif.name(), key -> new LongAdder()).increment();
    }

    /** Compteurs cumulés {@code "MOTIF" -> n}, triés, pour le log. */
    public Map<String, Long> compteurs() {
        Map<String, Long> out = new LinkedHashMap<>();
        compteurs.entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .forEach(entry -> out.put(entry.getKey(), entry.getValue().sum()));
        return out;
    }

    /** Remise à zéro — réservée aux tests. */
    public void reset() {
        compteurs.clear();
    }
}

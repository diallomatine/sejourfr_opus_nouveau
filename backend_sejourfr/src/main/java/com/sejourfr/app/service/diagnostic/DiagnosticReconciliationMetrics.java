package com.sejourfr.app.service.diagnostic;

import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.LongAdder;

/**
 * CE QUE LE SERVEUR RÉCONCILIE SUR UNE SORTIE DIAGNOSTIC, avant de la juger.
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
 *   <li>une <b>réconciliation</b> (ici) ne rejette rien, ne retire aucune phrase
 *       et ne touche à aucun niveau : elle recalcule un champ <b>dérivé</b>
 *       ({@code priority}) et applique un plafond par troncature.</li>
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
        PRIORITE_TRONQUEE
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

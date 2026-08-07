package com.sejourfr.app.service;

import org.springframework.stereotype.Component;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.LongAdder;

/**
 * CE QUE NOS PROPRES CONTROLES REFUSENT, compte par motif.
 *
 * <p>Avant, la liste exacte des violations partait dans un {@code log.warn} de
 * {@link AiEvaluationService} et se perdait dans la console : une enquete a du
 * conclure que sur 102 sorties refusees, 2 seulement avaient un motif tracable.
 * Or aucune de ces sorties n'etait un JSON casse — ce sont nos validateurs qui
 * les refusaient, sans qu'on sache lesquels ni pourquoi.
 *
 * <p>Deux usages, un seul objet :
 * <ul>
 *   <li><b>en exploitation</b> : des compteurs {@code (phase, motif)} bornes,
 *       relus dans les logs, qui disent enfin ce que le systeme refuse ;</li>
 *   <li><b>au banc de mesure</b> : une instance par cas, d'ou le banc tire les
 *       violations ET la citation refusee de CHAQUE appel — y compris celles du
 *       premier appel, que l'exception ne porte pas.</li>
 * </ul>
 *
 * <p>Le detail est conserve dans un anneau BORNE ({@value #REFUS_CONSERVES}) :
 * en production la memoire ne peut pas deriver, et au banc une instance ne voit
 * jamais plus de deux appels.
 */
@Component
public class EvaluationRefusalMetrics {

    /** Nombre de refus detailles conserves par instance (anneau borne). */
    static final int REFUS_CONSERVES = 20;

    /** A quel moment du pipeline la sortie a ete refusee. */
    public enum Phase {
        /** Premiere reponse du correcteur : un reessai reste possible. */
        PREMIER_APPEL,
        /** Reponse du reessai : apres elle, la submission echoue (ou se degrade). */
        APRES_REESSAI
    }

    /**
     * FAMILLE de violation. Volontairement grossiere : elle sert a savoir ce
     * qu'on refuse, pas a rejouer le validateur.
     */
    public enum Motif {
        /** Une citation n'a pas pu etre rattachee a la production. */
        PREUVE_NON_RATTACHEE,
        /** Preuve absente ou vide, alors que le contrat strict l'exige. */
        PREUVE_ABSENTE,
        /** Le feedback oral se fondait sur un element non evaluable. */
        GARDE_FOU_ORAL,
        /** Champ absent, champ en trop, plafond de restitution depasse. */
        STRUCTURE_CONTRAT,
        /** Codes de critere manquants, dupliques ou inattendus. */
        CRITERES,
        /** note_globale / note_sur_20 / niveau_cecrl hors contrat. */
        NOTE_OU_NIVEAU,
        AUTRE
    }

    /** Un refus, tel qu'il s'est produit : violations brutes + citations rejetees. */
    public record Refus(
        Phase phase,
        List<String> violations,
        List<String> citationsRefusees,
        Map<String, Integer> motifs) {
    }

    private final Map<String, LongAdder> compteurs = new ConcurrentHashMap<>();
    private final Deque<Refus> derniers = new ArrayDeque<>();

    /**
     * Enregistre une sortie refusee. {@code feedbackBrut} sert uniquement a
     * retrouver la CITATION rejetee critere par critere : sans elle, le motif
     * « rejet de preuve » ne dit pas quoi corriger.
     */
    public Refus enregistrer(Phase phase, List<String> violations, Map<String, Object> feedbackBrut) {
        Map<String, Integer> motifs = classer(violations);
        motifs.forEach((motif, n) ->
            compteurs.computeIfAbsent(phase.name() + "/" + motif, k -> new LongAdder()).add(n));
        Refus refus = new Refus(phase, List.copyOf(violations),
            citationsRefusees(violations, feedbackBrut), Map.copyOf(motifs));
        synchronized (derniers) {
            if (derniers.size() >= REFUS_CONSERVES) derniers.removeFirst();
            derniers.addLast(refus);
        }
        return refus;
    }

    /** Compteurs cumules {@code "PHASE/MOTIF" -> n}, tries, pour le log. */
    public Map<String, Long> compteurs() {
        Map<String, Long> out = new LinkedHashMap<>();
        compteurs.entrySet().stream()
            .sorted(Map.Entry.comparingByKey())
            .forEach(e -> out.put(e.getKey(), e.getValue().sum()));
        return out;
    }

    /** Derniers refus detailles, du plus ancien au plus recent. */
    public List<Refus> derniersRefus() {
        synchronized (derniers) {
            return List.copyOf(derniers);
        }
    }

    /** Vide le detail ET les compteurs : reservee au banc, entre deux tentatives. */
    public void reset() {
        compteurs.clear();
        synchronized (derniers) {
            derniers.clear();
        }
    }

    /** Ventilation d'une liste de violations par {@link Motif}. */
    static Map<String, Integer> classer(List<String> violations) {
        Map<Motif, Integer> compte = new EnumMap<>(Motif.class);
        for (String violation : violations) {
            compte.merge(motif(violation), 1, Integer::sum);
        }
        Map<String, Integer> out = new LinkedHashMap<>();
        for (Motif motif : Motif.values()) {
            Integer n = compte.get(motif);
            if (n != null) out.put(motif.name(), n);
        }
        return out;
    }

    static Motif motif(String violation) {
        if (violation == null) return Motif.AUTRE;
        if (violation.contains(EvaluationOutputValidator.ORAL_VIOLATION_MARKER)) {
            return Motif.GARDE_FOU_ORAL;
        }
        if (violation.contains("doit citer un passage reel")) return Motif.PREUVE_NON_RATTACHEE;
        // Contrat v6 : la preuve est un NUMERO de segment. Un numero inexistant
        // est l'exact equivalent d'une citation non rattachable, un numero absent
        // ou non entier celui d'une preuve vide — memes familles, pour que les
        // compteurs restent comparables d'une version de contrat a l'autre.
        if (violation.contains("doit designer un segment numerote")) {
            return Motif.PREUVE_NON_RATTACHEE;
        }
        if (violation.startsWith("preuve_segment[")) return Motif.PREUVE_ABSENTE;
        if (violation.startsWith("preuve[")) return Motif.PREUVE_ABSENTE;
        if (violation.contains("critere") && !violation.startsWith("note_sur_20")) {
            return Motif.CRITERES;
        }
        if (violation.startsWith("note_globale") || violation.startsWith("note_sur_20")
            || violation.startsWith("niveau_cecrl")) {
            return Motif.NOTE_OU_NIVEAU;
        }
        return Motif.STRUCTURE_CONTRAT;
    }

    /**
     * Citations litteralement refusees, dans l'ordre des violations. C'est le
     * seul element qui permet, apres coup, de savoir si le correcteur avait
     * invente sa preuve ou si c'est notre rapprochement qui l'a manquee.
     */
    static List<String> citationsRefusees(List<String> violations, Map<String, Object> feedbackBrut) {
        List<String> codes = EvaluationOutputValidator.unmatchedProofCodes(violations);
        if (codes.isEmpty() || feedbackBrut == null
            || !(feedbackBrut.get("scores_criteres") instanceof List<?> scores)) {
            return List.of();
        }
        List<String> out = new ArrayList<>();
        for (String code : codes) {
            for (Object score : scores) {
                if (score instanceof Map<?, ?> m && code.equals(String.valueOf(m.get("code")))) {
                    // Contrat v6 : ce n'est plus une citation mais un numero de
                    // segment — c'est neanmoins ce que le correcteur avait rendu,
                    // et c'est ce qu'on veut relire apres coup.
                    Object rendue = m.containsKey("preuve") ? m.get("preuve") : m.get("preuve_segment");
                    out.add(code + " : " + rendue);
                }
            }
        }
        return List.copyOf(out);
    }
}

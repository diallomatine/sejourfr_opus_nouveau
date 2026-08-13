package com.sejourfr.app.service.diagnostic;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

/**
 * DÉPARTAGE DES PRIORITÉS DU DIAGNOSTIC — règle unique, deux appelants.
 *
 * <p>Confiance décroissante ({@code HIGH > MEDIUM > LOW}), puis rang de la
 * compétence dans l'allowlist de son sujet
 * ({@code diagnostic_task_skills.display_order}, l'ordre éditorial
 * d'importance), et seulement en dernier recours le code — uniquement pour
 * rester déterministe.
 *
 * <p><b>Jamais l'ordre alphabétique comme critère utile.</b> C'est le défaut
 * corrigé dans {@link DiagnosticSessionCoordinator} : « EE… » précède toujours
 * « EO… », donc l'écrit passait mécaniquement devant l'oral et les compétences
 * C1/C2 devant les autres. Un rang alphabétique ne dit rien de l'importance
 * pédagogique.
 *
 * <p>Extrait ici à la <b>deuxième occurrence</b> (règle « duplication = signal »
 * du dépôt) : l'assemblage des deux productions
 * ({@code DiagnosticSessionCoordinator}) et la troncature du plafond de
 * priorités ({@link DiagnosticAnalysisReconciler}) doivent trancher exactement
 * pareil — deux copies finiraient par désigner deux priorités n°1 différentes.
 */
final class DiagnosticPriorityRanking {

    private DiagnosticPriorityRanking() {}

    /** Une priorité et ses clés de tri, résolues une seule fois. */
    record Ranked(Map<String, Object> item, String skillCode, int confidence, int order) {}

    /** Confiance décroissante, puis rang d'allowlist, puis code (déterminisme seul). */
    static final Comparator<Ranked> PAR_IMPORTANCE = Comparator
            .comparingInt(Ranked::confidence).reversed()
            .thenComparingInt(Ranked::order)
            .thenComparing(Ranked::skillCode);

    /**
     * Ordonne des entrées {@code skills} déjà filtrées sur les priorités.
     *
     * @param allowlistOrder rang de chaque code dans l'allowlist du sujet. Une
     *                       compétence absente — cas que le validateur refuse —
     *                       passe en dernier.
     */
    static List<Ranked> ranked(
            List<Map<String, Object>> items, Map<String, Integer> allowlistOrder) {
        List<Ranked> ranked = new ArrayList<>(items.size());
        for (Map<String, Object> item : items) {
            String code = String.valueOf(item.get("skill_code"));
            ranked.add(new Ranked(item, code, confidenceRank(item.get("confidence")),
                    allowlistOrder.getOrDefault(code, Integer.MAX_VALUE)));
        }
        ranked.sort(PAR_IMPORTANCE);
        return ranked;
    }

    /** {@code HIGH} 3, {@code MEDIUM} 2, tout le reste 1. */
    static int confidenceRank(Object raw) {
        return switch (String.valueOf(raw)) {
            case "HIGH" -> 3;
            case "MEDIUM" -> 2;
            default -> 1;
        };
    }
}

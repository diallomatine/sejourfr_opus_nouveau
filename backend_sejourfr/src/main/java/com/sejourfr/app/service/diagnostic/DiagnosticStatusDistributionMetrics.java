package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.LongAdder;

/**
 * <b>Ce que le correcteur rend vraiment</b>, modalite par modalite — un simple
 * compteur, aucune regle.
 *
 * <h2>Pourquoi il existe</h2>
 * Mesure du 2026-08-26, sur les 22 analyses de diagnostic en base :
 *
 * <pre>
 * EE : 2 PRIORITY · 34 TO_REINFORCE · 51 SOLID
 * EO : 0 PRIORITY · 10 TO_REINFORCE · 57 SOLID
 * </pre>
 *
 * <p>Zero {@code PRIORITY} sur 57 observations orales, et sept fois moins de
 * fragilites qu'a l'ecrit. Verification faite : ce n'est <b>pas</b> structurel —
 * le tool-schema autorise les quatre statuts pour les deux modalites (fichier
 * unique, la modalite n'est qu'une donnee d'entree), et les rubriques demandent
 * explicitement « au plus deux competences prioritaires sur cette production ».
 * La seule consigne propre a l'oral porte sur ce qu'on ne peut pas entendre
 * (prononciation, debit, intonation), pas sur les verdicts.
 *
 * <p>Ce desequilibre est donc <b>comportemental</b>, et il compte : c'est
 * toujours l'oral qui se retrouve sans fragilite, donc sans action, sur les
 * ecrans. Vingt-deux analyses ne permettent d'en conclure rien du tout — d'ou
 * ce compteur, a relire vers <b>N &asymp; 100</b>.
 *
 * <p>🛑 <b>Il ne decide de rien</b> et n'entre dans aucun calcul : ni garde-fou,
 * ni seuil, ni correction. On mesure d'abord, on tranchera apres — et surtout
 * pas en ajoutant une consigne de prompt de plus.
 */
@Component
public class DiagnosticStatusDistributionMetrics {

    private final Map<String, LongAdder> compteurs = new ConcurrentHashMap<>();

    /** Un verdict rendu par le correcteur sur une competence observee. */
    public void enregistrer(EpreuveType epreuve, LearningPlanSkillStatus status) {
        if (epreuve == null || status == null) return;
        compteurs.computeIfAbsent(cle(epreuve, status), key -> new LongAdder()).increment();
    }

    /** Compteurs cumules {@code "TCF_EO:SOLID" -> n}, tries, pour le log. */
    public Map<String, Long> compteurs() {
        Map<String, Long> out = new LinkedHashMap<>();
        compteurs.entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .forEach(entry -> out.put(entry.getKey(), entry.getValue().sum()));
        return out;
    }

    /** Remise a zero — reservee aux tests. */
    public void reset() {
        compteurs.clear();
    }

    private static String cle(EpreuveType epreuve, LearningPlanSkillStatus status) {
        return epreuve.name() + ':' + status.name();
    }
}

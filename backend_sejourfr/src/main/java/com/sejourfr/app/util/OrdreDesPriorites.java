package com.sejourfr.app.util;

import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.ObservationConfidence;

import java.time.Instant;
import java.util.Comparator;
import java.util.function.Function;
import java.util.function.ToIntFunction;

/**
 * <b>L'ordre des fragilites du Plan, ecrit une seule fois</b> — autorite unique
 * du lot du parcours ({@code JourneyLotBuilder}), des priorites de
 * {@code /api/me/plan} ({@code LearningPlanPriorityResolver}) et du departage
 * du classement de la seance ({@code PlanActionRanker}).
 *
 * <h2>L'ordre</h2>
 * <ol>
 *   <li>{@code PRIORITY} avant {@code TO_REINFORCE} ;</li>
 *   <li>confiance <b>decroissante</b> ({@code HIGH > MEDIUM > LOW}) ;</li>
 *   <li>observation la plus <b>recente</b> ;</li>
 *   <li><b>rang editorial</b> de la competence dans sa tache
 *       ({@code skills.display_order}, croissant) ;</li>
 *   <li>code de la competence, pour qu'une egalite parfaite reste
 *       deterministe.</li>
 * </ol>
 *
 * <h2>🛑 Pourquoi le rang editorial, et pourquoi celui-la (AR-3, 2026-10-04)</h2>
 * <p>Jusqu'ici, apres la recence venait directement le code — et la recence
 * departageait <b>a tort</b> : {@code LearningPlanObservationService} posait
 * {@code Instant.now()} a <b>chaque ligne</b>, dans l'ordre des {@code skills[]}
 * rendus par le correcteur. Les huit observations d'un diagnostic s'etalaient
 * sur une vingtaine de millisecondes, et « la plus recente d'abord »
 * retenait donc <b>la derniere competence ecrite</b> : {@code EE1-C8} (rang 8 de
 * l'allowlist) entrait dans 4 lots sur 7, {@code EE1-C7} (rang 1) dans aucun.
 * Desormais toutes les observations d'une meme soumission portent le
 * <b>meme</b> instant ; a statut et confiance egaux, la recence ne trie donc
 * plus rien a l'interieur d'une production, et il faut un critere METIER.
 *
 * <p>Le rang retenu est celui de la <b>taxonomie</b> ({@code skills.display_order}) :
 * l'ordre editorial d'importance des huit competences de chaque tache
 * officielle, celui-la meme qui sert d'allowlist a toute production standard et
 * a tout examen blanc. Il a ete prefere a l'allowlist propre a un sujet de
 * diagnostic ({@code diagnostic_task_skills.display_order}) pour trois raisons :
 * <ul>
 *   <li>il est porte par la competence, <b>deja chargee</b> partout : aucune
 *       requete de plus, donc le cout verrouille de {@code /api/me/plan} ne
 *       bouge pas ;</li>
 *   <li>il vaut pour <b>toutes</b> les sources (diagnostic, examen blanc,
 *       production, micro-entrainement, comprehension), la ou l'allowlist d'un
 *       sujet de diagnostic n'existe que pour lui — un comparateur qui
 *       dependrait de la source rendrait deux ordres pour la meme question ;</li>
 *   <li>le rapport du diagnostic ne lit plus ses propres priorites : il sert
 *       celles du lot ({@code DiagnosticResultDto.planPriorities}), donc la
 *       coherence rapport ⇄ Plan est tenue par construction, plus par
 *       l'alignement de deux regles.</li>
 * </ul>
 *
 * <p>⚠️ Ce changement ne vaut que pour les <b>futurs</b> calculs : un lot deja
 * ecrit est un fait date, il n'est pas reecrit.
 */
public final class OrdreDesPriorites {

    private OrdreDesPriorites() {
    }

    /**
     * Le departage <b>final</b>, partage par tout ce qui classe des competences
     * observees : recence decroissante (une date absente passe apres), rang
     * editorial croissant, puis code.
     */
    public static <T> Comparator<T> departage(
            Function<T, Instant> observeLe,
            ToIntFunction<T> rangEditorial,
            Function<T, String> code) {
        return Comparator.comparing(observeLe, Comparator.nullsLast(Comparator.reverseOrder()))
                .thenComparingInt(rangEditorial)
                .thenComparing(code, Comparator.nullsLast(Comparator.naturalOrder()));
    }

    /** Le departage, applique aux observations du Plan. */
    public static final Comparator<LearningPlanObservation> PLUS_RECENTE_D_ABORD = departage(
            LearningPlanObservation::getObservedAt,
            observation -> rangEditorial(observation.getSkill()),
            observation -> observation.getSkill() == null ? null : observation.getSkill().getCode());

    /** L'ordre de gravite complet : statut, confiance, puis {@link #PLUS_RECENTE_D_ABORD}. */
    public static final Comparator<LearningPlanObservation> PAR_GRAVITE = Comparator
            .comparingInt((LearningPlanObservation observation) ->
                    observation.getStatus() == LearningPlanSkillStatus.PRIORITY ? 0 : 1)
            .thenComparingInt(observation -> -rangConfiance(observation.getConfidence()))
            .thenComparing(PLUS_RECENTE_D_ABORD);

    /**
     * {@code HIGH} 3, {@code MEDIUM} 2, tout le reste 1 — miroir de
     * {@code DiagnosticPriorityRanking.confidenceRank}, sur l'observation
     * persistee au lieu du JSON du correcteur.
     */
    public static int rangConfiance(ObservationConfidence confidence) {
        if (confidence == null) return 1;
        return switch (confidence) {
            case HIGH -> 3;
            case MEDIUM -> 2;
            case LOW -> 1;
        };
    }

    /**
     * Le rang editorial d'une competence dans sa tache. Une competence absente
     * passe apres toutes les autres.
     */
    public static int rangEditorial(Skill skill) {
        return skill == null ? Integer.MAX_VALUE : skill.getDisplayOrder();
    }
}

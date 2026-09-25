package com.sejourfr.app.service.analytics;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.sejourfr.app.enums.SuiviIndicator;

import java.time.Duration;
import java.time.LocalDate;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

/**
 * <b>La configuration versionnee de la mesure d'audience</b> — image en memoire
 * de {@code analytics/analytics-config-vN.json} (chantier Suivi, brief §8).
 *
 * <p>🛑 Aucune valeur n'est ecrite en Java : pas de defaut, pas de repli. Une cle
 * absente, inconnue ou incoherente est une erreur de demarrage
 * ({@link AnalyticsConfigLoader}). Meme doctrine que {@code PlanConfig} et
 * {@code EmailAutomationConfig}.
 *
 * @param timezone               toujours {@code Europe/Paris} : c'est
 *                               {@code FenetreMesure.PARIS} qui fait autorite, la
 *                               config ne peut que le confirmer
 * @param cohortWindowDays       fenetre de la cohorte du tunnel (brief §7.2)
 * @param claimTokenTtlDays      duree de vie d'un claimToken de diagnostic_run
 * @param purchaseIntentTtlHours duree de vie d'une purchase_intent (Q12)
 * @param anonymousIdTtlDays     duree de vie du traceur cote client (13 mois)
 * @param rawEventRetentionDays  conservation des evenements bruts (Q5 : 395 j)
 * @param purgeBatchSize         lignes supprimees par transaction de purge
 * @param utmSourceGroups        groupe -> sources declarees (minuscules)
 * @param utmSourceFallbackGroup groupe de tout ce qui n'est dans aucun groupe
 * @param measurementStart       date de debut de mesure par indicateur (Q16),
 *                               {@code null} = pas encore mesure
 */
@JsonIgnoreProperties(ignoreUnknown = false)
public record AnalyticsConfig(
        int analyticsConfigVersion,
        String timezone,
        int cohortWindowDays,
        int claimTokenTtlDays,
        int purchaseIntentTtlHours,
        int anonymousIdTtlDays,
        int rawEventRetentionDays,
        int purgeBatchSize,
        Ingestion ingestion,
        Map<String, List<String>> utmSourceGroups,
        String utmSourceFallbackGroup,
        Map<SuiviIndicator, String> measurementStart
) {

    /**
     * @param maxBatchSize              evenements au plus par lot (au-dela : 400)
     * @param clockSkewToleranceMinutes horodate client dans le futur au-dela de
     *                                  cette tolerance ⇒ ramenee a l'heure serveur
     * @param maxEventAgeHours          horodate client plus ancienne ⇒ evenement
     *                                  refuse. Assez large pour une file mobile
     *                                  hors ligne, assez etroite pour qu'on ne
     *                                  fabrique pas un historique
     * @param rateLimit                 garde-fous de l'endpoint public en lot
     */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record Ingestion(
            int maxBatchSize,
            int clockSkewToleranceMinutes,
            int maxEventAgeHours,
            RateLimit rateLimit
    ) {
        public Duration clockSkewTolerance() {
            return Duration.ofMinutes(clockSkewToleranceMinutes);
        }

        public Duration maxEventAge() {
            return Duration.ofHours(maxEventAgeHours);
        }
    }

    /** Lots acceptes par fenetre, par IP et par identifiant de mesure. */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record RateLimit(Window perIpBurst, Window perIpDaily,
                            Window perAnonymousIdBurst, Window perAnonymousIdDaily) {
    }

    @JsonIgnoreProperties(ignoreUnknown = false)
    public record Window(int max, int windowSeconds) {
    }

    /** Date de debut de mesure, vide si l'indicateur n'est pas encore mesure. */
    public Optional<LocalDate> measurementStartOf(SuiviIndicator indicator) {
        String raw = measurementStart.get(indicator);
        return raw == null ? Optional.empty() : Optional.of(LocalDate.parse(raw));
    }

    /**
     * Groupe d'une source declaree ({@code ig} ⇒ {@code instagram}). Absente ou
     * hors groupe ⇒ {@link #utmSourceFallbackGroup}. Appliquee a la LECTURE :
     * changer un groupe ne demande aucune migration.
     */
    public String groupOfSource(String source) {
        if (source == null || source.isBlank()) return utmSourceFallbackGroup;
        String value = source.trim().toLowerCase(Locale.ROOT);
        for (Map.Entry<String, List<String>> group : utmSourceGroups.entrySet()) {
            if (group.getValue().contains(value)) return group.getKey();
        }
        return utmSourceFallbackGroup;
    }

    public Duration rawEventRetention() {
        return Duration.ofDays(rawEventRetentionDays);
    }
}

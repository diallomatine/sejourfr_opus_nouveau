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
 * @param diagnosticRunRateLimit garde-fous des routes publiques de
 *                               {@code diagnostic_run} (creation, « soumis »),
 *                               par IP et par identifiant de mesure
 * @param utmSourceGroups        groupe -> sources declarees (minuscules)
 * @param utmSourceFallbackGroup groupe de tout ce qui n'est dans aucun groupe
 * @param measurementStart       date de debut de mesure par indicateur (Q16),
 *                               {@code null} = pas encore mesure
 * @param civicSubmittedMinAnsweredRatio part minimale de questions repondues
 *                               pour qu'une run CIVIQUE compte « soumise » a la
 *                               lecture (controle C, V076), dans {@code ]0, 1]}.
 *                               Une run sans mesure n'est jamais comptee
 * @param runReuseWindowHours    age maximal d'une run rendue par sa
 *                               {@code clientKey} (controle F2) ; au-dela, run neuve
 * @param activity               activite des comptes connectes (presence,
 *                               connexions, ecrans ; chantier « Activite »)
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
        RateLimit diagnosticRunRateLimit,
        Map<String, List<String>> utmSourceGroups,
        String utmSourceFallbackGroup,
        Map<SuiviIndicator, String> measurementStart,
        double civicSubmittedMinAnsweredRatio,
        int runReuseWindowHours,
        Activity activity
) {

    /**
     * Activite des comptes connectes ({@code user_activity_day},
     * {@code user_login_event}, ecrans {@code SCREEN_VIEWED}).
     *
     * @param retentionDays        conservation de {@code user_login_event} et
     *                             {@code user_activity_day} (12 mois, D6)
     * @param writeIntervalSeconds au plus une ecriture de presence par compte,
     *                             plateforme et jour sur cet intervalle
     * @param onlineWindowSeconds  « en ligne » = derniere activite de moins de
     *                             cette duree. Superieure a deux battements
     *                             (60 s) : avec une ecriture par minute au plus,
     *                             une fenetre de 120 s ferait clignoter un compte
     *                             present
     * @param screenTopLimit       lignes d'ecran servies avant « Autres ecrans
     *                             suivis »
     * @param screenViewRetentionDays conservation des {@code SCREEN_VIEWED}
     *                             (12 mois : « pages et ecrans consultes » font
     *                             partie de l'historique d'activite annonce par
     *                             {@code /confidentialite}). Les autres evenements
     *                             gardent {@code rawEventRetentionDays}
     */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record Activity(int retentionDays, int writeIntervalSeconds, int onlineWindowSeconds,
                           int screenTopLimit, int screenViewRetentionDays) {

        public Duration retention() {
            return Duration.ofDays(retentionDays);
        }

        public Duration writeInterval() {
            return Duration.ofSeconds(writeIntervalSeconds);
        }

        public Duration screenViewRetention() {
            return Duration.ofDays(screenViewRetentionDays);
        }

        public Duration onlineWindow() {
            return Duration.ofSeconds(onlineWindowSeconds);
        }
    }

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

    /** Appels acceptes par fenetre, par IP et par identifiant de mesure. */
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

    public Duration runReuseWindow() {
        return Duration.ofHours(runReuseWindowHours);
    }

    public Duration claimTokenTtl() {
        return Duration.ofDays(claimTokenTtlDays);
    }

    public Duration rawEventRetention() {
        return Duration.ofDays(rawEventRetentionDays);
    }
}

package com.sejourfr.app.service.email;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.sejourfr.app.enums.EmailType;

import java.time.Duration;
import java.util.List;
import java.util.Map;

/**
 * <b>La configuration versionnee des emails</b> — image en memoire de
 * {@code email/email-automation-config-vN.json}.
 *
 * <p>🛑 Aucune valeur n'est ecrite en Java : pas de defaut, pas de repli. Une cle
 * absente est une erreur de demarrage ({@link EmailAutomationConfigLoader}).
 * Meme doctrine que {@code PlanConfig}.
 *
 * @param dailyCap                   voir {@link Engagement}
 * @param batchSize                  taille d'une page des requetes de scenario et
 *                                   des purges
 * @param retentionMonths            duree de conservation d'{@code email_deliveries}
 *                                   (arbitrage n°16 : 12 mois)
 * @param scenarios                  une fenetre par scenario automatise, exhaustive
 */
@JsonIgnoreProperties(ignoreUnknown = false)
public record EmailAutomationConfig(
        int emailAutomationConfigVersion,
        Engagement engagement,
        Retry retry,
        int batchSize,
        int retentionMonths,
        Map<EmailType, ScenarioWindow> scenarios
) {

    /**
     * @param dailyCap mails ENGAGEMENT par compte et par <b>jour calendaire
     *                 Europe/Paris</b> (arbitrage n°18), pas par 24 h glissantes.
     */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record Engagement(int dailyCap) {}

    /**
     * @param immediateDelaysSeconds attentes entre les tentatives SMTP d'une meme
     *                               ligne, dans le thread de l'executor email : une
     *                               tentative initiale puis une par delai
     * @param maxDeferredAttempts    nouvelles lignes autorisees apres un premier
     *                               echec, pour une meme cle
     * @param eventWindowHours       fenetre de relance differee d'un mail
     *                               evenementiel, comptee depuis sa premiere ligne
     * @param stalePendingMinutes    age au-dela duquel un PENDING est tenu pour
     *                               bloque et passe FAILED (« stale »)
     */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record Retry(
            List<Integer> immediateDelaysSeconds,
            int maxDeferredAttempts,
            int eventWindowHours,
            int stalePendingMinutes
    ) {
        public List<Duration> immediateDelays() {
            return immediateDelaysSeconds.stream().map(Duration::ofSeconds).toList();
        }

        /** Lignes au plus pour une cle : la premiere, plus les relances differees. */
        public int maxRowsPerKey() {
            return 1 + maxDeferredAttempts;
        }
    }

    /**
     * La fenetre d'un scenario, <b>bornee des deux cotes</b> : elle tolere un jour
     * manque ET empeche l'envoi retroactif massif au premier deploiement.
     *
     * <p>Lecture selon le scenario (documentee dans docs/regles/emails.md) :
     * jours calendaires Europe/Paris ecoules depuis l'inscription, la derniere
     * activite ou la date de reference pour les scenarios d'age et
     * d'inactivite ; fin d'acces dans {@code ]now + min, now + max]} pour
     * {@code PREMIUM_ENDING_*} ; fin dans {@code [now - max, now]} pour
     * {@code PREMIUM_ENDED}.
     *
     * @param minAccessAgeDays anciennete minimale de l'acces (ENDING_7 : 3 jours,
     *                         pour ne pas annoncer la fin d'un pass qu'on vient
     *                         d'acheter) ; 0 ailleurs
     */
    @JsonIgnoreProperties(ignoreUnknown = false)
    public record ScenarioWindow(int minDays, int maxDays, int minAccessAgeDays) {}

    public ScenarioWindow window(EmailType type) {
        return scenarios.get(type);
    }
}

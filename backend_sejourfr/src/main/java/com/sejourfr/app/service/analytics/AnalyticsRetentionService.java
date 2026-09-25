package com.sejourfr.app.service.analytics;

import com.sejourfr.app.manager.AnalyticsEventManager;
import com.sejourfr.app.manager.AnalyticsVisitorManager;
import com.sejourfr.app.manager.DiagnosticRunManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;

/**
 * Retention des donnees de mesure brutes : {@code rawEventRetentionDays} de la
 * config (395 j, arbitrage Q5). <b>Ce n'est pas optionnel</b> : c'est l'une des
 * conditions de l'exemption CNIL sur laquelle repose l'absence de bandeau de
 * consentement ({@code /confidentialite} art. 5 et 8.4).
 *
 * <p>Deux passes, dans cet ordre, par lots bornes (une transaction par lot,
 * patron {@code EmailRetentionService}) :
 * <ol>
 *   <li>les evenements dont la date retenue precede la limite ;</li>
 *   <li>les visiteurs <b>inactifs</b> depuis la limite (derniere activite, pas
 *       premiere vue), avec leurs liens {@code analytics_identity}.</li>
 * </ol>
 *
 * <p>🛑 <b>Ce qui n'est PAS purge ici</b> : les faits metier. {@code diagnostic_run},
 * {@code users}, {@code user_subscriptions} n'ont aucune cle etrangere vers
 * {@code analytics_visitor} et ne perdent rien (scenario 19).
 *
 * <p>Troisieme passe (lot 2a, D27) : une {@code diagnostic_run} vue avant la
 * limite <b>oublie son identifiant de mesure</b> ({@code anonymous_id},
 * {@code client_key}). La run et ses faits (vu, soumis, rattache) restent ;
 * seul le traceur, qui ne designe plus aucun visiteur, disparait. Non comptee
 * dans le total rendu, qui reste « lignes supprimees ».
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AnalyticsRetentionService {

    private final AnalyticsEventManager eventManager;
    private final AnalyticsVisitorManager visitorManager;
    private final DiagnosticRunManager runManager;
    private final AnalyticsConfig config;

    /** @return lignes supprimees (evenements + visiteurs). */
    public int purge(Instant now) {
        Instant cutoff = now.minus(config.rawEventRetention());
        int batch = config.purgeBatchSize();

        int events = 0;
        int deleted;
        do {
            deleted = eventManager.deleteOlderThan(cutoff, batch);
            events += deleted;
        } while (deleted == batch);

        int visitors = 0;
        do {
            deleted = visitorManager.deleteInactiveSince(cutoff, batch);
            visitors += deleted;
        } while (deleted == batch);

        int runs = 0;
        do {
            deleted = runManager.forgetAnonymousIdBefore(cutoff, batch, now);
            runs += deleted;
        } while (deleted == batch);

        if (events + visitors + runs > 0) {
            log.info("Retention analytics ({} j) : {} evenement(s) et {} visiteur(s) purges, "
                            + "{} run(s) sans identifiant de mesure",
                    config.rawEventRetentionDays(), events, visitors, runs);
        }
        return events + visitors;
    }
}

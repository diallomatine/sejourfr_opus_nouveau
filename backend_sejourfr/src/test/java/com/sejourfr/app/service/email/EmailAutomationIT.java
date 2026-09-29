package com.sejourfr.app.service.email;

import com.sejourfr.app.entity.EmailDelivery;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.EmailDeliveryStatus;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PlanPurchaseType;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.email.automation.EmailAutomationService;
import com.sejourfr.app.support.AbstractEmailIT;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Les scenarios automatises (brief §7 et §10), a horloge fixee.
 *
 * <p>L'instant de reference {@link #T} est calcule a partir de l'horloge
 * d'EXECUTION, decale d'un an : les donnees laissees par d'autres tests, datees
 * d'aujourd'hui, tombent hors de toutes les fenetres (au plus 14 jours), et aucun
 * test ne depend d'une date ecrite en dur. Chaque assertion ne regarde que les
 * comptes crees par le test.
 */
class EmailAutomationIT extends AbstractEmailIT {

    /** Aujourd'hui + 365 jours, a 8 h UTC (9 ou 10 h a Paris, loin de minuit). */
    private static final Instant T = java.time.LocalDate.now(java.time.ZoneOffset.UTC).plusDays(365)
            .atTime(8, 0).toInstant(java.time.ZoneOffset.UTC);
    private static final Duration JOUR = Duration.ofDays(1);

    @Autowired private EmailAutomationService automation;
    @Autowired private PlanManager planManager;
    @Autowired private UserSubscriptionManager subscriptionManager;

    // ------------------------------------------------------------ fixtures

    /** Passe le scheduler a l'instant donne et attend la fin des envois. */
    private EmailAutomationService.Report passage(Instant at) {
        clock.set(at);
        EmailAutomationService.Report report = automation.runDaily(at);
        awaitEmailExecutorIdle();
        return report;
    }

    private User compte(Instant createdAt) {
        User u = user();
        jdbc.update("UPDATE users SET created_at = ? WHERE id = ?", Timestamp.from(createdAt), u.getId());
        return u;
    }

    /**
     * Un acte d'entrainement a l'instant donne : une simulation orale reellement
     * jointe (l'un des quatre actes de la vue V073). Choisie parce qu'elle ne cree
     * aucun contenu partage — une question laissee en base pourrait etre tiree par
     * un autre test.
     */
    private void activite(User u, Instant at) {
        var session = data.realtimeSession(u);
        jdbc.update("UPDATE realtime_sessions SET connected_at = ?, started_at = ? WHERE id = ?",
                Timestamp.from(at), Timestamp.from(at), session.getId());
    }

    private Plan pass(ModuleAccess module) {
        Plan p = data.plan(module);
        p.setName(module == ModuleAccess.INTEGRAL ? "Intégral — pass 1 mois" : "Civique — pass 1 mois");
        p.setPurchaseType(PlanPurchaseType.ONE_TIME);
        p.setActive(false);
        return trackPlan(planManager.save(p));
    }

    private UserSubscription acces(User u, ModuleAccess module, Instant starts, Instant ends) {
        UserSubscription s = data.userSubscription(u, pass(module));
        s.setAutoRenew(false);
        s.setStartsAt(starts);
        s.setEndsAt(ends);
        return subscriptionManager.save(s);
    }

    private List<EmailType> recus(User u) {
        return rowsOf(u).stream()
                .filter(d -> d.getStatus() == EmailDeliveryStatus.SENT)
                .map(EmailDelivery::getEmailType).toList();
    }

    // ---------------------------------------------------- NO_PREMIUM_AFTER_7_DAYS

    @Test
    @DisplayName("Inscrit il y a 8 jours, jamais Premium : un rappel, une seule fois")
    void jamaisPremium() {
        User u = compte(T.minus(JOUR.multipliedBy(8)));

        passage(T);
        passage(T.plus(JOUR));

        assertThat(recus(u)).containsExactly(EmailType.NO_PREMIUM_AFTER_7_DAYS);
        EmailMessage m = mails.sentTo(u.getEmail()).getFirst();
        assertThat(m.unsubscribeUrl()).isNotNull();
        assertThat(m.oneClickUnsubscribeUrl()).isNotNull();
    }

    @Test
    @DisplayName("Deja Premium une fois (acces expire) : pas de NO_PREMIUM")
    void dejaPremiumPasse() {
        User u = compte(T.minus(JOUR.multipliedBy(8)));
        acces(u, ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(8)), T.minus(JOUR.multipliedBy(7)));

        passage(T);

        assertThat(recus(u)).doesNotContain(EmailType.NO_PREMIUM_AFTER_7_DAYS);
    }

    @Test
    @DisplayName("Deploiement : un ancien compte hors fenetre ne recoit rien")
    void ancienCompteHorsFenetre() {
        User vieux = compte(T.minus(JOUR.multipliedBy(40)));
        activite(vieux, T.minus(JOUR.multipliedBy(30)));

        passage(T);

        assertThat(rowsOf(vieux)).isEmpty();
    }

    @Test
    @DisplayName("Desabonne : exclu par la requete, aucune ligne ecrite")
    void desabonneExclu() {
        User u = compte(T.minus(JOUR.multipliedBy(8)));
        jdbc.update("INSERT INTO user_email_preferences (user_id, engagement_enabled) VALUES (?, FALSE)", u.getId());

        passage(T);

        assertThat(rowsOf(u)).isEmpty();
    }

    // --------------------------------------------------------- inactivite

    @Test
    @DisplayName("Non Premium : rien a J+2, NO_TRAINING a J+7, puis plus rien")
    void inactiviteNonPremium() {
        User u = compte(T.minus(JOUR.multipliedBy(60)));
        Instant derniere = T.minus(JOUR.multipliedBy(2));
        activite(u, derniere);

        passage(T);
        assertThat(recus(u)).isEmpty();

        passage(derniere.plus(JOUR.multipliedBy(7)));
        passage(derniere.plus(JOUR.multipliedBy(9)));
        passage(derniere.plus(JOUR.multipliedBy(12)));

        assertThat(recus(u)).containsExactly(EmailType.NO_TRAINING_7_DAYS);
        assertThat(rowsOf(u, EmailType.NO_TRAINING_7_DAYS).getFirst().getDeduplicationKey())
                .isEqualTo("NO_TRAINING_7_DAYS:" + u.getId() + ":"
                        + java.time.LocalDate.ofInstant(derniere, EmailFormats.PARIS));
    }

    @Test
    @DisplayName("Premium : J+2 puis J+7, jamais un 3e ; une nouvelle activite ouvre un nouvel episode")
    void inactivitePremiumEtNouvelEpisode() {
        User u = compte(T.minus(JOUR.multipliedBy(60)));
        acces(u, ModuleAccess.INTEGRAL, T.minus(JOUR.multipliedBy(20)), T.plus(JOUR.multipliedBy(60)));
        Instant derniere = T.minus(JOUR.multipliedBy(2));
        activite(u, derniere);

        passage(T);
        passage(T.plus(JOUR));
        passage(derniere.plus(JOUR.multipliedBy(7)));
        passage(derniere.plus(JOUR.multipliedBy(9)));
        passage(derniere.plus(JOUR.multipliedBy(12)));

        assertThat(recus(u)).containsExactly(EmailType.PREMIUM_INACTIVE_2_DAYS, EmailType.NO_TRAINING_7_DAYS);

        Instant reprise = derniere.plus(JOUR.multipliedBy(13));
        activite(u, reprise);
        passage(reprise.plus(JOUR.multipliedBy(2)));

        assertThat(recus(u)).containsExactly(EmailType.PREMIUM_INACTIVE_2_DAYS, EmailType.NO_TRAINING_7_DAYS,
                EmailType.PREMIUM_INACTIVE_2_DAYS);
    }

    @Test
    @DisplayName("Premium jamais entraine : la date de reference est le debut de l'acces (arbitrage n°19)")
    void premiumJamaisEntraine() {
        User u = compte(T.minus(JOUR.multipliedBy(60)));
        acces(u, ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(3)), T.plus(JOUR.multipliedBy(60)));

        passage(T);

        assertThat(recus(u)).containsExactly(EmailType.PREMIUM_INACTIVE_2_DAYS);
    }

    // -------------------------------------------------------------- plafond

    @Test
    @DisplayName("Plafond : deux scenarios eligibles le meme jour, seul le prioritaire part ; l'autre le lendemain")
    void plafondEtPriorite() {
        User u = compte(T.minus(JOUR.multipliedBy(60)));
        acces(u, ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(25)), T.plus(JOUR.multipliedBy(5)));
        activite(u, T.minus(JOUR.multipliedBy(3)));

        EmailAutomationService.Report jour1 = passage(T);

        assertThat(recus(u)).containsExactly(EmailType.PREMIUM_ENDING_7_DAYS);
        assertThat(jour1.count(EmailType.PREMIUM_INACTIVE_2_DAYS, EmailOutcome.CAPPED)).isGreaterThanOrEqualTo(1);
        assertThat(rowsOf(u, EmailType.PREMIUM_INACTIVE_2_DAYS)).isEmpty();

        passage(T.plus(JOUR));

        assertThat(recus(u)).containsExactlyInAnyOrder(
                EmailType.PREMIUM_ENDING_7_DAYS, EmailType.PREMIUM_INACTIVE_2_DAYS);
    }

    @Test
    @DisplayName("DIAGNOSTIC_PLAN_READY deja parti aujourd'hui : le scheduler n'ajoute rien le meme jour")
    void planReadyConsommeLePlafond() {
        User u = compte(T.minus(JOUR.multipliedBy(8)));
        clock.set(T.minus(Duration.ofHours(2)));
        UUID id = deliveries.insertPending(new com.sejourfr.app.manager.EmailDeliveryManager.NewDelivery(
                u.getId(), EmailType.DIAGNOSTIC_PLAN_READY, u.getEmail(),
                com.sejourfr.app.enums.EmailProvider.SPRING_MAIL, "DIAGNOSTIC_PLAN_READY:" + u.getId() + ":TCF",
                null, null, T.minus(Duration.ofHours(2)))).orElseThrow();
        deliveries.markSent(id, T.minus(Duration.ofHours(2)), null, 1);

        passage(T);

        assertThat(rowsOf(u, EmailType.NO_PREMIUM_AFTER_7_DAYS)).isEmpty();
        passage(T.plus(JOUR));
        assertThat(recus(u)).contains(EmailType.NO_PREMIUM_AFTER_7_DAYS);
    }

    // ------------------------------------------------------- fin d'acces

    @Test
    @DisplayName("ENDING_7, ENDING_2 et ENDED partent une fois chacun")
    void finDAccesUneFoisChacun() {
        User u = compte(T.minus(JOUR.multipliedBy(60)));
        Instant fin = T.plus(JOUR.multipliedBy(5));
        UserSubscription a = acces(u, ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(25)), fin);

        for (Instant at : List.of(fin.minus(JOUR.multipliedBy(5)), fin.minus(JOUR.multipliedBy(4)),
                fin.minus(JOUR), fin.minus(Duration.ofHours(12)),
                fin.plus(JOUR), fin.plus(JOUR.multipliedBy(2)))) {
            activite(u, at.minus(Duration.ofHours(1)));
            passage(at);
        }

        assertThat(recus(u)).containsExactly(
                EmailType.PREMIUM_ENDING_7_DAYS, EmailType.PREMIUM_ENDING_2_DAYS, EmailType.PREMIUM_ENDED);
        assertThat(rowsOf(u, EmailType.PREMIUM_ENDED).getFirst().getDeduplicationKey())
                .isEqualTo("PREMIUM_ENDED:" + a.getId());
        EmailMessage ending = mails.sentOfType(EmailType.PREMIUM_ENDING_7_DAYS).stream()
                .filter(m -> m.recipient().equals(u.getEmail())).findFirst().orElseThrow();
        assertThat(ending.variables()).containsEntry("accessLabel", "Votre accès Civique")
                .containsEntry("remainingAccessSentence", "")
                .containsEntry("manageAccessUrl", "http://localhost:3000/profil/abonnement");
        assertThat(String.join(" ", ending.variables().values())).doesNotContain("/paiement").doesNotContain("€");
    }

    @Test
    @DisplayName("Un autre acces prolonge au-dela : ni ENDING ni ENDED pour l'ancien")
    void prolongationSupprimeLesRappels() {
        User u = compte(T.minus(JOUR.multipliedBy(60)));
        Instant fin = T.plus(JOUR.multipliedBy(5));
        acces(u, ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(25)), fin);
        acces(u, ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(4)), fin.plus(JOUR.multipliedBy(30)));

        for (Instant at : List.of(fin.minus(JOUR.multipliedBy(5)), fin.minus(JOUR), fin.plus(JOUR))) {
            activite(u, at.minus(Duration.ofHours(1)));
            passage(at);
        }

        assertThat(recus(u)).doesNotContain(EmailType.PREMIUM_ENDING_7_DAYS, EmailType.PREMIUM_ENDING_2_DAYS,
                EmailType.PREMIUM_ENDED);
    }

    @Test
    @DisplayName("Jour manque : le rappel est rattrape tant que la fenetre le permet")
    void jourManqueRattrape() {
        User u = compte(T.minus(JOUR.multipliedBy(60)));
        Instant fin = T.plus(JOUR.multipliedBy(3));
        acces(u, ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(25)), fin);
        activite(u, T.minus(Duration.ofHours(1)));

        passage(T);

        assertThat(recus(u)).containsExactly(EmailType.PREMIUM_ENDING_7_DAYS);
    }

    @Test
    @DisplayName("Un pass achete il y a moins de 3 jours (et de moins de 14 jours) n'annonce pas deja sa fin (ENDING_7)")
    void passRecentPasDeEnding7() {
        User u = compte(T.minus(JOUR.multipliedBy(60)));
        acces(u, ModuleAccess.CIVIQUE, T.minus(JOUR), T.plus(JOUR.multipliedBy(5)));
        activite(u, T.minus(Duration.ofHours(1)));

        passage(T);

        assertThat(recus(u)).doesNotContain(EmailType.PREMIUM_ENDING_7_DAYS);
    }

    @Test
    @DisplayName("L'Integral se termine mais le Civique continue : « Votre accès TCF », Civique cite")
    void libelleSelonLeModule() {
        User u = compte(T.minus(JOUR.multipliedBy(60)));
        Instant fin = T.plus(JOUR);
        acces(u, ModuleAccess.INTEGRAL, T.minus(JOUR.multipliedBy(25)), fin);
        acces(u, ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(10)), fin.plus(JOUR.multipliedBy(20)));
        activite(u, T.minus(Duration.ofHours(1)));

        passage(T);

        EmailMessage m = mails.sentTo(u.getEmail()).stream()
                .filter(x -> x.type() == EmailType.PREMIUM_ENDING_2_DAYS).findFirst().orElseThrow();
        assertThat(m.variables()).containsEntry("accessLabel", "Votre accès TCF");
        assertThat(m.variables().get("remainingAccessSentence")).startsWith("Votre accès Civique reste actif jusqu'au ");
    }

    @Test
    @DisplayName("Un Integral seul se termine : « Votre pass Intégral »")
    void integralSeul() {
        User u = compte(T.minus(JOUR.multipliedBy(60)));
        acces(u, ModuleAccess.INTEGRAL, T.minus(JOUR.multipliedBy(25)), T.plus(JOUR));
        activite(u, T.minus(Duration.ofHours(1)));

        passage(T);

        EmailMessage m = mails.sentTo(u.getEmail()).getFirst();
        assertThat(m.type()).isEqualTo(EmailType.PREMIUM_ENDING_2_DAYS);
        assertThat(m.variables()).containsEntry("accessLabel", "Votre pass Intégral");
    }

    @Test
    @DisplayName("Abonnement recurrent dormant : exclu des rappels de fin (arbitrage n°5)")
    void recurrentDormantExclu() {
        User u = compte(T.minus(JOUR.multipliedBy(60)));
        UserSubscription s = acces(u, ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(25)), T.plus(JOUR));
        s.setAutoRenew(true);
        subscriptionManager.save(s);
        activite(u, T.minus(Duration.ofHours(1)));

        passage(T);
        passage(T.plus(JOUR.multipliedBy(2)));

        assertThat(recus(u)).doesNotContain(EmailType.PREMIUM_ENDING_2_DAYS, EmailType.PREMIUM_ENDED);
    }

    @Test
    @DisplayName("Un pass rembourse ne « se termine » pas")
    void remboursePasDeEnded() {
        User u = compte(T.minus(JOUR.multipliedBy(60)));
        UserSubscription s = acces(u, ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(25)), T.minus(JOUR));
        s.setStatus(SubscriptionStatus.REFUNDED);
        subscriptionManager.save(s);
        activite(u, T.minus(Duration.ofHours(1)));

        passage(T);

        assertThat(recus(u)).doesNotContain(EmailType.PREMIUM_ENDED);
    }

    // ------------------------------------------------------ PENDING bloques

    @Test
    @DisplayName("Un PENDING de plus d'une heure passe FAILED au debut du passage")
    void pendingBloque() {
        User u = user();
        String key = "TEST_STALE:" + UUID.randomUUID();
        deliveries.insertPending(new com.sejourfr.app.manager.EmailDeliveryManager.NewDelivery(
                u.getId(), EmailType.WELCOME, u.getEmail(), com.sejourfr.app.enums.EmailProvider.SPRING_MAIL,
                key, null, null, T.minus(Duration.ofHours(2))));

        EmailAutomationService.Report report = passage(T);

        assertThat(report.stalePending()).isGreaterThanOrEqualTo(1);
        assertThat(rows(key).getFirst().getStatus()).isEqualTo(EmailDeliveryStatus.FAILED);
        assertThat(rows(key).getFirst().getErrorMessage()).isEqualTo("stale");
    }

    /**
     * Revue du proprietaire : ENDING_7 exige un acces d'au moins 14 jours
     * ({@code minAccessDurationDays}). Un pass 7 jours recoit au plus le rappel
     * d'inactivite, ENDING_2 puis ENDED — jamais ENDING_7.
     */
    @Test
    @DisplayName("Pass 7 jours : jamais ENDING_7 ; ENDING_2 puis ENDED")
    void passSeptJoursJamaisEnding7() {
        User u = compte(T.minus(JOUR.multipliedBy(60)));
        Instant debut = T.minus(JOUR.multipliedBy(4));
        Instant fin = debut.plus(JOUR.multipliedBy(7));
        acces(u, ModuleAccess.CIVIQUE, debut, fin);

        for (int jour = 0; jour <= 6; jour++) {
            Instant at = T.plus(JOUR.multipliedBy(jour));
            activite(u, at.minus(Duration.ofHours(1)));
            passage(at);
        }

        assertThat(recus(u)).doesNotContain(EmailType.PREMIUM_ENDING_7_DAYS)
                .containsSubsequence(EmailType.PREMIUM_ENDING_2_DAYS, EmailType.PREMIUM_ENDED);
        EmailMessage m = mails.sentOfType(EmailType.PREMIUM_ENDING_2_DAYS).stream()
                .filter(x -> x.recipient().equals(u.getEmail())).findFirst().orElseThrow();
        assertThat(m.variables()).containsEntry("accessEndDate", EmailFormats.date(fin));
    }

    @Test
    @DisplayName("Pass de 14 jours : ENDING_7 reste envoye")
    void passQuatorzeJoursEnding7() {
        User u = compte(T.minus(JOUR.multipliedBy(60)));
        acces(u, ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(9)), T.plus(JOUR.multipliedBy(5)));
        activite(u, T.minus(Duration.ofHours(1)));

        passage(T);

        assertThat(recus(u)).containsExactly(EmailType.PREMIUM_ENDING_7_DAYS);
    }
}

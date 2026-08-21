package com.sejourfr.app.service.billing;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Geste commercial V038 envers les acheteurs de l'ancien catalogue Intégral.
 *
 * <p>Une migration de données ne peut pas être testée « en place » : elle s'exécute
 * au démarrage de Flyway, donc avant que le moindre jeu d'essai existe. On lit
 * donc <b>le fichier de migration lui-même</b>, on le coupe sur sa sentinelle
 * {@code @@APPLICATION_DU_GESTE@@} et on rejoue les deux ordres qui appliquent le
 * geste sur des acheteurs fabriqués ici. Le SQL exercé est celui qui tournera en
 * production, au caractère près — recopier la requête dans le test aurait fini
 * par la laisser diverger.
 *
 * <p>La migration a déjà tourné sur cette base : elle n'y a trouvé aucun acheteur
 * historique, la table est donc vide au départ (premier test).
 */
class LegacyPassCompensationIT extends AbstractIntegrationTest {

    private static final String SENTINELLE = "-- @@APPLICATION_DU_GESTE@@";

    @Autowired private JdbcTemplate jdbc;
    @Autowired private TestData testData;
    @Autowired private EntityManager em;

    /**
     * Le geste s'applique en SQL brut : il faut que l'utilisateur soit réellement
     * en base, pas seulement dans le contexte de persistance (sinon la clé
     * étrangère de {@code user_subscriptions} le refuse).
     */
    private User acheteurEnBase(String email) {
        User user = testData.user(email);
        em.flush();
        return user;
    }

    // ------------------------------------------------------------------------

    private void appliquerLeGeste() {
        jdbc.execute(sqlDApplication());
    }

    /** Les ordres d'application, lus dans la migration réelle. */
    private static String sqlDApplication() {
        ClassPathResource resource = new ClassPathResource(
                "db/migration/00_schema/V038__geste_anciens_acheteurs.sql");
        String migration;
        try (var in = resource.getInputStream()) {
            migration = new String(in.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new UncheckedIOException("Migration V038 introuvable", e);
        }
        int coupe = migration.indexOf(SENTINELLE);
        assertTrue(coupe > 0,
                "Sentinelle " + SENTINELLE + " absente de V038 : le test ne peut plus "
                        + "rejouer le SQL réel (cf. commentaire de la migration).");
        return migration.substring(coupe + SENTINELLE.length());
    }

    private UUID planId(String code) {
        return jdbc.queryForObject("SELECT id FROM plans WHERE code = ?", UUID.class, code);
    }

    /** Insère une souscription telle que les webhooks l'écrivent, sans passer par JPA. */
    private UUID souscription(User user, String planCode, String statut,
                              Instant endsAt, int soldeSessions) {
        UUID id = UUID.randomUUID();
        jdbc.update("""
                INSERT INTO user_subscriptions
                    (id, user_id, plan_id, status, starts_at, ends_at, source,
                     original_transaction_id, product_id, auto_renew,
                     realtime_eo_sessions_remaining, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, 'STRIPE', ?, ?, false, ?, now())
                """,
                id, user.getId(), planId(planCode), statut,
                java.sql.Timestamp.from(endsAt.minus(90, ChronoUnit.DAYS)),
                java.sql.Timestamp.from(endsAt),
                "tx_" + id, planCode, soldeSessions);
        return id;
    }

    private Map<String, Object> compensationDe(User user) {
        var lignes = jdbc.queryForList(
                "SELECT * FROM legacy_pass_compensations WHERE user_id = ?", user.getId());
        assertEquals(1, lignes.size(), "une seule compensation par compte");
        return lignes.get(0);
    }

    private Map<String, Object> souscriptionDe(UUID id) {
        return jdbc.queryForMap("SELECT * FROM user_subscriptions WHERE id = ?", id);
    }

    private static Instant instant(Object colonne) {
        return ((java.sql.Timestamp) colonne).toInstant();
    }

    // ------------------------------------------------------------------------

    @Test
    void sansAcheteurHistoriqueLaMigrationNAccordeRien() {
        Integer lignes = jdbc.queryForObject(
                "SELECT count(*) FROM legacy_pass_compensations", Integer.class);
        assertEquals(0, lignes,
                "la migration ne doit inventer aucune compensation sur une base sans acheteur");
    }

    @Test
    void unPassSprintExpireEstRouvertQuatorzeJoursAvecCinqSimulations() {
        User acheteur = acheteurEnBase("sprint.expire@sejourfr.fr");
        Instant finPassee = Instant.now().minus(60, ChronoUnit.DAYS);
        UUID sub = souscription(acheteur, "INTEGRAL_PASS_SPRINT", "ACTIVE", finPassee, 0);

        appliquerLeGeste();

        var geste = compensationDe(acheteur);
        assertEquals("INTEGRAL_PASS_SPRINT", geste.get("plan_code"));
        assertEquals(14, geste.get("days_granted"));
        assertEquals(0, geste.get("sessions_before"));
        assertEquals(5, geste.get("sessions_after"));

        var ligne = souscriptionDe(sub);
        assertEquals(5, ligne.get("realtime_eo_sessions_remaining"));
        // Le compte à rebours repart de MAINTENANT, pas de la fin passée : sinon
        // « prolonger » un pass mort depuis deux mois n'ouvrirait aucun accès.
        Instant nouvelleFin = instant(ligne.get("ends_at"));
        assertTrue(nouvelleFin.isAfter(Instant.now().plus(13, ChronoUnit.DAYS)));
        assertTrue(nouvelleFin.isBefore(Instant.now().plus(15, ChronoUnit.DAYS)));
    }

    @Test
    void unStatutExpireRedevientActifSinonLaProlongationNOuvriraitRien() {
        User acheteur = acheteurEnBase("sprint.statut@sejourfr.fr");
        UUID sub = souscription(acheteur, "INTEGRAL_PASS_SPRINT", "EXPIRED",
                Instant.now().minus(30, ChronoUnit.DAYS), 0);

        appliquerLeGeste();

        assertEquals("ACTIVE", souscriptionDe(sub).get("status"),
                "isCovering rejette EXPIRED quelle que soit la date de fin");
    }

    @Test
    void onNeRetireJamaisDeSimulationsDejaCreditees() {
        User acheteur = acheteurEnBase("sprint.riche@sejourfr.fr");
        Instant finFuture = Instant.now().plus(10, ChronoUnit.DAYS);
        UUID sub = souscription(acheteur, "INTEGRAL_PASS_SPRINT", "ACTIVE", finFuture, 25);

        appliquerLeGeste();

        var ligne = souscriptionDe(sub);
        assertEquals(25, ligne.get("realtime_eo_sessions_remaining"),
                "le barème est un plancher : 25 > 5, on ne redescend pas à 5");
        // Pass encore vivant : les 14 jours s'ajoutent à sa fin, pas à aujourd'hui.
        Instant nouvelleFin = instant(ligne.get("ends_at"));
        assertTrue(nouvelleFin.isAfter(finFuture.plus(13, ChronoUnit.DAYS)));
    }

    @Test
    void unPassTroisMoisRecoitVingtEtUnJoursEtQuinzeSimulations() {
        User acheteur = acheteurEnBase("troismois@sejourfr.fr");
        UUID sub = souscription(acheteur, "INTEGRAL_PASS_3M", "ACTIVE",
                Instant.now().minus(5, ChronoUnit.DAYS), 0);

        appliquerLeGeste();

        var geste = compensationDe(acheteur);
        assertEquals(21, geste.get("days_granted"));
        assertEquals(15, geste.get("sessions_after"));
        assertEquals(15, souscriptionDe(sub).get("realtime_eo_sessions_remaining"));
    }

    @Test
    void unAchatRembourseNOuvreAucunDroit() {
        User rembourse = acheteurEnBase("rembourse@sejourfr.fr");
        souscription(rembourse, "INTEGRAL_PASS_SPRINT", "REFUNDED",
                Instant.now().minus(40, ChronoUnit.DAYS), 0);

        appliquerLeGeste();

        Integer lignes = jdbc.queryForObject(
                "SELECT count(*) FROM legacy_pass_compensations WHERE user_id = ?",
                Integer.class, rembourse.getId());
        assertEquals(0, lignes, "on ne fait pas de cadeau sur un achat remboursé");
    }

    @Test
    void unCompteSupprimeEstIgnore() {
        User supprime = acheteurEnBase("supprime@sejourfr.fr");
        souscription(supprime, "INTEGRAL_PASS_SPRINT", "ACTIVE",
                Instant.now().minus(40, ChronoUnit.DAYS), 0);
        jdbc.update("UPDATE users SET deleted_at = now() WHERE id = ?", supprime.getId());

        appliquerLeGeste();

        Integer lignes = jdbc.queryForObject(
                "SELECT count(*) FROM legacy_pass_compensations WHERE user_id = ?",
                Integer.class, supprime.getId());
        assertEquals(0, lignes);
    }

    @Test
    void deuxPassEligiblesNeDonnentQuUnSeulGesteAuMeilleurBareme() {
        User acheteur = acheteurEnBase("deuxpass@sejourfr.fr");
        souscription(acheteur, "INTEGRAL_PASS_SPRINT", "ACTIVE",
                Instant.now().minus(90, ChronoUnit.DAYS), 0);
        souscription(acheteur, "INTEGRAL_PASS_3M", "ACTIVE",
                Instant.now().minus(20, ChronoUnit.DAYS), 0);

        appliquerLeGeste();

        var geste = compensationDe(acheteur);
        assertEquals("INTEGRAL_PASS_3M", geste.get("plan_code"), "le meilleur pass acheté fait foi");
        assertEquals(21, geste.get("days_granted"));
    }

    @Test
    void leGesteEstPoseSurLaSouscriptionQueLApplicationLira() {
        // Vieux sprint + pass récent du nouveau catalogue : le solde lu par
        // RealtimeQuotaService vient de currentSubscription(), donc de la
        // souscription au ends_at le plus tardif. Créditer le vieux sprint serait
        // invisible dans l'app.
        User acheteur = acheteurEnBase("mixte@sejourfr.fr");
        UUID vieuxSprint = souscription(acheteur, "INTEGRAL_PASS_SPRINT", "ACTIVE",
                Instant.now().minus(120, ChronoUnit.DAYS), 0);
        UUID passRecent = souscription(acheteur, "INTEGRAL_PASS_2M", "ACTIVE",
                Instant.now().plus(30, ChronoUnit.DAYS), 3);

        appliquerLeGeste();

        var geste = compensationDe(acheteur);
        assertEquals(passRecent, geste.get("subscription_id"),
                "le geste doit atterrir sur la souscription couvrante, pas sur le pass mort");
        assertEquals(0, jdbc.queryForObject(
                "SELECT realtime_eo_sessions_remaining FROM user_subscriptions WHERE id = ?",
                Integer.class, vieuxSprint));
        assertEquals(5, souscriptionDe(passRecent).get("realtime_eo_sessions_remaining"));
    }

    @Test
    void lEnvoiDuMailNEstPasEncoreMarque() {
        User acheteur = acheteurEnBase("amailer@sejourfr.fr");
        souscription(acheteur, "INTEGRAL_PASS_SPRINT", "ACTIVE",
                Instant.now().minus(10, ChronoUnit.DAYS), 0);

        appliquerLeGeste();

        var geste = compensationDe(acheteur);
        assertNull(geste.get("mailed_at"), "mailed_at est posé par le mailing admin, pas par la migration");
        assertNotNull(geste.get("granted_at"));
    }
}

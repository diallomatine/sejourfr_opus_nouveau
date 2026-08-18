package com.sejourfr.app.service;

import com.sejourfr.app.dto.AudienceFunnelResponse;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.FunnelEvent;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.jdbc.core.JdbcTemplate;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Vrai calcul de funnel, vraies requêtes agrégées, vraies migrations.
 *
 * <p>Assertions <b>tolérantes au seed</b> : la base porte déjà des comptes, et
 * ceux-ci tombent dans la provenance « inconnu ». On raisonne donc sur les
 * lignes des provenances que le test a lui-même créées, ou en delta — jamais
 * sur un total absolu.
 */
class AudienceFunnelServiceIT extends AbstractIntegrationTest {

    private static final ZoneId PARIS = ZoneId.of("Europe/Paris");

    @Autowired
    private AudienceFunnelService service;
    @Autowired
    private TestData testData;
    @Autowired
    private JdbcTemplate jdbcTemplate;
    @PersistenceContext
    private EntityManager entityManager;

    private static Optional<AudienceFunnelResponse.SourceFunnel> source(
            AudienceFunnelResponse funnel, String name) {
        return funnel.bySource().stream().filter(s -> s.source().equals(name)).findFirst();
    }

    private static Optional<AudienceFunnelResponse.PlatformFunnel> platform(
            AudienceFunnelResponse funnel, String name) {
        return funnel.byPlatform().stream().filter(p -> p.platform().equals(name)).findFirst();
    }

    /**
     * Le parcours complet d'un candidat venu de TikTok : il s'inscrit, fait son
     * diagnostic, voit l'écran Premium, clique, part payer, paie.
     */
    @Test
    void leParcoursCompletDUnCandidatRemonteSurLesSeptEtapes() {
        User converti = testData.userFrom("tiktok", ClientPlatform.WEB);
        testData.diagnosticSession(converti, DiagnosticSessionStatus.COMPLETED);
        testData.funnelEvent(converti, FunnelEvent.PAYWALL_VIEWED);
        testData.funnelEvent(converti, FunnelEvent.SUBSCRIBE_CLICKED);
        testData.funnelEvent(converti, FunnelEvent.CHECKOUT_STARTED);
        Plan plan = testData.plan();
        testData.userSubscription(converti, plan);

        AudienceFunnelResponse funnel = service.funnel(30);

        AudienceFunnelResponse.SourceFunnel tiktok = source(funnel, "tiktok").orElseThrow();
        assertThat(tiktok.signups()).isEqualTo(1);
        assertThat(tiktok.diagnosticsStarted()).isEqualTo(1);
        assertThat(tiktok.diagnosticsCompleted()).isEqualTo(1);
        assertThat(tiktok.paywallViewed()).isEqualTo(1);
        assertThat(tiktok.subscribeClicked()).isEqualTo(1);
        assertThat(tiktok.checkoutStarted()).isEqualTo(1);
        assertThat(tiktok.purchases()).isEqualTo(1);
    }

    /**
     * Le funnel se rétrécit : commencer un diagnostic n'est pas le terminer, et
     * voir l'écran Premium n'est pas payer.
     */
    @Test
    void leFunnelSeRetrecitEtapeApresEtape() {
        User complet = testData.userFrom("instagram", ClientPlatform.MOBILE);
        testData.diagnosticSession(complet, DiagnosticSessionStatus.COMPLETED);
        testData.funnelEvent(complet, FunnelEvent.PAYWALL_VIEWED, ClientPlatform.MOBILE, "instagram");

        User enCours = testData.userFrom("instagram", ClientPlatform.MOBILE);
        testData.diagnosticSession(enCours, DiagnosticSessionStatus.IN_PROGRESS);

        testData.userFrom("instagram", ClientPlatform.MOBILE); // inscrit, rien de plus

        AudienceFunnelResponse.SourceFunnel insta =
                source(service.funnel(30), "instagram").orElseThrow();

        assertThat(insta.signups()).isEqualTo(3);
        assertThat(insta.diagnosticsStarted()).isEqualTo(2);
        assertThat(insta.diagnosticsCompleted()).isEqualTo(1);
        assertThat(insta.paywallViewed()).isEqualTo(1);
        assertThat(insta.purchases()).isZero();
    }

    /** Un compte compte UNE fois par étape, quel que soit le nombre de lignes. */
    @Test
    void unCompteNeCompteQuUneFoisMemeAvecPlusieursSouscriptions() {
        User user = testData.userFrom("whatsapp", ClientPlatform.WEB);
        testData.userSubscription(user, testData.plan());
        testData.userSubscription(user, testData.plan());

        assertThat(source(service.funnel(30), "whatsapp").orElseThrow().purchases())
                .isEqualTo(1);
    }

    /** Un compte supprimé sort de la cohorte : on ne compte pas des fantômes. */
    @Test
    void unCompteSupprimeSortDeLaCohorte() {
        User parti = testData.userFrom("youtube", ClientPlatform.WEB);
        testData.diagnosticSession(parti, DiagnosticSessionStatus.COMPLETED);
        assertThat(source(service.funnel(30), "youtube").orElseThrow().signups()).isEqualTo(1);

        parti.anonymize();
        testData.saveUser(parti);

        assertThat(source(service.funnel(30), "youtube")).isEmpty();
    }

    @Test
    void laVentilationParPlateformeCouvreLaMemeCohorte() {
        testData.userFrom("tiktok", ClientPlatform.MOBILE);
        testData.userFrom("instagram", ClientPlatform.MOBILE);

        AudienceFunnelResponse funnel = service.funnel(30);

        assertThat(platform(funnel, "MOBILE").orElseThrow().signups()).isEqualTo(2);
        assertThat(source(funnel, "tiktok").orElseThrow().signups()).isEqualTo(1);
        assertThat(source(funnel, "instagram").orElseThrow().signups()).isEqualTo(1);
    }

    /** Les comptes antérieurs à la mesure existent : ils sortent en « inconnu ». */
    @Test
    void unCompteSansProvenanceSortEnInconnu() {
        testData.user();

        assertThat(source(service.funnel(30), "inconnu"))
                .hasValueSatisfying(row -> assertThat(row.signups()).isPositive());
        assertThat(platform(service.funnel(30), "UNKNOWN"))
                .hasValueSatisfying(row -> assertThat(row.signups()).isPositive());
    }

    @Test
    void laSerieJournaliereCouvreTouteLaFenetreEtPorteLeJourCourant() {
        testData.userFrom("facebook", ClientPlatform.WEB);

        AudienceFunnelResponse funnel = service.funnel(7);

        assertThat(funnel.daily()).hasSize(7);
        assertThat(funnel.daily().getLast().day())
                .isEqualTo(LocalDate.now(PARIS).toString());
        assertThat(funnel.daily().getLast().signups()).isPositive();
    }

    /**
     * Le compteur d'intégrité répond à « un compte ne fait-il qu'un seul
     * diagnostic ? ». Mesuré en delta : la base porte déjà des lignes.
     */
    @Test
    void lIntegriteRepereUnCompteAvecDeuxSessionsDeDiagnostic() {
        long avant = service.funnel(30).integrity().accountsWithMultipleDiagnosticSessions();

        User user = testData.userFrom("tiktok", ClientPlatform.WEB);
        testData.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);

        assertThat(service.funnel(30).integrity().accountsWithMultipleDiagnosticSessions())
                .isEqualTo(avant);

        // Seconde session du MEME compte : légitime en base (l'unicité porte sur
        // (user, code, version)), donc c'est bien ce compteur qui doit la voir.
        testData.diagnosticSession(user, DiagnosticSessionStatus.IN_PROGRESS);

        AudienceFunnelResponse.Integrity apres = service.funnel(30).integrity();
        assertThat(apres.accountsWithMultipleDiagnosticSessions()).isEqualTo(avant + 1);
        assertThat(apres.diagnosticSessionsTotal())
                .isGreaterThanOrEqualTo(apres.accountsWithDiagnostic());
    }

    /**
     * Hors fenêtre : un inscrit d'il y a un an ne pollue pas la cohorte du mois.
     * {@code created_at} est {@code updatable=false} côté JPA — c'est voulu, on
     * ne réécrit pas une date d'inscription — donc le test antidate en SQL.
     */
    @Test
    void unInscritHorsFenetreNEntrePasDansLaCohorte() {
        User ancien = testData.userFrom("tiktok", ClientPlatform.WEB);
        // save() ne flushe pas : sans ce flush, l'UPDATE natif passerait AVANT
        // l'INSERT et n'atteindrait aucune ligne.
        entityManager.flush();
        jdbcTemplate.update(
                "UPDATE users SET created_at = now() - interval '400 days' WHERE id = ?",
                ancien.getId());

        assertThat(source(service.funnel(30), "tiktok")).isEmpty();
    }
}

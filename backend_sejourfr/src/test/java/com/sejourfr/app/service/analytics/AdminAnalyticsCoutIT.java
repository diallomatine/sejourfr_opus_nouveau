package com.sejourfr.app.service.analytics;

import com.sejourfr.app.enums.AnalyticsDeviceType;
import com.sejourfr.app.enums.AnalyticsEvent;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.manager.AnalyticsReadManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import com.sejourfr.app.util.FenetreMesure;
import jakarta.persistence.EntityManager;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZonedDateTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>Le cout de l'ecran Analytics est CONSTANT</b> — c'est un critere
 * d'acceptation, pas un bonus (brief §66, §99, §109).
 *
 * <p>On compte les statements reellement prepares par Hibernate et on exige une
 * <b>egalite</b>, patron {@code SkillMasteryResolverIT}. Une inegalite
 * ({@code isLessThan}) laisserait passer un N+1 tant qu'il reste sous le
 * plafond, et c'est precisement ce qu'on veut attraper : le jour ou une
 * ventilation part chercher ses lignes une par une, ce test rougit.
 *
 * <p>Le test appelle {@link AdminAnalyticsService#compute} et non la methode
 * publique : compter des requetes derriere un cache de 60 s ne prouverait rien.
 */
class AdminAnalyticsCoutIT extends AbstractIntegrationTest {

    /**
     * Le budget, requete par requete :
     * <ol>
     *   <li>visiteurs et gestes de la periode (toutes ventilations d'un coup) ;</li>
     *   <li>cohorte de comptes de la periode (idem) ;</li>
     *   <li>visiteurs et gestes de la periode <i>precedente</i> ;</li>
     *   <li>cohorte de comptes de la periode precedente ;</li>
     *   <li>comptes actifs a date (hors periode) ;</li>
     *   <li>CTA Premium et attribution du paiement ;</li>
     *   <li>contextes d'inscription ;</li>
     *   <li>parcours reduits aux jalons ;</li>
     *   <li>progression par format de diagnostic ;</li>
     *   <li>reperes poses sur la courbe.</li>
     * </ol>
     */
    private static final int BUDGET_REQUETES = 10;

    private static final LocalDate DEBUT = LocalDate.of(2025, 5, 5);
    private static final LocalDate FIN = LocalDate.of(2025, 5, 11);
    private static final FenetreMesure FENETRE = new FenetreMesure(DEBUT, FIN);

    @Autowired private TestData data;
    @Autowired private AdminAnalyticsService service;
    @Autowired private EntityManager entityManager;

    @Test
    @DisplayName("Deux provenances ou vingt : le même nombre de requêtes")
    void leCoutNeDependPasDuNombreDeDimensions() {
        int avecDeux = compterRequetes(2);
        entityManager.clear();
        int avecVingt = compterRequetes(20);

        assertThat(avecDeux).isEqualTo(BUDGET_REQUETES);
        assertThat(avecVingt).isEqualTo(BUDGET_REQUETES);
    }

    /**
     * Un filtre ne doit pas non plus faire varier le cout : il se traduit par une
     * clause, pas par une requete de plus.
     */
    @Test
    @DisplayName("Un filtre ne coûte aucune requête supplémentaire")
    void unFiltreNeCoutePasUneRequete() {
        peupler(6);
        entityManager.flush();
        entityManager.clear();

        Statistics statistiques = statistiques();
        service.compute(FENETRE, new AnalyticsReadManager.Filtres("tiktok", "FR", null, "WEB"));

        assertThat(statistiques.getPrepareStatementCount()).isEqualTo(BUDGET_REQUETES);
    }

    // ------------------------------------------------------------------------

    private int compterRequetes(int provenances) {
        peupler(provenances);
        entityManager.flush();
        entityManager.clear();

        Statistics statistiques = statistiques();
        service.compute(FENETRE, AnalyticsReadManager.Filtres.AUCUN);
        return (int) statistiques.getPrepareStatementCount();
    }

    /**
     * Peuple la fenetre avec {@code n} provenances distinctes, chacune portant
     * son visiteur, ses gestes, sa campagne et son compte. C'est exactement le
     * genre de donnee qui fait exploser une lecture ecrite en boucle.
     */
    private void peupler(int n) {
        List<String> reseaux = List.of("tiktok", "instagram", "facebook", "youtube",
                "whatsapp", "direct", "autre");
        for (int i = 0; i < n; i++) {
            String reseau = reseaux.get(i % reseaux.size());
            Instant quand = paris(2025, 5, 6 + (i % 5), 9, i % 60);

            UUID visiteur = data.analyticsVisitorCampagne(reseau, "campagne-" + i, "video-" + i,
                    quand);
            data.analyticsEvent(visiteur, AnalyticsEvent.LANDING_VIEWED, quand);
            data.analyticsEvent(visiteur, AnalyticsEvent.DIAGNOSTIC_STARTED, quand,
                    "{\"diagnosticType\":\"" + (i % 2 == 0 ? "RAPID" : "COMPLETE") + "\"}");
            data.analyticsEvent(visiteur, AnalyticsEvent.PREMIUM_CTA_CLICKED, quand,
                    "{\"ctaLocation\":\"DIAGNOSTIC_REPORT\"}");
            data.analyticsEvent(visiteur, AnalyticsEvent.SIGNUP_STARTED, quand,
                    "{\"registrationContext\":\"AFTER_DIAGNOSTIC\"}");

            var compte = data.userCreatedAt(reseau,
                    i % 2 == 0 ? ClientPlatform.WEB : ClientPlatform.MOBILE, quand);
            data.analyticsIdentity(visiteur, compte);
            if (i % 3 == 0) {
                data.paidSubscription(compte, data.plan(), 1999, quand.plusSeconds(3600));
            }
        }
        // Un visiteur sans campagne ni compte : la dimension « campagne » ne doit
        // pas le faire apparaitre, et son absence ne coute rien de plus.
        UUID isole = data.analyticsVisitor("tiktok", null,
                AnalyticsDeviceType.UNKNOWN, ClientPlatform.UNKNOWN, paris(2025, 5, 8, 12, 0));
        data.analyticsEvent(isole, AnalyticsEvent.LANDING_VIEWED, paris(2025, 5, 8, 12, 0));
    }

    private Statistics statistiques() {
        Statistics statistiques = entityManager.getEntityManagerFactory()
                .unwrap(SessionFactory.class).getStatistics();
        statistiques.setStatisticsEnabled(true);
        statistiques.clear();
        return statistiques;
    }

    private static Instant paris(int annee, int mois, int jour, int heure, int minute) {
        return ZonedDateTime.of(LocalDateTime.of(annee, mois, jour, heure, minute),
                FenetreMesure.PARIS).toInstant();
    }
}

package com.sejourfr.app.service.analytics;

import com.sejourfr.app.dto.AdminAnalyticsResponse;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AnalyticsDeviceType;
import com.sejourfr.app.enums.AnalyticsEvent;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.manager.AnalyticsReadManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import com.sejourfr.app.util.FenetreMesure;
import com.sejourfr.app.util.TrafficSource;
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
 * L'ecran Analytics contre la <b>vraie base</b>.
 *
 * <p>Ce qui est verrouille ici, ce sont les regles qu'aucun test unitaire ne peut
 * tenir parce qu'elles vivent dans le SQL : la fenetre Europe/Paris et ses
 * bornes incluses, la cohorte d'inscription, le fait qu'un renouvellement
 * n'ajoute jamais un abonne, le revenu qui n'invente jamais un montant, et la
 * serie qui reste continue un jour creux.
 *
 * <p><b>Fenetre volontairement dans le passe</b> (mars 2025) : les comptes seedes
 * par Flyway sont crees au moment de la migration, donc aujourd'hui. Sans ce
 * decalage, chaque assertion devrait raisonner en delta — et un total exact sur
 * une table seedee est exactement ce que le depot interdit.
 */
class AdminAnalyticsServiceIT extends AbstractIntegrationTest {

    private static final LocalDate DEBUT = LocalDate.of(2025, 3, 10);
    private static final LocalDate FIN = LocalDate.of(2025, 3, 16);
    private static final FenetreMesure FENETRE = new FenetreMesure(DEBUT, FIN);

    @Autowired private TestData data;
    @Autowired private AdminAnalyticsService service;

    /**
     * Les bornes sont <b>incluses</b> et se lisent a Paris, pas en UTC. Un geste a
     * 00 h 30 le premier jour et un autre a 23 h 30 le dernier sont dans la
     * fenetre ; la veille a 23 h 30, non — alors que ce dernier tombe le
     * <i>meme</i> jour UTC que le premier.
     */
    @Test
    @DisplayName("La fenêtre se lit à Paris, bornes incluses — pas en UTC")
    void fenetreParisBornesIncluses() {
        UUID dedans = data.analyticsVisitor("tiktok", "FR",
                AnalyticsDeviceType.MOBILE_WEB, ClientPlatform.WEB, paris(2025, 3, 10, 0, 30));
        data.analyticsEvent(dedans, AnalyticsEvent.LANDING_VIEWED, paris(2025, 3, 10, 0, 30));

        UUID dernierJour = data.analyticsVisitor("tiktok", "FR",
                AnalyticsDeviceType.MOBILE_WEB, ClientPlatform.WEB, paris(2025, 3, 16, 23, 30));
        data.analyticsEvent(dernierJour, AnalyticsEvent.LANDING_VIEWED, paris(2025, 3, 16, 23, 30));

        UUID veille = data.analyticsVisitor("tiktok", "FR",
                AnalyticsDeviceType.MOBILE_WEB, ClientPlatform.WEB, paris(2025, 3, 9, 23, 30));
        data.analyticsEvent(veille, AnalyticsEvent.LANDING_VIEWED, paris(2025, 3, 9, 23, 30));

        AdminAnalyticsResponse reponse = service.compute(FENETRE, AnalyticsReadManager.Filtres.AUCUN);

        assertThat(reponse.total().v()).isEqualTo(2);
        assertThat(reponse.from()).isEqualTo("2025-03-10");
        assertThat(reponse.to()).isEqualTo("2025-03-16");
    }

    /**
     * La periode de comparaison est de <b>meme duree</b> et <b>collee</b> a
     * {@code from} : elle finit la veille. Les bornes appliquees sont rendues,
     * pour que l'ecran affiche la periode d'apres le serveur.
     */
    @Test
    @DisplayName("La période précédente est de même durée et finit la veille")
    void periodePrecedenteCollee() {
        AdminAnalyticsResponse reponse = service.compute(FENETRE, AnalyticsReadManager.Filtres.AUCUN);

        assertThat(reponse.prevTo()).isEqualTo("2025-03-09");
        assertThat(reponse.prevFrom()).isEqualTo("2025-03-03");
        assertThat(reponse.period().days()).isEqualTo(7);
        assertThat(reponse.period().grain()).isEqualTo("DAY");
    }

    /**
     * Un trou dans une courbe se lit comme une panne de mesure, pas comme une
     * journee sans visite. Sur {@code from == to}, la serie horaire compte
     * <b>24 points</b>, tous a zero.
     */
    @Test
    @DisplayName("Une journée creuse rend 24 points à zéro, jamais une série vide")
    void serieContinueSurJourneeCreuse() {
        FenetreMesure uneJournee = new FenetreMesure(DEBUT, DEBUT);

        AdminAnalyticsResponse reponse =
                service.compute(uneJournee, AnalyticsReadManager.Filtres.AUCUN);

        assertThat(reponse.period().grain()).isEqualTo("HOUR");
        assertThat(reponse.series()).hasSize(24);
        assertThat(reponse.series()).allMatch(AdminAnalyticsResponse.SeriesPoint::empty);
        assertThat(reponse.prevSeries()).hasSize(24);
    }

    /**
     * 🛑 La population est celle des comptes crees dans la fenetre, et chaque
     * etape se mesure sur ces memes comptes quelle que soit sa date : c'est ce
     * qui rend « 1 payant sur 2 inscrits TikTok » vrai.
     */
    @Test
    @DisplayName("La cohorte d'inscription tient la ventilation par provenance")
    void cohorteParProvenance() {
        Plan plan = data.plan();
        User tiktokPayant = data.userCreatedAt("tiktok", ClientPlatform.WEB, paris(2025, 3, 11, 10, 0));
        data.userCreatedAt("tiktok", ClientPlatform.WEB, paris(2025, 3, 12, 10, 0));
        data.userCreatedAt("instagram", ClientPlatform.MOBILE, paris(2025, 3, 13, 10, 0));
        // Hors fenetre : il ne doit apparaitre nulle part.
        data.userCreatedAt("tiktok", ClientPlatform.WEB, paris(2025, 3, 1, 10, 0));

        // Le paiement a lieu APRES la fenetre : la cohorte le compte quand meme.
        data.paidSubscription(tiktokPayant, plan, 1999, paris(2025, 4, 2, 9, 0));

        AdminAnalyticsResponse reponse = service.compute(FENETRE, AnalyticsReadManager.Filtres.AUCUN);

        assertThat(reponse.total().sig()).isEqualTo(3);
        assertThat(reponse.total().pay()).isEqualTo(1);

        AdminAnalyticsResponse.SourceRow tiktok = ligneSource(reponse, "tiktok");
        assertThat(tiktok.m().sig()).isEqualTo(2);
        assertThat(tiktok.m().pay()).isEqualTo(1);
        assertThat(ligneSource(reponse, "instagram").m().sig()).isEqualTo(1);

        // La somme des lignes egale le pied de table.
        long sommeLignes = reponse.sources().stream().mapToLong(r -> r.m().sig()).sum();
        assertThat(sommeLignes).isEqualTo(reponse.total().sig());
    }

    /**
     * 🛑 Un payant est un <b>compte</b>, jamais une souscription : un
     * renouvellement n'ajoute pas un nouvel abonne. Le revenu, lui, additionne
     * bien les deux encaissements.
     */
    @Test
    @DisplayName("Un renouvellement n'ajoute pas un payant, mais son revenu compte")
    void renouvellementNEstPasUnNouvelAbonne() {
        Plan plan = data.plan();
        User payant = data.userCreatedAt("tiktok", ClientPlatform.WEB, paris(2025, 3, 11, 10, 0));
        data.paidSubscription(payant, plan, 1999, paris(2025, 3, 12, 9, 0));
        data.paidSubscription(payant, plan, 1999, paris(2025, 4, 12, 9, 0));

        AdminAnalyticsResponse reponse = service.compute(FENETRE, AnalyticsReadManager.Filtres.AUCUN);

        assertThat(reponse.total().pay()).isEqualTo(1);
        assertThat(reponse.total().revEurCents()).isEqualTo(3998);
    }

    /**
     * 🛑 Le revenu est la <b>somme reelle</b> des montants encaisses. La maquette
     * calcule {@code pay × 14,99} — on ne le reproduit pas. Et un montant
     * inconnu ne vaut pas zero : il n'entre simplement pas dans la somme, alors
     * que le compte, lui, est bien un payant.
     */
    @Test
    @DisplayName("Un montant inconnu ne compte pas — il ne vaut pas zéro")
    void montantInconnuNeVautPasZero() {
        Plan plan = data.plan();
        User avecMontant = data.userCreatedAt("tiktok", ClientPlatform.WEB, paris(2025, 3, 11, 9, 0));
        User sansMontant = data.userCreatedAt("tiktok", ClientPlatform.WEB, paris(2025, 3, 11, 9, 30));
        data.paidSubscription(avecMontant, plan, 2999, paris(2025, 3, 12, 9, 0));
        data.paidSubscription(sansMontant, plan, null, paris(2025, 3, 12, 9, 0));

        AdminAnalyticsResponse reponse = service.compute(FENETRE, AnalyticsReadManager.Filtres.AUCUN);

        assertThat(reponse.total().pay()).isEqualTo(2);
        assertThat(reponse.total().revEurCents()).isEqualTo(2999);
    }

    /** Brief §85 : l'exclusion s'applique en SQL, jamais soustraite apres coup. */
    @Test
    @DisplayName("Les comptes de test sont exclus, en SQL")
    void comptesDeTestExclus() {
        data.userCreatedAt("admin@sejourfr.fr", "tiktok", ClientPlatform.WEB,
                paris(2025, 3, 11, 10, 0));
        data.userCreatedAt("tiktok", ClientPlatform.WEB, paris(2025, 3, 12, 10, 0));

        AdminAnalyticsResponse reponse = service.compute(FENETRE, AnalyticsReadManager.Filtres.AUCUN);

        assertThat(reponse.total().sig()).isEqualTo(1);
    }

    /**
     * 🛑 {@code direct} est une provenance observee, {@code inconnu} une absence
     * d'observation. Les fondre gonflerait le direct de tout l'historique
     * anterieur a la mesure.
     */
    @Test
    @DisplayName("« direct » et « inconnu » restent deux lignes distinctes")
    void directNEstPasInconnu() {
        data.userCreatedAt(TrafficSource.DIRECT, ClientPlatform.WEB, paris(2025, 3, 11, 10, 0));
        data.userCreatedAt(null, ClientPlatform.WEB, paris(2025, 3, 12, 10, 0));

        AdminAnalyticsResponse reponse = service.compute(FENETRE, AnalyticsReadManager.Filtres.AUCUN);

        assertThat(ligneSource(reponse, TrafficSource.DIRECT).m().sig()).isEqualTo(1);
        assertThat(ligneSource(reponse, TrafficSource.UNKNOWN).m().sig()).isEqualTo(1);
    }

    /**
     * 🛑 Un maillon dont aucun evenement n'existe <b>n'est pas servi</b> : un zero
     * se lirait « tout le monde abandonne ici », alors qu'on ne mesure pas encore
     * cette etape. C'est le cas de CO et CE tant que les fronts n'emettent que
     * leurs {@code _STARTED}.
     */
    @Test
    @DisplayName("Un maillon jamais mesuré est absent de la chaîne, jamais servi à zéro")
    void maillonJamaisMesureEstAbsent() {
        UUID visiteur = data.analyticsVisitor("tiktok", "FR",
                AnalyticsDeviceType.MOBILE_WEB, ClientPlatform.WEB, paris(2025, 3, 11, 9, 0));
        data.analyticsEvent(visiteur, AnalyticsEvent.DIAGNOSTIC_STARTED,
                paris(2025, 3, 11, 9, 0), "{\"diagnosticType\":\"COMPLETE\"}");
        data.analyticsEvent(visiteur, AnalyticsEvent.DIAGNOSTIC_EE_COMPLETED,
                paris(2025, 3, 11, 9, 10), "{\"diagnosticType\":\"COMPLETE\"}");

        AdminAnalyticsResponse reponse = service.compute(FENETRE, AnalyticsReadManager.Filtres.AUCUN);

        AdminAnalyticsResponse.DiagTypeRow complet = ligneFormat(reponse, "COMPLETE");
        assertThat(complet.start()).isEqualTo(1);
        assertThat(complet.chain()).extracting(AdminAnalyticsResponse.ChainLink::k)
                .containsExactly("start", "ee2", "eo2", "co2", "ce2", "rep");
        assertThat(complet.steps()).isEqualTo(6);
        // 🛑 Ce qui n'a jamais ete mesure vaut null, JAMAIS zero : un zero se
        // lirait « tout le monde abandonne ici ».
        assertThat(complet.chain()).filteredOn(l -> l.k().equals("ee2"))
                .singleElement()
                .satisfies(l -> assertThat(l.value()).isEqualTo(1L));
        assertThat(complet.chain()).filteredOn(l -> List.of("eo2", "co2", "ce2", "rep")
                        .contains(l.k()))
                .allSatisfy(l -> {
                    assertThat(l.value()).isNull();
                    assertThat(l.conv()).isNull();
                });

        // Aucun visiteur n'a choisi le format rapide : chaine VIDE, jamais une
        // suite de zeros qui se lirait comme un abandon general.
        AdminAnalyticsResponse.DiagTypeRow rapide = ligneFormat(reponse, "RAPID");
        assertThat(rapide.start()).isZero();
        assertThat(rapide.chain()).isEmpty();
    }

    /**
     * Sous le seuil d'honnetete, aucune etape n'est designee comme « celle qui
     * fuit » — mais les chiffres restent tous servis.
     */
    @Test
    @DisplayName("Sur un petit volume, aucune étape n'est désignée comme la pire")
    void aucunePireEtapeSousLeSeuil() {
        UUID visiteur = data.analyticsVisitor("tiktok", "FR",
                AnalyticsDeviceType.MOBILE_WEB, ClientPlatform.WEB, paris(2025, 3, 11, 9, 0));
        data.analyticsEvent(visiteur, AnalyticsEvent.DIAGNOSTIC_STARTED,
                paris(2025, 3, 11, 9, 0), "{\"diagnosticType\":\"RAPID\"}");

        AdminAnalyticsResponse reponse = service.compute(FENETRE, AnalyticsReadManager.Filtres.AUCUN);

        assertThat(reponse.abandon()).isNotEmpty();
        assertThat(reponse.abandon()).noneMatch(AdminAnalyticsResponse.AbandonRow::worst);
        // Le denominateur est une CLE de metrique : il se lit sur le vecteur,
        // qui fait foi, plutot que d'etre publie une seconde fois.
        assertThat(reponse.abandon().get(0).base()).isEqualTo("start");
        assertThat(reponse.total().start()).isEqualTo(1);
    }

    /**
     * L'entonnoir se lit sur le meme vecteur que les KPI : une marche ne peut pas
     * contredire le chiffre qui la resume. Et la premiere marche n'a ni
     * conversion ni perte — il n'y a rien avant elle.
     */
    @Test
    @DisplayName("La première marche de l'entonnoir n'a ni conversion ni perte")
    void premiereMarcheSansConversion() {
        AdminAnalyticsResponse reponse = service.compute(FENETRE, AnalyticsReadManager.Filtres.AUCUN);

        AdminAnalyticsResponse.FunnelStep premiere = reponse.funnel().get(0);
        assertThat(premiere.k()).isEqualTo("v");
        // Une conversion depuis rien est une INCONNUE ; une perte avant le
        // debut est un FAIT, et elle vaut zero.
        assertThat(premiere.conv()).isNull();
        assertThat(premiere.lost()).isZero();
        assertThat(premiere.lostShare()).isZero();
    }

    /** Le filtre de provenance recalcule tout, y compris la cohorte de comptes. */
    @Test
    @DisplayName("Le filtre par provenance recalcule visiteurs ET comptes")
    void filtreParProvenance() {
        UUID tiktok = data.analyticsVisitor("tiktok", "FR",
                AnalyticsDeviceType.MOBILE_WEB, ClientPlatform.WEB, paris(2025, 3, 11, 9, 0));
        data.analyticsEvent(tiktok, AnalyticsEvent.LANDING_VIEWED, paris(2025, 3, 11, 9, 0));
        UUID instagram = data.analyticsVisitor("instagram", "BE",
                AnalyticsDeviceType.DESKTOP_WEB, ClientPlatform.WEB, paris(2025, 3, 11, 9, 0));
        data.analyticsEvent(instagram, AnalyticsEvent.LANDING_VIEWED, paris(2025, 3, 11, 9, 0));

        data.userCreatedAt("tiktok", ClientPlatform.WEB, paris(2025, 3, 12, 10, 0));
        data.userCreatedAt("instagram", ClientPlatform.WEB, paris(2025, 3, 12, 10, 0));

        AdminAnalyticsResponse reponse = service.compute(
                FENETRE, new AnalyticsReadManager.Filtres("tiktok", null, null, null));

        assertThat(reponse.total().v()).isEqualTo(1);
        assertThat(reponse.total().sig()).isEqualTo(1);
    }

    /**
     * Le contexte d'inscription est ventile en parts <b>a somme conservee</b> :
     * le pied de table vaut toujours 100 %.
     */
    @Test
    @DisplayName("Les parts des contextes d'inscription font toujours 100 %")
    void partsDesContextesFontCent() {
        for (int i = 0; i < 3; i++) {
            UUID visiteur = data.analyticsVisitor("tiktok", "FR",
                    AnalyticsDeviceType.MOBILE_WEB, ClientPlatform.WEB, paris(2025, 3, 11, 9, 0));
            data.analyticsEvent(visiteur, AnalyticsEvent.SIGNUP_STARTED,
                    paris(2025, 3, 11, 9, i),
                    "{\"registrationContext\":\"" + (i == 0 ? "LANDING"
                            : i == 1 ? "AFTER_DIAGNOSTIC" : "PRICING") + "\"}");
        }

        AdminAnalyticsResponse reponse = service.compute(FENETRE, AnalyticsReadManager.Filtres.AUCUN);

        assertThat(reponse.triggers()).hasSize(3);
        assertThat(reponse.triggers().stream()
                .mapToInt(AdminAnalyticsResponse.TriggerRow::share).sum()).isEqualTo(100);
        assertThat(reponse.triggers()).allSatisfy(t -> assertThat(t.hint()).isNotBlank());
    }

    // ------------------------------------------------------------------------

    private static Instant paris(int annee, int mois, int jour, int heure, int minute) {
        return ZonedDateTime.of(LocalDateTime.of(annee, mois, jour, heure, minute),
                FenetreMesure.PARIS).toInstant();
    }

    private static AdminAnalyticsResponse.SourceRow ligneSource(
            AdminAnalyticsResponse reponse, String id) {
        List<AdminAnalyticsResponse.SourceRow> lignes = reponse.sources().stream()
                .filter(r -> r.id().equals(id)).toList();
        assertThat(lignes).as("ligne de provenance « %s »", id).hasSize(1);
        return lignes.get(0);
    }

    private static AdminAnalyticsResponse.DiagTypeRow ligneFormat(
            AdminAnalyticsResponse reponse, String id) {
        List<AdminAnalyticsResponse.DiagTypeRow> lignes = reponse.diagTypes().stream()
                .filter(r -> r.id().equals(id)).toList();
        assertThat(lignes).as("format « %s »", id).hasSize(1);
        return lignes.get(0);
    }
}

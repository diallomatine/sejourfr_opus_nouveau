package com.sejourfr.app.service.access;

import com.sejourfr.app.entity.AccessOverride;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.AccessOrigin;
import com.sejourfr.app.enums.AccessOverrideType;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PaymentStatus;
import com.sejourfr.app.enums.PlanPurchaseType;
import com.sejourfr.app.enums.ProductAccessStatus;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.service.access.AccesEffectifResolver.CodeAlerte;
import com.sejourfr.app.service.access.AccesEffectifResolver.EtatProduit;
import com.sejourfr.app.util.DateMetierParis;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * La règle de l'accès effectif (spec §2.3, §2.4 ; GO §4, §5, §18), toutes
 * branches, sur des instants FIXÉS : aucun test ne dépend de l'horloge.
 */
class AccesEffectifResolverTest {

    private static final ZoneId PARIS = ZoneId.of("Europe/Paris");
    private static final Instant T = LocalDateTime.of(2026, 10, 2, 14, 0).atZone(PARIS).toInstant();
    private static final Duration JOUR = Duration.ofDays(1);

    // ------------------------------------------------------------------ fixtures

    private static Plan plan(ModuleAccess m) {
        Plan p = new Plan();
        p.setCode(m == ModuleAccess.INTEGRAL ? "INTEGRAL_PASS_1M" : "CIVIQUE_PASS_3M");
        p.setModuleAccess(m);
        p.setPurchaseType(PlanPurchaseType.ONE_TIME);
        return p;
    }

    private static UserSubscription achat(ModuleAccess m, Instant achete, Instant fin) {
        UserSubscription s = new UserSubscription();
        s.setId(UUID.randomUUID());
        s.setPlan(plan(m));
        s.setStatus(SubscriptionStatus.ACTIVE);
        s.setSource(SubscriptionSource.STRIPE);
        s.setStartsAt(achete);
        s.setPurchasedAt(achete);
        s.setEndsAt(fin);
        s.setPaymentStatus(PaymentStatus.PAID);
        return s;
    }

    private static AccessOverride decision(ModuleAccess p, AccessOverrideType type, Instant debut, Instant fin,
                                           Instant decidee) {
        AccessOverride o = new AccessOverride();
        o.setId(UUID.randomUUID());
        o.setProduct(p);
        o.setType(type);
        o.setStartsAt(debut);
        o.setEndsAt(fin);
        o.setDecidedAt(decidee);
        return o;
    }

    private static AccessOverride grant(ModuleAccess p, Instant debut, Instant fin) {
        return decision(p, AccessOverrideType.GRANT, debut, fin, T.minus(JOUR));
    }

    private static AccessOverride revoke(ModuleAccess p, Instant debut, Instant decidee) {
        return decision(p, AccessOverrideType.REVOKE, debut, null, decidee);
    }

    private static Instant parisLe(int mois, int jour, int h, int min) {
        return LocalDateTime.of(2026, mois, jour, h, min).atZone(PARIS).toInstant();
    }

    // ------------------------------------------------------------------ §2.3

    @Nested
    @DisplayName("Règle §2.3")
    class Regle {

        @Test
        @DisplayName("Sans décision : le calcul historique (Intégral > Civique, fin empilée la plus tardive)")
        void sansDecisionCalculHistorique() {
            UserSubscription civ = achat(ModuleAccess.CIVIQUE, T.minus(JOUR), T.plus(JOUR.multipliedBy(90)));
            UserSubscription i1 = achat(ModuleAccess.INTEGRAL, T.minus(JOUR), T.plus(JOUR.multipliedBy(10)));
            UserSubscription i2 = achat(ModuleAccess.INTEGRAL, T, T.plus(JOUR.multipliedBy(40)));
            List<UserSubscription> achats = List.of(civ, i1, i2);

            assertThat(AccesEffectifResolver.module(achats, List.of(), T)).isEqualTo(ModuleAccess.INTEGRAL);
            assertThat(AccesEffectifResolver.fin(achats, List.of(), ModuleAccess.INTEGRAL, T).instant())
                    .isEqualTo(i2.getEndsAt());
            assertThat(AccesEffectifResolver.fin(achats, List.of(), ModuleAccess.CIVIQUE, T).instant())
                    .isEqualTo(civ.getEndsAt());
            assertThat(AccesEffectifResolver.achatRepresentatif(achats, List.of(), T)).containsSame(i2);
        }

        @Test
        @DisplayName("Achat remboursé ou expiré : aucun accès")
        void achatNonCouvrant() {
            UserSubscription rembourse = achat(ModuleAccess.INTEGRAL, T.minus(JOUR), T.plus(JOUR));
            rembourse.setStatus(SubscriptionStatus.REFUNDED);
            UserSubscription expire = achat(ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(9)), T.minus(JOUR));

            assertThat(AccesEffectifResolver.module(List.of(rembourse, expire), List.of(), T))
                    .isEqualTo(ModuleAccess.NONE);
        }

        @Test
        @DisplayName("Cas 1 — GRANT sans achat : accès immédiat, origine Admin, aucun achat représentatif")
        void grantSansAchat() {
            Instant fin = DateMetierParis.finExclusive(LocalDate.of(2026, 10, 31));
            List<AccessOverride> d = List.of(grant(ModuleAccess.INTEGRAL, T, fin));

            assertThat(AccesEffectifResolver.module(List.of(), d, T)).isEqualTo(ModuleAccess.INTEGRAL);
            assertThat(AccesEffectifResolver.fin(List.of(), d, ModuleAccess.INTEGRAL, T).instant()).isEqualTo(fin);
            assertThat(AccesEffectifResolver.achatRepresentatif(List.of(), d, T)).isEmpty();
            EtatProduit e = AccesEffectifResolver.etat(List.of(), d, ModuleAccess.INTEGRAL, T);
            assertThat(e.statut()).isEqualTo(ProductAccessStatus.ACTIVE);
            assertThat(e.origine()).isEqualTo(AccessOrigin.ADMIN_GRANT);
        }

        @Test
        @DisplayName("REVOKE : bloque l'achat ANTÉRIEUR à la décision")
        void revokeBloqueAchatAnterieur() {
            UserSubscription civ = achat(ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(5)), T.plus(JOUR.multipliedBy(60)));
            List<AccessOverride> d = List.of(revoke(ModuleAccess.CIVIQUE, T.minus(JOUR), T.minus(JOUR)));

            assertThat(AccesEffectifResolver.module(List.of(civ), d, T)).isEqualTo(ModuleAccess.NONE);
            EtatProduit e = AccesEffectifResolver.etat(List.of(civ), d, ModuleAccess.CIVIQUE, T);
            assertThat(e.statut()).isEqualTo(ProductAccessStatus.REVOKED);
            assertThat(e.origine()).isEqualTo(AccessOrigin.ADMIN_REVOKE);
        }

        @Test
        @DisplayName("Cas 7 — un achat POSTÉRIEUR au REVOKE rouvre l'accès")
        void rachatApresRevoke() {
            UserSubscription ancien = achat(ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(30)), T.plus(JOUR.multipliedBy(60)));
            UserSubscription rachat = achat(ModuleAccess.CIVIQUE, T.minus(JOUR), T.plus(JOUR.multipliedBy(89)));
            List<AccessOverride> d = List.of(revoke(ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(10)),
                    T.minus(JOUR.multipliedBy(10))));

            assertThat(AccesEffectifResolver.module(List.of(ancien, rachat), d, T)).isEqualTo(ModuleAccess.CIVIQUE);
            assertThat(AccesEffectifResolver.achatsOuvrants(List.of(ancien, rachat), d, ModuleAccess.CIVIQUE, T))
                    .containsExactly(rachat);
            assertThat(AccesEffectifResolver.etat(List.of(ancien, rachat), d, ModuleAccess.CIVIQUE, T).alertes())
                    .extracting(AccesEffectifResolver.Alerte::code).contains(CodeAlerte.ROUVERT_PAR_ACHAT);
        }

        @Test
        @DisplayName("La règle « postérieur » lit decidedAt : une copie tronquée ne rend pas un rachat antérieur")
        void decidedAtConserveSurUneCopie() {
            Instant decision = T.minus(JOUR.multipliedBy(10));
            UserSubscription rachat = achat(ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(5)), T.plus(JOUR.multipliedBy(85)));
            AccessOverride copie = revoke(ModuleAccess.CIVIQUE, decision, decision);
            copie.setCreatedAt(T.minus(JOUR)); // ré-insérée APRÈS le rachat

            assertThat(AccesEffectifResolver.acces(List.of(rachat), List.of(copie), ModuleAccess.CIVIQUE, T)).isTrue();
        }

        @Test
        @DisplayName("GO §4 — une décision FUTURE n'a aucun effet avant son début")
        void decisionFutureSansEffet() {
            UserSubscription civ = achat(ModuleAccess.CIVIQUE, T.minus(JOUR), T.plus(JOUR.multipliedBy(60)));
            Instant debutRevoke = T.plus(JOUR.multipliedBy(18));
            List<AccessOverride> d = List.of(revoke(ModuleAccess.CIVIQUE, debutRevoke, T));

            assertThat(AccesEffectifResolver.acces(List.of(civ), d, ModuleAccess.CIVIQUE, T)).isTrue();
            assertThat(AccesEffectifResolver.acces(List.of(civ), d, ModuleAccess.CIVIQUE, debutRevoke.minusMillis(1))).isTrue();
            assertThat(AccesEffectifResolver.acces(List.of(civ), d, ModuleAccess.CIVIQUE, debutRevoke)).isFalse();
        }

        @Test
        @DisplayName("REVOKE Civique sous un Intégral actif : Civique reste ouvert (module Intégral)")
        void revokeCiviqueSousIntegral() {
            UserSubscription integral = achat(ModuleAccess.INTEGRAL, T.minus(JOUR), T.plus(JOUR.multipliedBy(30)));
            List<AccessOverride> d = List.of(revoke(ModuleAccess.CIVIQUE, T.minus(JOUR), T.minus(JOUR)));

            assertThat(AccesEffectifResolver.module(List.of(integral), d, T)).isEqualTo(ModuleAccess.INTEGRAL);
            assertThat(AccesEffectifResolver.module(List.of(integral), d, T).hasCivique()).isTrue();
            assertThat(AccesEffectifResolver.etat(List.of(integral), d, ModuleAccess.CIVIQUE, T).alertes())
                    .extracting(AccesEffectifResolver.Alerte::code).contains(CodeAlerte.INCLUS_DANS_INTEGRAL);
        }

        @Test
        @DisplayName("GRANT Intégral au-dessus d'un achat Civique : module Intégral, aucun achat Intégral représentatif")
        void grantIntegralSurAchatCivique() {
            UserSubscription civ = achat(ModuleAccess.CIVIQUE, T.minus(JOUR), T.plus(JOUR.multipliedBy(60)));
            List<AccessOverride> d = List.of(grant(ModuleAccess.INTEGRAL, T.minus(JOUR), T.plus(JOUR.multipliedBy(20))));

            assertThat(AccesEffectifResolver.module(List.of(civ), d, T)).isEqualTo(ModuleAccess.INTEGRAL);
            assertThat(AccesEffectifResolver.achatRepresentatif(List.of(civ), d, T)).isEmpty();
            // Le Civique acheté continue après la fin du GRANT : la fin « tous modules » est la sienne.
            assertThat(AccesEffectifResolver.fin(List.of(civ), d, ModuleAccess.CIVIQUE, T).instant())
                    .isEqualTo(civ.getEndsAt());
            assertThat(AccesEffectifResolver.fin(List.of(civ), d, ModuleAccess.INTEGRAL, T).instant())
                    .isEqualTo(T.plus(JOUR.multipliedBy(20)));
        }

        @Test
        @DisplayName("Fin chaînée : achat jusqu'à A puis GRANT [A, B) ⇒ fin effective B")
        void finChainee() {
            Instant a = T.plus(JOUR.multipliedBy(5));
            Instant b = T.plus(JOUR.multipliedBy(25));
            UserSubscription integral = achat(ModuleAccess.INTEGRAL, T.minus(JOUR), a);

            assertThat(AccesEffectifResolver.fin(List.of(integral),
                    List.of(grant(ModuleAccess.INTEGRAL, a, b)), ModuleAccess.INTEGRAL, T).instant()).isEqualTo(b);
        }

        @Test
        @DisplayName("Achat sans date de fin : fin « sans fin »")
        void achatSansFin() {
            UserSubscription illimite = achat(ModuleAccess.INTEGRAL, T.minus(JOUR), null);

            AccesEffectifResolver.Fin f = AccesEffectifResolver.fin(List.of(illimite), List.of(), ModuleAccess.INTEGRAL, T);
            assertThat(f.sansFin()).isTrue();
            assertThat(f.instant()).isNull();
        }
    }

    // ------------------------------------------------------------------ §2.4

    @Nested
    @DisplayName("Statuts §2.4")
    class Statuts {

        @Test
        @DisplayName("Aucun : jamais d'achat ni de GRANT")
        void aucun() {
            EtatProduit e = AccesEffectifResolver.etat(List.of(), List.of(), ModuleAccess.CIVIQUE, T);
            assertThat(e.statut()).isEqualTo(ProductAccessStatus.NONE);
            assertThat(e.origine()).isNull();
        }

        @Test
        @DisplayName("Expiré : un achat passé, rien d'actif ; origine de l'achat")
        void expire() {
            UserSubscription passe = achat(ModuleAccess.INTEGRAL, T.minus(JOUR.multipliedBy(40)), T.minus(JOUR.multipliedBy(10)));
            passe.setSource(SubscriptionSource.APPLE);

            EtatProduit e = AccesEffectifResolver.etat(List.of(passe), List.of(), ModuleAccess.INTEGRAL, T);
            assertThat(e.statut()).isEqualTo(ProductAccessStatus.EXPIRED);
            assertThat(e.fin()).isEqualTo(passe.getEndsAt());
            assertThat(e.origine()).isEqualTo(AccessOrigin.PURCHASE_APPLE);
        }

        @Test
        @DisplayName("Expiré : un GRANT passé")
        void expireParGrant() {
            AccessOverride g = grant(ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(9)), T.minus(JOUR));
            EtatProduit e = AccesEffectifResolver.etat(List.of(), List.of(g), ModuleAccess.CIVIQUE, T);
            assertThat(e.statut()).isEqualTo(ProductAccessStatus.EXPIRED);
            assertThat(e.origine()).isEqualTo(AccessOrigin.ADMIN_GRANT);
        }

        @Test
        @DisplayName("Cas 10 — Programmé : GRANT qui démarre plus tard, pas d'accès avant")
        void programme() {
            Instant debut = DateMetierParis.minuit(LocalDate.of(2026, 10, 15));
            Instant fin = DateMetierParis.finExclusive(LocalDate.of(2026, 11, 15));
            AccessOverride g = grant(ModuleAccess.INTEGRAL, debut, fin);

            EtatProduit e = AccesEffectifResolver.etat(List.of(), List.of(g), ModuleAccess.INTEGRAL, T);
            assertThat(e.statut()).isEqualTo(ProductAccessStatus.SCHEDULED);
            assertThat(e.debut()).isEqualTo(debut);
            assertThat(AccesEffectifResolver.module(List.of(), List.of(g), T)).isEqualTo(ModuleAccess.NONE);
            assertThat(AccesEffectifResolver.module(List.of(), List.of(g), debut)).isEqualTo(ModuleAccess.INTEGRAL);
        }

        @Test
        @DisplayName("Cas 9 — achat jusqu'au 15/11, raccourci au 05/11 : actif jusqu'au 05/11 inclus, puis Révoqué")
        void raccourciPuisRevoque() {
            UserSubscription a = achat(ModuleAccess.CIVIQUE, T.minus(JOUR), parisLe(11, 15, 18, 42));
            Instant revoke = DateMetierParis.finExclusive(LocalDate.of(2026, 11, 5));
            List<AccessOverride> d = List.of(revoke(ModuleAccess.CIVIQUE, revoke, T));

            EtatProduit maintenant = AccesEffectifResolver.etat(List.of(a), d, ModuleAccess.CIVIQUE, T);
            assertThat(maintenant.statut()).isEqualTo(ProductAccessStatus.ACTIVE);
            assertThat(maintenant.fin()).isEqualTo(revoke);
            assertThat(DateMetierParis.finIncluse(maintenant.fin())).contains(LocalDate.of(2026, 11, 5));
            assertThat(maintenant.alertes()).extracting(AccesEffectifResolver.Alerte::code)
                    .contains(CodeAlerte.REVOCATION_PROGRAMMEE);

            EtatProduit apres = AccesEffectifResolver.etat(List.of(a), d, ModuleAccess.CIVIQUE, revoke.plusSeconds(60));
            assertThat(apres.statut()).isEqualTo(ProductAccessStatus.REVOKED);
        }

        @Test
        @DisplayName("Cas 11 — GRANT en cours + achat remboursé : GRANT conservé, alerte « Achat remboursé »")
        void grantEtAchatRembourse() {
            UserSubscription a = achat(ModuleAccess.INTEGRAL, T.minus(JOUR), T.plus(JOUR.multipliedBy(29)));
            a.setStatus(SubscriptionStatus.REFUNDED);
            a.setPaymentStatus(PaymentStatus.REFUNDED);
            List<AccessOverride> d = List.of(grant(ModuleAccess.INTEGRAL, T.minus(JOUR), T.plus(JOUR.multipliedBy(29))));

            EtatProduit e = AccesEffectifResolver.etat(List.of(a), d, ModuleAccess.INTEGRAL, T);
            assertThat(e.statut()).isEqualTo(ProductAccessStatus.ACTIVE);
            assertThat(e.origine()).isEqualTo(AccessOrigin.ADMIN_GRANT);
            assertThat(e.alertes()).extracting(AccesEffectifResolver.Alerte::code)
                    .contains(CodeAlerte.ACHAT_REMBOURSE);
        }

        @Test
        @DisplayName("Abonnement récurrent couvrant : alerte « lecture seule » (G-12)")
        void recurrent() {
            UserSubscription a = achat(ModuleAccess.INTEGRAL, T.minus(JOUR), T.plus(JOUR.multipliedBy(29)));
            a.setAutoRenew(true);
            assertThat(AccesEffectifResolver.etat(List.of(a), List.of(), ModuleAccess.INTEGRAL, T).alertes())
                    .extracting(AccesEffectifResolver.Alerte::code).contains(CodeAlerte.ABONNEMENT_RECURRENT);
        }
    }

    // ------------------------------------------------------- bornes de Paris (cas 12)

    @Nested
    @DisplayName("Cas 12 — bornes Europe/Paris")
    class BornesParis {

        @Test
        @DisplayName("Fin le 31/10 inclus : accès le 31/10 à 23:30, plus d'accès le 01/11 à 00:01 (heure de Paris)")
        void finIncluseLe31() {
            Instant fin = DateMetierParis.finExclusive(LocalDate.of(2026, 10, 31));
            List<AccessOverride> d = List.of(grant(ModuleAccess.INTEGRAL, T, fin));

            assertThat(fin).isEqualTo(parisLe(11, 1, 0, 0));
            assertThat(AccesEffectifResolver.acces(List.of(), d, ModuleAccess.INTEGRAL, parisLe(10, 31, 23, 30))).isTrue();
            assertThat(AccesEffectifResolver.acces(List.of(), d, ModuleAccess.INTEGRAL, parisLe(11, 1, 0, 1))).isFalse();
        }

        @Test
        @DisplayName("Passage à l'heure d'hiver (25/10/2026) : la borne reste minuit Paris")
        void passageHeureDHiver() {
            Instant fin = DateMetierParis.finExclusive(LocalDate.of(2026, 10, 24));
            List<AccessOverride> d = List.of(grant(ModuleAccess.CIVIQUE, T, fin));

            assertThat(AccesEffectifResolver.acces(List.of(), d, ModuleAccess.CIVIQUE, parisLe(10, 24, 23, 59))).isTrue();
            assertThat(AccesEffectifResolver.acces(List.of(), d, ModuleAccess.CIVIQUE, parisLe(10, 25, 0, 1))).isFalse();
        }
    }

    // --------------------------------------------- D-32 (révise D-09) / D-34

    @Nested
    @DisplayName("Emails : les décisions changent-elles l'accès par rapport aux seuls achats ?")
    class DecisionsEtEmails {

        @Test
        @DisplayName("Sans décision, ou GRANT terminé depuis longtemps : non")
        void sansEffet() {
            UserSubscription pass = achat(ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(20)), T.plus(JOUR));
            assertThat(AccesEffectifResolver.decisionsChangentLAcces(List.of(pass), List.of(), T, T.plus(JOUR)))
                    .isFalse();
            AccessOverride ancien = grant(ModuleAccess.INTEGRAL, T.minus(JOUR.multipliedBy(200)),
                    T.minus(JOUR.multipliedBy(100)));
            assertThat(AccesEffectifResolver.decisionsChangentLAcces(List.of(pass), List.of(ancien), T, T.plus(JOUR)))
                    .isFalse();
        }

        @Test
        @DisplayName("GRANT en cours ou REVOKE en cours : oui, dès maintenant")
        void decisionEnCours() {
            UserSubscription pass = achat(ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(20)), T.plus(JOUR));
            assertThat(AccesEffectifResolver.decisionsChangentLAcces(List.of(),
                    List.of(grant(ModuleAccess.CIVIQUE, T.minus(JOUR), T.plus(JOUR))), T, T)).isTrue();
            assertThat(AccesEffectifResolver.decisionsChangentLAcces(List.of(pass),
                    List.of(revoke(ModuleAccess.CIVIQUE, T.minus(JOUR), T.minus(JOUR))), T, T)).isTrue();
        }

        @Test
        @DisplayName("GRANT programmé qui prolonge au-delà de la fin annoncée : oui, à la date annoncée seulement")
        void grantProgramme() {
            UserSubscription pass = achat(ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(20)), T.plus(JOUR));
            List<AccessOverride> d = List.of(grant(ModuleAccess.CIVIQUE, T.plus(JOUR), T.plus(JOUR.multipliedBy(20))));
            assertThat(AccesEffectifResolver.decisionsChangentLAcces(List.of(pass), d, T, T)).isFalse();
            assertThat(AccesEffectifResolver.decisionsChangentLAcces(List.of(pass), d, T, T.plus(JOUR))).isTrue();
        }

        @Test
        @DisplayName("REVOKE programmé entre maintenant et la fin annoncée : oui (borne intérieure)")
        void revokeProgrammeAvantLaFin() {
            UserSubscription pass = achat(ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(20)), T.plus(JOUR.multipliedBy(5)));
            List<AccessOverride> d = List.of(revoke(ModuleAccess.CIVIQUE, T.plus(JOUR.multipliedBy(2)), T.minus(JOUR)));
            assertThat(AccesEffectifResolver.decisionsChangentLAcces(List.of(pass), d, T,
                    T.plus(JOUR.multipliedBy(5)))).isTrue();
        }

        @Test
        @DisplayName("REVOKE ouvert puis rachat postérieur : non — le rachat se termine comme un achat")
        void revokePuisRachat() {
            UserSubscription revoque = achat(ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(70)),
                    T.minus(JOUR.multipliedBy(35)));
            UserSubscription rachat = achat(ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(30)), T.plus(JOUR));
            List<AccessOverride> d = List.of(revoke(ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(40)),
                    T.minus(JOUR.multipliedBy(40))));
            assertThat(AccesEffectifResolver.decisionsChangentLAcces(List.of(revoque, rachat), d, T, T.plus(JOUR)))
                    .isFalse();
        }
    }

    @Nested
    @DisplayName("Achat révoqué : fin proposée et achat qui reste révoqué (D-34)")
    class AchatRevoque {

        @Test
        @DisplayName("Statut Révoqué : finAchatRevoque = fin de l'achat neutralisé ; un rachat n'en est pas un")
        void finAchatRevoque() {
            UserSubscription pass = achat(ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(10)), T.plus(JOUR.multipliedBy(30)));
            List<AccessOverride> d = List.of(revoke(ModuleAccess.CIVIQUE, T.minus(JOUR), T.minus(JOUR)));
            EtatProduit e = AccesEffectifResolver.etat(List.of(pass), d, ModuleAccess.CIVIQUE, T);
            assertThat(e.statut()).isEqualTo(ProductAccessStatus.REVOKED);
            assertThat(e.finAchatRevoque()).isEqualTo(pass.getEndsAt());

            EtatProduit actif = AccesEffectifResolver.etat(List.of(pass), List.of(), ModuleAccess.CIVIQUE, T);
            assertThat(actif.finAchatRevoque()).isNull();
        }

        @Test
        @DisplayName("GRANT sur REVOKE : à la fin du GRANT, l'achat reste révoqué tant qu'il aurait couvert")
        void achatResteRevoque() {
            UserSubscription pass = achat(ModuleAccess.CIVIQUE, T.minus(JOUR.multipliedBy(10)), T.plus(JOUR.multipliedBy(30)));
            List<AccessOverride> d = List.of(
                    revoke(ModuleAccess.CIVIQUE, T.minus(JOUR), T.minus(JOUR)),
                    grant(ModuleAccess.CIVIQUE, T, T.plus(JOUR.multipliedBy(10))));
            List<AccessOverride> apres = List.of(
                    d.get(1),
                    revoke(ModuleAccess.CIVIQUE, T.plus(JOUR.multipliedBy(10)), T.minus(JOUR)));
            assertThat(AccesEffectifResolver.achatResteRevoque(List.of(pass), apres, ModuleAccess.CIVIQUE,
                    T.plus(JOUR.multipliedBy(10)))).isTrue();
            assertThat(AccesEffectifResolver.achatResteRevoque(List.of(pass), apres, ModuleAccess.CIVIQUE,
                    T.plus(JOUR.multipliedBy(31)))).isFalse();
        }
    }
}

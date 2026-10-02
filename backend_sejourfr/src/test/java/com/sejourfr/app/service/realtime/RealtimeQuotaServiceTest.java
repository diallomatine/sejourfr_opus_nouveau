package com.sejourfr.app.service.realtime;

import com.sejourfr.app.entity.AccessOverride;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.RealtimeSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.AccessOverrideType;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PaymentStatus;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.manager.AccessOverrideManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.service.SubscriptionService;
import com.sejourfr.app.service.SubscriptionService.DonneesAcces;
import com.sejourfr.app.service.access.AccessOverridePlanner;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InOrder;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * L'unique règle du quota EO temps réel ({@link RealtimeQuotaService#evaluer}) et
 * son unique point de débit ({@link RealtimeQuotaService#debiter}) : GRANT
 * INTEGRAL admin d'abord, achat Intégral ensuite ; sommes servies aux fronts ;
 * sans décision, exactement le calcul d'avant. Sans base.
 */
@ExtendWith(MockitoExtension.class)
class RealtimeQuotaServiceTest {

    private static final Instant T = Instant.parse("2026-10-02T12:00:00Z");
    private static final Duration JOUR = Duration.ofDays(1);

    @Mock private SubscriptionService subscriptionService;
    @Mock private UserSubscriptionManager userSubscriptionManager;
    @Mock private AccessOverrideManager accessOverrideManager;

    private RealtimeQuotaService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        service = new RealtimeQuotaService(subscriptionService, userSubscriptionManager, accessOverrideManager);
    }

    // -------------------------------------------------------------- fabriques

    private static UserSubscription achat(ModuleAccess module, int planCap, int remaining) {
        Plan plan = new Plan();
        plan.setCode(module.name() + "_PASS");
        plan.setModuleAccess(module);
        plan.setRealtimeEoSessions(planCap);
        UserSubscription sub = new UserSubscription();
        sub.setId(UUID.randomUUID());
        sub.setPlan(plan);
        sub.setSource(SubscriptionSource.STRIPE);
        sub.setStatus(SubscriptionStatus.ACTIVE);
        sub.setPaymentStatus(PaymentStatus.PAID);
        sub.setStartsAt(T.minus(JOUR));
        sub.setPurchasedAt(T.minus(JOUR));
        sub.setEndsAt(T.plus(JOUR.multipliedBy(20)));
        sub.setRealtimeEoSessionsRemaining(remaining);
        return sub;
    }

    private static AccessOverride grant(ModuleAccess p, Instant debut, Instant fin, int granted, int remaining) {
        AccessOverride o = new AccessOverride();
        o.setId(UUID.randomUUID());
        o.setUserId(UUID.randomUUID());
        o.setProduct(p);
        o.setType(AccessOverrideType.GRANT);
        o.setStartsAt(debut);
        o.setEndsAt(fin);
        o.setDecidedAt(debut);
        o.setOperationId(UUID.randomUUID());
        o.setRealtimeEoSessionsGranted(granted);
        o.setRealtimeEoSessionsRemaining(remaining);
        return o;
    }

    private static AccessOverride grantActif(int granted, int remaining) {
        return grant(ModuleAccess.INTEGRAL, T.minus(JOUR), T.plus(JOUR.multipliedBy(30)), granted, remaining);
    }

    private static DonneesAcces donnees(List<UserSubscription> achats, List<AccessOverride> decisions) {
        return new DonneesAcces(achats, decisions);
    }

    // ---------------------------------------------------------------- evaluer

    @Nested
    @DisplayName("evaluer — la règle unique")
    class Evaluer {

        @Test
        @DisplayName("Sans décision : identique au calcul d'avant (solde et allocation de l'achat qui compte)")
        void sansDecisionIdentiqueAAvant() {
            UserSubscription a = achat(ModuleAccess.INTEGRAL, 5, 3);
            RealtimeQuotaService.Quota q = RealtimeQuotaService.evaluer(donnees(List.of(a), List.of()), T);

            assertThat(q.grant()).isEmpty();
            assertThat(q.achat()).containsSame(a);
            assertThat(q.cap()).isEqualTo(5);
            assertThat(q.remaining()).isEqualTo(3);
            assertThat(q.canStartRealtime()).isTrue();
            assertThat(q.achatPorteur()).containsSame(a);
            assertThat(q.grantPorteur()).isEmpty();
        }

        @Test
        @DisplayName("Rien du tout : quota vide, pas de temps réel")
        void quotaVide() {
            RealtimeQuotaService.Quota q = RealtimeQuotaService.evaluer(DonneesAcces.VIDE, T);
            assertThat(q.cap()).isZero();
            assertThat(q.remaining()).isZero();
            assertThat(q.canStartRealtime()).isFalse();
        }

        @Test
        @DisplayName("Civique acheté (0 session) : cap 0, async")
        void civiqueSansSession() {
            RealtimeQuotaService.Quota q = RealtimeQuotaService.evaluer(
                    donnees(List.of(achat(ModuleAccess.CIVIQUE, 0, 0)), List.of()), T);
            assertThat(q.cap()).isZero();
            assertThat(q.canStartRealtime()).isFalse();
        }

        @Test
        @DisplayName("Solde négatif ramené à 0")
        void soldeNegatifClampe() {
            RealtimeQuotaService.Quota q = RealtimeQuotaService.evaluer(
                    donnees(List.of(achat(ModuleAccess.INTEGRAL, 5, -2)), List.of()), T);
            assertThat(q.remaining()).isZero();
        }

        @Test
        @DisplayName("Priorité : le GRANT admin est réservé d'abord, l'achat seulement quand le GRANT est épuisé")
        void grantDAbordPuisAchat() {
            UserSubscription a = achat(ModuleAccess.INTEGRAL, 15, 7);
            AccessOverride g = grantActif(10, 4);
            RealtimeQuotaService.Quota q = RealtimeQuotaService.evaluer(donnees(List.of(a), List.of(g)), T);
            assertThat(q.grantPorteur()).containsSame(g);
            assertThat(q.achatPorteur()).isEmpty();

            g.setRealtimeEoSessionsRemaining(0);
            RealtimeQuotaService.Quota epuise = RealtimeQuotaService.evaluer(donnees(List.of(a), List.of(g)), T);
            assertThat(epuise.grantPorteur()).isEmpty();
            assertThat(epuise.achatPorteur()).containsSame(a);
        }

        @Test
        @DisplayName("Ce que voient les fronts : remaining = somme des soldes, cap = somme des allocations")
        void remainingEtCapSontDesSommes() {
            UserSubscription a = achat(ModuleAccess.INTEGRAL, 15, 7);
            AccessOverride g = grantActif(10, 4);
            RealtimeQuotaService.Quota q = RealtimeQuotaService.evaluer(donnees(List.of(a), List.of(g)), T);

            assertThat(q.remaining()).isEqualTo(11);
            assertThat(q.cap()).isEqualTo(25);
            assertThat(q.grantRemaining()).isEqualTo(4);
            assertThat(q.grantGranted()).isEqualTo(10);
            assertThat(q.achatRemaining()).isEqualTo(7);
        }

        @Test
        @DisplayName("GRANT Intégral seul (aucun achat) : ses sessions suffisent à ouvrir le temps réel")
        void grantSeul() {
            RealtimeQuotaService.Quota q = RealtimeQuotaService.evaluer(donnees(List.of(), List.of(grantActif(10, 10))), T);
            assertThat(q.achat()).isEmpty();
            assertThat(q.cap()).isEqualTo(10);
            assertThat(q.remaining()).isEqualTo(10);
            assertThat(q.canStartRealtime()).isTrue();
        }

        @Test
        @DisplayName("GRANT épuisé : cap reste > 0 (pas de paywall), remaining 0")
        void grantEpuiseGardeLeCap() {
            RealtimeQuotaService.Quota q = RealtimeQuotaService.evaluer(donnees(List.of(), List.of(grantActif(10, 0))), T);
            assertThat(q.cap()).isEqualTo(10);
            assertThat(q.remaining()).isZero();
            assertThat(q.canStartRealtime()).isFalse();
        }

        @Test
        @DisplayName("GRANT sans session offerte : cap = celui de l'achat (comportement d'avant)")
        void grantSansSessionCapDeLAchat() {
            UserSubscription a = achat(ModuleAccess.INTEGRAL, 15, 4);
            RealtimeQuotaService.Quota q = RealtimeQuotaService.evaluer(donnees(List.of(a), List.of(grantActif(0, 0))), T);
            assertThat(q.cap()).isEqualTo(15);
            assertThat(q.remaining()).isEqualTo(4);
            assertThat(q.achatPorteur()).containsSame(a);
        }

        @Test
        @DisplayName("GRANT CIVIQUE : ne porte jamais de session")
        void grantCiviqueIgnore() {
            AccessOverride civique = grant(ModuleAccess.CIVIQUE, T.minus(JOUR), T.plus(JOUR), 0, 0);
            RealtimeQuotaService.Quota q = RealtimeQuotaService.evaluer(donnees(List.of(), List.of(civique)), T);
            assertThat(q.grant()).isEmpty();
            assertThat(q.cap()).isZero();
        }

        @Test
        @DisplayName("GRANT expiré ou programmé : son solde n'est pas consommable maintenant")
        void grantHorsFenetre() {
            AccessOverride expire = grant(ModuleAccess.INTEGRAL, T.minus(JOUR.multipliedBy(10)), T.minus(JOUR), 10, 6);
            AccessOverride futur = grant(ModuleAccess.INTEGRAL, T.plus(JOUR), T.plus(JOUR.multipliedBy(9)), 5, 5);
            RealtimeQuotaService.Quota q = RealtimeQuotaService.evaluer(donnees(List.of(), List.of(expire, futur)), T);
            assertThat(q.grant()).isEmpty();
            assertThat(q.remaining()).isZero();
            assertThat(q.cap()).isZero();
        }

        @Test
        @DisplayName("Achat remboursé en totalité : seul le GRANT compte encore")
        void achatRembourseSortDuQuota() {
            UserSubscription a = achat(ModuleAccess.INTEGRAL, 15, 7);
            a.setStatus(SubscriptionStatus.REFUNDED);
            a.setPaymentStatus(PaymentStatus.REFUNDED);
            AccessOverride g = grantActif(5, 5);
            RealtimeQuotaService.Quota q = RealtimeQuotaService.evaluer(donnees(List.of(a), List.of(g)), T);
            assertThat(q.achat()).isEmpty();
            assertThat(q.remaining()).isEqualTo(5);
            assertThat(q.cap()).isEqualTo(5);
        }
    }

    // ------------------------------------------- lignée (planner + evaluer)

    @Nested
    @DisplayName("Lignée d'un GRANT : la même règle relue après le plan")
    class Lignee {

        private final AccessOverridePlanner.Contexte ctx =
                new AccessOverridePlanner.Contexte(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), "Motif", T);

        private RealtimeQuotaService.Quota apres(List<AccessOverride> courants, AccessOverridePlanner.Decision d) {
            AccessOverridePlanner.Plan plan = AccessOverridePlanner.planifier(courants, List.of(d), ctx);
            return RealtimeQuotaService.evaluer(donnees(List.of(), plan.appliqueA(courants)), T);
        }

        @Test
        @DisplayName("Prolonger sans ajout : 4 restantes → 4 restantes, offertes conservées (10)")
        void prolongation4Vers4() {
            RealtimeQuotaService.Quota q = apres(List.of(grantActif(10, 4)), new AccessOverridePlanner.Decision(
                    ModuleAccess.INTEGRAL, AccessOverrideType.GRANT, T, T.plus(JOUR.multipliedBy(60))));
            assertThat(q.grantRemaining()).isEqualTo(4);
            assertThat(q.grantGranted()).isEqualTo(10);
            assertThat(q.grantRemaining()).isLessThanOrEqualTo(q.grantGranted());
        }

        @Test
        @DisplayName("Donner Intégral +10 sur un GRANT actif à 4 : 14 disponibles, granted cohérent (≥ remaining)")
        void cumul4Plus10() {
            RealtimeQuotaService.Quota q = apres(List.of(grantActif(10, 4)), new AccessOverridePlanner.Decision(
                    ModuleAccess.INTEGRAL, AccessOverrideType.GRANT, T, T.plus(JOUR.multipliedBy(60)), 10));
            assertThat(q.grantRemaining()).isEqualTo(14);
            assertThat(q.grantGranted()).isEqualTo(20);
            assertThat(q.remaining()).isEqualTo(14);
        }

        @Test
        @DisplayName("Terminer : le GRANT ne couvre plus maintenant, son solde est perdu (0 consommable)")
        void finPerdu() {
            RealtimeQuotaService.Quota q = apres(List.of(grantActif(10, 4)), new AccessOverridePlanner.Decision(
                    ModuleAccess.INTEGRAL, AccessOverrideType.REVOKE, T, null));
            assertThat(q.grant()).isEmpty();
            assertThat(q.remaining()).isZero();
        }
    }

    // ------------------------------------------------------------- évaluate

    @Test
    @DisplayName("evaluate / remaining : la même règle sur les données chargées par l'autorité d'accès")
    void evaluateDelegue() {
        UserSubscription a = achat(ModuleAccess.INTEGRAL, 4, 3);
        when(subscriptionService.charger(userId)).thenReturn(donnees(List.of(a), List.of()));

        assertThat(service.remaining(userId)).isEqualTo(3);
    }

    // ------------------------------------------------------------- debiter

    private RealtimeSession session() {
        User u = new User();
        u.setId(userId);
        RealtimeSession s = new RealtimeSession();
        s.setId(UUID.randomUUID());
        s.setUser(u);
        return s;
    }

    @Test
    @DisplayName("Débit d'une session portée par un achat : SQL d'avant, aucune décision lue ni verrou")
    void debitAchatInchange() {
        RealtimeSession s = session();
        UserSubscription a = achat(ModuleAccess.INTEGRAL, 5, 3);
        s.setSubscription(a);

        service.debiter(s);

        verify(userSubscriptionManager).decrementRealtimeSessions(a.getId());
        verifyNoInteractions(accessOverrideManager);
        assertThat(s.getAccessOverrideId()).isNull();
    }

    @Test
    @DisplayName("Débit d'un GRANT : sous le verrou du compte, sur la ligne COURANTE relue, tracée sur la session")
    void debitGrantALaConnexionTraceLaLigne() {
        RealtimeSession s = session();
        AccessOverride reserve = grantActif(10, 4);
        AccessOverride courant = grantActif(10, 4); // remplacé entre démarrage et connexion (prolongation)
        s.setAccessOverrideId(reserve.getId());
        when(subscriptionService.charger(userId)).thenReturn(donnees(List.of(), List.of(courant)));
        when(accessOverrideManager.decrementRealtimeSessions(courant.getId())).thenReturn(true);

        service.debiter(s);

        InOrder ordre = inOrder(accessOverrideManager, subscriptionService);
        ordre.verify(accessOverrideManager).verrouiller(userId);
        ordre.verify(subscriptionService).charger(userId);
        ordre.verify(accessOverrideManager).decrementRealtimeSessions(courant.getId());
        assertThat(s.getAccessOverrideId()).isEqualTo(courant.getId());
        verifyNoInteractions(userSubscriptionManager);
    }

    @Test
    @DisplayName("GRANT disparu (terminé) ou solde à 0 entre démarrage et connexion : aucun débit, porteur null")
    void grantDisparuAucunDebitEtPorteurNull() {
        RealtimeSession s = session();
        s.setAccessOverrideId(UUID.randomUUID());
        when(subscriptionService.charger(userId)).thenReturn(DonneesAcces.VIDE);

        service.debiter(s);

        verify(accessOverrideManager, never()).decrementRealtimeSessions(any());
        assertThat(s.getAccessOverrideId()).isNull();

        RealtimeSession s2 = session();
        AccessOverride vide = grantActif(10, 0);
        s2.setAccessOverrideId(vide.getId());
        when(subscriptionService.charger(userId)).thenReturn(donnees(List.of(), List.of(vide)));
        when(accessOverrideManager.decrementRealtimeSessions(vide.getId())).thenReturn(false);

        service.debiter(s2);

        assertThat(s2.getAccessOverrideId()).isNull();
        verifyNoInteractions(userSubscriptionManager);
    }

    @Test
    @DisplayName("Session sans porteur (cas dégradé) : rien")
    void sansPorteur() {
        service.debiter(session());
        verifyNoInteractions(userSubscriptionManager, accessOverrideManager, subscriptionService);
    }
}

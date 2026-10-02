package com.sejourfr.app.service.access;

import com.sejourfr.app.entity.AccessOverride;
import com.sejourfr.app.enums.AccessOverrideType;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.service.access.AccessOverridePlanner.Contexte;
import com.sejourfr.app.service.access.AccessOverridePlanner.Decision;
import com.sejourfr.app.service.access.AccessOverridePlanner.Plan;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Traduction des décisions en écritures (GO §4, §18) : troncature, queue d'un
 * REVOKE, abandon de la queue d'un GRANT, lignée des copies, et l'invariant
 * « aucune fenêtre courante ne se chevauche » sur le résultat.
 */
class AccessOverridePlannerTest {

    private static final Instant T = Instant.parse("2026-10-02T12:00:00Z");
    private static final Duration JOUR = Duration.ofDays(1);
    private static final UUID USER = UUID.randomUUID();
    private static final UUID ADMIN = UUID.randomUUID();
    private static final UUID ANCIEN_ADMIN = UUID.randomUUID();

    private final UUID operation = UUID.randomUUID();
    private final Contexte ctx = new Contexte(USER, operation, ADMIN, "Motif de test", T);

    private static AccessOverride existante(ModuleAccess p, AccessOverrideType type, Instant debut, Instant fin) {
        AccessOverride o = new AccessOverride();
        o.setId(UUID.randomUUID());
        o.setUserId(USER);
        o.setProduct(p);
        o.setType(type);
        o.setStartsAt(debut);
        o.setEndsAt(fin);
        o.setDecidedAt(debut.minus(JOUR));
        o.setReason("Ancien motif");
        o.setCreatedBy(ANCIEN_ADMIN);
        o.setOperationId(UUID.randomUUID());
        return o;
    }

    private static void sansChevauchement(List<AccessOverride> courants) {
        for (ModuleAccess p : AccesEffectifResolver.PRODUITS) {
            List<AccessOverride> l = courants.stream().filter(o -> o.getProduct() == p)
                    .sorted(Comparator.comparing(AccessOverride::getStartsAt)).toList();
            for (int i = 1; i < l.size(); i++) {
                Instant finPrecedente = l.get(i - 1).getEndsAt();
                assertThat(finPrecedente).as("fenêtre ouverte suivie d'une autre").isNotNull();
                assertThat(finPrecedente).isBeforeOrEqualTo(l.get(i).getStartsAt());
            }
        }
    }

    @Test
    @DisplayName("GO §4 — programmer au 20/10 un GRANT actif jusqu'au 31/10 : tronqué au 20/10, l'accès d'ici là ne bouge pas")
    void programmerTronqueSansToucherLePresent() {
        AccessOverride actif = existante(ModuleAccess.INTEGRAL, AccessOverrideType.GRANT, T.minus(JOUR), T.plus(JOUR.multipliedBy(29)));
        Instant le20 = T.plus(JOUR.multipliedBy(18));
        Decision future = new Decision(ModuleAccess.INTEGRAL, AccessOverrideType.REVOKE, le20, null);

        Plan plan = AccessOverridePlanner.planifier(List.of(actif), List.of(future), ctx);

        assertThat(plan.aRemplacer()).containsExactly(actif);
        assertThat(plan.aInserer()).hasSize(2);
        AccessOverride tete = plan.aInserer().getFirst();
        assertThat(tete.getType()).isEqualTo(AccessOverrideType.GRANT);
        assertThat(tete.getStartsAt()).isEqualTo(actif.getStartsAt());
        assertThat(tete.getEndsAt()).isEqualTo(le20);
        assertThat(tete.getDecidedAt()).isEqualTo(actif.getDecidedAt());
        assertThat(tete.getReason()).isEqualTo("Ancien motif");
        assertThat(tete.getCreatedBy()).isEqualTo(ANCIEN_ADMIN);
        assertThat(tete.getOperationId()).isEqualTo(operation);
        assertThat(tete.getReplacesOverrideId()).isEqualTo(actif.getId());

        List<AccessOverride> apres = plan.appliqueA(List.of(actif));
        sansChevauchement(apres);
        for (Instant t : List.of(T, le20.minusMillis(1))) {
            assertThat(AccesEffectifResolver.acces(List.of(), apres, ModuleAccess.INTEGRAL, t))
                    .isEqualTo(AccesEffectifResolver.acces(List.of(), List.of(actif), ModuleAccess.INTEGRAL, t));
        }
        assertThat(AccesEffectifResolver.acces(List.of(), apres, ModuleAccess.INTEGRAL, le20)).isFalse();
    }

    @Test
    @DisplayName("Réactiver sur un REVOKE ouvert : tête conservée, GRANT, puis la révocation reprend après le GRANT")
    void grantSurRevokeOuvert() {
        AccessOverride revoke = existante(ModuleAccess.CIVIQUE, AccessOverrideType.REVOKE, T.minus(JOUR.multipliedBy(5)), null);
        Instant fin = T.plus(JOUR.multipliedBy(30));

        Plan plan = AccessOverridePlanner.planifier(List.of(revoke),
                List.of(new Decision(ModuleAccess.CIVIQUE, AccessOverrideType.GRANT, T, fin)), ctx);
        List<AccessOverride> apres = plan.appliqueA(List.of(revoke));

        sansChevauchement(apres);
        assertThat(apres).extracting(AccessOverride::getType, AccessOverride::getStartsAt, AccessOverride::getEndsAt)
                .containsExactlyInAnyOrder(
                        org.assertj.core.groups.Tuple.tuple(AccessOverrideType.REVOKE, revoke.getStartsAt(), T),
                        org.assertj.core.groups.Tuple.tuple(AccessOverrideType.GRANT, T, fin),
                        org.assertj.core.groups.Tuple.tuple(AccessOverrideType.REVOKE, fin, null));
        assertThat(apres).filteredOn(o -> o.getType() == AccessOverrideType.REVOKE)
                .allMatch(o -> o.getDecidedAt().equals(revoke.getDecidedAt()));
    }

    @Test
    @DisplayName("Raccourcir un GRANT : la queue du GRANT n'est jamais conservée")
    void raccourcirUnGrant() {
        AccessOverride g = existante(ModuleAccess.INTEGRAL, AccessOverrideType.GRANT, T.minus(JOUR), T.plus(JOUR.multipliedBy(30)));
        Instant coupe = T.plus(JOUR.multipliedBy(10));

        List<AccessOverride> apres = AccessOverridePlanner.planifier(List.of(g),
                List.of(new Decision(ModuleAccess.INTEGRAL, AccessOverrideType.REVOKE, coupe, null)), ctx)
                .appliqueA(List.of(g));

        sansChevauchement(apres);
        assertThat(AccesEffectifResolver.fin(List.of(), apres, ModuleAccess.INTEGRAL, T).instant()).isEqualTo(coupe);
    }

    @Test
    @DisplayName("Une décision qui ne recoupe rien laisse les autres intactes ; un autre produit n'est jamais touché")
    void sansRecoupement() {
        AccessOverride futur = existante(ModuleAccess.CIVIQUE, AccessOverrideType.REVOKE, T.plus(JOUR.multipliedBy(40)), null);
        AccessOverride autreProduit = existante(ModuleAccess.INTEGRAL, AccessOverrideType.GRANT, T.minus(JOUR), T.plus(JOUR));

        Plan plan = AccessOverridePlanner.planifier(List.of(futur, autreProduit),
                List.of(new Decision(ModuleAccess.CIVIQUE, AccessOverrideType.GRANT, T, T.plus(JOUR.multipliedBy(10)))), ctx);

        assertThat(plan.aRemplacer()).isEmpty();
        assertThat(plan.aInserer()).hasSize(1);
    }

    @Test
    @DisplayName("Correction de produit : REVOKE A + GRANT B, même operationId, même motif")
    void correctionDeProduit() {
        Instant fin = T.plus(JOUR.multipliedBy(28));
        Plan plan = AccessOverridePlanner.planifier(List.of(), List.of(
                new Decision(ModuleAccess.CIVIQUE, AccessOverrideType.REVOKE, T, null),
                new Decision(ModuleAccess.INTEGRAL, AccessOverrideType.GRANT, T, fin)), ctx);

        assertThat(plan.aInserer()).extracting(AccessOverride::getProduct, AccessOverride::getType)
                .containsExactly(
                        org.assertj.core.groups.Tuple.tuple(ModuleAccess.CIVIQUE, AccessOverrideType.REVOKE),
                        org.assertj.core.groups.Tuple.tuple(ModuleAccess.INTEGRAL, AccessOverrideType.GRANT));
        assertThat(plan.aInserer()).allMatch(o -> o.getOperationId().equals(operation)
                && o.getReason().equals("Motif de test") && o.getCreatedBy().equals(ADMIN)
                && o.getDecidedAt().equals(T));
    }

    // ------------------------------------------------ sessions EO temps réel (V084)

    private static AccessOverride grantIntegral(Instant debut, Instant fin, int granted, int remaining) {
        AccessOverride o = existante(ModuleAccess.INTEGRAL, AccessOverrideType.GRANT, debut, fin);
        o.setRealtimeEoSessionsGranted(granted);
        o.setRealtimeEoSessionsRemaining(remaining);
        return o;
    }

    private static AccessOverride couvrantMaintenant(List<AccessOverride> l) {
        return l.stream().filter(o -> o.getProduct() == ModuleAccess.INTEGRAL
                && o.getType() == AccessOverrideType.GRANT && o.couvre(T)).findFirst().orElseThrow();
    }

    /** Invariants des CHECK V084 sur ce qui serait inséré. */
    private static void checksV084(Plan plan) {
        for (AccessOverride o : plan.aInserer()) {
            assertThat(o.getRealtimeEoSessionsRemaining()).isBetween(0, o.getRealtimeEoSessionsGranted());
            if (o.getRealtimeEoSessionsGranted() > 0) {
                assertThat(o.getProduct()).isEqualTo(ModuleAccess.INTEGRAL);
                assertThat(o.getType()).isEqualTo(AccessOverrideType.GRANT);
            }
        }
    }

    @Test
    @DisplayName("Sessions — nouvelle décision : granted = remaining = N ; REVOKE et CIVIQUE : toujours 0")
    void nouvelleDecisionPorteN() {
        Plan plan = AccessOverridePlanner.planifier(List.of(), List.of(
                new Decision(ModuleAccess.CIVIQUE, AccessOverrideType.REVOKE, T, null, 7),
                new Decision(ModuleAccess.INTEGRAL, AccessOverrideType.GRANT, T, T.plus(JOUR.multipliedBy(30)), 10)), ctx);
        assertThat(plan.aInserer().get(0).getRealtimeEoSessionsGranted()).isZero();
        AccessOverride g = plan.aInserer().get(1);
        assertThat(g.getRealtimeEoSessionsGranted()).isEqualTo(10);
        assertThat(g.getRealtimeEoSessionsRemaining()).isEqualTo(10);
        assertThat(plan.sessionsEo()).isEqualTo(new AccessOverridePlanner.SessionsEo(10, 0, false, 0));
        checksV084(plan);
    }

    @Test
    @DisplayName("Sessions — Prolonger un GRANT à 4 restantes, sans ajout : 4 sur la nouvelle ligne, rien de perdu, l'ancienne n'est pas touchée")
    void prolongerConserveLeSolde() {
        AccessOverride p = grantIntegral(T.minus(JOUR), T.plus(JOUR.multipliedBy(10)), 10, 4);
        Plan plan = AccessOverridePlanner.planifier(List.of(p), List.of(new Decision(
                ModuleAccess.INTEGRAL, AccessOverrideType.GRANT, T, T.plus(JOUR.multipliedBy(40)))), ctx);

        AccessOverride courant = couvrantMaintenant(plan.aInserer());
        assertThat(courant.getRealtimeEoSessionsRemaining()).isEqualTo(4);
        assertThat(courant.getRealtimeEoSessionsGranted()).isEqualTo(10);
        assertThat(plan.sessionsEo()).isEqualTo(new AccessOverridePlanner.SessionsEo(0, 4, true, 0));
        // La remise à 0 de l'ancienne se fait à l'écriture, jamais dans le planner (aperçu).
        assertThat(p.getRealtimeEoSessionsRemaining()).isEqualTo(4);
        checksV084(plan);
    }

    @Test
    @DisplayName("Sessions — Donner Intégral +10 sur un GRANT actif à 4 : cumul 14, granted cohérent (10 + 10)")
    void donnerMaintenantSurGrantActif() {
        AccessOverride p = grantIntegral(T.minus(JOUR), T.plus(JOUR.multipliedBy(10)), 10, 4);
        Plan plan = AccessOverridePlanner.planifier(List.of(p), List.of(new Decision(
                ModuleAccess.INTEGRAL, AccessOverrideType.GRANT, T, T.plus(JOUR.multipliedBy(40)), 10)), ctx);

        AccessOverride courant = couvrantMaintenant(plan.aInserer());
        assertThat(courant.getRealtimeEoSessionsRemaining()).isEqualTo(14);
        assertThat(courant.getRealtimeEoSessionsGranted()).isEqualTo(20);
        assertThat(plan.sessionsEo()).isEqualTo(new AccessOverridePlanner.SessionsEo(10, 4, true, 0));
        checksV084(plan);
    }

    @Test
    @DisplayName("Sessions — Donner programmé par-dessus un GRANT en cours : la tête garde le solde, le futur a son N")
    void donnerProgrammeGardeLeSoldeSurLaTeteEtNPourLeFutur() {
        AccessOverride p = grantIntegral(T.minus(JOUR), T.plus(JOUR.multipliedBy(30)), 10, 4);
        Instant s = T.plus(JOUR.multipliedBy(10));
        Plan plan = AccessOverridePlanner.planifier(List.of(p), List.of(new Decision(
                ModuleAccess.INTEGRAL, AccessOverrideType.GRANT, s, T.plus(JOUR.multipliedBy(60)), 6)), ctx);

        AccessOverride tete = couvrantMaintenant(plan.aInserer());
        assertThat(tete.getReplacesOverrideId()).isEqualTo(p.getId());
        assertThat(tete.getRealtimeEoSessionsRemaining()).isEqualTo(4);
        assertThat(tete.getRealtimeEoSessionsGranted()).isEqualTo(10);
        AccessOverride futur = plan.aInserer().stream().filter(o -> o.getStartsAt().equals(s)).findFirst().orElseThrow();
        assertThat(futur.getRealtimeEoSessionsRemaining()).isEqualTo(6);
        assertThat(futur.getRealtimeEoSessionsGranted()).isEqualTo(6);
        assertThat(plan.sessionsEo()).isEqualTo(new AccessOverridePlanner.SessionsEo(6, 4, false, 0));
        checksV084(plan);
    }

    @Test
    @DisplayName("Sessions — Raccourcir : la tête qui couvre maintenant garde le solde jusqu'à la nouvelle fin")
    void raccourcirConserveLeSolde() {
        AccessOverride p = grantIntegral(T.minus(JOUR), T.plus(JOUR.multipliedBy(30)), 10, 4);
        Plan plan = AccessOverridePlanner.planifier(List.of(p), List.of(new Decision(
                ModuleAccess.INTEGRAL, AccessOverrideType.REVOKE, T.plus(JOUR.multipliedBy(5)), null)), ctx);

        AccessOverride tete = couvrantMaintenant(plan.aInserer());
        assertThat(tete.getEndsAt()).isEqualTo(T.plus(JOUR.multipliedBy(5)));
        assertThat(tete.getRealtimeEoSessionsRemaining()).isEqualTo(4);
        assertThat(plan.sessionsEo()).isEqualTo(new AccessOverridePlanner.SessionsEo(0, 4, false, 0));
        checksV084(plan);
    }

    @Test
    @DisplayName("Sessions — Terminer : la tête ne couvre plus maintenant, le solde est perdu (annoncé)")
    void terminerPerdLeSolde() {
        AccessOverride p = grantIntegral(T.minus(JOUR), T.plus(JOUR.multipliedBy(30)), 10, 4);
        Plan plan = AccessOverridePlanner.planifier(List.of(p), List.of(new Decision(
                ModuleAccess.INTEGRAL, AccessOverrideType.REVOKE, T, null)), ctx);

        assertThat(plan.aInserer()).allMatch(o -> o.getRealtimeEoSessionsRemaining() == 0);
        assertThat(plan.sessionsEo()).isEqualTo(new AccessOverridePlanner.SessionsEo(0, 0, false, 4));
        checksV084(plan);
    }

    @Test
    @DisplayName("Sessions — Corriger Intégral → Civique : le solde du GRANT Intégral est perdu, rien sur Civique")
    void correctionIntegralVersCiviquePerdLeSolde() {
        AccessOverride p = grantIntegral(T.minus(JOUR), T.plus(JOUR.multipliedBy(30)), 10, 4);
        Plan plan = AccessOverridePlanner.planifier(List.of(p), List.of(
                new Decision(ModuleAccess.INTEGRAL, AccessOverrideType.REVOKE, T, null),
                new Decision(ModuleAccess.CIVIQUE, AccessOverrideType.GRANT, T, T.plus(JOUR.multipliedBy(30)))), ctx);

        assertThat(plan.aInserer()).allMatch(o -> o.getRealtimeEoSessionsRemaining() == 0);
        assertThat(plan.sessionsEo().perdues()).isEqualTo(4);
        assertThat(plan.sessionsEo().offertes()).isZero();
        checksV084(plan);
    }

    @Test
    @DisplayName("Sessions — Terminer un GRANT programmé : son N est perdu ; un GRANT futur tronqué garde son solde sur sa tête")
    void grantFutur() {
        Instant debut = T.plus(JOUR.multipliedBy(5));
        AccessOverride futur = grantIntegral(debut, T.plus(JOUR.multipliedBy(30)), 6, 6);
        Plan termine = AccessOverridePlanner.planifier(List.of(futur), List.of(new Decision(
                ModuleAccess.INTEGRAL, AccessOverrideType.REVOKE, T, null)), ctx);
        assertThat(termine.sessionsEo().perdues()).isEqualTo(6);

        Plan tronque = AccessOverridePlanner.planifier(List.of(futur), List.of(new Decision(
                ModuleAccess.INTEGRAL, AccessOverrideType.REVOKE, T.plus(JOUR.multipliedBy(10)), null)), ctx);
        AccessOverride tete = tronque.aInserer().stream()
                .filter(o -> futur.getId().equals(o.getReplacesOverrideId())).findFirst().orElseThrow();
        assertThat(tete.getRealtimeEoSessionsRemaining()).isEqualTo(6);
        assertThat(tronque.sessionsEo()).isEqualTo(new AccessOverridePlanner.SessionsEo(0, 6, false, 0));
        checksV084(tronque);
    }

    @Test
    @DisplayName("Sessions — une copie hérite de l'allocation, jamais d'un solde qui ne couvre pas maintenant")
    void copiesSansSolde() {
        AccessOverride revoke = existante(ModuleAccess.INTEGRAL, AccessOverrideType.REVOKE, T.minus(JOUR), null);
        Plan plan = AccessOverridePlanner.planifier(List.of(revoke), List.of(new Decision(
                ModuleAccess.INTEGRAL, AccessOverrideType.GRANT, T, T.plus(JOUR.multipliedBy(10)), 3)), ctx);

        assertThat(plan.aInserer()).filteredOn(o -> o.getType() == AccessOverrideType.REVOKE)
                .hasSize(2)
                .allMatch(o -> o.getRealtimeEoSessionsGranted() == 0 && o.getRealtimeEoSessionsRemaining() == 0);
        assertThat(couvrantMaintenant(plan.aInserer()).getRealtimeEoSessionsRemaining()).isEqualTo(3);
        checksV084(plan);
    }
}

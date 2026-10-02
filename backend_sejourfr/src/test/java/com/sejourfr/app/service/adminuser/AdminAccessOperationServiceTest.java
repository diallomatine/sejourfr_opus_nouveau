package com.sejourfr.app.service.adminuser;

import com.sejourfr.app.dto.AdminAccessOperationRequest;
import com.sejourfr.app.dto.AdminAccessOperationResponse;
import com.sejourfr.app.entity.AccessOverride;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.AccessOverrideType;
import com.sejourfr.app.enums.AdminAccessOperationType;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PlanPurchaseType;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AccessOverrideManager;
import com.sejourfr.app.manager.AdminAccessOperationManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.mapper.AdminUserMapper;
import com.sejourfr.app.service.SubscriptionService;
import com.sejourfr.app.util.DateMetierParis;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * Validations et préconditions des actions admin (spec §6, §11 cas 13 ; GO §5,
 * §14) — sans base. Les écritures réelles, la contrainte d'exclusion et
 * l'atomicité sont couvertes par {@code AdminUserControllerIT} et
 * {@code AdminAccessAtomiciteIT}.
 */
class AdminAccessOperationServiceTest {

    private final UUID userId = UUID.randomUUID();
    private final UUID adminId = UUID.randomUUID();

    private UserManager userManager;
    private SubscriptionService subscriptionService;
    private AccessOverrideManager overrideManager;
    private AdminAccessOperationManager operationManager;
    private AdminAccessOperationService service;

    private SubscriptionService.DonneesAcces donnees = SubscriptionService.DonneesAcces.VIDE;

    @BeforeEach
    void setUp() {
        userManager = mock(UserManager.class);
        subscriptionService = mock(SubscriptionService.class);
        overrideManager = mock(AccessOverrideManager.class);
        operationManager = mock(AdminAccessOperationManager.class);
        User u = new User();
        u.setId(userId);
        when(userManager.findById(userId)).thenReturn(Optional.of(u));
        when(subscriptionService.charger(userId)).thenAnswer(i -> donnees);
        service = new AdminAccessOperationService(userManager, subscriptionService, overrideManager,
                operationManager, new AdminUserMapper(), new com.sejourfr.app.config.RealtimeProperties());
    }

    private static LocalDate aujourdhui() {
        return DateMetierParis.aujourdhui(Instant.now());
    }

    private AdminAccessOperationRequest req(AdminAccessOperationType op, ModuleAccess p, ModuleAccess from,
                                            LocalDate debut, LocalDate fin, String motif, boolean dryRun) {
        return new AdminAccessOperationRequest(op, p, from, debut, fin, motif, dryRun,
                dryRun ? null : VersionAcces.de(donnees), null);
    }

    private static UserSubscription achat(ModuleAccess m, int joursRestants) {
        Plan plan = new Plan();
        plan.setCode(m.name() + "_PASS");
        plan.setModuleAccess(m);
        plan.setPurchaseType(PlanPurchaseType.ONE_TIME);
        UserSubscription s = new UserSubscription();
        s.setId(UUID.randomUUID());
        s.setPlan(plan);
        s.setStatus(SubscriptionStatus.ACTIVE);
        s.setSource(SubscriptionSource.STRIPE);
        s.setStartsAt(Instant.now().minus(1, ChronoUnit.DAYS));
        s.setPurchasedAt(s.getStartsAt());
        s.setEndsAt(Instant.now().plus(joursRestants, ChronoUnit.DAYS));
        return s;
    }

    private int statut(Runnable r) {
        try {
            r.run();
            return 200;
        } catch (ResponseStatusException e) {
            return e.getStatusCode().value();
        }
    }

    // ----------------------------------------------------------- 400 (cas 13)

    @Test
    @DisplayName("Cas 13 — fin < début, motif vide ou trop court, produit NONE, fin passée : 400")
    void validations400() {
        LocalDate j = aujourdhui();
        assertThat(statut(() -> service.executer(userId, adminId, req(AdminAccessOperationType.GRANT,
                ModuleAccess.INTEGRAL, null, j.plusDays(10), j.plusDays(5), "Motif valide", true)))).isEqualTo(400);
        assertThat(statut(() -> service.executer(userId, adminId, req(AdminAccessOperationType.GRANT,
                ModuleAccess.INTEGRAL, null, null, j.plusDays(5), "  a ", true)))).isEqualTo(400);
        assertThat(statut(() -> service.executer(userId, adminId, req(AdminAccessOperationType.GRANT,
                ModuleAccess.NONE, null, null, j.plusDays(5), "Motif valide", true)))).isEqualTo(400);
        assertThat(statut(() -> service.executer(userId, adminId, req(AdminAccessOperationType.GRANT,
                ModuleAccess.CIVIQUE, null, null, j.minusDays(1), "Motif valide", true)))).isEqualTo(400);
        assertThat(statut(() -> service.executer(userId, adminId, req(AdminAccessOperationType.GRANT,
                ModuleAccess.CIVIQUE, null, j.minusDays(1), j.plusDays(3), "Motif valide", true)))).isEqualTo(400);
        assertThat(statut(() -> service.executer(userId, adminId, req(AdminAccessOperationType.GRANT,
                ModuleAccess.CIVIQUE, null, null, null, "Motif valide", true)))).isEqualTo(400);
    }

    @Test
    @DisplayName("Correction de produit sans produit d'origine, ou vers le même produit : 400")
    void correctionMalFormee() {
        donnees = new SubscriptionService.DonneesAcces(List.of(achat(ModuleAccess.CIVIQUE, 30)), List.of());
        LocalDate fin = aujourdhui().plusDays(30);
        assertThat(statut(() -> service.executer(userId, adminId, req(AdminAccessOperationType.CORRECT_PRODUCT,
                ModuleAccess.INTEGRAL, null, null, fin, "Erreur de produit", true)))).isEqualTo(400);
        assertThat(statut(() -> service.executer(userId, adminId, req(AdminAccessOperationType.CORRECT_PRODUCT,
                ModuleAccess.CIVIQUE, ModuleAccess.CIVIQUE, null, fin, "Erreur de produit", true)))).isEqualTo(400);
    }

    @Test
    @DisplayName("Écrire sans état attendu : 400, rien n'est écrit")
    void ecrireSansVersion() {
        AdminAccessOperationRequest r = new AdminAccessOperationRequest(AdminAccessOperationType.GRANT,
                ModuleAccess.INTEGRAL, null, null, aujourdhui().plusDays(5), "Motif valide", false, null, null);
        assertThat(statut(() -> service.executer(userId, adminId, r))).isEqualTo(400);
        verifyNoInteractions(operationManager);
    }

    // ------------------------------------------------------------------- 409

    @Test
    @DisplayName("GO §5 — « Terminer Civique » isolé sous un Intégral actif : 409")
    void terminerCiviqueSousIntegral() {
        donnees = new SubscriptionService.DonneesAcces(
                List.of(achat(ModuleAccess.CIVIQUE, 60), achat(ModuleAccess.INTEGRAL, 20)), List.of());
        assertThatThrownBy(() -> service.executer(userId, adminId, req(AdminAccessOperationType.END,
                ModuleAccess.CIVIQUE, null, null, null, "Fin demandée", false)))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("Civique reste accessible via Intégral");
        verifyNoInteractions(operationManager);
    }

    @Test
    @DisplayName("GO §5 — mais une CORRECTION Civique → Intégral n'est pas refusée pour autant")
    void correctionCiviqueVersIntegralAcceptee() {
        donnees = new SubscriptionService.DonneesAcces(
                List.of(achat(ModuleAccess.CIVIQUE, 60), achat(ModuleAccess.INTEGRAL, 20)), List.of());
        AdminAccessOperationResponse r = service.executer(userId, adminId, req(AdminAccessOperationType.CORRECT_PRODUCT,
                ModuleAccess.INTEGRAL, ModuleAccess.CIVIQUE, null, aujourdhui().plusDays(60), "Erreur de produit", true));
        assertThat(r.confirmationRequired()).isTrue();
        assertThat(r.preview()).startsWith("Vous allez retirer l'accès Civique et donner l'accès Intégral jusqu'au");
    }

    @Test
    @DisplayName("Préconditions : Prolonger sans accès, Réactiver un actif, Corriger un produit inactif : 409")
    void preconditions409() {
        LocalDate fin = aujourdhui().plusDays(30);
        assertThat(statut(() -> service.executer(userId, adminId, req(AdminAccessOperationType.EXTEND,
                ModuleAccess.INTEGRAL, null, null, fin, "Motif valide", true)))).isEqualTo(409);
        assertThat(statut(() -> service.executer(userId, adminId, req(AdminAccessOperationType.CORRECT_PRODUCT,
                ModuleAccess.INTEGRAL, ModuleAccess.CIVIQUE, null, fin, "Motif valide", true)))).isEqualTo(409);
        assertThat(statut(() -> service.executer(userId, adminId, req(AdminAccessOperationType.END,
                ModuleAccess.INTEGRAL, null, null, null, "Motif valide", true)))).isEqualTo(409);
        donnees = new SubscriptionService.DonneesAcces(List.of(achat(ModuleAccess.INTEGRAL, 20)), List.of());
        assertThat(statut(() -> service.executer(userId, adminId, req(AdminAccessOperationType.REACTIVATE,
                ModuleAccess.INTEGRAL, null, null, fin, "Motif valide", true)))).isEqualTo(409);
    }

    @Test
    @DisplayName("Prolonger vers une date plus proche / Raccourcir vers une date plus lointaine : 400 explicite")
    void sensDesDates() {
        donnees = new SubscriptionService.DonneesAcces(List.of(achat(ModuleAccess.INTEGRAL, 20)), List.of());
        assertThat(statut(() -> service.executer(userId, adminId, req(AdminAccessOperationType.EXTEND,
                ModuleAccess.INTEGRAL, null, null, aujourdhui().plusDays(5), "Motif valide", true)))).isEqualTo(400);
        assertThat(statut(() -> service.executer(userId, adminId, req(AdminAccessOperationType.SHORTEN,
                ModuleAccess.INTEGRAL, null, null, aujourdhui().plusDays(40), "Motif valide", true)))).isEqualTo(400);
    }

    @Test
    @DisplayName("G-11 — état attendu périmé : 409, rien n'est écrit")
    void etatPerime() {
        AdminAccessOperationRequest r = new AdminAccessOperationRequest(AdminAccessOperationType.GRANT,
                ModuleAccess.INTEGRAL, null, null, aujourdhui().plusDays(5), "Motif valide", false, "deadbeefdeadbeef", null);
        assertThatThrownBy(() -> service.executer(userId, adminId, r))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("a changé");
        verify(overrideManager, never()).saveAndFlush(any());
        verifyNoInteractions(operationManager);
    }

    @Test
    @DisplayName("Cas 14 — utilisateur inexistant : 404")
    void utilisateurInexistant() {
        UUID inconnu = UUID.randomUUID();
        when(userManager.findById(inconnu)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.executer(inconnu, adminId, req(AdminAccessOperationType.GRANT,
                ModuleAccess.INTEGRAL, null, null, aujourdhui().plusDays(5), "Motif valide", true)))
                .isInstanceOf(NotFoundException.class);
    }

    // ---------------------------------------------------------------- dryRun

    @Test
    @DisplayName("dryRun : aperçu et état résultant calculés serveur, rien n'est écrit ni verrouillé")
    void dryRunNEcritRien() {
        AdminAccessOperationResponse r = service.executer(userId, adminId, req(AdminAccessOperationType.GRANT,
                ModuleAccess.INTEGRAL, null, null, LocalDate.of(2099, 10, 31), "Geste commercial", true));

        assertThat(r.dryRun()).isTrue();
        assertThat(r.operationId()).isNull();
        assertThat(r.preview()).isEqualTo("Vous allez donner l'accès Intégral dès maintenant, jusqu'au 31/10/2099 inclus. "
                + "Cet accès manuel n'ajoute pas actuellement de sessions EO temps réel.");
        assertThat(r.effectiveAccess().effectiveProduct()).isEqualTo(ModuleAccess.INTEGRAL);
        assertThat(r.effectiveAccess().openModulesLabel()).isEqualTo("TCF + Civique");
        assertThat(r.changes()).containsExactly("Intégral : Aucun → Actif jusqu'au 31/10/2099 inclus");
        verifyNoInteractions(operationManager);
        verify(overrideManager, never()).verrouiller(any());
        verify(overrideManager, never()).saveAndFlush(any());
    }

    @Test
    @DisplayName("Écriture : journal, supersessions puis insertions, sous verrou ; version renvoyée = nouvel état")
    void ecritureOrdonnee() {
        AccessOverride revokeOuvert = new AccessOverride();
        revokeOuvert.setId(UUID.randomUUID());
        revokeOuvert.setUserId(userId);
        revokeOuvert.setProduct(ModuleAccess.CIVIQUE);
        revokeOuvert.setType(AccessOverrideType.REVOKE);
        revokeOuvert.setStartsAt(Instant.now().minus(3, ChronoUnit.DAYS));
        revokeOuvert.setDecidedAt(revokeOuvert.getStartsAt());
        revokeOuvert.setReason("Fraude");
        revokeOuvert.setCreatedBy(adminId);
        donnees = new SubscriptionService.DonneesAcces(List.of(), List.of(revokeOuvert));

        AdminAccessOperationResponse r = service.executer(userId, adminId, req(AdminAccessOperationType.REACTIVATE,
                ModuleAccess.CIVIQUE, null, null, aujourdhui().plusDays(10), "Réactivation", false));

        org.mockito.InOrder ordre = org.mockito.Mockito.inOrder(overrideManager, operationManager);
        ordre.verify(overrideManager).verrouiller(userId);
        ordre.verify(operationManager).saveAndFlush(any());
        ordre.verify(overrideManager).saveAndFlush(revokeOuvert);
        assertThat(revokeOuvert.getSupersededAt()).isNotNull();
        assertThat(revokeOuvert.getSupersededByOperationId()).isEqualTo(r.operationId());
        assertThat(r.accessVersion()).isNotEqualTo(VersionAcces.de(new SubscriptionService.DonneesAcces(
                List.of(), List.of())));
    }

    // ------------------------------------------------------ D-34 (révise D-02)

    private AccessOverride revokeOuvert(ModuleAccess p) {
        AccessOverride o = new AccessOverride();
        o.setId(UUID.randomUUID());
        o.setUserId(userId);
        o.setProduct(p);
        o.setType(AccessOverrideType.REVOKE);
        o.setStartsAt(Instant.now().minus(1, ChronoUnit.HOURS));
        o.setDecidedAt(o.getStartsAt());
        o.setReason("Erreur");
        o.setCreatedBy(adminId);
        return o;
    }

    @Test
    @DisplayName("D-34 — achat révoqué : la fiche propose la fin de l'ACHAT comme fin par défaut de « Réactiver »")
    void reactiverProposeLaFinDeLAchat() {
        UserSubscription civique = achat(ModuleAccess.CIVIQUE, 40);
        donnees = new SubscriptionService.DonneesAcces(List.of(civique), List.of(revokeOuvert(ModuleAccess.CIVIQUE)));
        Instant now = Instant.now();

        var acces = service.accesses(AdminAccessOperationService.etats(donnees.achats(), donnees.decisions(), now),
                donnees, now);
        var civiqueDto = acces.stream().filter(a -> a.product() == ModuleAccess.CIVIQUE).findFirst().orElseThrow();

        assertThat(civiqueDto.status()).isEqualTo(com.sejourfr.app.enums.ProductAccessStatus.REVOKED);
        assertThat(civiqueDto.defaultEndDateInclusive()).isEqualTo(DateMetierParis.aujourdhui(civique.getEndsAt()));
    }

    @Test
    @DisplayName("D-34 — Réactiver jusqu'AVANT la fin de l'achat : l'aperçu dit que l'achat restera révoqué ensuite")
    void reactiverAvantLaFinSignaleLAchatRevoque() {
        donnees = new SubscriptionService.DonneesAcces(List.of(achat(ModuleAccess.CIVIQUE, 40)),
                List.of(revokeOuvert(ModuleAccess.CIVIQUE)));
        LocalDate fin = aujourdhui().plusDays(10);

        AdminAccessOperationResponse r = service.executer(userId, adminId, req(AdminAccessOperationType.REACTIVATE,
                ModuleAccess.CIVIQUE, null, null, fin, "Réactivation", true));

        assertThat(r.preview()).startsWith("Vous allez réactiver l'accès Civique dès maintenant, jusqu'au ")
                .endsWith(" Attention : l'achat Civique révoqué ne sera pas rétabli. À partir du "
                        + DateMetierParis.jour(fin.plusDays(1)) + ", l'accès Civique sera de nouveau fermé.");
    }

    @Test
    @DisplayName("D-34 — Réactiver jusqu'à la fin de l'achat (ou au-delà), ou sans achat révoqué : aucun avertissement")
    void reactiverJusquALaFinNeSignaleRien() {
        UserSubscription civique = achat(ModuleAccess.CIVIQUE, 40);
        donnees = new SubscriptionService.DonneesAcces(List.of(civique), List.of(revokeOuvert(ModuleAccess.CIVIQUE)));
        LocalDate finAchat = DateMetierParis.aujourdhui(civique.getEndsAt());

        AdminAccessOperationResponse r = service.executer(userId, adminId, req(AdminAccessOperationType.REACTIVATE,
                ModuleAccess.CIVIQUE, null, null, finAchat, "Réactivation", true));
        assertThat(r.preview()).doesNotContain("Attention");

        donnees = new SubscriptionService.DonneesAcces(List.of(), List.of(revokeOuvert(ModuleAccess.CIVIQUE)));
        AdminAccessOperationResponse sansAchat = service.executer(userId, adminId, req(
                AdminAccessOperationType.REACTIVATE, ModuleAccess.CIVIQUE, null, null, aujourdhui().plusDays(5),
                "Réactivation", true));
        assertThat(sansAchat.preview()).doesNotContain("Attention");
    }

    // --------------------------------------------- sessions EO temps réel (V084)

    private AdminAccessOperationRequest reqSessions(AdminAccessOperationType op, ModuleAccess p, ModuleAccess from,
                                                    LocalDate fin, Integer sessions, boolean dryRun) {
        return new AdminAccessOperationRequest(op, p, from, null, fin, "Geste support", dryRun,
                dryRun ? null : VersionAcces.de(donnees), sessions);
    }

    private AccessOverride grantIntegralActif(int granted, int remaining) {
        AccessOverride o = new AccessOverride();
        o.setId(UUID.randomUUID());
        o.setUserId(userId);
        o.setProduct(ModuleAccess.INTEGRAL);
        o.setType(AccessOverrideType.GRANT);
        o.setStartsAt(Instant.now().minus(1, ChronoUnit.DAYS));
        o.setEndsAt(Instant.now().plus(10, ChronoUnit.DAYS));
        o.setDecidedAt(o.getStartsAt());
        o.setReason("Geste");
        o.setCreatedBy(adminId);
        o.setOperationId(UUID.randomUUID());
        o.setRealtimeEoSessionsGranted(granted);
        o.setRealtimeEoSessionsRemaining(remaining);
        return o;
    }

    @Test
    @DisplayName("Sessions EO — 400 : négatif, au-delà du plafond (50), sur Prolonger / Raccourcir / Terminer, sur Civique")
    void sessionsEo400() {
        LocalDate fin = aujourdhui().plusDays(20);
        assertThat(statut(() -> service.executer(userId, adminId, reqSessions(AdminAccessOperationType.GRANT,
                ModuleAccess.INTEGRAL, null, fin, -1, true)))).isEqualTo(400);
        assertThat(statut(() -> service.executer(userId, adminId, reqSessions(AdminAccessOperationType.GRANT,
                ModuleAccess.INTEGRAL, null, fin, 51, true)))).isEqualTo(400);
        assertThat(statut(() -> service.executer(userId, adminId, reqSessions(AdminAccessOperationType.GRANT,
                ModuleAccess.INTEGRAL, null, fin, 50, true)))).isEqualTo(200);
        assertThat(statut(() -> service.executer(userId, adminId, reqSessions(AdminAccessOperationType.GRANT,
                ModuleAccess.CIVIQUE, null, fin, 5, true)))).isEqualTo(400);
        assertThat(statut(() -> service.executer(userId, adminId, reqSessions(AdminAccessOperationType.CORRECT_PRODUCT,
                ModuleAccess.CIVIQUE, ModuleAccess.INTEGRAL, fin, 5, true)))).isEqualTo(400);
        donnees = new SubscriptionService.DonneesAcces(List.of(), List.of(grantIntegralActif(10, 4)));
        for (AdminAccessOperationType op : List.of(AdminAccessOperationType.EXTEND,
                AdminAccessOperationType.SHORTEN, AdminAccessOperationType.END)) {
            assertThatThrownBy(() -> service.executer(userId, adminId, reqSessions(op, ModuleAccess.INTEGRAL, null,
                    op == AdminAccessOperationType.SHORTEN ? aujourdhui().plusDays(3) : fin, 5, true)))
                    .isInstanceOf(ResponseStatusException.class)
                    .hasMessageContaining("ne s'offrent qu'en donnant, réactivant ou corrigeant vers un accès Intégral");
        }
        // 0 explicite = absent : accepté partout.
        assertThat(statut(() -> service.executer(userId, adminId, reqSessions(AdminAccessOperationType.END,
                ModuleAccess.INTEGRAL, null, null, 0, true)))).isEqualTo(200);
    }

    @Test
    @DisplayName("Sessions EO — le plafond vient de la configuration")
    void sessionsEoPlafondConfigurable() {
        com.sejourfr.app.config.RealtimeProperties props = new com.sejourfr.app.config.RealtimeProperties();
        props.setAdminGrantMaxSessions(5);
        AdminAccessOperationService bas = new AdminAccessOperationService(userManager, subscriptionService,
                overrideManager, operationManager, new AdminUserMapper(), props);
        LocalDate fin = aujourdhui().plusDays(20);
        assertThat(statut(() -> bas.executer(userId, adminId, reqSessions(AdminAccessOperationType.GRANT,
                ModuleAccess.INTEGRAL, null, fin, 6, true)))).isEqualTo(400);
        assertThat(statut(() -> bas.executer(userId, adminId, reqSessions(AdminAccessOperationType.GRANT,
                ModuleAccess.INTEGRAL, null, fin, 5, true)))).isEqualTo(200);
    }

    @Test
    @DisplayName("Sessions EO — aperçu du cumul : « 4 sessions restantes + 10 offertes → 14 sessions disponibles », sans 409")
    void apercuCumul() {
        donnees = new SubscriptionService.DonneesAcces(List.of(), List.of(grantIntegralActif(10, 4)));
        AdminAccessOperationResponse r = service.executer(userId, adminId, reqSessions(AdminAccessOperationType.GRANT,
                ModuleAccess.INTEGRAL, null, aujourdhui().plusDays(40), 10, true));

        assertThat(r.preview()).contains("4 sessions restantes + 10 offertes → 14 sessions disponibles");
        var integral = r.accesses().stream().filter(a -> a.product() == ModuleAccess.INTEGRAL).findFirst().orElseThrow();
        assertThat(integral.realtimeEoSessions().remaining()).isEqualTo(14);
        assertThat(integral.realtimeEoSessions().grantRemaining()).isEqualTo(14);
        assertThat(integral.realtimeEoSessions().grantGranted()).isEqualTo(20);
        assertThat(r.changes()).contains("Intégral — sessions EO temps réel : 4 → 14");
    }

    @Test
    @DisplayName("Sessions EO — aperçus : sessions offertes, conservées (Prolonger), perdues (Terminer), info quand 0")
    void apercusSessions() {
        LocalDate fin = aujourdhui().plusDays(40);
        assertThat(service.executer(userId, adminId, reqSessions(AdminAccessOperationType.GRANT,
                ModuleAccess.INTEGRAL, null, fin, 10, true)).preview())
                .contains("Cet accès manuel offre 10 sessions EO temps réel.");
        assertThat(service.executer(userId, adminId, reqSessions(AdminAccessOperationType.GRANT,
                ModuleAccess.INTEGRAL, null, fin, null, true)).preview())
                .contains(AdminUserMapper.INFO_SANS_SESSION_EO);
        assertThat(service.executer(userId, adminId, reqSessions(AdminAccessOperationType.GRANT,
                ModuleAccess.CIVIQUE, null, fin, null, true)).preview())
                .doesNotContain("session");

        donnees = new SubscriptionService.DonneesAcces(List.of(), List.of(grantIntegralActif(10, 4)));
        assertThat(service.executer(userId, adminId, reqSessions(AdminAccessOperationType.EXTEND,
                ModuleAccess.INTEGRAL, null, fin, null, true)).preview())
                .contains("Les 4 sessions EO temps réel restantes de l'accès manuel sont conservées.");
        assertThat(service.executer(userId, adminId, reqSessions(AdminAccessOperationType.END,
                ModuleAccess.INTEGRAL, null, null, null, true)).preview())
                .isEqualTo("Cet utilisateur perdra immédiatement son accès Intégral. Les 4 sessions EO temps réel "
                        + "restantes de l'accès manuel seront perdues. Continuer ?");
    }

    @Test
    @DisplayName("Sessions EO — Prolonger un Intégral ACHETÉ : aucune session transférée, l'aperçu dit jusqu'à quand restent celles de l'achat")
    void prolongerAchatGardeSesSessions() {
        UserSubscription integral = achat(ModuleAccess.INTEGRAL, 5);
        integral.getPlan().setRealtimeEoSessions(15);
        integral.setRealtimeEoSessionsRemaining(3);
        donnees = new SubscriptionService.DonneesAcces(List.of(integral), List.of());
        AdminAccessOperationResponse r = service.executer(userId, adminId, reqSessions(AdminAccessOperationType.EXTEND,
                ModuleAccess.INTEGRAL, null, aujourdhui().plusDays(40), null, true));

        assertThat(r.preview()).contains(AdminUserMapper.INFO_SANS_SESSION_EO)
                .contains("Les 3 sessions EO temps réel de l'achat restent utilisables jusqu'au");
        var dto = r.accesses().stream().filter(a -> a.product() == ModuleAccess.INTEGRAL).findFirst().orElseThrow()
                .realtimeEoSessions();
        assertThat(dto.purchaseRemaining()).isEqualTo(3);
        assertThat(dto.grantGranted()).isZero();
        assertThat(dto.grantRemaining()).isZero();
        assertThat(dto.remaining()).isEqualTo(3);
        assertThat(dto.info()).isEqualTo(AdminUserMapper.INFO_SANS_SESSION_EO);
        assertThat(integral.getRealtimeEoSessionsRemaining()).isEqualTo(3);
    }

    @Test
    @DisplayName("Sessions EO — écriture : la ligne remplacée est remise à 0 avec sa supersession, la nouvelle porte le report")
    void ecritureRemetLAncienneAZero() {
        AccessOverride p = grantIntegralActif(10, 4);
        donnees = new SubscriptionService.DonneesAcces(List.of(), List.of(p));
        when(operationManager.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));
        when(overrideManager.saveAndFlush(any())).thenAnswer(i -> i.getArgument(0));

        service.executer(userId, adminId, reqSessions(AdminAccessOperationType.EXTEND,
                ModuleAccess.INTEGRAL, null, aujourdhui().plusDays(40), null, false));

        assertThat(p.getSupersededAt()).isNotNull();
        assertThat(p.getRealtimeEoSessionsRemaining()).isZero();
        org.mockito.ArgumentCaptor<AccessOverride> ecrits = org.mockito.ArgumentCaptor.forClass(AccessOverride.class);
        verify(overrideManager, org.mockito.Mockito.atLeastOnce()).saveAndFlush(ecrits.capture());
        assertThat(ecrits.getAllValues()).filteredOn(o -> o.getSupersededAt() == null && o.couvre(Instant.now()))
                .singleElement()
                .satisfies(o -> {
                    assertThat(o.getRealtimeEoSessionsRemaining()).isEqualTo(4);
                    assertThat(o.getRealtimeEoSessionsGranted()).isEqualTo(10);
                });
    }

    @Test
    @DisplayName("Sessions EO — fiche : la carte Civique n'a pas de bloc, la carte Intégral a la phrase info si 0 offerte")
    void ficheSessions() {
        donnees = new SubscriptionService.DonneesAcces(List.of(), List.of(grantIntegralActif(0, 0)));
        Instant now = Instant.now();
        var acces = service.accesses(AdminAccessOperationService.etats(donnees.achats(), donnees.decisions(), now),
                donnees, now);
        var civique = acces.stream().filter(a -> a.product() == ModuleAccess.CIVIQUE).findFirst().orElseThrow();
        var integral = acces.stream().filter(a -> a.product() == ModuleAccess.INTEGRAL).findFirst().orElseThrow();
        assertThat(civique.realtimeEoSessions()).isNull();
        assertThat(integral.realtimeEoSessions().info())
                .isEqualTo("Cet accès manuel n'ajoute pas actuellement de sessions EO temps réel.");

        donnees = new SubscriptionService.DonneesAcces(List.of(), List.of(grantIntegralActif(10, 4)));
        var avecSessions = service.accesses(AdminAccessOperationService.etats(donnees.achats(), donnees.decisions(), now),
                donnees, now).stream().filter(a -> a.product() == ModuleAccess.INTEGRAL).findFirst().orElseThrow()
                .realtimeEoSessions();
        assertThat(avecSessions.info()).isNull();
        assertThat(avecSessions.label()).isEqualTo("4 sessions restantes — accès manuel : 4 sur 10");
        assertThat(avecSessions.purchaseRemaining()).isNull();
    }
}

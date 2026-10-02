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
                operationManager, new AdminUserMapper());
    }

    private static LocalDate aujourdhui() {
        return DateMetierParis.aujourdhui(Instant.now());
    }

    private AdminAccessOperationRequest req(AdminAccessOperationType op, ModuleAccess p, ModuleAccess from,
                                            LocalDate debut, LocalDate fin, String motif, boolean dryRun) {
        return new AdminAccessOperationRequest(op, p, from, debut, fin, motif, dryRun,
                dryRun ? null : VersionAcces.de(donnees));
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
                ModuleAccess.INTEGRAL, null, null, aujourdhui().plusDays(5), "Motif valide", false, null);
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
                ModuleAccess.INTEGRAL, null, null, aujourdhui().plusDays(5), "Motif valide", false, "deadbeefdeadbeef");
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
        assertThat(r.preview()).isEqualTo("Vous allez donner l'accès Intégral dès maintenant, jusqu'au 31/10/2099 inclus.");
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
}

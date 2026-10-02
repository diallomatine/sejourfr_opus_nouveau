package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.AdminAccessAlertDto;
import com.sejourfr.app.dto.AdminAccessHistoryEntryDto;
import com.sejourfr.app.dto.AdminAccessOperationOptionDto;
import com.sejourfr.app.dto.AdminAccessProductDto;
import com.sejourfr.app.dto.AdminEffectiveAccessDto;
import com.sejourfr.app.dto.AdminUserAccessBadgeDto;
import com.sejourfr.app.dto.AdminUserAccessDto;
import com.sejourfr.app.dto.AdminUserAccountDto;
import com.sejourfr.app.dto.AdminUserCycleDto;
import com.sejourfr.app.dto.AdminUserListItemDto;
import com.sejourfr.app.dto.AdminUserProgressionDto;
import com.sejourfr.app.dto.AdminUserPurchaseDto;
import com.sejourfr.app.entity.AdminAccessOperation;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.AdminAccessOperationType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.PaymentStatus;
import com.sejourfr.app.enums.PlanPurchaseType;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.repository.AdminUserReadRepository;
import com.sejourfr.app.service.access.AccesEffectifResolver;
import com.sejourfr.app.service.access.AccesEffectifResolver.EtatProduit;
import com.sejourfr.app.util.DateMetierParis;
import com.sejourfr.app.util.ReferenceExterne;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * Mapper pur de la console admin « Utilisateurs ». Il reçoit des états DÉJÀ
 * calculés par l'autorité ({@link AccesEffectifResolver}) et n'en dérive que
 * des libellés : aucun accès, statut ni date n'est décidé ici.
 */
@Component
public class AdminUserMapper {

    // ------------------------------------------------------------- libellés

    public String productLabel(ModuleAccess p) {
        if (p == null) return null;
        return switch (p) {
            case CIVIQUE -> "Civique";
            case INTEGRAL -> "Intégral";
            case NONE -> "Aucun";
        };
    }

    public String moduleLabel(Module m) {
        return m == Module.TCF ? "TCF" : "Civique";
    }

    private static List<Module> modulesDe(ModuleAccess p) {
        if (p == null) return List.of();
        return switch (p) {
            case INTEGRAL -> List.of(Module.TCF, Module.CIVIQUE);
            case CIVIQUE -> List.of(Module.CIVIQUE);
            case NONE -> List.of();
        };
    }

    private String modulesLabel(List<Module> modules) {
        if (modules.isEmpty()) return "Aucun";
        return String.join(" + ", modules.stream().map(this::moduleLabel).toList());
    }

    public List<AdminAccessProductDto> products() {
        return AccesEffectifResolver.PRODUITS.stream()
                .map(p -> new AdminAccessProductDto(p, productLabel(p), modulesDe(p), modulesLabel(modulesDe(p))))
                .toList();
    }

    public AdminEffectiveAccessDto effective(ModuleAccess module) {
        List<Module> modules = modulesDe(module);
        return new AdminEffectiveAccessDto(module, productLabel(module), modules, modulesLabel(modules));
    }

    // ---------------------------------------------------------------- accès

    public AdminUserAccessDto access(EtatProduit e, List<AdminAccessOperationType> operations) {
        return new AdminUserAccessDto(
                e.produit(), productLabel(e.produit()),
                e.statut(), e.statut().label(),
                resume(e),
                e.debut(), e.fin(),
                DateMetierParis.finIncluse(e.fin()).orElse(null),
                e.fin() != null ? DateMetierParis.libelleFin(e.fin()) : null,
                e.origine(), e.origine() != null ? e.origine().label() : null,
                e.alertes().stream().map(this::alerte).toList(),
                operations.stream().map(o -> new AdminAccessOperationOptionDto(o, o.label())).toList());
    }

    public AdminUserAccessBadgeDto badge(EtatProduit e) {
        return new AdminUserAccessBadgeDto(e.produit(), productLabel(e.produit()), e.statut(), e.statut().label());
    }

    /** « Actif jusqu'au 31/10/2026 inclus », « Révoqué depuis le 30/09/2026 »… */
    public String resume(EtatProduit e) {
        return switch (e.statut()) {
            case ACTIVE -> e.fin() != null
                    ? "Actif jusqu'au " + DateMetierParis.libelleFin(e.fin())
                    : "Actif (sans date de fin)";
            case SCHEDULED -> "Programmé du " + DateMetierParis.jour(e.debut())
                    + " au " + DateMetierParis.libelleFin(e.fin());
            case REVOKED -> "Révoqué depuis le " + DateMetierParis.jour(e.debut());
            case EXPIRED -> e.fin() != null
                    ? "Expiré depuis le " + DateMetierParis.jour(e.fin())
                    : "Expiré";
            case NONE -> "Aucun";
        };
    }

    public AdminAccessAlertDto alerte(AccesEffectifResolver.Alerte a) {
        String label = switch (a.code()) {
            case ACHAT_REMBOURSE -> "Achat remboursé";
            case ACHAT_PARTIELLEMENT_REMBOURSE -> "Achat partiellement remboursé";
            case REVOCATION_PROGRAMMEE -> "Révocation programmée le " + DateMetierParis.jour(a.date1());
            case ACCES_PROGRAMME -> "Accès programmé du " + DateMetierParis.jour(a.date1())
                    + " au " + DateMetierParis.libelleFin(a.date2());
            case ROUVERT_PAR_ACHAT -> "Accès rouvert par un achat postérieur à la révocation";
            case INCLUS_DANS_INTEGRAL -> "Civique reste ouvert via Intégral";
            case ABONNEMENT_RECURRENT -> "Abonnement récurrent : lecture seule pour les opérations commerciales";
        };
        return new AdminAccessAlertDto(a.code().name(), label);
    }

    // --------------------------------------------------------------- compte

    public String displayName(User u) {
        String first = u.getFirstName() == null ? "" : u.getFirstName().trim();
        String last = u.getLastName() == null ? "" : u.getLastName().trim();
        String full = (first + " " + last).trim();
        return full.isEmpty() ? null : full;
    }

    public String accountStatus(User u) {
        return u.getDeletedAt() != null ? "DELETED" : "ACTIVE";
    }

    public String accountStatusLabel(User u) {
        return u.getDeletedAt() != null ? "Supprimé" : "Actif";
    }

    public AdminUserAccountDto account(User u) {
        return new AdminUserAccountDto(
                u.getId(), u.getEmail(), u.getFirstName(), u.getLastName(), displayName(u),
                u.getCreatedAt(), u.getLastLoginAt(),
                accountStatus(u), accountStatusLabel(u),
                u.getRole(), u.getAuthProvider(), u.isInternal(),
                u.getTargetProcedure(), u.getTargetLevel());
    }

    /**
     * @param prochaineFin la fin la plus proche parmi les produits actifs ({@code null} sinon),
     *                     choisie par le service.
     */
    public AdminUserListItemDto listItem(User u, ModuleAccess module, List<EtatProduit> etats,
                                         Instant prochaineFin, Instant lastActivityAt, boolean manualAccess) {
        return new AdminUserListItemDto(
                u.getId(), displayName(u), u.getEmail(), u.getCreatedAt(),
                effective(module),
                etats.stream().map(this::badge).toList(),
                prochaineFin,
                DateMetierParis.finIncluse(prochaineFin).orElse(null),
                prochaineFin != null ? DateMetierParis.libelleFin(prochaineFin) : null,
                lastActivityAt,
                accountStatus(u), accountStatusLabel(u),
                manualAccess);
    }

    // --------------------------------------------------------------- achats

    public AdminUserPurchaseDto purchase(UserSubscription s) {
        Plan plan = s.getPlan();
        ModuleAccess product = plan != null ? plan.getModuleAccess() : null;
        boolean recurring = s.isAutoRenew()
                || (plan != null && plan.getPurchaseType() == PlanPurchaseType.SUBSCRIPTION);
        return new AdminUserPurchaseDto(
                s.getId(), product, productLabel(product),
                plan != null ? plan.getCode() : null,
                plan != null ? plan.getName() : null,
                s.getSource(), sourceLabel(s.getSource()),
                s.getStatus(), statusLabel(s.getStatus()),
                s.getPaymentStatus(), paymentStatusLabel(s.getPaymentStatus()),
                s.getAmountCents(), s.getCurrency(),
                s.getPurchasedAt(), s.getStartsAt(), s.getEndsAt(),
                s.getEndsAt() != null ? DateMetierParis.libelleFin(s.getEndsAt()) : null,
                recurring,
                ReferenceExterne.tronquer(s.getOriginalTransactionId()));
    }

    private static String sourceLabel(SubscriptionSource source) {
        if (source == null) return null;
        return switch (source) {
            case STRIPE -> "Stripe";
            case APPLE -> "Apple";
            case GOOGLE -> "Google Play";
        };
    }

    private static String statusLabel(SubscriptionStatus status) {
        if (status == null) return null;
        return switch (status) {
            case ACTIVE -> "Actif";
            case TRIAL -> "Essai";
            case IN_GRACE -> "Période de grâce";
            case PENDING -> "En attente";
            case CANCELED -> "Résilié";
            case EXPIRED -> "Expiré";
            case REFUNDED -> "Remboursé";
        };
    }

    private static String paymentStatusLabel(PaymentStatus status) {
        if (status == null) return null;
        return switch (status) {
            case PAID -> "Payé";
            case PARTIALLY_REFUNDED -> "Partiellement remboursé";
            case REFUNDED -> "Remboursé";
        };
    }

    // ---------------------------------------------------------- progression

    public AdminUserProgressionDto progression(Module module, Instant diagnosticAt,
                                               AdminUserReadRepository.CurrentCycle cycle, long historised) {
        AdminUserCycleDto c = cycle == null ? null : new AdminUserCycleDto(
                cycle.getStatus(), cycle.getEntryLevel(), cycle.getTargetLevel(), cycle.getTargetProcedure(),
                cycle.getStartedAt(), cycle.getStepsClosed(), cycle.getStepsTotal());
        return new AdminUserProgressionDto(module, moduleLabel(module), diagnosticAt != null, diagnosticAt,
                c, historised);
    }

    // ----------------------------------------------------------- historique

    /** Photo d'état pour le journal (jsonb) : des chaînes, jamais relues pour calculer un accès. */
    public List<Map<String, Object>> snapshot(List<EtatProduit> etats) {
        List<Map<String, Object>> out = new ArrayList<>();
        for (EtatProduit e : etats) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("product", e.produit().name());
            m.put("status", e.statut().name());
            m.put("endsAt", e.fin() != null ? e.fin().toString() : null);
            m.put("origin", e.origine() != null ? e.origine().name() : null);
            m.put("summary", resume(e));
            out.add(m);
        }
        return out;
    }

    /** Une phrase par produit dont le résumé a changé : « Civique : Actif jusqu'au … → Révoqué depuis le … ». */
    public List<String> changes(List<Map<String, Object>> avant, List<Map<String, Object>> apres) {
        List<String> out = new ArrayList<>();
        for (Map<String, Object> a : apres) {
            Object produit = a.get("product");
            Map<String, Object> b = avant.stream().filter(m -> Objects.equals(m.get("product"), produit))
                    .findFirst().orElse(Map.of());
            Object resumeAvant = b.getOrDefault("summary", "Aucun");
            if (!Objects.equals(resumeAvant, a.get("summary"))) {
                out.add(productLabel(ModuleAccess.valueOf(String.valueOf(produit))) + " : "
                        + resumeAvant + " → " + a.get("summary"));
            }
        }
        return out;
    }

    public AdminAccessHistoryEntryDto history(AdminAccessOperation op, String adminEmail) {
        return new AdminAccessHistoryEntryDto(
                op.getId(), op.getCreatedAt(), op.getAdminUserId(), adminEmail,
                op.getOperation(), op.getOperation().label(),
                op.getProduct(), productLabel(op.getProduct()),
                op.getFromProduct(), productLabel(op.getFromProduct()),
                op.getReason(),
                changes(op.getBeforeState(), op.getAfterState()));
    }

    // ---------------------------------------------------------------- aperçu

    /**
     * La phrase d'aperçu / de confirmation d'une action (spec §6), calculée
     * serveur sur les bornes réellement retenues.
     *
     * @param debut      début retenu ({@code null} si sans objet)
     * @param fin        fin EXCLUSIVE retenue ({@code null} si sans objet)
     * @param debutImmediat le début est « maintenant »
     */
    public String preview(AdminAccessOperationType op, ModuleAccess product, ModuleAccess fromProduct,
                          Instant debut, Instant fin, boolean debutImmediat) {
        String p = productLabel(product);
        String jusquau = fin != null ? DateMetierParis.libelleFin(fin) : null;
        return switch (op) {
            case GRANT -> debutImmediat
                    ? "Vous allez donner l'accès " + p + " dès maintenant, jusqu'au " + jusquau + "."
                    : "Vous allez donner l'accès " + p + " du " + DateMetierParis.jour(debut)
                            + " au " + jusquau + ".";
            case REACTIVATE -> debutImmediat
                    ? "Vous allez réactiver l'accès " + p + " dès maintenant, jusqu'au " + jusquau + "."
                    : "Vous allez réactiver l'accès " + p + " du " + DateMetierParis.jour(debut)
                            + " au " + jusquau + ".";
            case EXTEND -> "Vous allez prolonger l'accès " + p + " jusqu'au " + jusquau + ".";
            case SHORTEN -> "Vous allez raccourcir l'accès " + p + " : il restera ouvert jusqu'au "
                    + DateMetierParis.libelleFin(debut) + ", puis sera révoqué.";
            case END -> "Cet utilisateur perdra immédiatement son accès " + p + ". Continuer ?";
            case CORRECT_PRODUCT -> "Vous allez retirer l'accès " + productLabel(fromProduct)
                    + " et donner l'accès " + p + " jusqu'au " + jusquau + ".";
        };
    }
}

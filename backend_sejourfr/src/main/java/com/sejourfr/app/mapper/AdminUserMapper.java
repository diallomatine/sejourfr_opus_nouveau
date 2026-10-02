package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.AdminAccessAlertDto;
import com.sejourfr.app.dto.AdminAccessHistoryEntryDto;
import com.sejourfr.app.dto.AdminAccessOperationOptionDto;
import com.sejourfr.app.dto.AdminAccessProductDto;
import com.sejourfr.app.dto.AdminEffectiveAccessDto;
import com.sejourfr.app.dto.AdminRealtimeEoSessionsDto;
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
import com.sejourfr.app.enums.ProductAccessStatus;
import com.sejourfr.app.enums.PaymentStatus;
import com.sejourfr.app.enums.PlanPurchaseType;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.repository.AdminUserReadRepository;
import com.sejourfr.app.service.access.AccesEffectifResolver;
import com.sejourfr.app.service.access.AccesEffectifResolver.EtatProduit;
import com.sejourfr.app.service.realtime.RealtimeQuotaService;
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

    /** Phrase servie quand l'accès manuel Intégral n'offre aucune session (arbitrage n°3, B-1). */
    public static final String INFO_SANS_SESSION_EO =
            "Cet accès manuel n'ajoute pas actuellement de sessions EO temps réel.";

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

    /** @param maxSessionsEo plafond configuré des sessions EO temps réel offertes par action */
    public List<AdminAccessProductDto> products(int maxSessionsEo) {
        return AccesEffectifResolver.PRODUITS.stream()
                .map(p -> new AdminAccessProductDto(p, productLabel(p), modulesDe(p), modulesLabel(modulesDe(p)),
                        p == ModuleAccess.INTEGRAL ? maxSessionsEo : null))
                .toList();
    }

    public AdminEffectiveAccessDto effective(ModuleAccess module) {
        List<Module> modules = modulesDe(module);
        return new AdminEffectiveAccessDto(module, productLabel(module), modules, modulesLabel(modules));
    }

    // ---------------------------------------------------------------- accès

    /**
     * @param sessions la vue du quota EO servie par l'autorité ; lue pour la carte
     *                 INTEGRAL seulement
     */
    public AdminUserAccessDto access(EtatProduit e, List<AdminAccessOperationType> operations,
                                     RealtimeQuotaService.VueAdmin sessions) {
        return new AdminUserAccessDto(
                e.produit(), productLabel(e.produit()),
                e.statut(), e.statut().label(),
                resume(e),
                e.debut(), e.fin(),
                DateMetierParis.finIncluse(e.fin()).orElse(null),
                e.fin() != null ? DateMetierParis.libelleFin(e.fin()) : null,
                DateMetierParis.finProposee(finParDefaut(e)).orElse(null),
                e.origine(), e.origine() != null ? e.origine().label() : null,
                e.alertes().stream().map(this::alerte).toList(),
                operations.stream().map(o -> new AdminAccessOperationOptionDto(o, o.label())).toList(),
                e.produit() == ModuleAccess.INTEGRAL && sessions != null ? sessionsEo(sessions) : null);
    }

    /** « 14 sessions restantes — accès manuel : 14 sur 20 ; achat : 0 » : des libellés, aucun calcul. */
    public AdminRealtimeEoSessionsDto sessionsEo(RealtimeQuotaService.VueAdmin v) {
        List<String> details = new ArrayList<>();
        if (v.grantGranted() != null) {
            details.add("accès manuel : " + v.grantRemaining() + " sur " + v.grantGranted());
        }
        if (v.purchaseRemaining() != null) {
            details.add("achat : " + v.purchaseRemaining());
        }
        if (v.scheduledGrantGranted() != null) {
            details.add("accès programmé : " + sessions(v.scheduledGrantGranted()) + " "
                    + accord(v.scheduledGrantGranted(), "offerte"));
        }
        String label = sessions(v.remaining()) + " " + accord(v.remaining(), "restante")
                + (details.isEmpty() ? "" : " — " + String.join(" ; ", details));
        return new AdminRealtimeEoSessionsDto(v.remaining(), v.grantGranted(), v.grantRemaining(),
                v.purchaseRemaining(), v.scheduledGrantGranted(), label,
                v.sansSessionOfferte() ? INFO_SANS_SESSION_EO : null);
    }

    private static String sessions(int n) {
        return n + (n > 1 ? " sessions" : " session");
    }

    private static String accord(int n, String mot) {
        return n > 1 ? mot + "s" : mot;
    }

    /**
     * La fin que la modale pré-remplit : celle de l'accès, ou, pour un produit
     * révoqué, celle de l'achat révoqué — « Réactiver » rend alors l'accès
     * jusqu'à la fin de ce que le client a payé (D-34, révise D-02).
     */
    private static Instant finParDefaut(EtatProduit e) {
        return e.statut() == ProductAccessStatus.REVOKED ? e.finAchatRevoque() : e.fin();
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
                ReferenceExterne.identifiantOrigine(s.getSource(), s.getOriginalTransactionId()));
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

    /**
     * Photo d'état pour le journal (jsonb) : des chaînes, jamais relues pour
     * calculer un accès. La carte INTEGRAL porte aussi le total des sessions EO
     * temps réel consommables ({@code realtimeEoSessions}, V084).
     */
    public List<Map<String, Object>> snapshot(List<EtatProduit> etats, RealtimeQuotaService.VueAdmin sessions) {
        List<Map<String, Object>> out = new ArrayList<>();
        for (EtatProduit e : etats) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("product", e.produit().name());
            m.put("status", e.statut().name());
            m.put("endsAt", e.fin() != null ? e.fin().toString() : null);
            m.put("origin", e.origine() != null ? e.origine().name() : null);
            m.put("summary", resume(e));
            if (e.produit() == ModuleAccess.INTEGRAL && sessions != null) {
                m.put(CLE_SESSIONS_EO, sessions.remaining());
            }
            out.add(m);
        }
        return out;
    }

    private static final String CLE_SESSIONS_EO = "realtimeEoSessions";

    /** Une phrase par produit dont le résumé a changé : « Civique : Actif jusqu'au … → Révoqué depuis le … ». */
    public List<String> changes(List<Map<String, Object>> avant, List<Map<String, Object>> apres) {
        List<String> out = new ArrayList<>();
        for (Map<String, Object> a : apres) {
            Object produit = a.get("product");
            Map<String, Object> b = avant.stream().filter(m -> Objects.equals(m.get("product"), produit))
                    .findFirst().orElse(Map.of());
            Object resumeAvant = b.getOrDefault("summary", "Aucun");
            String libelle = productLabel(ModuleAccess.valueOf(String.valueOf(produit)));
            if (!Objects.equals(resumeAvant, a.get("summary"))) {
                out.add(libelle + " : " + resumeAvant + " → " + a.get("summary"));
            }
            // Une entrée de journal d'avant V084 n'a pas la clé : rien à comparer.
            Object sessionsAvant = b.get(CLE_SESSIONS_EO);
            Object sessionsApres = a.get(CLE_SESSIONS_EO);
            if (sessionsAvant != null && sessionsApres != null
                    && !String.valueOf(sessionsAvant).equals(String.valueOf(sessionsApres))) {
                out.add(libelle + " — sessions EO temps réel : " + sessionsAvant + " → " + sessionsApres);
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
    /**
     * @param achatResteRevoque vrai si, à la fin du GRANT posé, un achat de ce
     *                          produit restera révoqué (la queue du REVOKE survit,
     *                          D-02) : la phrase le dit à l'admin (D-34).
     */
    /**
     * Le devenir des sessions EO temps réel annoncé dans l'aperçu (V084, B-1),
     * calculé par le planner et l'autorité du quota.
     *
     * @param creeGrantIntegral l'action pose une nouvelle décision GRANT INTEGRAL
     * @param achatRestant      solde de l'achat Intégral qui compte (avant l'action)
     * @param achatFin          fin de cet achat : son solde n'est utilisable que jusque-là
     * @param prolongeIntegral  l'action prolonge l'accès Intégral
     */
    public record ApercuSessions(boolean creeGrantIntegral, int offertes, int reportees, boolean cumulees,
                                 int perdues, int achatRestant, Instant achatFin, boolean prolongeIntegral) {
        public static final ApercuSessions AUCUNE = new ApercuSessions(false, 0, 0, false, 0, 0, null, false);
    }

    public String preview(AdminAccessOperationType op, ModuleAccess product, ModuleAccess fromProduct,
                          Instant debut, Instant fin, boolean debutImmediat, boolean achatResteRevoque,
                          ApercuSessions sessions) {
        String phrase = phrase(op, product, fromProduct, debut, fin, debutImmediat);
        List<String> phrasesSessions = phrasesSessions(sessions);
        if (!phrasesSessions.isEmpty()) {
            String suite = String.join(" ", phrasesSessions);
            phrase = op == AdminAccessOperationType.END
                    ? phrase.replace(" Continuer ?", " " + suite + " Continuer ?")
                    : phrase + " " + suite;
        }
        if (!achatResteRevoque || fin == null) return phrase;
        return phrase + " Attention : l'achat " + productLabel(product)
                + " révoqué ne sera pas rétabli. À partir du " + DateMetierParis.jour(fin)
                + ", l'accès " + productLabel(product) + " sera de nouveau fermé.";
    }

    /** « 4 sessions restantes + 10 offertes → 14 sessions disponibles », « … seront perdues »… */
    private static List<String> phrasesSessions(ApercuSessions a) {
        List<String> out = new ArrayList<>();
        if (a == null) return out;
        String conservees = a.reportees() == 1
                ? "La session EO temps réel restante de l'accès manuel est conservée."
                : "Les " + a.reportees() + " sessions EO temps réel restantes de l'accès manuel sont conservées.";
        if (a.creeGrantIntegral()) {
            if (a.offertes() > 0 && a.cumulees() && a.reportees() > 0) {
                int total = a.reportees() + a.offertes();
                out.add("Sessions EO temps réel : " + sessions(a.reportees()) + " " + accord(a.reportees(), "restante")
                        + " + " + a.offertes() + " " + accord(a.offertes(), "offerte")
                        + " → " + sessions(total) + " " + accord(total, "disponible") + ".");
            } else if (a.offertes() > 0) {
                out.add("Cet accès manuel offre " + sessions(a.offertes()) + " EO temps réel.");
                if (a.reportees() > 0) out.add(conservees);
            } else if (a.reportees() > 0) {
                out.add(conservees);
            } else {
                out.add(INFO_SANS_SESSION_EO);
            }
        } else if (a.reportees() > 0) {
            out.add(conservees);
        }
        if (a.perdues() > 0) {
            out.add(a.perdues() == 1
                    ? "La session EO temps réel restante de l'accès manuel sera perdue."
                    : "Les " + a.perdues() + " sessions EO temps réel restantes de l'accès manuel seront perdues.");
        }
        if (a.prolongeIntegral() && a.achatRestant() > 0 && a.achatFin() != null) {
            out.add((a.achatRestant() == 1
                    ? "La session EO temps réel de l'achat reste utilisable"
                    : "Les " + a.achatRestant() + " sessions EO temps réel de l'achat restent utilisables")
                    + " jusqu'au " + DateMetierParis.libelleFin(a.achatFin()) + ".");
        }
        return out;
    }

    private String phrase(AdminAccessOperationType op, ModuleAccess product, ModuleAccess fromProduct,
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

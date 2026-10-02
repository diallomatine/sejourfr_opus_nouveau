package com.sejourfr.app.service.adminuser;

import com.sejourfr.app.dto.AdminAccessOperationRequest;
import com.sejourfr.app.dto.AdminAccessOperationResponse;
import com.sejourfr.app.dto.AdminUserAccessDto;
import com.sejourfr.app.entity.AccessOverride;
import com.sejourfr.app.entity.AdminAccessOperation;
import com.sejourfr.app.enums.AccessOverrideType;
import com.sejourfr.app.enums.AdminAccessOperationType;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.ProductAccessStatus;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AccessOverrideManager;
import com.sejourfr.app.manager.AdminAccessOperationManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.mapper.AdminUserMapper;
import com.sejourfr.app.service.SubscriptionService;
import com.sejourfr.app.service.access.AccesEffectifResolver;
import com.sejourfr.app.service.access.AccesEffectifResolver.EtatProduit;
import com.sejourfr.app.service.access.AccessOverridePlanner;
import com.sejourfr.app.util.DateMetierParis;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Les actions admin sur l'accès d'un compte (spec §2.6, §6, §8 ; GO §4, §5,
 * §14, §18). Une action :
 * <ol>
 *   <li>est validée (400 : dates, produit, motif ; 409 : précondition d'état,
 *       état attendu périmé) ;</li>
 *   <li>est traduite en décisions GRANT / REVOKE, puis en écritures par
 *       {@link AccessOverridePlanner} — le même plan sert à l'aperçu
 *       ({@code dryRun}) et à l'écriture ;</li>
 *   <li>s'écrit dans UNE transaction, sous verrou consultatif par compte :
 *       la ligne de journal, les supersessions, puis les insertions. Tout ou
 *       rien (une correction de produit qui échoue à mi-chemin n'écrit rien).</li>
 * </ol>
 * 🛑 Aucun achat n'est jamais touché : ni {@code user_subscriptions}, ni
 * paiement, ni montant, ni abonnement récurrent (G-12).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AdminAccessOperationService {

    static final String MSG_ETAT_PERIME =
            "L'accès de cet utilisateur a changé depuis l'ouverture de la fenêtre. Rechargez la fiche.";

    private final UserManager userManager;
    private final SubscriptionService subscriptionService;
    private final AccessOverrideManager accessOverrideManager;
    private final AdminAccessOperationManager operationManager;
    private final AdminUserMapper mapper;

    @Transactional
    public AdminAccessOperationResponse executer(UUID userId, UUID adminId, AdminAccessOperationRequest req) {
        userManager.findById(userId)
                .orElseThrow(() -> new NotFoundException("Utilisateur introuvable : " + userId));
        if (!req.dryRun()) {
            if (req.expectedVersion() == null || req.expectedVersion().isBlank()) {
                throw badRequest("L'état attendu (expectedVersion) est obligatoire pour enregistrer une action.");
            }
            accessOverrideManager.verrouiller(userId);
        }
        Instant now = Instant.now();
        SubscriptionService.DonneesAcces d = subscriptionService.charger(userId);
        if (req.expectedVersion() != null && !req.expectedVersion().isBlank()
                && !req.expectedVersion().equals(VersionAcces.de(d))) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, MSG_ETAT_PERIME);
        }
        String motif = motif(req.reason());
        Traduction t = traduire(req, d, now);

        UUID operationId = UUID.randomUUID();
        AccessOverridePlanner.Plan plan = AccessOverridePlanner.planifier(d.decisions(), t.decisions(),
                new AccessOverridePlanner.Contexte(userId, operationId, adminId, motif, now));
        List<AccessOverride> apres = plan.appliqueA(d.decisions());
        List<EtatProduit> etatsAvant = etats(d.achats(), d.decisions(), now);
        List<EtatProduit> etatsApres = etats(d.achats(), apres, now);
        List<Map<String, Object>> avant = mapper.snapshot(etatsAvant);
        List<Map<String, Object>> apresSnapshot = mapper.snapshot(etatsApres);

        if (!req.dryRun()) {
            AdminAccessOperation op = new AdminAccessOperation();
            op.setId(operationId);
            op.setUserId(userId);
            op.setAdminUserId(adminId);
            op.setOperation(req.operation());
            op.setProduct(req.product());
            op.setFromProduct(req.operation() == AdminAccessOperationType.CORRECT_PRODUCT ? req.fromProduct() : null);
            op.setStartsAt(t.debut());
            op.setEndsAt(t.fin());
            op.setReason(motif);
            op.setBeforeState(avant);
            op.setAfterState(apresSnapshot);
            op.setCreatedAt(now);
            operationManager.saveAndFlush(op);
            // Supersessions AVANT insertions : la contrainte d'exclusion est immédiate.
            for (AccessOverride o : plan.aRemplacer()) {
                o.setSupersededAt(now);
                o.setSupersededByOperationId(operationId);
                accessOverrideManager.saveAndFlush(o);
            }
            for (AccessOverride o : plan.aInserer()) {
                accessOverrideManager.saveAndFlush(o);
            }
            log.info("Action admin sur l'accès : operation={} type={} user={} admin={} produit={}",
                    operationId, req.operation(), userId, adminId, req.product());
        }

        SubscriptionService.DonneesAcces resultat = new SubscriptionService.DonneesAcces(d.achats(), apres);
        ModuleAccess module = AccesEffectifResolver.module(d.achats(), apres, now);
        return new AdminAccessOperationResponse(
                req.dryRun(),
                req.dryRun() ? null : operationId,
                req.operation(),
                mapper.preview(req.operation(), req.product(), req.fromProduct(), t.debut(), t.fin(), t.debutImmediat(),
                        achatResteRevoqueApresLeGrant(t, d.achats(), apres)),
                confirmationRequise(req.operation()),
                mapper.changes(avant, apresSnapshot),
                mapper.effective(module),
                accesses(etatsApres, d.achats(), apres, now),
                req.dryRun() ? VersionAcces.de(d) : VersionAcces.de(resultat));
    }

    /** Les blocs d'accès servis à la fiche et à la réponse d'une action. */
    List<AdminUserAccessDto> accesses(List<EtatProduit> etats, List<com.sejourfr.app.entity.UserSubscription> achats,
                                      List<AccessOverride> decisions, Instant now) {
        boolean integralActif = AccesEffectifResolver.acces(achats, decisions, ModuleAccess.INTEGRAL, now);
        List<AdminUserAccessDto> out = new ArrayList<>();
        for (EtatProduit e : etats) {
            boolean terminable = !(e.produit() == ModuleAccess.CIVIQUE && integralActif);
            out.add(mapper.access(e, OperationsDisponibles.pour(e.statut(), terminable)));
        }
        return out;
    }

    static List<EtatProduit> etats(List<com.sejourfr.app.entity.UserSubscription> achats,
                                   List<AccessOverride> decisions, Instant now) {
        return AccesEffectifResolver.PRODUITS.stream()
                .map(p -> AccesEffectifResolver.etat(achats, decisions, p, now))
                .toList();
    }

    /**
     * D-34 : à la fin d'un GRANT posé par cette action, l'achat du même produit
     * reste-t-il révoqué ? (La queue d'un REVOKE survit au GRANT, D-02.) Lu par
     * l'autorité sur l'état d'APRÈS l'action, à la borne de fin du GRANT.
     */
    static boolean achatResteRevoqueApresLeGrant(Traduction t, List<com.sejourfr.app.entity.UserSubscription> achats,
                                                 List<AccessOverride> apres) {
        return t.decisions().stream()
                .filter(g -> g.type() == AccessOverrideType.GRANT && g.fin() != null)
                .anyMatch(g -> AccesEffectifResolver.achatResteRevoque(achats, apres, g.produit(), g.fin()));
    }

    static boolean confirmationRequise(AdminAccessOperationType op) {
        return op == AdminAccessOperationType.CORRECT_PRODUCT
                || op == AdminAccessOperationType.SHORTEN
                || op == AdminAccessOperationType.END;
    }

    // -------------------------------------------------------------- traduction

    /** Les décisions à poser, et les bornes retenues pour le journal et l'aperçu. */
    record Traduction(List<AccessOverridePlanner.Decision> decisions, Instant debut, Instant fin,
                      boolean debutImmediat) {}

    /**
     * Spec §2.6 + GO §5 / §18, sur les produits réellement vendus :
     * <ul>
     *   <li>Donner / Réactiver : {@code GRANT [début, fin+1j)} ;</li>
     *   <li>Prolonger : {@code GRANT [maintenant, nouvelle fin+1j)} ;</li>
     *   <li>Raccourcir : {@code REVOKE [nouvelle fin+1j, ∅)} — vaut pour un accès
     *       acheté comme accordé (le GRANT recouvert est tronqué) ;</li>
     *   <li>Terminer : {@code REVOKE [maintenant, ∅)} ;</li>
     *   <li>Corriger A → B : {@code REVOKE A [maintenant, ∅)} + {@code GRANT B
     *       [maintenant, fin+1j)}, une seule opération. Le 409 « Civique reste
     *       accessible via Intégral » ne concerne que « Terminer » isolé.</li>
     * </ul>
     */
    Traduction traduire(AdminAccessOperationRequest req, SubscriptionService.DonneesAcces d, Instant now) {
        ModuleAccess p = req.product();
        if (p == null || p == ModuleAccess.NONE) {
            throw badRequest("Produit invalide : CIVIQUE ou INTEGRAL.");
        }
        LocalDate aujourdhui = DateMetierParis.aujourdhui(now);
        EtatProduit etat = AccesEffectifResolver.etat(d.achats(), d.decisions(), p, now);
        return switch (req.operation()) {
            case GRANT, REACTIVATE -> {
                if (req.operation() == AdminAccessOperationType.REACTIVATE
                        && etat.statut() != ProductAccessStatus.EXPIRED
                        && etat.statut() != ProductAccessStatus.REVOKED) {
                    throw conflict("Réactiver ne s'applique qu'à un accès expiré ou révoqué (statut actuel : "
                            + etat.statut().label() + ").");
                }
                LocalDate debutJour = req.startDate() != null ? req.startDate() : aujourdhui;
                if (debutJour.isBefore(aujourdhui)) {
                    throw badRequest("La date de début ne peut pas être dans le passé.");
                }
                LocalDate finJour = finObligatoire(req, aujourdhui);
                if (finJour.isBefore(debutJour)) {
                    throw badRequest("La date de fin doit être postérieure ou égale à la date de début.");
                }
                Instant debut = DateMetierParis.debut(debutJour, now);
                Instant fin = DateMetierParis.finExclusive(finJour);
                yield new Traduction(List.of(new AccessOverridePlanner.Decision(
                        p, AccessOverrideType.GRANT, debut, fin)), debut, fin, debut.equals(now));
            }
            case EXTEND -> {
                exigerActif(etat, "Prolonger");
                Instant fin = DateMetierParis.finExclusive(finObligatoire(req, aujourdhui));
                if (etat.fin() != null && !fin.isAfter(etat.fin())) {
                    throw badRequest("La nouvelle fin doit être postérieure à la fin actuelle ("
                            + DateMetierParis.libelleFin(etat.fin()) + "). Pour l'avancer, utilisez Raccourcir.");
                }
                yield new Traduction(List.of(new AccessOverridePlanner.Decision(
                        p, AccessOverrideType.GRANT, now, fin)), now, fin, true);
            }
            case SHORTEN -> {
                exigerActif(etat, "Raccourcir");
                Instant fin = DateMetierParis.finExclusive(finObligatoire(req, aujourdhui));
                if (etat.fin() != null && !fin.isBefore(etat.fin())) {
                    throw badRequest("La nouvelle fin doit précéder la fin actuelle ("
                            + DateMetierParis.libelleFin(etat.fin()) + "). Pour la repousser, utilisez Prolonger.");
                }
                yield new Traduction(List.of(new AccessOverridePlanner.Decision(
                        p, AccessOverrideType.REVOKE, fin, null)), fin, null, false);
            }
            case END -> {
                if (etat.statut() != ProductAccessStatus.ACTIVE && etat.statut() != ProductAccessStatus.SCHEDULED) {
                    throw conflict("Aucun accès " + mapper.productLabel(p) + " actif ou programmé à terminer.");
                }
                if (p == ModuleAccess.CIVIQUE
                        && AccesEffectifResolver.acces(d.achats(), d.decisions(), ModuleAccess.INTEGRAL, now)) {
                    throw conflict("Civique reste accessible via Intégral : terminez Intégral, "
                            + "ou corrigez le produit.");
                }
                yield new Traduction(List.of(new AccessOverridePlanner.Decision(
                        p, AccessOverrideType.REVOKE, now, null)), now, null, true);
            }
            case CORRECT_PRODUCT -> {
                ModuleAccess from = req.fromProduct();
                if (from == null || from == ModuleAccess.NONE) {
                    throw badRequest("Le produit à corriger (fromProduct) est obligatoire : CIVIQUE ou INTEGRAL.");
                }
                if (from == p) {
                    throw badRequest("Le produit à corriger et le produit cible doivent être différents.");
                }
                EtatProduit etatFrom = AccesEffectifResolver.etat(d.achats(), d.decisions(), from, now);
                if (etatFrom.statut() != ProductAccessStatus.ACTIVE) {
                    throw conflict("Le produit à corriger (" + mapper.productLabel(from) + ") n'est pas actif.");
                }
                Instant fin = DateMetierParis.finExclusive(finObligatoire(req, aujourdhui));
                yield new Traduction(List.of(
                        new AccessOverridePlanner.Decision(from, AccessOverrideType.REVOKE, now, null),
                        new AccessOverridePlanner.Decision(p, AccessOverrideType.GRANT, now, fin)),
                        now, fin, true);
            }
        };
    }

    private static LocalDate finObligatoire(AdminAccessOperationRequest req, LocalDate aujourdhui) {
        if (req.endDateInclusive() == null) {
            throw badRequest("La date de fin (incluse) est obligatoire pour cette action.");
        }
        if (req.endDateInclusive().isBefore(aujourdhui)) {
            throw badRequest("La date de fin ne peut pas être dans le passé.");
        }
        return req.endDateInclusive();
    }

    private void exigerActif(EtatProduit etat, String action) {
        if (etat.statut() != ProductAccessStatus.ACTIVE) {
            throw conflict(action + " ne s'applique qu'à un accès actif (accès "
                    + mapper.productLabel(etat.produit()) + " : " + etat.statut().label() + ").");
        }
    }

    private static String motif(String reason) {
        String m = reason == null ? "" : reason.trim();
        if (m.length() < 3 || m.length() > 500) {
            throw badRequest("Le motif est obligatoire (3 à 500 caractères).");
        }
        return m;
    }

    private static ResponseStatusException badRequest(String message) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
    }

    private static ResponseStatusException conflict(String message) {
        return new ResponseStatusException(HttpStatus.CONFLICT, message);
    }
}

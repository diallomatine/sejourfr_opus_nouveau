package com.sejourfr.app.service.adminuser;

import com.sejourfr.app.config.RealtimeProperties;
import com.sejourfr.app.dto.AdminAccessHistoryEntryDto;
import com.sejourfr.app.dto.AdminAccessProductDto;
import com.sejourfr.app.dto.AdminUserDetailDto;
import com.sejourfr.app.dto.AdminUserListItemDto;
import com.sejourfr.app.dto.AdminUserProgressionDto;
import com.sejourfr.app.dto.AdminUserPurchaseDto;
import com.sejourfr.app.dto.PageResponse;
import com.sejourfr.app.entity.AdminAccessOperation;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.AdminUserFilter;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.ProductAccessStatus;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AccessOverrideManager;
import com.sejourfr.app.manager.AdminAccessOperationManager;
import com.sejourfr.app.manager.AdminUserReadManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.mapper.AdminUserMapper;
import com.sejourfr.app.repository.AdminUserReadRepository;
import com.sejourfr.app.service.SubscriptionService;
import com.sejourfr.app.service.access.AccesEffectifResolver;
import com.sejourfr.app.service.access.AccesEffectifResolver.EtatProduit;
import com.sejourfr.app.specification.UserSpecifications;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Lecture de la console admin « Utilisateurs » : liste filtrable, fiche,
 * produits. 🛑 Lecture SEULE et sans effet de bord : l'accès vient de
 * l'autorité ({@link SubscriptionService} + {@link AccesEffectifResolver}), la
 * progression des tables (jamais {@code JourneyService.lire()}, qui écrit).
 *
 * <p>Filtres sur l'accès effectif (spec §4, audit C.5) : un SUR-ENSEMBLE SQL
 * des comptes qui peuvent avoir un accès ouvert (achat pas encore terminé, ou
 * GRANT courant) est résolu en Java par l'autorité, puis la pagination SQL
 * s'applique sur les ids retenus. Coût O(payants), pas O(comptes) ; aucune
 * copie SQL de la règle.
 */
@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
public class AdminUserService {

    private static final int MAX_SIZE = 100;
    static final Sort ORDER = Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id"));

    private final UserManager userManager;
    private final SubscriptionService subscriptionService;
    private final AccessOverrideManager accessOverrideManager;
    private final AdminAccessOperationManager operationManager;
    private final AdminUserReadManager readManager;
    private final AdminUserMapper mapper;
    private final AdminAccessOperationService operationService;
    private final RealtimeProperties realtimeProperties;

    public List<AdminAccessProductDto> products() {
        return mapper.products(realtimeProperties.getAdminGrantMaxSessions());
    }

    public PageResponse<AdminUserListItemDto> list(String q, AdminUserFilter filter, int page, int size) {
        int safeSize = Math.min(Math.max(size, 1), MAX_SIZE);
        int safePage = Math.max(page, 0);
        Instant now = Instant.now();

        Specification<User> spec = Specification.where(UserSpecifications.notDeleted())
                .and(UserSpecifications.search(q));
        AdminUserFilter f = filter == null ? AdminUserFilter.ALL : filter;
        switch (f) {
            case ALL -> { }
            case MANUAL_ACCESS -> spec = spec.and(UserSpecifications.hasOpenOverride(now));
            case TCF_ACTIVE, CIVIQUE_ACTIVE, NO_ACTIVE_ACCESS, EXPIRED -> {
                Map<UUID, ModuleAccess> ouverts = modulesOuverts(now);
                Set<UUID> tcf = idsOu(ouverts, m -> m.hasTcf());
                Set<UUID> civique = idsOu(ouverts, m -> m.hasCivique());
                Set<UUID> actifs = idsOu(ouverts, m -> m != ModuleAccess.NONE);
                spec = switch (f) {
                    case TCF_ACTIVE -> spec.and(UserSpecifications.idIn(tcf));
                    case CIVIQUE_ACTIVE -> spec.and(UserSpecifications.idIn(civique));
                    case NO_ACTIVE_ACCESS -> spec.and(UserSpecifications.idNotIn(actifs));
                    default -> spec.and(UserSpecifications.hasPurchaseOrGrant())
                            .and(UserSpecifications.idNotIn(actifs));
                };
            }
        }

        Page<User> users = userManager.findAll(spec, PageRequest.of(safePage, safeSize, ORDER));
        List<UUID> ids = users.getContent().stream().map(User::getId).toList();
        Map<UUID, SubscriptionService.DonneesAcces> acces = subscriptionService.charger(ids);
        Map<UUID, Instant> activite = readManager.findLastActivity(ids);
        return PageResponse.from(users.map(u -> {
            SubscriptionService.DonneesAcces d = acces.getOrDefault(u.getId(), SubscriptionService.DonneesAcces.VIDE);
            List<EtatProduit> etats = AdminAccessOperationService.etats(d.achats(), d.decisions(), now);
            return mapper.listItem(u,
                    AccesEffectifResolver.module(d.achats(), d.decisions(), now),
                    etats,
                    prochaineFin(etats),
                    activite.get(u.getId()),
                    AccesEffectifResolver.aDecisionOuverte(d.decisions(), now));
        }));
    }

    public AdminUserDetailDto detail(UUID userId) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new NotFoundException("Utilisateur introuvable : " + userId));
        Instant now = Instant.now();
        SubscriptionService.DonneesAcces d = subscriptionService.charger(userId);
        List<EtatProduit> etats = AdminAccessOperationService.etats(d.achats(), d.decisions(), now);

        List<AdminUserPurchaseDto> achats = d.achats().stream()
                .sorted(Comparator.comparing(AdminUserService::dateAchat, Comparator.nullsLast(Comparator.reverseOrder())))
                .map(mapper::purchase)
                .toList();

        return new AdminUserDetailDto(
                mapper.account(user),
                mapper.effective(AccesEffectifResolver.module(d.achats(), d.decisions(), now)),
                readManager.findLastActivity(List.of(userId)).get(userId),
                operationService.accesses(etats, d, now),
                achats,
                progression(userId),
                historique(userId),
                VersionAcces.de(d));
    }

    // ------------------------------------------------------------- internes

    /**
     * Module effectif des comptes du sur-ensemble « peut-être ouvert » : achat
     * pas encore terminé (statut non filtré) ou GRANT courant qui couvre maintenant.
     */
    private Map<UUID, ModuleAccess> modulesOuverts(Instant now) {
        Set<UUID> candidats = new LinkedHashSet<>(readManager.findUserIdsWithOpenPurchase(now));
        candidats.addAll(accessOverrideManager.findUserIdsWithGrantCovering(now));
        Map<UUID, ModuleAccess> out = new HashMap<>();
        subscriptionService.charger(candidats).forEach((id, d) ->
                out.put(id, AccesEffectifResolver.module(d.achats(), d.decisions(), now)));
        return out;
    }

    private static Set<UUID> idsOu(Map<UUID, ModuleAccess> modules, Function<ModuleAccess, Boolean> test) {
        Set<UUID> out = new HashSet<>();
        modules.forEach((id, m) -> {
            if (test.apply(m)) out.add(id);
        });
        return out;
    }

    /** La fin la plus proche parmi les produits actifs (spec §4, « Prochaine fin »). */
    private static Instant prochaineFin(List<EtatProduit> etats) {
        return etats.stream()
                .filter(e -> e.statut() == ProductAccessStatus.ACTIVE && e.fin() != null)
                .map(EtatProduit::fin)
                .min(Comparator.naturalOrder())
                .orElse(null);
    }

    private static Instant dateAchat(UserSubscription s) {
        return s.getPurchasedAt() != null ? s.getPurchasedAt() : s.getStartsAt();
    }

    private List<AdminUserProgressionDto> progression(UUID userId) {
        Map<String, AdminUserReadRepository.CurrentCycle> cycles = readManager.findCurrentCycles(userId).stream()
                .collect(Collectors.toMap(AdminUserReadRepository.CurrentCycle::getModule, c -> c, (a, b) -> a));
        Map<String, Long> historises = readManager.countHistorisedCycles(userId).stream()
                .collect(Collectors.toMap(AdminUserReadRepository.ModuleCount::getModule,
                        AdminUserReadRepository.ModuleCount::getCount));
        Map<String, Instant> diagnostics = new HashMap<>();
        for (AdminUserReadRepository.ModuleDate m : readManager.findLastCompletedDiagnostics(userId)) {
            if (m.getAt() != null) diagnostics.put(m.getModule(), m.getAt());
        }
        return List.of(Module.TCF, Module.CIVIQUE).stream()
                .map(m -> mapper.progression(m, diagnostics.get(m.name()), cycles.get(m.name()),
                        historises.getOrDefault(m.name(), 0L)))
                .toList();
    }

    private List<AdminAccessHistoryEntryDto> historique(UUID userId) {
        List<AdminAccessOperation> ops = operationManager.findByUserId(userId);
        Set<UUID> adminIds = ops.stream().map(AdminAccessOperation::getAdminUserId).collect(Collectors.toSet());
        Map<UUID, String> emails = userManager.findAllById(adminIds).stream()
                .collect(Collectors.toMap(User::getId, User::getEmail));
        return ops.stream().map(op -> mapper.history(op, emails.get(op.getAdminUserId()))).toList();
    }
}

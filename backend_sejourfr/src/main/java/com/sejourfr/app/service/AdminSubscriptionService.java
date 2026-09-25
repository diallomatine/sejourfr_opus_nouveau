package com.sejourfr.app.service;

import com.sejourfr.app.dto.AdminSubscriptionDto;
import com.sejourfr.app.dto.PageResponse;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.mapper.UserSubscriptionMapper;
import com.sejourfr.app.specification.UserSubscriptionSpecifications;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Service admin pour la liste paginée des UserSubscription. Pagination, filtres
 * (source / status / moduleAccess) et recherche (email, prénom, nom) sont tous
 * appliqués dans la requête SQL. Tri : plus récentes en tête (updatedAt desc),
 * départagées par l'id — sans ce second critère, deux lignes au même
 * {@code updated_at} (import, backfill) pouvaient apparaître sur deux pages ou
 * sur aucune.
 *
 * <p>User et Plan arrivent par jointure dans la requête de page
 * ({@code @EntityGraph} du repository) : une page coûte deux requêtes (contenu +
 * total), quel que soit le nombre de lignes.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AdminSubscriptionService {

    private static final int MAX_SIZE = 100;

    private final UserSubscriptionManager userSubscriptionManager;
    private final UserSubscriptionMapper userSubscriptionMapper;

    static final Sort ORDER = Sort.by(Sort.Order.desc("updatedAt"), Sort.Order.desc("id"));

    public PageResponse<AdminSubscriptionDto> list(
            SubscriptionSource source,
            SubscriptionStatus status,
            ModuleAccess moduleAccess,
            String search,
            int page,
            int size) {

        int safeSize = Math.min(Math.max(size, 1), MAX_SIZE);
        int safePage = Math.max(page, 0);

        Specification<UserSubscription> spec = Specification
                .where(UserSubscriptionSpecifications.hasSource(source))
                .and(UserSubscriptionSpecifications.hasStatus(status))
                .and(UserSubscriptionSpecifications.hasModuleAccess(moduleAccess))
                .and(UserSubscriptionSpecifications.userSearch(search));

        Page<UserSubscription> result = userSubscriptionManager.findAll(
                spec, PageRequest.of(safePage, safeSize, ORDER));

        return PageResponse.from(result.map(userSubscriptionMapper::toAdminDto));
    }

    /**
     * Pose le solde de sessions EO temps réel d'une souscription (support :
     * offrir / corriger des sessions). Renvoie la souscription mise à jour.
     */
    @Transactional
    public AdminSubscriptionDto setRealtimeSessions(UUID subscriptionId, int remaining) {
        UserSubscription sub = userSubscriptionManager.findById(subscriptionId)
                .orElseThrow(() -> new NotFoundException(
                        "Souscription introuvable : " + subscriptionId));
        sub.setRealtimeEoSessionsRemaining(Math.max(0, remaining));
        userSubscriptionManager.save(sub);
        return userSubscriptionMapper.toAdminDto(sub);
    }
}

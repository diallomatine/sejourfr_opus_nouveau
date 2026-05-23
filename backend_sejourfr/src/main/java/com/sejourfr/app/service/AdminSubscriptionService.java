package com.sejourfr.app.service;

import com.sejourfr.app.dto.AdminSubscriptionDto;
import com.sejourfr.app.dto.AdminSubscriptionListResponse;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.SubscriptionSource;
import com.sejourfr.app.enums.SubscriptionStatus;
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

import java.util.List;

/**
 * Service admin pour la liste paginée des UserSubscription. Filtres optionnels
 * par source / status / moduleAccess et recherche LIKE sur email + nom. Tri :
 * plus récentes en tête (updatedAt desc) — utile pour voir les changements
 * récents (paiements, annulations, refunds).
 *
 * <p>L'open-in-view est désactivé : la transaction read-only ouverte ici
 * autorise les lookups lazy (User, Plan) faits dans {@link UserSubscriptionMapper}.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AdminSubscriptionService {

    private static final int MAX_SIZE = 100;

    private final UserSubscriptionManager userSubscriptionManager;
    private final UserSubscriptionMapper userSubscriptionMapper;

    public AdminSubscriptionListResponse list(
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
                spec,
                PageRequest.of(safePage, safeSize, Sort.by(Sort.Direction.DESC, "updatedAt"))
        );

        List<AdminSubscriptionDto> items = result.getContent().stream()
                .map(userSubscriptionMapper::toAdminDto)
                .toList();

        return new AdminSubscriptionListResponse(
                items,
                result.getTotalElements(),
                safePage,
                safeSize
        );
    }
}

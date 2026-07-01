package com.sejourfr.app.service;

import com.sejourfr.app.dto.AdminSubscriptionListResponse;
import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.mapper.UserSubscriptionMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Couvre le clamp de pagination (size dans [1,100], page &gt;= 0), le tri
 * updatedAt desc et le passage du total à la réponse. Les Specifications sont
 * construites par {@code UserSubscriptionSpecifications} (statiques, sans DB) ;
 * on capture juste le Pageable passé au manager. Test unitaire pur.
 */
class AdminSubscriptionServiceTest {

    private UserSubscriptionManager userSubscriptionManager;
    private UserSubscriptionMapper userSubscriptionMapper;
    private AdminSubscriptionService service;

    @BeforeEach
    void setUp() {
        userSubscriptionManager = mock(UserSubscriptionManager.class);
        userSubscriptionMapper = mock(UserSubscriptionMapper.class);
        service = new AdminSubscriptionService(userSubscriptionManager, userSubscriptionMapper);
    }

    @SuppressWarnings("unchecked")
    private Pageable captureListCall(Page<UserSubscription> page, int reqPage, int reqSize) {
        when(userSubscriptionManager.findAll(any(Specification.class), any(Pageable.class)))
                .thenReturn(page);
        service.list(null, null, null, null, reqPage, reqSize);
        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        org.mockito.Mockito.verify(userSubscriptionManager)
                .findAll(any(Specification.class), captor.capture());
        return captor.getValue();
    }

    @Test
    void clampSize_au_dessus_de_100_borneA100() {
        Pageable p = captureListCall(new PageImpl<>(List.of()), 0, 5000);
        assertThat(p.getPageSize()).isEqualTo(100);
    }

    @Test
    void clampSize_zeroOuNegatif_borneA1() {
        Pageable p = captureListCall(new PageImpl<>(List.of()), 0, 0);
        assertThat(p.getPageSize()).isEqualTo(1);
    }

    @Test
    void clampPage_negatif_borneA0() {
        Pageable p = captureListCall(new PageImpl<>(List.of()), -3, 20);
        assertThat(p.getPageNumber()).isEqualTo(0);
        assertThat(p.getPageSize()).isEqualTo(20);
    }

    @Test
    void tri_parUpdatedAtDescendant() {
        Pageable p = captureListCall(new PageImpl<>(List.of()), 0, 20);
        Sort.Order order = p.getSort().getOrderFor("updatedAt");
        assertThat(order).isNotNull();
        assertThat(order.getDirection()).isEqualTo(Sort.Direction.DESC);
    }

    @Test
    @SuppressWarnings("unchecked")
    void response_porteTotalEtPageSizeClampes() {
        UserSubscription sub = new UserSubscription();
        Page<UserSubscription> page = new PageImpl<>(
                List.of(sub), PageRequest.of(0, 100), 42L);
        when(userSubscriptionManager.findAll(any(Specification.class), any(Pageable.class)))
                .thenReturn(page);
        when(userSubscriptionMapper.toAdminDto(any())).thenReturn(null);

        AdminSubscriptionListResponse res = service.list(null, null, null, null, 0, 5000);

        // PageImpl normalise le total : avec une page de taille 100 à l'offset 0 et
        // un contenu d'1 élément, offset+pageSize (100) > total (42), donc PageImpl
        // recalcule total = offset + content.size() = 1. C'est ce que renvoie
        // getTotalElements() et donc ce que porte la réponse.
        assertThat(res.total()).isEqualTo(1L);
        assertThat(res.page()).isEqualTo(0);
        assertThat(res.size()).isEqualTo(100);
        assertThat(res.items()).hasSize(1);
    }
}

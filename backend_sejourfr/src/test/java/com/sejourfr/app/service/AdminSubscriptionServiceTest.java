package com.sejourfr.app.service;

import com.sejourfr.app.dto.AdminSubscriptionDto;
import com.sejourfr.app.dto.PageResponse;
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
 * updatedAt desc départagé par l'id, et le passage du total à la réponse. Les Specifications sont
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
    void tri_parUpdatedAtDescendant_puisIdDescendant() {
        Pageable p = captureListCall(new PageImpl<>(List.of()), 0, 20);
        assertThat(p.getSort().toList())
                .extracting(Sort.Order::getProperty, Sort.Order::getDirection)
                .containsExactly(
                        org.assertj.core.groups.Tuple.tuple("updatedAt", Sort.Direction.DESC),
                        org.assertj.core.groups.Tuple.tuple("id", Sort.Direction.DESC));
    }

    @Test
    @SuppressWarnings("unchecked")
    void response_porteTotalEtNombreDePages() {
        UserSubscription sub = new UserSubscription();
        Page<UserSubscription> page = new PageImpl<>(
                List.of(sub), PageRequest.of(2, 10), 42L);
        when(userSubscriptionManager.findAll(any(Specification.class), any(Pageable.class)))
                .thenReturn(page);
        when(userSubscriptionMapper.toAdminDto(any())).thenReturn(null);

        PageResponse<AdminSubscriptionDto> res = service.list(null, null, null, null, 2, 10);

        assertThat(res.totalElements()).isEqualTo(42L);
        assertThat(res.totalPages()).isEqualTo(5);
        assertThat(res.page()).isEqualTo(2);
        assertThat(res.size()).isEqualTo(10);
        assertThat(res.first()).isFalse();
        assertThat(res.last()).isFalse();
        assertThat(res.content()).hasSize(1);
    }
}

package com.sejourfr.app.service;

import com.sejourfr.app.dto.AnswerResultResponse;
import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.StartAttemptRequest;
import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.exception.BusinessException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * Pipeline guest : validations propres (type autorisé, IP présente) et
 * délégation à {@link AttemptService}. Unitaire pur (mock d'AttemptService).
 */
class PublicAttemptServiceTest {

    private AttemptService attemptService;
    private PublicAttemptService service;

    private final String ip = "203.0.113.7";

    @BeforeEach
    void setUp() {
        attemptService = mock(AttemptService.class);
        service = new PublicAttemptService(attemptService);
    }

    private static StartAttemptRequest req(AttemptType type) {
        return new StartAttemptRequest(type, Module.CIVIQUE, null, null, null, null, null, null, null, null, null);
    }

    @Test
    void startDemo_typeReview_refuse() {
        assertThatThrownBy(() -> service.startDemo(req(AttemptType.REVIEW), ip))
                .isInstanceOf(BusinessException.class);
        verifyNoInteractions(attemptService);
    }

    @Test
    void startDemo_ipNulle_refuse() {
        assertThatThrownBy(() -> service.startDemo(req(AttemptType.TRAINING), null))
                .isInstanceOf(BusinessException.class);
        verifyNoInteractions(attemptService);
    }

    @Test
    void startDemo_ipVide_refuse() {
        assertThatThrownBy(() -> service.startDemo(req(AttemptType.TRAINING), "  "))
                .isInstanceOf(BusinessException.class);
        verifyNoInteractions(attemptService);
    }

    @Test
    void startDemo_valide_delegueAuService() {
        StartAttemptRequest r = req(AttemptType.TRAINING);
        AttemptResponse expected = mock(AttemptResponse.class);
        when(attemptService.startGuestDemo(r, ip)).thenReturn(expected);

        assertThat(service.startDemo(r, ip)).isSameAs(expected);
        verify(attemptService).startGuestDemo(r, ip);
    }

    @Test
    void startDemo_mockExam_autorise() {
        StartAttemptRequest r = req(AttemptType.MOCK_EXAM);
        when(attemptService.startGuestDemo(eq(r), eq(ip))).thenReturn(mock(AttemptResponse.class));

        service.startDemo(r, ip);

        verify(attemptService).startGuestDemo(r, ip);
    }

    @Test
    void getDemoById_chargeParIp_puisLit() {
        UUID id = UUID.randomUUID();
        Attempt attempt = new Attempt();
        AttemptResponse expected = mock(AttemptResponse.class);
        when(attemptService.loadGuestAttempt(id, ip)).thenReturn(attempt);
        when(attemptService.readAttempt(attempt)).thenReturn(expected);

        assertThat(service.getDemoById(id, ip)).isSameAs(expected);
    }

    @Test
    void submitDemoAnswer_chargeParIp_puisSoumet() {
        UUID id = UUID.randomUUID();
        Attempt attempt = new Attempt();
        SubmitAnswerRequest sar = new SubmitAnswerRequest(UUID.randomUUID(), List.of(UUID.randomUUID()));
        AnswerResultResponse expected = mock(AnswerResultResponse.class);
        when(attemptService.loadGuestAttempt(id, ip)).thenReturn(attempt);
        when(attemptService.submitAnswerForAttempt(attempt, sar)).thenReturn(expected);

        assertThat(service.submitDemoAnswer(id, ip, sar)).isSameAs(expected);
        verify(attemptService).submitAnswerForAttempt(attempt, sar);
    }

    @Test
    void finishDemo_chargeParIp_puisTermine() {
        UUID id = UUID.randomUUID();
        Attempt attempt = new Attempt();
        AttemptResponse expected = mock(AttemptResponse.class);
        when(attemptService.loadGuestAttempt(id, ip)).thenReturn(attempt);
        when(attemptService.finishAttempt(attempt)).thenReturn(expected);

        assertThat(service.finishDemo(id, ip)).isSameAs(expected);
        verify(attemptService).finishAttempt(attempt);
    }
}

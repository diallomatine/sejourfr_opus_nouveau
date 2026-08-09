package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import org.junit.jupiter.api.Test;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class DiagnosticSessionFailureRecorderTest {

    @Test
    void recorderTardifNeRetrogradeJamaisUneSessionCompletee() {
        DiagnosticSessionManager sessions = mock(DiagnosticSessionManager.class);
        DiagnosticSessionFailureRecorder recorder = new DiagnosticSessionFailureRecorder(sessions);
        UUID attemptId = UUID.randomUUID();
        DiagnosticSession found = session(DiagnosticSessionStatus.ANALYZING);
        DiagnosticSession locked = session(DiagnosticSessionStatus.COMPLETED);
        locked.setId(found.getId());
        when(sessions.findByAttemptIdWithContent(attemptId)).thenReturn(Optional.of(found));
        when(sessions.findByIdForUpdate(found.getId())).thenReturn(Optional.of(locked));

        recorder.markFailedByAttempt(attemptId, "échec tardif");

        assertThat(locked.getStatus()).isEqualTo(DiagnosticSessionStatus.COMPLETED);
        assertThat(locked.getErrorMessage()).isNull();
        verify(sessions, never()).save(locked);
    }

    @Test
    void echecSousVerrouEstDurableEtMessageBorne() {
        DiagnosticSessionManager sessions = mock(DiagnosticSessionManager.class);
        DiagnosticSessionFailureRecorder recorder = new DiagnosticSessionFailureRecorder(sessions);
        UUID attemptId = UUID.randomUUID();
        DiagnosticSession session = session(DiagnosticSessionStatus.ANALYZING);
        when(sessions.findByAttemptIdWithContent(attemptId)).thenReturn(Optional.of(session));
        when(sessions.findByIdForUpdate(session.getId())).thenReturn(Optional.of(session));

        recorder.markFailedByAttempt(attemptId, "x".repeat(1200));

        assertThat(session.getStatus()).isEqualTo(DiagnosticSessionStatus.FAILED);
        assertThat(session.getErrorMessage()).hasSize(1000);
        verify(sessions).save(session);
    }

    private static DiagnosticSession session(DiagnosticSessionStatus status) {
        DiagnosticSession session = new DiagnosticSession();
        session.setId(UUID.randomUUID());
        session.setStatus(status);
        return session;
    }
}

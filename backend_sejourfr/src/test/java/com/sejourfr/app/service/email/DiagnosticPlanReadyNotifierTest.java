package com.sejourfr.app.service.email;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.manager.CivicDiagnosticSessionManager;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.TcfDiagnosticSessionManager;
import com.sejourfr.app.service.email.event.DiagnosticPlanReadyEvent;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;

import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** Arbitrage n°7 : le mail part a la PREMIERE ouverture du Plan d'un module, jamais a un affinage. */
class DiagnosticPlanReadyNotifierTest {

    private DiagnosticSessionManager rapide;
    private TcfDiagnosticSessionManager complet;
    private CivicDiagnosticSessionManager civique;
    private ApplicationEventPublisher events;
    private DiagnosticPlanReadyNotifier notifier;
    private User user;
    private final UUID session = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        rapide = mock(DiagnosticSessionManager.class);
        complet = mock(TcfDiagnosticSessionManager.class);
        civique = mock(CivicDiagnosticSessionManager.class);
        events = mock(ApplicationEventPublisher.class);
        notifier = new DiagnosticPlanReadyNotifier(rapide, complet, civique, events);
        user = new User();
        user.setId(UUID.randomUUID());
        user.setEmail("alice@example.com");
    }

    @Test
    void premierDiagnosticTcfClosPublie() {
        notifier.tcfClos(user, session);

        verify(events).publishEvent(new DiagnosticPlanReadyEvent(
                user.getId(), "alice@example.com", Module.TCF, session, false));
    }

    @Test
    void unCompletQuiAffineUnPlanExistantNePubliePas() {
        when(rapide.countCompletedExcluding(user.getId(), session)).thenReturn(1L);

        notifier.tcfClos(user, session);

        verify(events, never()).publishEvent(any(Object.class));
    }

    @Test
    void unRapideApresUnCompletClosNePubliePas() {
        when(complet.countCompletedExcluding(user.getId(), session)).thenReturn(1L);

        notifier.tcfClos(user, session);

        verify(events, never()).publishEvent(any(Object.class));
    }

    @Test
    void premierDiagnosticCiviquePublie() {
        notifier.civiqueClos(user, session);

        verify(events).publishEvent(new DiagnosticPlanReadyEvent(
                user.getId(), "alice@example.com", Module.CIVIQUE, session, false));
    }

    @Test
    void unSecondDiagnosticCiviqueNePubliePas() {
        when(civique.countCompletedExcluding(user.getId(), session)).thenReturn(1L);

        notifier.civiqueClos(user, session);
        notifier.civiqueAdopte(user, session);

        verify(events, never()).publishEvent(any(Object.class));
    }

    @Test
    void lAdoptionPublieUneConsommationDeCle() {
        notifier.civiqueAdopte(user, session);

        verify(events).publishEvent(new DiagnosticPlanReadyEvent(
                user.getId(), "alice@example.com", Module.CIVIQUE, session, true));
    }

    @Test
    void sansCompteRienNEstPublie() {
        notifier.tcfClos(null, session);
        notifier.civiqueClos(null, session);

        verify(events, never()).publishEvent(any(Object.class));
    }
}

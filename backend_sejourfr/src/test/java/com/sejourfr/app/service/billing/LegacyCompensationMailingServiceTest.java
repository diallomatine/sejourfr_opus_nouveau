package com.sejourfr.app.service.billing;

import com.sejourfr.app.entity.LegacyPassCompensation;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.manager.LegacyPassCompensationManager;
import com.sejourfr.app.service.MailService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * Mailing d'annonce aux acheteurs de l'ancien catalogue.
 *
 * <p>Ce qui compte ici : on n'écrit jamais deux fois à un vrai client payant, et
 * un envoi raté reste à retenter au lieu d'être perdu.
 */
@ExtendWith(MockitoExtension.class)
class LegacyCompensationMailingServiceTest {

    @Mock private LegacyPassCompensationManager compensationManager;
    @Mock private MailService mailService;
    @InjectMocks private LegacyCompensationMailingService service;

    private LegacyPassCompensation compensation;

    @BeforeEach
    void setUp() {
        User user = new User();
        user.setEmail("ancien@sejourfr.fr");
        user.setFirstName("Awa");

        compensation = new LegacyPassCompensation();
        compensation.setUser(user);
        compensation.setPlanCode("INTEGRAL_PASS_SPRINT");
        compensation.setDaysGranted(14);
        compensation.setSessionsAfter(5);
        compensation.setEndsAtAfter(Instant.now().plusSeconds(14 * 86400));
    }

    @Test
    void leDryRunCompteSansEcrireAPersonne() {
        when(compensationManager.findAEnvoyer()).thenReturn(List.of(compensation));
        when(compensationManager.countTotal()).thenReturn(8L);
        when(compensationManager.countDejaEnvoyes()).thenReturn(0L);

        var rapport = service.envoyer(true);

        assertTrue(rapport.dryRun());
        assertEquals(8L, rapport.total());
        assertEquals(1, rapport.aEnvoyer());
        assertEquals(0, rapport.envoyes());
        verifyNoInteractions(mailService);
        verify(compensationManager, never()).save(any());
    }

    @Test
    void unEnvoiReussiEstMarqueDoncJamaisRepete() {
        when(compensationManager.findAEnvoyer()).thenReturn(List.of(compensation));
        when(mailService.sendNouveautesAnciensAcheteursEmail(
                eq("ancien@sejourfr.fr"), eq("Awa"), eq(14), eq(5), any())).thenReturn(true);

        var rapport = service.envoyer(false);

        assertEquals(1, rapport.envoyes());
        assertEquals(0, rapport.echecs());
        assertNotNull(compensation.getMailedAt());
        verify(compensationManager).save(compensation);
    }

    @Test
    void unEnvoiRateResteAEnvoyer() {
        when(compensationManager.findAEnvoyer()).thenReturn(List.of(compensation));
        when(mailService.sendNouveautesAnciensAcheteursEmail(
                anyString(), any(), anyInt(), anyInt(), any())).thenReturn(false);

        var rapport = service.envoyer(false);

        assertEquals(0, rapport.envoyes());
        assertEquals(1, rapport.echecs());
        assertNull(compensation.getMailedAt(),
                "un mail qui n'est pas parti ne doit pas être marqué envoyé");
        verify(compensationManager, never()).save(any());
    }

    @Test
    void uneExceptionSurUnDestinataireNInterromptPasLesSuivants() {
        User second = new User();
        second.setEmail("second@sejourfr.fr");
        LegacyPassCompensation autre = new LegacyPassCompensation();
        autre.setUser(second);
        autre.setDaysGranted(21);
        autre.setSessionsAfter(15);

        when(compensationManager.findAEnvoyer()).thenReturn(List.of(compensation, autre));
        when(mailService.sendNouveautesAnciensAcheteursEmail(
                eq("ancien@sejourfr.fr"), any(), anyInt(), anyInt(), any()))
                .thenThrow(new IllegalStateException("SMTP down"));
        when(mailService.sendNouveautesAnciensAcheteursEmail(
                eq("second@sejourfr.fr"), any(), anyInt(), anyInt(), any())).thenReturn(true);

        var rapport = service.envoyer(false);

        assertEquals(1, rapport.envoyes());
        assertEquals(1, rapport.echecs());
        assertNull(compensation.getMailedAt());
        assertNotNull(autre.getMailedAt());
    }

    @Test
    void unCompteSansEmailEstCompteEnEchecEtNonMarque() {
        compensation.getUser().setEmail("  ");
        when(compensationManager.findAEnvoyer()).thenReturn(List.of(compensation));

        var rapport = service.envoyer(false);

        assertEquals(0, rapport.envoyes());
        assertEquals(1, rapport.echecs());
        assertNull(compensation.getMailedAt());
        verify(mailService, never()).sendNouveautesAnciensAcheteursEmail(
                any(), any(), anyInt(), anyInt(), any());
    }

    @Test
    void rappelerLEndpointNeReprendQueLesRestants() {
        // Le repository ne rend que mailed_at IS NULL : un second appel après un
        // envoi complet ne trouve plus personne.
        when(compensationManager.findAEnvoyer()).thenReturn(List.of());
        when(compensationManager.countTotal()).thenReturn(8L);
        when(compensationManager.countDejaEnvoyes()).thenReturn(8L);

        var rapport = service.envoyer(false);

        assertEquals(0, rapport.aEnvoyer());
        assertEquals(8L, rapport.dejaEnvoyes());
        verify(mailService, times(0)).sendNouveautesAnciensAcheteursEmail(
                any(), any(), anyInt(), anyInt(), any());
    }
}

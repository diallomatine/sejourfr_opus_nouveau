package com.sejourfr.app.service;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Ce qui compte comme un <b>examen complet</b> d'épreuve EE/EO.
 *
 * <p>Deux responsabilités, et une seule est ici : <b>quelles sessions</b> sont
 * lues (la requête, verrouillée en base par {@code EpreuveHistoriqueServiceIT}
 * et {@code TcfProfileServiceIT}) et <b>ce que chacune vaut</b> (le bilan,
 * verrouillé par {@code ProductionBilanServiceTest}). Ce test vérifie ce que le
 * resolver ajoute : il demande le niveau d'<b>épreuve</b> — jamais de tâche — et
 * il ne sert que ce qui porte un verdict.
 */
class EpreuvesProductionQualifiantesResolverTest {

    private AttemptManager attemptManager;
    private ProductionSubmissionManager submissionManager;
    private AiEvaluationManager aiEvaluationManager;
    private ProductionBilanService bilanService;
    private EpreuvesProductionQualifiantesResolver resolver;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        attemptManager = mock(AttemptManager.class);
        submissionManager = mock(ProductionSubmissionManager.class);
        aiEvaluationManager = mock(AiEvaluationManager.class);
        bilanService = mock(ProductionBilanService.class);
        resolver = new EpreuvesProductionQualifiantesResolver(
                attemptManager, submissionManager, aiEvaluationManager, bilanService);
    }

    private Attempt session(Instant fin) {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setSlotNumber(1);
        a.setFinishedAt(fin);
        return a;
    }

    private void stubSessions(EpreuveType epreuve, Attempt... attempts) {
        when(attemptManager.findProductionEpreuvesPassees(eq(userId), eq(epreuve), anyInt()))
                .thenReturn(List.of(attempts));
    }

    private void stubNiveau(NiveauCecrl niveau) {
        when(bilanService.niveauEpreuve(any(), any(), anyBoolean(), anyBoolean()))
                .thenReturn(new ProductionBilanService.NiveauEpreuve(niveau, false, Map.of()));
    }

    /**
     * 🛑 <b>Le cas du propriétaire</b> : un candidat qui n'a fait que de
     * l'entraînement libre n'a AUCUNE session qualifiante. La requête ne rend
     * rien (ni slot ni parent), donc le bilan n'est même pas sollicité.
     */
    @Test
    void aucuneSessionDExamen_rendUneListeVide_etNeCalculeAucunBilan() {
        assertThat(resolver.qualifiantes(userId, EpreuveType.TCF_EO, 200)).isEmpty();

        verify(bilanService, org.mockito.Mockito.never())
                .niveauEpreuve(any(), any(), anyBoolean(), anyBoolean());
        // 🛑 Et surtout : AUCUNE requête de plus. Un candidat qui n'a jamais
        // passé d'épreuve ne paie pas le prix de ceux qui en ont.
        verify(submissionManager, org.mockito.Mockito.never()).findByAttemptIdsGrouped(any());
        verify(aiEvaluationManager, org.mockito.Mockito.never()).findLatestBySubmissionIds(any());
    }

    /**
     * 🛑 <b>Le coût ne grandit pas avec l'historique</b> : dix sessions se lisent
     * en <b>un</b> lot de soumissions et <b>un</b> lot d'évaluations, jamais une
     * requête par session ni par soumission.
     */
    @Test
    void dixSessions_seLisentEnUnSeulLot_jamaisUneRequeteParSession() {
        Attempt[] sessions = new Attempt[10];
        for (int i = 0; i < sessions.length; i++) {
            sessions[i] = session(Instant.now().minusSeconds(86_400L * i));
        }
        stubSessions(EpreuveType.TCF_EE, sessions);
        when(submissionManager.findByAttemptIdsGrouped(any())).thenReturn(Map.of());
        stubNiveau(NiveauCecrl.B1);

        resolver.qualifiantes(userId, EpreuveType.TCF_EE, 200);

        verify(submissionManager, org.mockito.Mockito.times(1)).findByAttemptIdsGrouped(any());
        verify(aiEvaluationManager, org.mockito.Mockito.times(1)).findLatestBySubmissionIds(any());
        verify(submissionManager, org.mockito.Mockito.never()).findByAttemptId(any());
    }

    /**
     * 🛑 Le niveau servi est celui de l'<b>épreuve</b>, demandé en mode
     * « examen terminé » — les deux drapeaux sont vrais par construction, la
     * requête ne rendant que des sessions d'examen finies.
     */
    @Test
    void uneSessionDExamen_estServieAvecLeNiveauDEpreuve_pasDeTache() {
        Instant fin = Instant.now();
        Attempt a = session(fin);
        stubSessions(EpreuveType.TCF_EE, a);
        ProductionSubmission sub = new ProductionSubmission();
        sub.setId(UUID.randomUUID());
        List<ProductionSubmission> subs = List.of(sub);
        when(submissionManager.findByAttemptIdsGrouped(any())).thenReturn(Map.of(a.getId(), subs));
        stubNiveau(NiveauCecrl.B1);

        List<EpreuvesProductionQualifiantesResolver.EpreuveQualifiante> out =
                resolver.qualifiantes(userId, EpreuveType.TCF_EE, 200);

        assertThat(out).singleElement().satisfies(q -> {
            assertThat(q.niveau()).isEqualTo(NiveauCecrl.B1);
            assertThat(q.mesureA()).isEqualTo(fin);
            assertThat(q.attempt()).isSameAs(a);
        });
        verify(bilanService).niveauEpreuve(eq(subs), any(), eq(true), eq(true));
    }

    /**
     * 🛑 <b>{@code null} = inconnu, jamais mauvais.</b> Une session dont rien
     * n'est encore exploitable (évaluation en vol, tâche en échec, production
     * inexploitable) n'est pas servie — elle ne devient surtout pas un
     * {@code A1_NON_ATTEINT} qui tirerait le profil au fond.
     */
    @Test
    void uneSessionSansVerdict_nEstPasServie_etNeDevientPasUnMauvaisNiveau() {
        Attempt a = session(Instant.now());
        stubSessions(EpreuveType.TCF_EO, a);
        when(submissionManager.findByAttemptIdsGrouped(any())).thenReturn(Map.of());
        stubNiveau(null);

        assertThat(resolver.qualifiantes(userId, EpreuveType.TCF_EO, 200)).isEmpty();
    }

    /** L'ordre de la requête est conservé : la plus récente d'abord. */
    @Test
    void lOrdreDeLaRequeteEstConserve() {
        Instant recent = Instant.now();
        Instant ancien = recent.minusSeconds(86_400);
        Attempt a = session(recent);
        Attempt b = session(ancien);
        stubSessions(EpreuveType.TCF_EE, a, b);
        when(submissionManager.findByAttemptIdsGrouped(any())).thenReturn(Map.of());
        stubNiveau(NiveauCecrl.A2);

        assertThat(resolver.qualifiantes(userId, EpreuveType.TCF_EE, 200))
                .extracting(EpreuvesProductionQualifiantesResolver.EpreuveQualifiante::mesureA)
                .containsExactly(recent, ancien);
    }
}

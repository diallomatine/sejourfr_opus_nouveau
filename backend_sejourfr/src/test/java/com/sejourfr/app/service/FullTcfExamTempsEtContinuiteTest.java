package com.sejourfr.app.service;

import com.sejourfr.app.dto.FullTcfExamResponse;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.ContinuiteSimulation;
import com.sejourfr.app.enums.DureeEpreuve;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Ce que le read-model d'un examen blanc complet doit dire du TEMPS.
 *
 * <p>Trois acquis à ne pas perdre :
 * <ul>
 *   <li>chaque sous-épreuve porte <b>sa</b> durée et <b>son</b> échéance — les
 *       fronts avaient recopié les minutes en dur, et elles avaient déjà
 *       divergé (CE annoncée 30 min ici, 35 là) ;</li>
 *   <li>l'oral n'a <b>pas</b> de chrono d'épreuve : le lire à null est le
 *       contrat, pas un oubli ;</li>
 *   <li>« d'une traite » ou « en plusieurs sessions » est dérivé serveur, à la
 *       lecture, et n'est jamais persisté.</li>
 * </ul>
 */
class FullTcfExamTempsEtContinuiteTest {

    private static final Instant T0 = Instant.parse("2026-08-15T09:00:00Z");

    private static final EpreuveType[] ORDRE = {
            EpreuveType.TCF_CO, EpreuveType.TCF_CE,
            EpreuveType.TCF_EE, EpreuveType.TCF_EO};

    private AttemptManager attemptManager;
    private FullTcfExamResponseBuilder builder;

    @BeforeEach
    void setUp() {
        attemptManager = mock(AttemptManager.class);
        ProductionSubmissionManager productionSubmissionManager = mock(ProductionSubmissionManager.class);
        ProductionBilanService productionBilanService = mock(ProductionBilanService.class);
        builder = new FullTcfExamResponseBuilder(
                attemptManager, productionSubmissionManager,
                new TcfLevelEstimatorService(), productionBilanService);

        when(productionSubmissionManager.findByAttemptId(any())).thenReturn(List.of());
        when(productionBilanService.latestEvalsByTache(any())).thenReturn(Map.of());
        when(productionBilanService.bilanEpreuveTerminee(any())).thenReturn(NiveauCecrl.B1);
        when(productionBilanService.bilanEpreuve(any())).thenReturn(NiveauCecrl.B1);
    }

    // ------------------------------------------------------------------ fixtures

    private Attempt parent(Integer finMin) {
        Attempt p = new Attempt();
        p.setId(UUID.randomUUID());
        p.setEpreuve(EpreuveType.TCF_COMPLET);
        p.setStartedAt(T0);
        p.setTimerStartedAt(T0);
        if (finMin != null) {
            p.setFinishedAt(T0.plus(Duration.ofMinutes(finMin)));
            p.setStatus(AttemptStatus.TERMINE);
        } else {
            p.setStatus(AttemptStatus.EN_COURS);
        }
        return p;
    }

    /** Sous-épreuve lancée à {@code debutMin} et terminée à {@code finMin} (minutes depuis T0). */
    private static Attempt sub(Attempt parent, EpreuveType e, Integer debutMin, Integer finMin) {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setEpreuve(e);
        a.setParentAttempt(parent);
        a.setStartedAt(T0);
        a.setTimeLimitSeconds(DureeEpreuve.secondes(e));
        if (debutMin != null) a.setTimerStartedAt(T0.plus(Duration.ofMinutes(debutMin)));
        if (finMin != null) {
            a.setFinishedAt(T0.plus(Duration.ofMinutes(finMin)));
            a.setStatus(AttemptStatus.TERMINE);
        }
        if ((e == EpreuveType.TCF_CO || e == EpreuveType.TCF_CE) && finMin != null) {
            a.setCecrlLevel(NiveauCecrl.B1);
        }
        return a;
    }

    /**
     * Les 4 sous-épreuves dans l'ordre canonique, décrites par
     * {@code {debut, fin}} en minutes depuis T0 ({@code null} = pas lancée /
     * pas terminée).
     */
    private List<Attempt> quatreEpreuves(Attempt parent, Integer[][] minutes) {
        List<Attempt> subs = new ArrayList<>();
        for (int i = 0; i < ORDRE.length; i++) {
            subs.add(sub(parent, ORDRE[i], minutes[i][0], minutes[i][1]));
        }
        return subs;
    }

    private FullTcfExamResponse build(Attempt parent, List<Attempt> subs) {
        when(attemptManager.findSubAttempts(parent.getId())).thenReturn(subs);
        return builder.buildResponse(parent);
    }

    private static FullTcfExamResponse.SubAttempt of(FullTcfExamResponse r, EpreuveType e) {
        return r.subAttempts().stream().filter(s -> s.epreuve() == e).findFirst().orElseThrow();
    }

    private static Integer[][] enchaine() {
        return new Integer[][]{{0, 20}, {21, 56}, {57, 87}, {88, 98}};
    }

    // ------------------------------------------------------------------ durées

    @Test
    @DisplayName("Chaque sous-epreuve porte sa duree ; l'oral n'en a pas")
    void dureesParSousEpreuve() {
        Attempt p = parent(100);
        FullTcfExamResponse r = build(p, quatreEpreuves(p, enchaine()));

        assertThat(of(r, EpreuveType.TCF_CO).timeLimitSeconds()).isEqualTo(20 * 60);
        // 35 min, comme en standalone : la CE n'est plus raccourcie à 30 min.
        assertThat(of(r, EpreuveType.TCF_CE).timeLimitSeconds()).isEqualTo(35 * 60);
        assertThat(of(r, EpreuveType.TCF_EE).timeLimitSeconds()).isEqualTo(30 * 60);
        assertThat(of(r, EpreuveType.TCF_EO).timeLimitSeconds()).isNull();
    }

    @Test
    @DisplayName("L'echeance est calculee serveur depuis le lancement reel de l'epreuve")
    void echeanceServie() {
        Attempt p = parent(100);
        FullTcfExamResponse r = build(p, quatreEpreuves(p, enchaine()));

        FullTcfExamResponse.SubAttempt ce = of(r, EpreuveType.TCF_CE);
        assertThat(ce.timerStartedAt()).isEqualTo(T0.plus(Duration.ofMinutes(21)));
        // 21 min + 35 min : le temps non consommé sur la CO ne se reporte pas.
        assertThat(ce.deadlineAt()).isEqualTo(T0.plus(Duration.ofMinutes(56)));
        // L'oral n'a pas de chrono, donc pas d'échéance non plus.
        assertThat(of(r, EpreuveType.TCF_EO).deadlineAt()).isNull();
    }

    @Test
    @DisplayName("Tant qu'une epreuve n'est pas lancee, elle n'a ni ancre ni echeance")
    void epreuveNonLancee() {
        Attempt p = parent(null);
        FullTcfExamResponse r = build(p, quatreEpreuves(p, new Integer[][]{
                {0, 20}, {null, null}, {null, null}, {null, null}}));

        FullTcfExamResponse.SubAttempt co = of(r, EpreuveType.TCF_CO);
        assertThat(co.timerStartedAt()).isEqualTo(T0);
        assertThat(co.deadlineAt()).isEqualTo(T0.plusSeconds(20 * 60));

        FullTcfExamResponse.SubAttempt ce = of(r, EpreuveType.TCF_CE);
        assertThat(ce.timerStartedAt()).isNull();
        assertThat(ce.deadlineAt()).isNull();
        // La durée reste servie : le briefing affiche « CE · 35 min » avant même
        // que l'épreuve ne soit ouverte.
        assertThat(ce.timeLimitSeconds()).isEqualTo(35 * 60);
    }

    @Test
    @DisplayName("Une epreuve verrouillee n'a aucune donnee de temps")
    void epreuveVerrouillee() {
        Attempt p = parent(60);
        p.setProductionLocked(true);
        FullTcfExamResponse r = build(p, quatreEpreuves(p, new Integer[][]{
                {0, 20}, {21, 56}, {null, 57}, {null, 57}}));

        FullTcfExamResponse.SubAttempt ee = of(r, EpreuveType.TCF_EE);
        assertThat(ee.locked()).isTrue();
        assertThat(ee.timeLimitSeconds()).isNull();
        assertThat(ee.timerStartedAt()).isNull();
        assertThat(ee.deadlineAt()).isNull();
    }

    // ------------------------------------------------------------------ continuité

    @Test
    @DisplayName("Examen enchaine d'une traite")
    void duneTraite() {
        Attempt p = parent(100);
        FullTcfExamResponse r = build(p, quatreEpreuves(p, enchaine()));

        assertThat(r.continuite()).isEqualTo(ContinuiteSimulation.SESSION_UNIQUE);
    }

    @Test
    @DisplayName("Une reprise entre deux epreuves declasse la simulation")
    void repriseEntreDeuxEpreuves() {
        Attempt p = parent(60 * 24 + 20);
        FullTcfExamResponse r = build(p, quatreEpreuves(p, new Integer[][]{
                {0, 20}, {21, 56}, {57, 87}, {60 * 24, 60 * 24 + 10}}));

        assertThat(r.continuite()).isEqualTo(ContinuiteSimulation.PLUSIEURS_SESSIONS);
    }

    @Test
    @DisplayName("Tant que l'examen court, la question ne se pose pas")
    void nullTantQueNonTermine() {
        Attempt p = parent(null);
        FullTcfExamResponse r = build(p, quatreEpreuves(p, new Integer[][]{
                {0, 20}, {21, 56}, {57, 87}, {88, null}}));

        assertThat(r.continuite()).isNull();
    }

    @Test
    @DisplayName("Le resume porte la meme continuite que le detail")
    void resumeAligne() {
        Attempt p = parent(100);
        when(attemptManager.findSubAttempts(p.getId()))
                .thenReturn(quatreEpreuves(p, enchaine()));

        assertThat(builder.buildSummary(p).continuite())
                .isEqualTo(builder.buildResponse(p).continuite())
                .isEqualTo(ContinuiteSimulation.SESSION_UNIQUE);
    }

    @Test
    @DisplayName("La continuite ne rend PAS compte du perimetre du niveau — c'est finalLevelPartial")
    void continuiteEtPerimetreSontDeuxChoses() {
        Attempt p = parent(100);
        p.setProductionLocked(true);
        FullTcfExamResponse r = build(p, quatreEpreuves(p, new Integer[][]{
                {0, 20}, {21, 56}, {null, 57}, {null, 57}}));

        // Enchaîné d'une traite ET bilan partiel : les deux notions coexistent,
        // la seconde n'est pas une troisième valeur de la première.
        assertThat(r.continuite()).isEqualTo(ContinuiteSimulation.SESSION_UNIQUE);
        assertThat(r.finalLevelPartial()).isTrue();
        assertThat(r.epreuvesCountedInFinalLevel()).isEqualTo(2);
    }
}

package com.sejourfr.app.service;

import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.AttemptManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Niveau TCF d'un candidat : plancher des 4 épreuves, chacune retenant son
 * MEILLEUR résultat, une épreuve jamais réellement passée étant exclue.
 *
 * <p>Les managers sont mockés ; {@link TcfLevelEstimatorService} (math CECRL
 * pure) est instancié réel pour exercer le vrai plancher / plafond B2.
 * L'exclusion des examens QCM sans aucune réponse vit dans la requête et est
 * verrouillée par {@code AttemptManagerIT}.
 */
class TcfProfileServiceTest {

    private AttemptManager attemptManager;
    private AiEvaluationManager aiEvaluationManager;
    private TcfProfileService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        attemptManager = mock(AttemptManager.class);
        aiEvaluationManager = mock(AiEvaluationManager.class);
        service = new TcfProfileService(attemptManager, aiEvaluationManager,
                new TcfLevelEstimatorService());
    }

    // ------------------------------------------------------------------ fixtures

    private static Attempt qcm(NiveauCecrl level) {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setFinishedAt(Instant.now());
        a.setCecrlLevel(level);
        a.setWeightedScore(25);
        a.setMaxWeightedScore(50);
        return a;
    }

    private static AiEvaluation eval(NiveauCecrl level, Instant at) {
        ProductionSubmission sub = new ProductionSubmission();
        sub.setId(UUID.randomUUID());
        AiEvaluation e = new AiEvaluation();
        e.setSubmission(sub);
        e.setNiveauCecrl(level);
        e.setEvaluatedAt(at);
        return e;
    }

    private void stubQcm(EpreuveType epreuve, List<Attempt> attempts) {
        when(attemptManager.findQcmEpreuvesPassees(eq(userId), eq(epreuve), anyInt()))
                .thenReturn(attempts);
    }

    private void stubProduction(EpreuveType epreuve, List<AiEvaluation> evals) {
        when(aiEvaluationManager.findByUserAndEpreuve(userId, epreuve)).thenReturn(evals);
    }

    // ------------------------------------------------------------------ aucune donnée

    @Test
    void aucuneDonnee_niveauInconnu_jamaisA1NonAtteint() {
        TcfLevelProfile p = service.levelProfile(userId);

        assertThat(p.co()).isNull();
        assertThat(p.ce()).isNull();
        assertThat(p.ee()).isNull();
        assertThat(p.eo()).isNull();
        assertThat(p.globalLevel()).isNull();
    }

    // ------------------------------------------------------------------ meilleur, pas dernier

    @Test
    void qcm_retientLeMeilleurExamen_pasLeDernier() {
        // Ordre de la requête = du plus récent au plus ancien : le dernier
        // examen est A1_NON_ATTEINT, le meilleur est B2.
        stubQcm(EpreuveType.TCF_CO,
                List.of(qcm(NiveauCecrl.A1_NON_ATTEINT), qcm(NiveauCecrl.B2), qcm(NiveauCecrl.A2)));

        assertThat(service.levelProfile(userId).co()).isEqualTo(NiveauCecrl.B2);
    }

    @Test
    void production_retientLaMeilleureTache_pasLaDerniere() {
        Instant now = Instant.now();
        stubProduction(EpreuveType.TCF_EE, List.of(
                eval(NiveauCecrl.A2, now),
                eval(NiveauCecrl.B1, now.minus(3, ChronoUnit.DAYS)),
                eval(NiveauCecrl.A1, now.minus(5, ChronoUnit.DAYS))));

        assertThat(service.levelProfile(userId).ee()).isEqualTo(NiveauCecrl.B1);
    }

    @Test
    void qcm_niveauDeriveDuScorePondere_quandCecrlLevelAbsent() {
        Attempt legacy = qcm(null);
        legacy.setWeightedScore(50);
        legacy.setMaxWeightedScore(50);
        stubQcm(EpreuveType.TCF_CE, List.of(legacy));

        assertThat(service.levelProfile(userId).ce()).isEqualTo(NiveauCecrl.B2);
    }

    // ------------------------------------------------------- plancher produit A1

    /**
     * Le <b>plancher produit SejourFR</b> (« au moins une bonne réponse ⇒ au
     * moins A1 ») se propage ici <b>sans être recodé</b> : le service ne fait
     * que lire {@code cecrl_level}, ou le dériver par
     * {@link TcfLevelEstimatorService#levelFromWeighted}, qui le porte déjà.
     * 1/50 pondéré (2 %, sous la ligne du hasard) valait
     * {@code A1_NON_ATTEINT} ; il vaut désormais A1.
     */
    @Test
    void plancherProduit_uneBonneReponseSuffitAFaireA1_sansRecoderLaRegle() {
        Attempt legacy = qcm(null);
        legacy.setWeightedScore(1);
        legacy.setMaxWeightedScore(50);
        stubQcm(EpreuveType.TCF_CO, List.of(legacy));

        assertThat(service.levelProfile(userId).co()).isEqualTo(NiveauCecrl.A1);
    }

    /** Zéro bonne réponse : le plancher ne rachète rien, l'épreuve reste au plus bas. */
    @Test
    void plancherProduit_zeroBonneReponse_resteA1NonAtteint() {
        Attempt legacy = qcm(null);
        legacy.setWeightedScore(0);
        legacy.setMaxWeightedScore(50);
        stubQcm(EpreuveType.TCF_CO, List.of(legacy));

        assertThat(service.levelProfile(userId).co()).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
    }

    // ------------------------------------------------------------------ épreuve non passée

    @Test
    void epreuveSansAucuneSoumission_estExclue_etNeTirePasLeNiveauVersLeBas() {
        // EE évaluée B1, EO jamais rendue, CO/CE jamais passées.
        stubProduction(EpreuveType.TCF_EE, List.of(eval(NiveauCecrl.B1, Instant.now())));

        TcfLevelProfile p = service.levelProfile(userId);

        assertThat(p.ee()).isEqualTo(NiveauCecrl.B1);
        assertThat(p.eo()).isNull();
        assertThat(p.globalLevel()).isEqualTo(NiveauCecrl.B1);
    }

    @Test
    void uneEvaluationEeFaitRemonterLeNiveau_malgreUnExamenCompletRateEtAbandonne() {
        // Cas réel user@sejourfr.fr : l'examen complet du 04/08 est parti sans
        // aucune réponse (donc exclu par la requête, rien à stubber ici) et 14
        // évaluations EE/EO ont suivi.
        stubProduction(EpreuveType.TCF_EE, List.of(
                eval(NiveauCecrl.B1, Instant.now()),
                eval(NiveauCecrl.A2, Instant.now().minus(1, ChronoUnit.DAYS))));
        stubProduction(EpreuveType.TCF_EO, List.of(
                eval(NiveauCecrl.B1, Instant.now().minus(2, ChronoUnit.DAYS)),
                eval(NiveauCecrl.A1, Instant.now().minus(9, ChronoUnit.DAYS))));

        assertThat(service.levelProfile(userId).globalLevel()).isEqualTo(NiveauCecrl.B1);
    }

    // ------------------------------------------------------------------ plancher

    @Test
    void global_estLePlancherDesEpreuvesRenseignees() {
        stubQcm(EpreuveType.TCF_CO, List.of(qcm(NiveauCecrl.B2)));
        stubQcm(EpreuveType.TCF_CE, List.of(qcm(NiveauCecrl.B2)));
        stubProduction(EpreuveType.TCF_EE, List.of(eval(NiveauCecrl.B1, Instant.now())));
        stubProduction(EpreuveType.TCF_EO, List.of(eval(NiveauCecrl.A2, Instant.now())));

        TcfLevelProfile p = service.levelProfile(userId);

        assertThat(p.globalLevel()).isEqualTo(NiveauCecrl.A2);
        // 4 épreuves comptées : le niveau porte sur tout, rien à annoter.
        assertThat(p.epreuvesCounted()).isEqualTo(4);
        assertThat(p.partial()).isFalse();
    }

    // ------------------------------------------------------------------ périmètre

    @Test
    void perimetre_uneSeuleEpreuvePassee_estPartiel() {
        stubProduction(EpreuveType.TCF_EE, List.of(eval(NiveauCecrl.B1, Instant.now())));

        TcfLevelProfile p = service.levelProfile(userId);

        assertThat(p.globalLevel()).isEqualTo(NiveauCecrl.B1);
        assertThat(p.epreuvesCounted()).isEqualTo(1);
        assertThat(p.epreuvesCounted()).isLessThan(TcfLevelProfile.EPREUVES_EXPECTED);
        assertThat(p.partial()).isTrue();
    }

    @Test
    void perimetre_aucuneEpreuve_nEstPasPartiel_carIlNyARienAAnnoter() {
        TcfLevelProfile p = service.levelProfile(userId);

        assertThat(p.globalLevel()).isNull();
        assertThat(p.epreuvesCounted()).isZero();
        assertThat(p.partial()).isFalse();
    }

    @Test
    void niveauxPlafonnesB2() {
        stubProduction(EpreuveType.TCF_EE, List.of(eval(NiveauCecrl.C1, Instant.now())));

        TcfLevelProfile p = service.levelProfile(userId);

        assertThat(p.ee()).isEqualTo(NiveauCecrl.B2);
        assertThat(p.globalLevel()).isEqualTo(NiveauCecrl.B2);
    }

    // ------------------------------------------------------------------ ré-évaluation

    @Test
    void production_surUneMemeSoumission_seuleLaPlusRecenteFaitFoi() {
        ProductionSubmission sub = new ProductionSubmission();
        sub.setId(UUID.randomUUID());

        AiEvaluation perimee = new AiEvaluation();
        perimee.setSubmission(sub);
        perimee.setNiveauCecrl(NiveauCecrl.B2);
        perimee.setEvaluatedAt(Instant.now().minus(1, ChronoUnit.HOURS));

        AiEvaluation courante = new AiEvaluation();
        courante.setSubmission(sub);
        courante.setNiveauCecrl(NiveauCecrl.A2);
        courante.setEvaluatedAt(Instant.now());

        stubProduction(EpreuveType.TCF_EO, List.of(perimee, courante));

        assertThat(service.levelProfile(userId).eo()).isEqualTo(NiveauCecrl.A2);
    }
}

package com.sejourfr.app.service;

import com.sejourfr.app.dto.FullTcfExamResponse;
import com.sejourfr.app.dto.FullTcfExamSummaryResponse;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.manager.AnswerManager;
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
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Verrouille la RESTITUTION du bilan d'un examen blanc TCF complet — ce que le
 * candidat lit, par opposition aux règles qui la produisent :
 *
 * <ul>
 *   <li>une épreuve <b>verrouillée</b> par le freemium n'a pas été passée :
 *       elle n'a aucun niveau et sort du plancher global. Un verrou commercial
 *       n'est pas un verdict de langue — le défaut historique affichait
 *       « A1 non atteint » à un candidat qui n'avait simplement pas payé ;</li>
 *   <li>une épreuve close <b>sans avoir jamais été ouverte</b> (le candidat a
 *       quitté après la CE ; les fronts clôturent le reste pour permettre
 *       l'abandon) n'a pas non plus de niveau — à ne pas confondre avec une
 *       épreuve OUVERTE puis écourtée, qui vaut A1_NON_ATTEINT et compte ;</li>
 *   <li>une épreuve dont les évaluations IA ont <b>échoué</b> est également hors
 *       plancher (niveau inconnu, pas mauvais niveau) ;</li>
 *   <li>dans les deux cas le périmètre réel du plancher est publié
 *       ({@code epreuvesCountedInFinalLevel} / {@code finalLevelPartial}), pour
 *       que les fronts n'affirment pas « le plus bas de tes 4 épreuves » quand
 *       il n'y en a que 2 ou 3.</li>
 * </ul>
 *
 * <p>Unitaire pur. {@link TcfLevelEstimatorService} est utilisé RÉEL (sans
 * dépendance, c'est la math CECRL elle-même) ; seul le bilan de production est
 * mocké, ses propres règles étant couvertes par {@code ProductionBilanServiceTest}.
 */
class FullTcfExamResponseBuilderTest {

    private AttemptManager attemptManager;
    private AnswerManager answerManager;
    private ProductionSubmissionManager productionSubmissionManager;
    private ProductionBilanService productionBilanService;
    private FullTcfExamResponseBuilder builder;

    @BeforeEach
    void setUp() {
        attemptManager = mock(AttemptManager.class);
        answerManager = mock(AnswerManager.class);
        productionSubmissionManager = mock(ProductionSubmissionManager.class);
        productionBilanService = mock(ProductionBilanService.class);
        builder = new FullTcfExamResponseBuilder(
                attemptManager, answerManager, productionSubmissionManager,
                new TcfLevelEstimatorService(), productionBilanService);

        when(productionSubmissionManager.findByAttemptId(any())).thenReturn(List.of());
        // Fidèle au vrai service : seules les submissions EVALUATED donnent une
        // évaluation exploitable (une par tâche). Une épreuve dont tout a échoué
        // rend donc une map vide, comme en production.
        when(productionBilanService.latestEvalsByTache(any())).thenAnswer(inv -> {
            List<ProductionSubmission> subs = inv.getArgument(0);
            Map<Integer, AiEvaluation> out = new java.util.LinkedHashMap<>();
            int tache = 1;
            for (ProductionSubmission s : subs) {
                if (s.getStatut() == SubmissionStatut.EVALUATED) {
                    out.put(tache++, new AiEvaluation());
                }
            }
            return out;
        });
        // Une épreuve productive terminée sans aucune tâche rendue vaut
        // A1_NON_ATTEINT : c'est précisément ce qu'on ne veut PAS voir remonter
        // sur une épreuve verrouillée.
        when(productionBilanService.bilanEpreuveTerminee(any()))
                .thenReturn(NiveauCecrl.A1_NON_ATTEINT);
        when(productionBilanService.bilanEpreuve(any())).thenReturn(NiveauCecrl.B1);
    }

    // ------------------------------------------------------------------ fixtures

    /** Parent TCF_COMPLET terminé, verrou de production optionnel. */
    private Attempt parent(boolean productionLocked) {
        Attempt p = new Attempt();
        p.setId(UUID.randomUUID());
        p.setEpreuve(EpreuveType.TCF_COMPLET);
        p.setStartedAt(Instant.now().minusSeconds(5400));
        p.setFinishedAt(Instant.now());
        p.setStatus(AttemptStatus.TERMINE);
        p.setProductionLocked(productionLocked);
        return p;
    }

    /**
     * Sous-attempt QCM terminé portant son niveau persisté. <b>Ouvert</b> :
     * {@code timerStartedAt} posé — une épreuve qui porte un score a
     * forcément été lancée, et sans cette ancre elle serait « jamais
     * ouverte », donc sans niveau.
     */
    private static Attempt qcm(EpreuveType e, NiveauCecrl level) {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setEpreuve(e);
        a.setTimerStartedAt(Instant.now().minusSeconds(1200));
        a.setFinishedAt(Instant.now());
        a.setStatus(AttemptStatus.TERMINE);
        a.setCecrlLevel(level);
        a.setWeightedScore(40);
        a.setMaxWeightedScore(50);
        return a;
    }

    /**
     * Sous-attempt productif terminé (EE/EO) et <b>ouvert</b> : le candidat a
     * lancé l'épreuve. C'est ce qui la distingue de {@link #jamaisOuverte} —
     * ouverte puis écourtée, elle a un vrai résultat ; jamais ouverte, elle
     * n'en a aucun.
     */
    private static Attempt production(EpreuveType e) {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setEpreuve(e);
        a.setTimerStartedAt(Instant.now().minusSeconds(1800));
        a.setFinishedAt(Instant.now());
        a.setStatus(AttemptStatus.TERMINE);
        return a;
    }

    /**
     * Sous-attempt clos <b>sans avoir jamais été ouvert</b> : aucune ancre de
     * chrono ({@code timerStartedAt} null, le seul signal de lancement d'une
     * sous-épreuve) et rien de rendu. C'est ce que produisent les fronts quand
     * le candidat abandonne l'examen : ils clôturent les épreuves restantes
     * avant d'appeler {@code finish}.
     */
    private static Attempt jamaisOuverte(EpreuveType e) {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setEpreuve(e);
        a.setFinishedAt(Instant.now());
        a.setStatus(AttemptStatus.TERMINE);
        return a;
    }

    private static ProductionSubmission submission(SubmissionStatut statut) {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(UUID.randomUUID());
        s.setStatut(statut);
        return s;
    }

    private static FullTcfExamResponse.SubAttempt subOf(FullTcfExamResponse r, EpreuveType e) {
        return r.subAttempts().stream().filter(s -> s.epreuve() == e).findFirst().orElseThrow();
    }

    // ------------------------------------------------------- score calibré

    /**
     * Ce que le candidat lit sur le hub de progression : le relevé du TCF se
     * lit sur 100-499, pas sur le score pondéré interne (« 23/50 »), qui ne
     * veut rien dire pour lui. Le pondéré reste servi comme repli.
     *
     * <p>40/50 pondéré = 80 % brut, corrigé du hasard (25 %) → (0,80 − 0,25)
     * / 0,75 = 0,7333 → 100 + 0,7333 × 399 = <b>393</b>. La valeur est celle
     * du vrai {@link TcfLevelEstimatorService} : si elle bouge ici sans avoir
     * bougé là-bas, c'est qu'une copie de la formule s'est glissée quelque part.
     */
    @Test
    void sousEpreuvesQcm_portentLeScoreCalibre100_499() {
        Attempt p = parent(false);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.B1),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B1),
                production(EpreuveType.TCF_EE),
                production(EpreuveType.TCF_EO)));

        FullTcfExamResponse r = builder.buildResponse(p);

        int attendu = new TcfLevelEstimatorService().calibratedScore(40, 50);
        assertThat(attendu).isEqualTo(393);
        assertThat(subOf(r, EpreuveType.TCF_CO).calibratedScore()).isEqualTo(attendu);
        assertThat(subOf(r, EpreuveType.TCF_CE).calibratedScore()).isEqualTo(attendu);
        // Le pondéré reste servi : c'est le repli des fronts, pas leur affichage.
        assertThat(subOf(r, EpreuveType.TCF_CO).score()).isEqualTo(40);
        assertThat(subOf(r, EpreuveType.TCF_CO).maxScore()).isEqualTo(50);
    }

    /** EE/EO n'ont pas de QCM : aucun score calibré à inventer. */
    @Test
    void epreuvesProductives_nOntAucunScoreCalibre() {
        Attempt p = parent(false);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.B1),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B1),
                production(EpreuveType.TCF_EE),
                production(EpreuveType.TCF_EO)));

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(subOf(r, EpreuveType.TCF_EE).calibratedScore()).isNull();
        assertThat(subOf(r, EpreuveType.TCF_EO).calibratedScore()).isNull();
    }

    /** Épreuve verrouillée : jamais passée, donc aucun score — calibré compris. */
    @Test
    void epreuveVerrouillee_nAAucunScoreCalibre() {
        Attempt p = parent(true);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.B1),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B1),
                production(EpreuveType.TCF_EE),
                production(EpreuveType.TCF_EO)));

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(subOf(r, EpreuveType.TCF_EE).locked()).isTrue();
        assertThat(subOf(r, EpreuveType.TCF_EE).calibratedScore()).isNull();
        assertThat(subOf(r, EpreuveType.TCF_EO).calibratedScore()).isNull();
    }

    /**
     * Épreuve QCM sans score pondéré (en cours, ou terminée sans notation) :
     * {@code null}, jamais 100. Le service rend sa borne basse sur une entrée
     * nulle — l'afficher reviendrait à écrire « 100/499 » là où on ne sait rien.
     */
    @Test
    void epreuveQcmSansScorePondere_nInventePasUnCalibre() {
        Attempt p = parent(false);
        Attempt co = qcm(EpreuveType.TCF_CO, null);
        co.setFinishedAt(null);
        co.setWeightedScore(null);
        co.setMaxWeightedScore(null);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                co,
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B1),
                production(EpreuveType.TCF_EE),
                production(EpreuveType.TCF_EO)));

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(subOf(r, EpreuveType.TCF_CO).calibratedScore()).isNull();
        assertThat(subOf(r, EpreuveType.TCF_CO).score()).isNull();
    }

    // ------------------------------------------------- épreuve VERROUILLÉE

    /**
     * LE défaut corrigé : un compte gratuit qui refait l'examen 1 voyait ses
     * EE/EO pré-terminées comptées A1_NON_ATTEINT, ce qui tirait le plancher
     * global au plus bas niveau de l'examen. On lui annonçait qu'il n'avait pas
     * atteint le A1 parce qu'il n'avait pas payé.
     */
    @Test
    void epreuveVerrouillee_naAucunNiveauEtSortDuPlancher() {
        Attempt p = parent(true);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.B1),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B2),
                production(EpreuveType.TCF_EE),
                production(EpreuveType.TCF_EO)));

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(subOf(r, EpreuveType.TCF_EE).locked()).isTrue();
        assertThat(subOf(r, EpreuveType.TCF_EE).cecrlLevel()).isNull();
        assertThat(subOf(r, EpreuveType.TCF_EO).locked()).isTrue();
        assertThat(subOf(r, EpreuveType.TCF_EO).cecrlLevel()).isNull();
        // Le niveau global est celui des épreuves RÉELLEMENT passées (CO+CE).
        assertThat(r.finalCecrlLevel()).isEqualTo(NiveauCecrl.B1);
        assertThat(r.epreuvesCountedInFinalLevel()).isEqualTo(2);
        assertThat(r.epreuvesExpected()).isEqualTo(4);
        assertThat(r.finalLevelPartial()).isTrue();
    }

    // ------------------------------------------- plancher produit « ≥ 1 bonne »

    /**
     * Le <b>plancher produit SejourFR</b> (« au moins une bonne réponse ⇒ au
     * moins A1 ») remonte jusqu'ici par le {@code cecrl_level} persisté : une CO
     * à une seule bonne réponse vaut désormais A1, et c'est cet A1 — non plus
     * {@code A1_NON_ATTEINT} — qui devient le plancher global de l'examen.
     *
     * <p>Les trois exclusions du plancher restent intactes et se cumulent :
     * épreuve {@code locked} (freemium), épreuve à niveau {@code null}, épreuve
     * <b>jamais ouverte</b>. Aucune n'est « remontée » à A1 par la nouvelle
     * règle : elles n'ont pas de bonne réponse à compter, elles n'ont pas de
     * niveau du tout.
     */
    @Test
    void plancherProduit_uneEpreuveQcmAUnA1_devientLePlancherGlobal() {
        Attempt p = parent(true);
        Attempt co = qcm(EpreuveType.TCF_CO, NiveauCecrl.A1);
        co.setWeightedScore(1);
        co.setMaxWeightedScore(50);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                co,
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B1),
                production(EpreuveType.TCF_EE),          // verrouillée par le parent
                jamaisOuverte(EpreuveType.TCF_EO)));     // jamais ouverte

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(subOf(r, EpreuveType.TCF_CO).cecrlLevel()).isEqualTo(NiveauCecrl.A1);
        // Le score calibré, lui, reste à sa borne basse : la règle ne le touche pas.
        assertThat(subOf(r, EpreuveType.TCF_CO).calibratedScore()).isEqualTo(100);
        assertThat(subOf(r, EpreuveType.TCF_EE).locked()).isTrue();
        assertThat(subOf(r, EpreuveType.TCF_EE).cecrlLevel()).isNull();
        assertThat(subOf(r, EpreuveType.TCF_EO).cecrlLevel()).isNull();
        // Plancher = A1, plus A1_NON_ATTEINT : seules CO et CE sont comptées.
        assertThat(r.finalCecrlLevel()).isEqualTo(NiveauCecrl.A1);
        assertThat(r.epreuvesCountedInFinalLevel()).isEqualTo(2);
        assertThat(r.finalLevelPartial()).isTrue();
    }

    /**
     * Une épreuve QCM réellement passée et <b>tout fausse</b> reste
     * {@code A1_NON_ATTEINT} et continue de tirer le plancher : le plancher
     * produit ne rachète pas une épreuve à zéro bonne réponse.
     */
    @Test
    void plancherProduit_neRachetePasUneEpreuveSansAucuneBonneReponse() {
        Attempt p = parent(false);
        Attempt co = qcm(EpreuveType.TCF_CO, NiveauCecrl.A1_NON_ATTEINT);
        co.setWeightedScore(0);
        co.setMaxWeightedScore(50);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                co,
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B1),
                production(EpreuveType.TCF_EE),
                production(EpreuveType.TCF_EO)));
        when(productionSubmissionManager.findByAttemptId(any()))
                .thenReturn(List.of(submission(SubmissionStatut.EVALUATED)));

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(subOf(r, EpreuveType.TCF_CO).cecrlLevel()).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
        assertThat(r.finalCecrlLevel()).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
    }

    /**
     * Repli legacy (sous-attempts antérieurs à V416, {@code cecrl_level} null) :
     * sa table de seuils reste celle d'origine — on ne réécrit pas
     * rétroactivement l'historique — mais le plancher produit s'y applique
     * aussi, via l'autorité unique de {@link TcfLevelEstimatorService}. 1/50 =
     * 2 %, sous les 20 % de la table legacy, donc {@code A1_NON_ATTEINT} avant
     * plancher.
     */
    @Test
    void plancherProduit_sappliqueAussiAuRepliLegacyDuNiveau() {
        Attempt p = parent(false);
        Attempt co = qcm(EpreuveType.TCF_CO, null);   // pas de cecrl_level persisté
        co.setWeightedScore(1);
        co.setMaxWeightedScore(50);
        Attempt ce = qcm(EpreuveType.TCF_CE, null);
        ce.setWeightedScore(0);                        // zéro bonne réponse
        ce.setMaxWeightedScore(50);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                co, ce, production(EpreuveType.TCF_EE), production(EpreuveType.TCF_EO)));
        when(productionSubmissionManager.findByAttemptId(any()))
                .thenReturn(List.of(submission(SubmissionStatut.EVALUATED)));

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(subOf(r, EpreuveType.TCF_CO).cecrlLevel()).isEqualTo(NiveauCecrl.A1);
        assertThat(subOf(r, EpreuveType.TCF_CE).cecrlLevel()).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
    }

    /** On ne calcule même pas un bilan pour une épreuve jamais passée. */
    @Test
    void epreuveVerrouillee_neDeclencheAucunCalculDeBilan() {
        Attempt p = parent(true);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.B1),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B1),
                production(EpreuveType.TCF_EE),
                production(EpreuveType.TCF_EO)));

        builder.buildResponse(p);

        verify(productionBilanService, never()).bilanEpreuveTerminee(any());
        verify(productionBilanService, never()).bilanEpreuve(any());
    }

    /** Le verrou ne déborde jamais sur la compréhension : CO/CE restent notées. */
    @Test
    void epreuveVerrouillee_nafectePasLesNiveauxCoCe() {
        Attempt p = parent(true);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.A2),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B1),
                production(EpreuveType.TCF_EE),
                production(EpreuveType.TCF_EO)));

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(subOf(r, EpreuveType.TCF_CO).cecrlLevel()).isEqualTo(NiveauCecrl.A2);
        assertThat(subOf(r, EpreuveType.TCF_CO).locked()).isFalse();
        assertThat(subOf(r, EpreuveType.TCF_CE).cecrlLevel()).isEqualTo(NiveauCecrl.B1);
        assertThat(r.finalCecrlLevel()).isEqualTo(NiveauCecrl.A2);
    }

    /**
     * Contamination des statistiques : le résumé d'historique (« meilleur
     * niveau », « dernier examen ») porte le drapeau de partialité, faute de
     * quoi un examen à moitié verrouillé passerait pour un résultat complet.
     */
    @Test
    void resume_dUnExamenVerrouille_estMarquePartiel() {
        Attempt p = parent(true);
        p.setSlotNumber(3);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.B1),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B1),
                production(EpreuveType.TCF_EE),
                production(EpreuveType.TCF_EO)));

        FullTcfExamSummaryResponse s = builder.buildSummary(p);

        assertThat(s.finalLevelPartial()).isTrue();
        assertThat(s.finalCecrlLevel()).isEqualTo(NiveauCecrl.B1);
        assertThat(s.slotNumber()).isEqualTo(3);
    }

    // ---------------------------------------------------- épreuve EN ÉCHEC

    /**
     * Les 3 soumissions EE sont FAILED : l'épreuve n'a pas de niveau. Le
     * plancher l'ignore (calcul correct, déjà en place) — ce qui manquait,
     * c'est de le DIRE aux fronts, qui affirment « le plus bas de tes 4
     * épreuves » pendant qu'il n'y en a que 3.
     */
    @Test
    void epreuveEnEchec_sortDuPlancherEtRendLeBilanPartiel() {
        Attempt p = parent(false);
        Attempt ee = production(EpreuveType.TCF_EE);
        Attempt eo = production(EpreuveType.TCF_EO);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.B1),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B2),
                ee, eo));
        when(productionSubmissionManager.findByAttemptId(ee.getId())).thenReturn(List.of(
                submission(SubmissionStatut.FAILED),
                submission(SubmissionStatut.FAILED),
                submission(SubmissionStatut.FAILED)));
        when(productionSubmissionManager.findByAttemptId(eo.getId())).thenReturn(List.of(
                submission(SubmissionStatut.EVALUATED),
                submission(SubmissionStatut.EVALUATED),
                submission(SubmissionStatut.EVALUATED)));

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(subOf(r, EpreuveType.TCF_EE).cecrlLevel()).isNull();
        assertThat(subOf(r, EpreuveType.TCF_EE).failedSubmissionIds()).hasSize(3);
        assertThat(subOf(r, EpreuveType.TCF_EO).cecrlLevel()).isEqualTo(NiveauCecrl.B1);
        // Plancher sur CO(B1) + CE(B2) + EO(B1) = B1, sur 3 épreuves seulement.
        assertThat(r.finalCecrlLevel()).isEqualTo(NiveauCecrl.B1);
        assertThat(r.epreuvesCountedInFinalLevel()).isEqualTo(3);
        assertThat(r.finalLevelPartial()).isTrue();
        assertThat(r.status()).isEqualTo(FullTcfExamResponse.FullTcfExamStatus.COMPLETED);
    }

    // ------------------------------------------------------ examen complet

    /** Les 4 épreuves passées et notées : rien de partiel, plancher sur 4. */
    @Test
    void examenIntegralement_passe_nestPasPartiel() {
        Attempt p = parent(false);
        Attempt ee = production(EpreuveType.TCF_EE);
        Attempt eo = production(EpreuveType.TCF_EO);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.B2),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B2),
                ee, eo));
        List<ProductionSubmission> evaluees = List.of(
                submission(SubmissionStatut.EVALUATED),
                submission(SubmissionStatut.EVALUATED),
                submission(SubmissionStatut.EVALUATED));
        when(productionSubmissionManager.findByAttemptId(ee.getId())).thenReturn(evaluees);
        when(productionSubmissionManager.findByAttemptId(eo.getId())).thenReturn(evaluees);

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(r.epreuvesCountedInFinalLevel()).isEqualTo(4);
        assertThat(r.finalLevelPartial()).isFalse();
        assertThat(r.finalCecrlLevel()).isEqualTo(NiveauCecrl.B1); // plancher EE/EO
        assertThat(builder.buildSummary(p).finalLevelPartial()).isFalse();
    }

    /**
     * Épreuve productive <b>OUVERTE puis écourtée</b>, sans verrou et sans rien
     * rendre (abandon, chrono écoulé) : elle vaut bien A1_NON_ATTEINT et compte
     * au plancher. Le candidat a vu le sujet et n'a rien produit — c'est un
     * vrai résultat. Le « reste noté 0 » d'un examen écourté n'est pas remis en
     * cause : seules la porte verrouillée et la porte jamais franchie le sont.
     *
     * <p>L'ancre {@code timerStartedAt} est ce qui sépare ce cas du suivant.
     */
    @Test
    void epreuveOuvertePuisAbandonnee_compteToujoursAuPlancher() {
        Attempt p = parent(false);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.B2),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B2),
                production(EpreuveType.TCF_EE),
                production(EpreuveType.TCF_EO)));

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(subOf(r, EpreuveType.TCF_EE).timerStartedAt()).isNotNull();
        assertThat(subOf(r, EpreuveType.TCF_EE).cecrlLevel()).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
        assertThat(r.finalCecrlLevel()).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
        assertThat(r.epreuvesCountedInFinalLevel()).isEqualTo(4);
        assertThat(r.finalLevelPartial()).isFalse();
    }

    // -------------------------------------------------- épreuve JAMAIS OUVERTE

    /**
     * LE défaut corrigé : le candidat termine la CO et la CE puis quitte. Les
     * fronts clôturent l'EE et l'EO — jamais lancées, zéro soumission — pour
     * pouvoir appeler {@code finish}, et le bilan leur attribuait
     * A1_NON_ATTEINT. Ce niveau entrait au plancher, écrasait la CO et la CE,
     * et {@code finalLevelPartial} restait false : l'écran affirmait un bilan
     * complet sur 4 épreuves alors que 2 n'avaient jamais été ouvertes.
     *
     * <p>Une porte jamais franchie n'a pas davantage été passée qu'une porte
     * verrouillée : {@code null = inconnu, jamais mauvais}.
     */
    @Test
    void epreuveJamaisOuverte_naAucunNiveauEtSortDuPlancher() {
        Attempt p = parent(false);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.A2),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.A1),
                jamaisOuverte(EpreuveType.TCF_EE),
                jamaisOuverte(EpreuveType.TCF_EO)));

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(subOf(r, EpreuveType.TCF_EE).cecrlLevel()).isNull();
        assertThat(subOf(r, EpreuveType.TCF_EE).locked()).isFalse();
        assertThat(subOf(r, EpreuveType.TCF_EO).cecrlLevel()).isNull();
        // Le plancher ne porte que sur ce qui a été réellement joué : CO + CE.
        assertThat(r.finalCecrlLevel()).isEqualTo(NiveauCecrl.A1);
        assertThat(r.epreuvesCountedInFinalLevel()).isEqualTo(2);
        assertThat(r.epreuvesExpected()).isEqualTo(4);
        assertThat(r.finalLevelPartial()).isTrue();
        assertThat(r.status()).isEqualTo(FullTcfExamResponse.FullTcfExamStatus.COMPLETED);
    }

    /** On ne calcule aucun bilan de production pour une épreuve jamais ouverte. */
    @Test
    void epreuveJamaisOuverte_neDeclencheAucunCalculDeBilan() {
        Attempt p = parent(false);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.B1),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B1),
                jamaisOuverte(EpreuveType.TCF_EE),
                jamaisOuverte(EpreuveType.TCF_EO)));

        builder.buildResponse(p);

        verify(productionBilanService, never()).bilanEpreuveTerminee(any());
        verify(productionBilanService, never()).bilanEpreuve(any());
    }

    /**
     * Même règle en compréhension : une CO close sans jamais avoir été lancée
     * et sans une seule réponse n'a pas de niveau. Un score pondéré à 0 y
     * produisait A1_NON_ATTEINT — la borne basse de l'échelle rendue pour une
     * épreuve que le candidat n'a pas vue.
     *
     * <p>Et l'examen reste {@code COMPLETED} : sans niveau à attendre, le
     * laisser en PENDING_EVALUATIONS le figerait pour toujours.
     */
    @Test
    void epreuveQcmJamaisOuverte_naAucunNiveauEtNeBloquePasLeStatut() {
        Attempt p = parent(false);
        Attempt co = jamaisOuverte(EpreuveType.TCF_CO);
        co.setWeightedScore(0);
        co.setMaxWeightedScore(50);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                co,
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B1),
                production(EpreuveType.TCF_EE),
                production(EpreuveType.TCF_EO)));
        when(answerManager.hasAnyAnswer(co.getId())).thenReturn(false);

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(subOf(r, EpreuveType.TCF_CO).cecrlLevel()).isNull();
        assertThat(r.status()).isEqualTo(FullTcfExamResponse.FullTcfExamStatus.COMPLETED);
        // CE(B1) + EE/EO abandonnées après ouverture (A1_NON_ATTEINT) = 3 épreuves.
        assertThat(r.epreuvesCountedInFinalLevel()).isEqualTo(3);
        assertThat(r.finalLevelPartial()).isTrue();
    }

    /**
     * Le second critère n'est pas décoratif : les sous-attempts antérieurs au
     * chrono par épreuve portent tous {@code timer_started_at} null. Une CO
     * ancienne qui porte des réponses reste une épreuve passée, et garde son
     * niveau.
     */
    @Test
    void epreuveQcmSansAncre_maisAvecReponses_gardeSonNiveau() {
        Attempt p = parent(false);
        Attempt co = jamaisOuverte(EpreuveType.TCF_CO);
        co.setCecrlLevel(NiveauCecrl.A2);
        co.setWeightedScore(20);
        co.setMaxWeightedScore(50);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                co,
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B1),
                production(EpreuveType.TCF_EE),
                production(EpreuveType.TCF_EO)));
        when(answerManager.hasAnyAnswer(co.getId())).thenReturn(true);

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(subOf(r, EpreuveType.TCF_CO).cecrlLevel()).isEqualTo(NiveauCecrl.A2);
        assertThat(r.epreuvesCountedInFinalLevel()).isEqualTo(4);
    }

    /** Idem côté production : une soumission suffit à prouver que l'épreuve a été ouverte. */
    @Test
    void epreuveProductiveSansAncre_maisAvecSoumission_gardeSonNiveau() {
        Attempt p = parent(false);
        Attempt ee = jamaisOuverte(EpreuveType.TCF_EE);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.B1),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B1),
                ee,
                production(EpreuveType.TCF_EO)));
        when(productionSubmissionManager.findByAttemptId(ee.getId())).thenReturn(List.of(
                submission(SubmissionStatut.EVALUATED)));

        FullTcfExamResponse r = builder.buildResponse(p);

        assertThat(subOf(r, EpreuveType.TCF_EE).cecrlLevel()).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
        assertThat(r.epreuvesCountedInFinalLevel()).isEqualTo(4);
    }

    /**
     * Une épreuve encore ouverte (pas de {@code finishedAt}) n'est jamais
     * qualifiée de « jamais ouverte » — et surtout, on n'interroge pas la base
     * pour rien : l'examen est de toute façon IN_PROGRESS.
     */
    @Test
    void epreuveEnCours_neDeclencheAucuneRequeteDeReponses() {
        Attempt p = parent(false);
        Attempt co = jamaisOuverte(EpreuveType.TCF_CO);
        co.setFinishedAt(null);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                co,
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B1),
                production(EpreuveType.TCF_EE),
                production(EpreuveType.TCF_EO)));

        FullTcfExamResponse r = builder.buildResponse(p);

        verify(answerManager, never()).hasAnyAnswer(any());
        assertThat(r.status()).isEqualTo(FullTcfExamResponse.FullTcfExamStatus.IN_PROGRESS);
    }

    /** Une épreuve QCM lancée ne coûte aucune requête supplémentaire. */
    @Test
    void epreuveQcmLancee_neDeclencheAucuneRequeteDeReponses() {
        Attempt p = parent(false);
        when(attemptManager.findSubAttempts(p.getId())).thenReturn(List.of(
                qcm(EpreuveType.TCF_CO, NiveauCecrl.B1),
                qcm(EpreuveType.TCF_CE, NiveauCecrl.B1),
                production(EpreuveType.TCF_EE),
                production(EpreuveType.TCF_EO)));

        builder.buildResponse(p);

        verify(answerManager, never()).hasAnyAnswer(any());
    }
}

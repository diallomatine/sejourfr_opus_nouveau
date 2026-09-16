package com.sejourfr.app.service;

import com.sejourfr.app.dto.DiagnosticEpreuveLevel;
import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.DiagnosticProductionAnalysisManager;
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
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Niveau TCF d'un candidat : plancher des 4 épreuves, chacune retenant son
 * MEILLEUR résultat, une épreuve jamais réellement passée étant exclue.
 *
 * <p>Les managers sont mockés ; {@link TcfLevelEstimatorService} (math CECRL
 * pure) est instancié réel pour exercer le vrai plancher / plafond B2.
 * L'exclusion des examens QCM sans aucune réponse vit dans la requête et est
 * verrouillée par {@code AttemptManagerIT}.
 *
 * <p>🛑 <b>EE/EO : ce test ne parle plus qu'en ÉPREUVES COMPLÈTES</b>
 * (2026-09-16). Ce qui qualifie une session et ce qu'elle vaut sont l'affaire de
 * {@link EpreuvesProductionQualifiantesResolver}, mocké ici et couvert par
 * {@code EpreuvesProductionQualifiantesResolverTest} et {@code TcfProfileServiceIT} —
 * ce service ne fait plus que prendre le meilleur.
 */
class TcfProfileServiceTest {

    private AttemptManager attemptManager;
    private EpreuvesProductionQualifiantesResolver qualifiantesResolver;
    private DiagnosticProductionAnalysisManager diagnosticAnalysisManager;
    private TcfProfileService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        attemptManager = mock(AttemptManager.class);
        qualifiantesResolver = mock(EpreuvesProductionQualifiantesResolver.class);
        diagnosticAnalysisManager = mock(DiagnosticProductionAnalysisManager.class);
        when(diagnosticAnalysisManager.findCompletedLevelsByUser(userId)).thenReturn(List.of());
        service = new TcfProfileService(attemptManager, qualifiantesResolver,
                diagnosticAnalysisManager, new TcfLevelEstimatorService());
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

    /** Une épreuve complète réellement passée, et ce qu'elle vaut. */
    private static EpreuvesProductionQualifiantesResolver.EpreuveQualifiante epreuveComplete(
            NiveauCecrl niveau, Instant fin) {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setFinishedAt(fin);
        a.setSlotNumber(1);
        return new EpreuvesProductionQualifiantesResolver.EpreuveQualifiante(a, fin, niveau);
    }

    private void stubQcm(EpreuveType epreuve, List<Attempt> attempts) {
        when(attemptManager.findQcmEpreuvesPassees(eq(userId), eq(epreuve), anyInt()))
                .thenReturn(attempts);
    }

    /**
     * Les épreuves complètes servies pour {@code epreuve}. Sans stub, le mock
     * rend une liste vide — l'état d'un candidat qui n'a jamais passé d'épreuve
     * de production, entraînement libre inclus.
     */
    private void stubProduction(
            EpreuveType epreuve,
            List<EpreuvesProductionQualifiantesResolver.EpreuveQualifiante> epreuves) {
        when(qualifiantesResolver.qualifiantes(eq(userId), eq(epreuve), anyInt()))
                .thenReturn(epreuves);
    }

    /**
     * Raccourci : des épreuves complètes de la plus récente à la plus ancienne,
     * dans l'ordre où la requête les rend. L'ordre n'influence rien ici — c'est
     * exactement ce que les cas C et I vérifient.
     */
    private void stubProduction(EpreuveType epreuve, NiveauCecrl... niveaux) {
        Instant now = Instant.now();
        List<EpreuvesProductionQualifiantesResolver.EpreuveQualifiante> epreuves =
                new java.util.ArrayList<>();
        for (int i = 0; i < niveaux.length; i++) {
            epreuves.add(epreuveComplete(niveaux[i], now.minus(i, ChronoUnit.DAYS)));
        }
        stubProduction(epreuve, epreuves);
    }

    private void stubDiagnostic(DiagnosticEpreuveLevel... rows) {
        when(diagnosticAnalysisManager.findCompletedLevelsByUser(userId))
                .thenReturn(List.of(rows));
    }

    /**
     * La date portée par la projection n'intéresse pas ce service : il cherche
     * un <b>maximum</b>, pas une chronologie. Elle existe pour
     * {@code EpreuveHistoriqueService}, qui lit la même requête.
     */
    private static DiagnosticEpreuveLevel diag(EpreuveType epreuve, NiveauCecrl level) {
        return new DiagnosticEpreuveLevel(epreuve, level, java.time.Instant.now());
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
    void production_retientLaMeilleureEpreuveComplete_pasLaDerniere() {
        stubProduction(EpreuveType.TCF_EE,
                NiveauCecrl.A2, NiveauCecrl.B1, NiveauCecrl.A1);

        assertThat(service.levelProfile(userId).ee()).isEqualTo(NiveauCecrl.B1);
    }

    /**
     * 🛑 <b>LE CAS QUI A MOTIVÉ LA RÈGLE</b> (propriétaire, 2026-09-16). Un
     * compte dont la seule trace EO était un entraînement libre de trois minutes,
     * noté A2 par l'IA, affichait « expression orale : A2 » à l'Accueil sans
     * avoir jamais passé d'épreuve d'EO.
     *
     * <p>Aucune épreuve complète ⇒ aucune session qualifiante servie ⇒ le
     * domaine reste <b>à évaluer</b>. Ce que le resolver écarte est verrouillé,
     * lui, par {@code EpreuvesProductionQualifiantesResolverTest} et par
     * {@code TcfProfileServiceIT}, contre la vraie base.
     */
    @Test
    void production_sansAucuneEpreuveComplete_resteAEvaluer_memeSiLEntrainementEstNote() {
        TcfLevelProfile p = service.levelProfile(userId);

        assertThat(p.eo()).isNull();
        assertThat(p.ee()).isNull();
        assertThat(p.globalLevel()).isNull();
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
    void epreuveSansAucuneEpreuveComplete_estExclue_etNeTirePasLeNiveauVersLeBas() {
        // EE mesurée B1, EO jamais passée, CO/CE jamais passées.
        stubProduction(EpreuveType.TCF_EE, NiveauCecrl.B1);

        TcfLevelProfile p = service.levelProfile(userId);

        assertThat(p.ee()).isEqualTo(NiveauCecrl.B1);
        assertThat(p.eo()).isNull();
        assertThat(p.globalLevel()).isEqualTo(NiveauCecrl.B1);
    }

    @Test
    void uneEpreuveCompleteFaitRemonterLeNiveau_malgreUnExamenCompletRateEtAbandonne() {
        // Cas réel user@sejourfr.fr : l'examen complet du 04/08 est parti sans
        // aucune réponse (donc exclu par la requête, rien à stubber ici) et des
        // épreuves EE/EO ont suivi.
        stubProduction(EpreuveType.TCF_EE, NiveauCecrl.B1, NiveauCecrl.A2);
        stubProduction(EpreuveType.TCF_EO, NiveauCecrl.B1, NiveauCecrl.A1);

        assertThat(service.levelProfile(userId).globalLevel()).isEqualTo(NiveauCecrl.B1);
    }

    // ------------------------------------------------------------- anti-yoyo (spec V2 §5.3)

    /*
     * 🛑 LA RÈGLE ANTI-YOYO EST TENUE PAR CONSTRUCTION, ET PLUS FORT QUE LA SPEC.
     *
     * La spec V2 §5.3 protège un `estimatedLevel` qui vaudrait « la dernière
     * évaluation » : elle exige deux évaluations qualifiantes CONSÉCUTIVES pour
     * bouger. Ici, le niveau d'une épreuve est le MEILLEUR résultat de tout
     * l'historique — un maximum monotone. Il ne peut donc pas redescendre sur un
     * mauvais jour, et l'ordre des résultats ne l'influence pas : les deux
     * défauts que la règle de la spec cherche à éviter n'existent pas.
     *
     * Les trois cas obligatoires de la spec §14 sont vérifiés ci-dessous. Le
     * seul écart est la VITESSE DE MONTÉE (cas B intermédiaire), volontaire et
     * verrouillé lui aussi : une épreuve réellement réussie compte tout de
     * suite. Attendre une seconde preuve reviendrait à annoncer A2 à un candidat
     * qui vient de démontrer B1, c'est-à-dire à faire mentir la mesure dans le
     * sens du reproche.
     */

    /**
     * <b>Cas B de la spec §14 — amélioration réelle.</b> Diagnostic A2 puis deux
     * épreuves complètes B1 consécutives ⇒ le niveau vaut B1.
     *
     * <p>⚠️ Écart assumé avec la spec : chez nous le passage à B1 a lieu dès la
     * <b>première</b> épreuve complète (cf. le test suivant). La spec ne
     * l'obtient qu'à la seconde.
     */
    @Test
    void casB_deuxEpreuvesCompletesConsecutivesB1_leNiveauVautB1() {
        // La baseline du diagnostic (A2) n'est lue qu'à défaut d'épreuve
        // complète : deux épreuves existent, elle ne concurrence rien.
        stubDiagnostic(diag(EpreuveType.TCF_EE, NiveauCecrl.A2));
        stubProduction(EpreuveType.TCF_EE, NiveauCecrl.B1, NiveauCecrl.B1);

        assertThat(service.levelProfile(userId).ee()).isEqualTo(NiveauCecrl.B1);
    }

    /**
     * <b>Cas B, l'étape intermédiaire — l'écart VOULU avec la spec.</b> Une
     * première épreuve complète B1 après un diagnostic A2 fait <b>déjà</b>
     * passer à B1 : une baseline de diagnostic n'a jamais l'autorité d'une
     * production réelle, et une preuve réelle n'attend pas sa jumelle.
     */
    @Test
    void casB_uneSeuleEpreuveCompleteB1_suffitDejaAPasserAB1_ecartVouluAvecLaSpec() {
        stubDiagnostic(diag(EpreuveType.TCF_EE, NiveauCecrl.A2));
        stubProduction(EpreuveType.TCF_EE, NiveauCecrl.B1);

        assertThat(service.levelProfile(userId).ee()).isEqualTo(NiveauCecrl.B1);
    }

    /**
     * <b>Cas C de la spec §14 — la mauvaise journée.</b> Un candidat stable B1
     * rate un jour et sort un A2 isolé : le niveau <b>reste B1</b>. Ce n'est pas
     * une règle de séquence ici, c'est le maximum : un résultat atypique ne peut
     * structurellement pas faire redescendre.
     */
    @Test
    void casC_unSeulResultatAtypiqueBas_neFaitPasRedescendre() {
        stubProduction(EpreuveType.TCF_EO,
                NiveauCecrl.A2,   // la mauvaise journée, la plus récente
                NiveauCecrl.B1,
                NiveauCecrl.B1);

        assertThat(service.levelProfile(userId).eo()).isEqualTo(NiveauCecrl.B1);
    }

    /** Même cas C, côté QCM : le dernier examen ne fait jamais la loi. */
    @Test
    void casC_unExamenQcmRateNeFaitPasRedescendreLEpreuve() {
        stubQcm(EpreuveType.TCF_CO, List.of(
                qcm(NiveauCecrl.A2),   // le plus récent
                qcm(NiveauCecrl.B1),
                qcm(NiveauCecrl.B1)));

        assertThat(service.levelProfile(userId).co()).isEqualTo(NiveauCecrl.B1);
    }

    /**
     * <b>Cas I de la spec §14 — évaluations non consécutives.</b> B1, puis A2,
     * puis B1 : le niveau <b>ne change pas</b>, il vaut B1 du début à la fin. La
     * spec y arrive en refusant une paire non consécutive ; nous y arrivons
     * parce que le A2 intercalé n'a jamais pu faire descendre quoi que ce soit.
     */
    @Test
    void casI_evaluationsNonConsecutives_leNiveauNeChangePas() {
        stubProduction(EpreuveType.TCF_EE,
                NiveauCecrl.B1,   // 3ᵉ
                NiveauCecrl.A2,   // 2ᵉ
                NiveauCecrl.B1);  // 1ʳᵉ

        assertThat(service.levelProfile(userId).ee()).isEqualTo(NiveauCecrl.B1);
    }

    // ------------------------------------------------------------------ plancher

    @Test
    void global_estLePlancherDesEpreuvesRenseignees() {
        stubQcm(EpreuveType.TCF_CO, List.of(qcm(NiveauCecrl.B2)));
        stubQcm(EpreuveType.TCF_CE, List.of(qcm(NiveauCecrl.B2)));
        stubProduction(EpreuveType.TCF_EE, NiveauCecrl.B1);
        stubProduction(EpreuveType.TCF_EO, NiveauCecrl.A2);

        TcfLevelProfile p = service.levelProfile(userId);

        assertThat(p.globalLevel()).isEqualTo(NiveauCecrl.A2);
        // 4 épreuves comptées : le niveau porte sur tout, rien à annoter.
        assertThat(p.epreuvesCounted()).isEqualTo(4);
        assertThat(p.partial()).isFalse();
    }

    // ------------------------------------------------------------------ périmètre

    @Test
    void perimetre_uneSeuleEpreuvePassee_estPartiel() {
        stubProduction(EpreuveType.TCF_EE, NiveauCecrl.B1);

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
        stubProduction(EpreuveType.TCF_EE, NiveauCecrl.C1);

        TcfLevelProfile p = service.levelProfile(userId);

        assertThat(p.ee()).isEqualTo(NiveauCecrl.B2);
        assertThat(p.globalLevel()).isEqualTo(NiveauCecrl.B2);
    }

    /*
     * La dédup d'une soumission RÉ-ÉVALUÉE (« seule la plus récente fait foi »)
     * a quitté ce service avec la règle des épreuves complètes : elle vit une
     * seule fois, dans `ProductionBilanService.latestEvalsByTache`, et y est
     * verrouillée par `ProductionBilanServiceTest`. Ce service ne voit plus que
     * des niveaux d'épreuve déjà agrégés.
     */

    // ------------------------------------------------------- diagnostic (baseline)

    /**
     * Le diagnostic est bifurqué avant {@code ai_evaluations} : sans lecture
     * dédiée, un candidat qui vient d'être évalué sur son écrit ET son oral
     * affichait « 0 domaine évalué sur 4 ». Mesuré en base au moment du
     * correctif : 13 domaines perdus sur 7 comptes.
     */
    @Test
    void diagnostic_renseigneEeEtEo_quandAucuneProductionEvaluee() {
        stubDiagnostic(diag(EpreuveType.TCF_EE, NiveauCecrl.A2),
                diag(EpreuveType.TCF_EO, NiveauCecrl.B1));

        TcfLevelProfile p = service.levelProfile(userId);

        assertThat(p.ee()).isEqualTo(NiveauCecrl.A2);
        assertThat(p.eo()).isEqualTo(NiveauCecrl.B1);
        assertThat(p.epreuvesCounted()).isEqualTo(2);
        assertThat(p.partial()).isTrue();
        assertThat(p.globalLevel()).isEqualTo(NiveauCecrl.A2);
    }

    /** Une production réelle prime sur la baseline, même quand elle est PLUS BASSE. */
    @Test
    void diagnostic_neRemonteJamaisUnDomaineQuiAUneProductionEvaluee() {
        stubProduction(EpreuveType.TCF_EE, NiveauCecrl.A1);
        stubDiagnostic(diag(EpreuveType.TCF_EE, NiveauCecrl.B2));

        assertThat(service.levelProfile(userId).ee()).isEqualTo(NiveauCecrl.A1);
    }

    /** ...et symétriquement, il ne l'écrase pas non plus quand il est plus bas. */
    @Test
    void diagnostic_neRabaisseJamaisUnDomaineQuiAUneProductionEvaluee() {
        stubProduction(EpreuveType.TCF_EO, NiveauCecrl.B2);
        stubDiagnostic(diag(EpreuveType.TCF_EO, NiveauCecrl.A1_NON_ATTEINT));

        assertThat(service.levelProfile(userId).eo()).isEqualTo(NiveauCecrl.B2);
    }

    /** Le repli est par DOMAINE : l'EE travaillée garde sa note, l'EO retombe sur la baseline. */
    @Test
    void diagnostic_replieDomaineParDomaine() {
        stubProduction(EpreuveType.TCF_EE, NiveauCecrl.B2);
        stubDiagnostic(diag(EpreuveType.TCF_EE, NiveauCecrl.A2),
                diag(EpreuveType.TCF_EO, NiveauCecrl.A2));

        TcfLevelProfile p = service.levelProfile(userId);

        assertThat(p.ee()).isEqualTo(NiveauCecrl.B2);
        assertThat(p.eo()).isEqualTo(NiveauCecrl.A2);
    }

    /**
     * Aucune requête de baseline quand les deux domaines de production sont déjà
     * renseignés : le repli ne se paie que là où il sert.
     */
    @Test
    void diagnostic_nEstMemePasLu_quandLesDeuxProductionsSontEvaluees() {
        stubProduction(EpreuveType.TCF_EE, NiveauCecrl.B1);
        stubProduction(EpreuveType.TCF_EO, NiveauCecrl.B1);

        service.levelProfile(userId);

        verify(diagnosticAnalysisManager, never()).findCompletedLevelsByUser(userId);
    }

    /** Plusieurs sessions terminées (versions successives) : on retient le meilleur. */
    @Test
    void diagnostic_plusieursAnalysesSurUnMemeDomaine_retientLeMeilleur() {
        stubDiagnostic(diag(EpreuveType.TCF_EE, NiveauCecrl.A1),
                diag(EpreuveType.TCF_EE, NiveauCecrl.B1));

        assertThat(service.levelProfile(userId).ee()).isEqualTo(NiveauCecrl.B1);
    }

    /** Le diagnostic ne parle jamais de CO/CE : ces domaines restent inconnus. */
    @Test
    void diagnostic_neRenseigneNiCoNiCe() {
        stubDiagnostic(diag(EpreuveType.TCF_EE, NiveauCecrl.B1),
                diag(EpreuveType.TCF_EO, NiveauCecrl.B1));

        TcfLevelProfile p = service.levelProfile(userId);

        assertThat(p.co()).isNull();
        assertThat(p.ce()).isNull();
    }
}

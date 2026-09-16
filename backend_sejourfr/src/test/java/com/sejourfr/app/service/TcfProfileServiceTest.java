package com.sejourfr.app.service;

import com.sejourfr.app.dto.DiagnosticEpreuveLevel;
import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ProductionEvaluabilite;
import com.sejourfr.app.manager.AiEvaluationManager;
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
 */
class TcfProfileServiceTest {

    private AttemptManager attemptManager;
    private AiEvaluationManager aiEvaluationManager;
    private DiagnosticProductionAnalysisManager diagnosticAnalysisManager;
    private TcfProfileService service;

    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        attemptManager = mock(AttemptManager.class);
        aiEvaluationManager = mock(AiEvaluationManager.class);
        diagnosticAnalysisManager = mock(DiagnosticProductionAnalysisManager.class);
        when(diagnosticAnalysisManager.findCompletedLevelsByUser(userId)).thenReturn(List.of());
        service = new TcfProfileService(attemptManager, aiEvaluationManager,
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

    private static AiEvaluation eval(NiveauCecrl level, Instant at) {
        return eval(level, at, UUID.randomUUID());
    }

    private static AiEvaluation eval(NiveauCecrl level, Instant at, UUID submissionId) {
        ProductionSubmission sub = new ProductionSubmission();
        sub.setId(submissionId);
        AiEvaluation e = new AiEvaluation();
        e.setSubmission(sub);
        e.setNiveauCecrl(level);
        e.setEvaluatedAt(at);
        return e;
    }

    /**
     * Production RENDUE mais INEXPLOITABLE : la ligne existe, aucun appel LLM
     * n'a eu lieu, elle ne porte ni note ni niveau.
     */
    private static AiEvaluation evalInexploitable(Instant at) {
        return evalInexploitable(at, UUID.randomUUID());
    }

    private static AiEvaluation evalInexploitable(Instant at, UUID submissionId) {
        AiEvaluation e = eval(null, at, submissionId);
        e.setEvaluabilite(ProductionEvaluabilite.NON_EVALUABLE);
        return e;
    }

    private void stubQcm(EpreuveType epreuve, List<Attempt> attempts) {
        when(attemptManager.findQcmEpreuvesPassees(eq(userId), eq(epreuve), anyInt()))
                .thenReturn(attempts);
    }

    private void stubProduction(EpreuveType epreuve, List<AiEvaluation> evals) {
        when(aiEvaluationManager.findByUserAndEpreuve(userId, epreuve)).thenReturn(evals);
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

    // ------------------------------------------------- production inexploitable

    /**
     * LE TROU JUMEAU de celui du diagnostic (2026-08-21). Une production rendue
     * mais inexploitable (vide, quasi vide, langue non française, recopiage de la
     * consigne) écrivait note 0 + {@code A1_NON_ATTEINT} dans
     * {@code ai_evaluations} — une ABSENCE DE PREUVE enregistrée comme la PREUVE
     * DU NIVEAU LE PLUS FAIBLE. Or c'est la table lue EN PRIORITÉ ici, et le
     * niveau global est le PLANCHER des quatre domaines : un enregistrement raté
     * tirait tout le profil au fond.
     *
     * <p>Elle ne porte plus aucun niveau, donc le domaine reste NON ÉVALUÉ et le
     * profil PARTIEL — « aucune preuve » n'est pas « mauvaise preuve ».
     */
    @Test
    void productionInexploitable_neRendAucunNiveau_etLaisseLeDomaineNonEvalue() {
        stubProduction(EpreuveType.TCF_EO, List.of(evalInexploitable(Instant.now())));
        stubProduction(EpreuveType.TCF_EE, List.of(eval(NiveauCecrl.B1, Instant.now())));

        TcfLevelProfile p = service.levelProfile(userId);

        assertThat(p.eo()).isNull();
        assertThat(p.ee()).isEqualTo(NiveauCecrl.B1);
        // Le domaine oral sort du plancher au lieu de le tirer a A1_NON_ATTEINT.
        assertThat(p.globalLevel()).isEqualTo(NiveauCecrl.B1);
    }

    /**
     * Une production inexploitable ne PLOMBE pas les autres : une seule tâche
     * ratée sur une épreuve qui en compte de vraies laisse le meilleur niveau
     * intact.
     */
    @Test
    void productionInexploitable_neSupprimePasLeNiveauDesAutresTaches() {
        Instant now = Instant.now();
        stubProduction(EpreuveType.TCF_EE, List.of(
                evalInexploitable(now),
                eval(NiveauCecrl.B1, now.minus(2, ChronoUnit.DAYS))));

        assertThat(service.levelProfile(userId).ee()).isEqualTo(NiveauCecrl.B1);
    }

    /**
     * « La plus récente fait foi » vaut AUSSI quand la plus récente n'a rien
     * observé : sur une MÊME soumission ré-évaluée, un verdict périmé ne
     * ressuscite pas derrière une ligne inexploitable.
     */
    @Test
    void memeSoumission_uneReevaluationInexploitableNeRessuscitePasLAncienVerdict() {
        UUID submissionId = UUID.randomUUID();
        Instant now = Instant.now();
        stubProduction(EpreuveType.TCF_EE, List.of(
                evalInexploitable(now, submissionId),
                eval(NiveauCecrl.B2, now.minus(1, ChronoUnit.DAYS), submissionId)));

        assertThat(service.levelProfile(userId).ee()).isNull();
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
        Instant now = Instant.now();
        // La baseline du diagnostic (A2) n'est lue qu'à défaut de vraie
        // production : deux productions existent, elle ne concurrence rien.
        stubDiagnostic(diag(EpreuveType.TCF_EE, NiveauCecrl.A2));
        stubProduction(EpreuveType.TCF_EE, List.of(
                eval(NiveauCecrl.B1, now),
                eval(NiveauCecrl.B1, now.minus(2, ChronoUnit.DAYS))));

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
        stubProduction(EpreuveType.TCF_EE, List.of(eval(NiveauCecrl.B1, Instant.now())));

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
        Instant now = Instant.now();
        stubProduction(EpreuveType.TCF_EO, List.of(
                eval(NiveauCecrl.A2, now),                              // la mauvaise journée
                eval(NiveauCecrl.B1, now.minus(3, ChronoUnit.DAYS)),
                eval(NiveauCecrl.B1, now.minus(8, ChronoUnit.DAYS))));

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
        Instant now = Instant.now();
        stubProduction(EpreuveType.TCF_EE, List.of(
                eval(NiveauCecrl.B1, now),                              // 3ᵉ
                eval(NiveauCecrl.A2, now.minus(2, ChronoUnit.DAYS)),    // 2ᵉ
                eval(NiveauCecrl.B1, now.minus(5, ChronoUnit.DAYS))));  // 1ʳᵉ

        assertThat(service.levelProfile(userId).ee()).isEqualTo(NiveauCecrl.B1);
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
        stubProduction(EpreuveType.TCF_EE, List.of(eval(NiveauCecrl.A1, Instant.now())));
        stubDiagnostic(diag(EpreuveType.TCF_EE, NiveauCecrl.B2));

        assertThat(service.levelProfile(userId).ee()).isEqualTo(NiveauCecrl.A1);
    }

    /** ...et symétriquement, il ne l'écrase pas non plus quand il est plus bas. */
    @Test
    void diagnostic_neRabaisseJamaisUnDomaineQuiAUneProductionEvaluee() {
        stubProduction(EpreuveType.TCF_EO, List.of(eval(NiveauCecrl.B2, Instant.now())));
        stubDiagnostic(diag(EpreuveType.TCF_EO, NiveauCecrl.A1_NON_ATTEINT));

        assertThat(service.levelProfile(userId).eo()).isEqualTo(NiveauCecrl.B2);
    }

    /** Le repli est par DOMAINE : l'EE travaillée garde sa note, l'EO retombe sur la baseline. */
    @Test
    void diagnostic_replieDomaineParDomaine() {
        stubProduction(EpreuveType.TCF_EE, List.of(eval(NiveauCecrl.B2, Instant.now())));
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
        stubProduction(EpreuveType.TCF_EE, List.of(eval(NiveauCecrl.B1, Instant.now())));
        stubProduction(EpreuveType.TCF_EO, List.of(eval(NiveauCecrl.B1, Instant.now())));

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

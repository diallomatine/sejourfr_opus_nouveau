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
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
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
 * <p>🛑 <b>Ce fichier couvre {@code levelProfile}</b>, la lecture du <b>PLAN</b>
 * — celle qui voit toute évaluation IA valide, entraînement compris, et qui
 * retient le <b>meilleur</b> résultat. La lecture d'<b>AFFICHAGE</b>
 * ({@code levelProfileAccueil}) a sa propre section en bas : elle ne vérifie
 * que le <b>câblage</b>, l'arithmétique de la moyenne des 3 derniers examens
 * vivant dans {@code NiveauActuelEpreuveResolverTest}. Ce qui sépare les deux
 * lectures est verrouillé bout en bout par
 * {@code ProgressServiceIT.lEntrainementRenseigneLePlanPasLAccueil}.
 */
class TcfProfileServiceTest {

    private AttemptManager attemptManager;
    private AiEvaluationManager aiEvaluationManager;
    private NiveauActuelEpreuveResolver niveauActuelResolver;
    private DiagnosticProductionAnalysisManager diagnosticAnalysisManager;
    private TcfProfileService service;

    private final UUID userId = UUID.randomUUID();
    private com.sejourfr.app.manager.AttemptQuestionManager attemptQuestionManager;
    /** Ce que les réponses de chaque épreuve QCM démontrent. */
    private final Map<UUID, NiveauCecrl> niveauxQcm = new java.util.HashMap<>();

    @BeforeEach
    void setUp() {
        attemptManager = mock(AttemptManager.class);
        attemptQuestionManager = mock(com.sejourfr.app.manager.AttemptQuestionManager.class);
        niveauxQcm.clear();
        // Le niveau d'une épreuve QCM se DÉRIVE de ses réponses : les fixtures
        // déclarent des strates, jamais un palier persisté.
        when(attemptQuestionManager.stratesParAttempt(any())).thenAnswer(inv -> {
            List<com.sejourfr.app.dto.LigneStrateQcm> out = new java.util.ArrayList<>();
            for (UUID id : (java.util.Collection<UUID>) inv.getArgument(0)) {
                NiveauCecrl n = niveauxQcm.get(id);
                if (n == null) continue;
                for (com.sejourfr.app.dto.StrateQcm st : stratesPour(n)) {
                    out.add(new com.sejourfr.app.dto.LigneStrateQcm(
                            id, com.sejourfr.app.enums.QuestionType.CO, st));
                }
            }
            return out;
        });
        aiEvaluationManager = mock(AiEvaluationManager.class);
        niveauActuelResolver = mock(NiveauActuelEpreuveResolver.class);
        diagnosticAnalysisManager = mock(DiagnosticProductionAnalysisManager.class);
        when(diagnosticAnalysisManager.findCompletedLevelsByUser(userId)).thenReturn(List.of());
        service = new TcfProfileService(attemptManager, aiEvaluationManager,
                niveauActuelResolver, diagnosticAnalysisManager,
                new TcfLevelEstimatorService(attemptQuestionManager));
    }

    // ------------------------------------------------------------------ fixtures

    /** Une épreuve QCM passée dont les RÉPONSES démontrent {@code level}. */
    private Attempt qcm(NiveauCecrl level) {
        Attempt a = new Attempt();
        a.setId(UUID.randomUUID());
        a.setFinishedAt(Instant.now());
        a.setWeightedScore(25);
        a.setMaxWeightedScore(50);
        if (level != null) niveauxQcm.put(a.getId(), level);
        return a;
    }

    /** Strates 10 A2 / 8 B1 / 7 B2 qui démontrent exactement {@code niveau}. */
    private static List<com.sejourfr.app.dto.StrateQcm> stratesPour(NiveauCecrl niveau) {
        com.sejourfr.app.enums.Difficulty a2 = com.sejourfr.app.enums.Difficulty.A2;
        com.sejourfr.app.enums.Difficulty b1 = com.sejourfr.app.enums.Difficulty.B1;
        com.sejourfr.app.enums.Difficulty b2 = com.sejourfr.app.enums.Difficulty.B2;
        int[] r = switch (niveau) {
            case B2 -> new int[] {10, 8, 7};
            case B1 -> new int[] {10, 8, 0};
            case A2 -> new int[] {10, 0, 0};
            case A1 -> new int[] {1, 0, 0};
            default -> new int[] {0, 0, 0};
        };
        return List.of(
                com.sejourfr.app.dto.StrateQcm.mesuree(a2, 10, r[0]),
                com.sejourfr.app.dto.StrateQcm.mesuree(b1, 8, r[1]),
                com.sejourfr.app.dto.StrateQcm.mesuree(b2, 7, r[2]));
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

    /**
     * 🛑 <b>Un examen ancien reste parfaitement lisible.</b> Il n'a jamais porté
     * de niveau persisté — la colonne n'existe plus — et son score pondéré ne
     * sert plus à en dériver un : ce sont ses RÉPONSES qui le donnent. Le
     * service ne recode rien, il demande à l'autorité unique.
     */
    @Test
    void qcm_leNiveauSeDeriveDesReponses_jamaisDuScorePondere() {
        Attempt ancien = qcm(NiveauCecrl.B2);
        ancien.setWeightedScore(1);          // pondéré incohérent, exprès
        ancien.setMaxWeightedScore(50);
        stubQcm(EpreuveType.TCF_CE, List.of(ancien));

        assertThat(service.levelProfile(userId).ce()).isEqualTo(NiveauCecrl.B2);
    }

    // ------------------------------------------------------- plancher bas

    /**
     * {@code A1} est le plancher réel : au moins une bonne réponse, aucune
     * strate maîtrisée. Le service ne recode pas la règle, il la demande.
     */
    @Test
    void uneBonneReponseSuffitAFaireA1_sansRecoderLaRegle() {
        stubQcm(EpreuveType.TCF_CO, List.of(qcm(NiveauCecrl.A1)));

        assertThat(service.levelProfile(userId).co()).isEqualTo(NiveauCecrl.A1);
    }

    /** Zéro bonne réponse sur l'épreuve entière : l'épreuve reste au plus bas. */
    @Test
    void zeroBonneReponse_resteA1NonAtteint() {
        stubQcm(EpreuveType.TCF_CO, List.of(qcm(NiveauCecrl.A1_NON_ATTEINT)));

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

    // ------------------------------- anti-yoyo (spec V2 §5.3) — LECTURE DU PLAN

    /*
     * 🛑 CETTE SECTION NE VAUT QUE POUR `levelProfile`, LA LECTURE DU PLAN.
     *
     * ⚠️ RÉVOCATION DU 2026-09-16 : elle valait autrefois pour tout le dépôt.
     * Le propriétaire a tranché que le niveau AFFICHÉ « doit représenter le
     * niveau actuel estimé, donc il peut monter comme descendre » — la lecture
     * d'affichage (`levelProfileAccueil`) moyenne désormais les 3 derniers
     * examens qualifiants et n'a plus AUCUNE protection anti-yoyo. Les cas B /
     * C / I ci-dessous sont donc FAUX de l'affichage, et leur contrepartie
     * (« un mauvais examen récent fait baisser ») est verrouillée dans
     * `NiveauActuelEpreuveResolverTest` et par
     * `affichage_peutEtrePlusBasQueLePlan_leMaximumMonotoneEstRevoque`.
     *
     * Ce qui reste vrai, et qui est l'objet de cette section : le PLAN garde le
     * MEILLEUR résultat de tout l'historique — un maximum monotone. Un Plan n'a
     * pas à désapprendre ce qu'un candidat a démontré, et l'ordre des résultats
     * ne l'influence pas. La spec V2 §5.3 protégeait un `estimatedLevel` qui
     * vaudrait « la dernière évaluation » en exigeant deux évaluations
     * qualifiantes CONSÉCUTIVES ; ici les deux défauts qu'elle vise n'existent
     * pas.
     *
     * Les trois cas obligatoires de la spec §14 sont vérifiés ci-dessous, sur la
     * lecture du Plan. Le seul écart est la VITESSE DE MONTÉE (cas B
     * intermédiaire), volontaire et verrouillé lui aussi : une épreuve
     * réellement réussie compte tout de suite. Attendre une seconde preuve
     * reviendrait à annoncer A2 à un candidat qui vient de démontrer B1,
     * c'est-à-dire à faire mentir la mesure dans le sens du reproche.
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

    // ---------------------------------------------- la lecture d'AFFICHAGE
    // 🛑 Deux arbitrages du proprietaire, tous deux du 2026-09-16 :
    //   1. seule une EPREUVE COMPLETE peut AFFICHER un niveau d'EE/EO ;
    //   2. le niveau affiche est la MOYENNE des 3 derniers examens qualifiants,
    //      donc il peut redescendre — le maximum monotone est REVOQUE ici.
    // Le PLAN, lui, garde sa lecture large et son maximum : `levelProfile`,
    // teste au-dessus. Ce que cette section verifie, c'est le CABLAGE — que la
    // lecture d'affichage passe bien par `NiveauActuelEpreuveResolver` et par
    // lui seul. L'arithmetique de la moyenne, elle, vit dans
    // `NiveauActuelEpreuveResolverTest`.

    private void stubAffichage(EpreuveType epreuve, NiveauCecrl niveau) {
        if (epreuve == EpreuveType.TCF_CO || epreuve == EpreuveType.TCF_CE) {
            when(niveauActuelResolver.qcm(eq(userId), eq(epreuve), anyInt())).thenReturn(niveau);
        } else {
            when(niveauActuelResolver.production(eq(userId), eq(epreuve), anyInt()))
                    .thenReturn(niveau);
        }
    }

    /**
     * 🛑 <b>LE test de la separation.</b> Le meme candidat, les memes donnees :
     * un entrainement EO evalue B1, aucune epreuve complete. Le Plan lit B1,
     * l'affichage ne lit rien — et « rien » veut dire <b>null</b>, pas A1.
     */
    @Test
    void affichage_unEntrainementNAfficheAucunNiveau_maisLePlanLeVoit() {
        stubProduction(EpreuveType.TCF_EO, List.of(eval(NiveauCecrl.B1, Instant.now())));
        stubAffichage(EpreuveType.TCF_EO, null);

        assertThat(service.levelProfile(userId).eo())
                .as("le PLAN voit l'entrainement, c'est une observation")
                .isEqualTo(NiveauCecrl.B1);
        assertThat(service.levelProfileAccueil(userId).eo())
                .as("l'AFFICHAGE exige une epreuve complete")
                .isNull();
    }

    /**
     * 🛑 <b>LE test de la revocation.</b> Le Plan garde son MEILLEUR resultat,
     * l'affichage sert la moyenne des 3 derniers — et elle est <b>plus
     * basse</b>. La regle du matin (« le niveau ne redescend jamais ») rendait
     * ce cas impossible ; il est maintenant exige.
     */
    @Test
    void affichage_peutEtrePlusBasQueLePlan_leMaximumMonotoneEstRevoque() {
        Instant now = Instant.now();
        stubProduction(EpreuveType.TCF_EE, List.of(
                eval(NiveauCecrl.A2, now),
                eval(NiveauCecrl.B2, now.minus(30, ChronoUnit.DAYS))));
        stubAffichage(EpreuveType.TCF_EE, NiveauCecrl.A2);

        assertThat(service.levelProfile(userId).ee())
                .as("le PLAN retient le meilleur, il ne desapprend pas")
                .isEqualTo(NiveauCecrl.B2);
        assertThat(service.levelProfileAccueil(userId).ee())
                .as("l'AFFICHAGE dit le niveau ACTUEL, il redescend")
                .isEqualTo(NiveauCecrl.A2);
    }

    /**
     * Le repli baseline reste le meme pour les deux lectures : le diagnostic
     * rapide n'a pas ete retire de l'affichage, il n'a jamais ete l'objet de
     * l'arbitrage.
     */
    @Test
    void affichage_gardeLeRepliSurLaBaselineDuDiagnostic() {
        stubDiagnostic(diag(EpreuveType.TCF_EE, NiveauCecrl.A2));
        stubAffichage(EpreuveType.TCF_EE, null);

        assertThat(service.levelProfileAccueil(userId).ee()).isEqualTo(NiveauCecrl.A2);
    }

    /**
     * 🛑 Le <b>niveau global</b> affiche est le plancher des paliers AFFICHES.
     * Sans ca, l'ecran annoncerait « A2 » a cause d'une EO d'entrainement qu'il
     * presente deux lignes plus bas comme non evaluee.
     */
    @Test
    void affichage_leNiveauGlobalNeTombePasSurUneEpreuveQuIlNAffichePas() {
        stubQcm(EpreuveType.TCF_CO, List.of(qcm(NiveauCecrl.B1)));
        stubQcm(EpreuveType.TCF_CE, List.of(qcm(NiveauCecrl.B1)));
        stubProduction(EpreuveType.TCF_EO, List.of(eval(NiveauCecrl.A2, Instant.now())));
        stubAffichage(EpreuveType.TCF_CO, NiveauCecrl.B1);
        stubAffichage(EpreuveType.TCF_CE, NiveauCecrl.B1);
        stubAffichage(EpreuveType.TCF_EO, null);

        assertThat(service.levelProfile(userId).globalLevel())
                .as("le PLAN plancher sur l'entrainement EO")
                .isEqualTo(NiveauCecrl.A2);
        assertThat(service.levelProfileAccueil(userId).globalLevel())
                .as("l'AFFICHAGE ne plancher que sur ce qu'il montre")
                .isEqualTo(NiveauCecrl.B1);
    }

    /**
     * 🛑 <b>Le niveau global affiche est le MIN des 4 epreuves</b>, calculees
     * chacune par la lecture d'affichage — la regle du plancher n'est pas
     * dupliquee, c'est {@code TcfLevelEstimatorService.floor}.
     */
    @Test
    void affichage_leNiveauGlobalEstLeMinDesQuatreEpreuves() {
        stubAffichage(EpreuveType.TCF_CO, NiveauCecrl.B2);
        stubAffichage(EpreuveType.TCF_CE, NiveauCecrl.B1);
        stubAffichage(EpreuveType.TCF_EE, NiveauCecrl.B2);
        stubAffichage(EpreuveType.TCF_EO, NiveauCecrl.A2);

        TcfLevelProfile p = service.levelProfileAccueil(userId);

        assertThat(p.globalLevel()).isEqualTo(NiveauCecrl.A2);
        assertThat(p.epreuvesCounted()).isEqualTo(4);
        assertThat(p.partial()).isFalse();
    }

    /** Aucune epreuve mesuree : tout reste inconnu, rien n'est fabrique. */
    @Test
    void affichage_aucunExamenQualifiant_toutResteNull() {
        TcfLevelProfile p = service.levelProfileAccueil(userId);

        assertThat(p.co()).isNull();
        assertThat(p.ce()).isNull();
        assertThat(p.ee()).isNull();
        assertThat(p.eo()).isNull();
        assertThat(p.globalLevel()).isNull();
        assertThat(p.epreuvesCounted()).isZero();
    }

    /**
     * 🛑 <b>CO et CE passent par la MEME lecture d'affichage</b> depuis le
     * 2026-09-16 : elles se moyennent comme EE et EO. L'affichage ne lit donc
     * plus du tout la requete du maximum — une lecture directe contournerait la
     * regle sans bruit.
     */
    @Test
    void affichage_neLitNiLesExamensQcmNiLesEvaluationsDeTaches() {
        stubAffichage(EpreuveType.TCF_CO, NiveauCecrl.B2);
        stubAffichage(EpreuveType.TCF_CE, NiveauCecrl.A2);
        stubAffichage(EpreuveType.TCF_EE, NiveauCecrl.B1);
        stubAffichage(EpreuveType.TCF_EO, NiveauCecrl.B1);

        TcfLevelProfile affichage = service.levelProfileAccueil(userId);

        assertThat(affichage.co()).isEqualTo(NiveauCecrl.B2);
        assertThat(affichage.ce()).isEqualTo(NiveauCecrl.A2);
        verify(attemptManager, never())
                .findQcmEpreuvesPassees(eq(userId), any(EpreuveType.class), anyInt());
        verify(aiEvaluationManager, never())
                .findByUserAndEpreuve(userId, EpreuveType.TCF_EE);
        verify(aiEvaluationManager, never())
                .findByUserAndEpreuve(userId, EpreuveType.TCF_EO);
    }
}

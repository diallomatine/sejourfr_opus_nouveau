package com.sejourfr.app.service;

import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ProductionEvaluabilite;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.enums.TcfDiagnosticStatus;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.TcfDiagnosticSessionManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Chemin réel en base du profil TCF par domaine, sur Postgres embarqué :
 * l'analyse du <b>diagnostic</b> vit dans {@code diagnostic_production_analyses}
 * et jamais dans {@code ai_evaluations} — c'est exactement ce que la requête
 * dédiée doit rattraper, et que deux mocks ne prouveraient pas.
 *
 * <p>Tolérant au seed Flyway : chaque test crée son propre candidat et
 * n'assert que sur lui.
 */
class TcfProfileServiceIT extends AbstractIntegrationTest {

    @Autowired
    private TcfProfileService service;

    @Autowired
    private TestData data;

    @Autowired
    private AiEvaluationManager aiEvaluationManager;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private AttemptManager attemptManager;

    @Autowired
    private ProductionSubmissionManager submissionManager;

    @Autowired
    private TcfDiagnosticSessionManager tcfSessionManager;

    @PersistenceContext
    private EntityManager entityManager;

    /** Les deux productions du diagnostic, analysées, sur une session donnée. */
    private void analyseLesDeuxProductions(
            DiagnosticSession session, NiveauCecrl ecrit, NiveauCecrl oral) {
        final User user = session.getUser();
        data.diagnosticAnalysis(
                data.diagnosticSubmission(
                        session.getWrittenAttempt(), session.getWrittenTask(), user),
                ecrit);
        data.diagnosticAnalysis(
                data.diagnosticSubmission(
                        session.getOralAttempt(), session.getOralTask(), user),
                oral);
    }

    /**
     * Production RENDUE mais inexploitable : la ligne existe (aucun appel LLM
     * n'a eu lieu), et elle ne porte ni note ni niveau.
     */
    private void evaluationInexploitable(User user, EpreuveType epreuve) {
        final AiEvaluation evaluation = evaluationReelle(user, epreuve, NiveauCecrl.B2);
        evaluation.setEvaluabilite(ProductionEvaluabilite.NON_EVALUABLE);
        evaluation.setNoteSur20(null);
        evaluation.setNiveauCecrl(null);
        evaluation.setNiveauCecrlIa(null);
        aiEvaluationManager.save(evaluation);
    }

    private AiEvaluation evaluationReelle(User user, EpreuveType epreuve, NiveauCecrl niveau) {
        final ProductionTask task = data.productionTask(epreuve);
        final ProductionSubmission submission =
                data.productionSubmission(data.attempt(user), task, user);
        final AiEvaluation evaluation = data.aiEvaluation(submission);
        evaluation.setNiveauCecrl(niveau);
        return aiEvaluationManager.save(evaluation);
    }

    // ------------------------------------------------------------------ diagnostic

    @Test
    void diagnosticTermine_renseigneEeEtEo_alorsQuAucuneAiEvaluationNExiste() {
        final User user = data.user();
        final DiagnosticSession session =
                data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        analyseLesDeuxProductions(session, NiveauCecrl.A2, NiveauCecrl.B1);

        // Le diagnostic ne produit AUCUNE ai_evaluation : c'est le trou corrigé.
        assertThat(aiEvaluationManager.findByUserAndEpreuve(user.getId(), EpreuveType.TCF_EE))
                .isEmpty();

        final TcfLevelProfile profile = service.levelProfile(user.getId());

        assertThat(profile.ee()).isEqualTo(NiveauCecrl.A2);
        assertThat(profile.eo()).isEqualTo(NiveauCecrl.B1);
        assertThat(profile.co()).isNull();
        assertThat(profile.ce()).isNull();
        assertThat(profile.globalLevel()).isEqualTo(NiveauCecrl.A2);
        assertThat(profile.epreuvesCounted()).isEqualTo(2);
        assertThat(profile.partial()).isTrue();
    }

    /** Session non terminée : aucun verdict opposable, les domaines restent inconnus. */
    @Test
    void diagnosticEnCours_nEstJamaisComptePourUnDomaine() {
        final User user = data.user();
        final DiagnosticSession session =
                data.diagnosticSession(user, DiagnosticSessionStatus.IN_PROGRESS);
        analyseLesDeuxProductions(session, NiveauCecrl.B2, NiveauCecrl.B2);

        final TcfLevelProfile profile = service.levelProfile(user.getId());

        assertThat(profile.ee()).isNull();
        assertThat(profile.eo()).isNull();
        assertThat(profile.epreuvesCounted()).isZero();
        assertThat(profile.partial()).isFalse();
    }

    /** Le diagnostic d'un AUTRE candidat ne fuit jamais dans le profil. */
    @Test
    void diagnosticDUnAutreCandidat_nEstJamaisLu() {
        final User autre = data.user();
        analyseLesDeuxProductions(
                data.diagnosticSession(autre, DiagnosticSessionStatus.COMPLETED),
                NiveauCecrl.B2, NiveauCecrl.B2);

        final TcfLevelProfile profile = service.levelProfile(data.user().getId());

        assertThat(profile.ee()).isNull();
        assertThat(profile.eo()).isNull();
    }

    // ------------------------------------------------------- baseline vs production

    /**
     * Règle d'arbitrage : une production réellement évaluée prime toujours sur
     * la baseline du diagnostic, <b>même quand elle est plus basse</b>. Le repli
     * se fait domaine par domaine — l'EO, elle, reste sur sa baseline.
     */
    @Test
    void productionEvaluee_primeSurLaBaseline_domaineParDomaine() {
        final User user = data.user();
        final DiagnosticSession session =
                data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        analyseLesDeuxProductions(session, NiveauCecrl.B2, NiveauCecrl.B2);

        evaluationReelle(user, EpreuveType.TCF_EE, NiveauCecrl.A1);

        final TcfLevelProfile profile = service.levelProfile(user.getId());

        assertThat(profile.ee()).isEqualTo(NiveauCecrl.A1);
        assertThat(profile.eo()).isEqualTo(NiveauCecrl.B2);
    }

    // --------------------------------------------------- production inexploitable

    /**
     * LE TROU JUMEAU de celui du diagnostic. Une production rendue mais
     * INEXPLOITABLE (vide, quasi vide, langue non française, recopiage de la
     * consigne) écrivait note 0 + {@code A1_NON_ATTEINT} dans
     * {@code ai_evaluations} — la table lue EN PRIORITÉ ici. Une absence de
     * preuve devenait la preuve du niveau le plus faible, et comme le niveau
     * global est le <b>plancher</b> des quatre domaines, tout le profil tombait.
     *
     * <p>Elle ne porte plus aucun niveau : le domaine reste NON ÉVALUÉ, le
     * profil PARTIEL, et le niveau global est celui des domaines réellement
     * mesurés.
     */
    @Test
    void productionInexploitable_neRendAucunNiveau_etLaisseLeDomaineAMesurer() {
        final User user = data.user();
        evaluationInexploitable(user, EpreuveType.TCF_EO);
        evaluationReelle(user, EpreuveType.TCF_EE, NiveauCecrl.B1);

        final TcfLevelProfile profile = service.levelProfile(user.getId());

        assertThat(profile.eo()).isNull();
        assertThat(profile.ee()).isEqualTo(NiveauCecrl.B1);
        assertThat(profile.globalLevel()).isEqualTo(NiveauCecrl.B1);
        assertThat(profile.epreuvesCounted()).isEqualTo(1);
        assertThat(profile.partial()).isTrue();
    }

    /**
     * Conséquence heureuse et non écrite : une production inexploitable ne
     * bloque plus le repli sur la baseline du diagnostic. Elle le bloquait —
     * elle comptait comme « production réellement évaluée », donc prioritaire,
     * avec son faux {@code A1_NON_ATTEINT}.
     */
    @Test
    void productionInexploitable_laisseLaBaselineDuDiagnosticRenseignerLeDomaine() {
        final User user = data.user();
        final DiagnosticSession session =
                data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        analyseLesDeuxProductions(session, NiveauCecrl.B1, NiveauCecrl.B1);

        evaluationInexploitable(user, EpreuveType.TCF_EE);

        assertThat(service.levelProfile(user.getId()).ee()).isEqualTo(NiveauCecrl.B1);
    }

    /**
     * L'invariant est OPPOSABLE EN BASE, pas seulement tenu par le Java :
     * {@code chk_ai_eval_aucun_verdict_si_non_evaluable} interdit qu'une ligne
     * dise à la fois « rien n'a été observé » et « voici le niveau ».
     */
    @Test
    void uneLigneNonEvaluableNePeutPasPorterUnNiveau_laBaseLeRefuse() {
        final AiEvaluation avecNiveau =
                evaluationReelle(data.user(), EpreuveType.TCF_EE, NiveauCecrl.B1);
        // save() ne flushe pas : sans ce flush, l'UPDATE ci-dessous ne verrait
        // aucune ligne et le test passerait pour de mauvaises raisons.
        entityManager.flush();

        assertThatThrownBy(() -> jdbcTemplate.update(
                "UPDATE ai_evaluations SET evaluabilite = 'NON_EVALUABLE' WHERE id = ?",
                avecNiveau.getId()))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("chk_ai_eval_aucun_verdict_si_non_evaluable");
    }

    /** Sans diagnostic ni production : rien n'est inventé, tout reste inconnu. */
    @Test
    void aucuneTrace_toutResteNull_jamaisA1NonAtteint() {
        final TcfLevelProfile profile = service.levelProfile(data.user().getId());

        assertThat(profile.co()).isNull();
        assertThat(profile.ce()).isNull();
        assertThat(profile.ee()).isNull();
        assertThat(profile.eo()).isNull();
        assertThat(profile.globalLevel()).isNull();
    }

    // ================================================================
    // LECTURE D'AFFICHAGE — la moyenne des 3 derniers examens qualifiants
    // ================================================================
    // 🛑 Règle du propriétaire du 2026-09-16, qui RÉVOQUE le maximum monotone
    // de cette lecture : « le niveau affiché doit représenter le niveau actuel
    // estimé, donc il peut monter comme descendre ». Ce que ces tests prouvent
    // et que des mocks ne prouveraient pas : les TROIS provenances d'examen
    // complet sont réellement reconnues par la requête, et l'entraînement
    // réellement dehors.
    //
    // Grille active en test (v15) : compétence ≥ 10 ⇒ B2, ≥ 6 ⇒ B1, ≥ 2 ⇒ A2.
    // Sans `scores_criteres`, la compétence d'une tâche vaut sa note /20.

    /** Le conteneur d'un examen blanc TCF complet — il porte les sous-épreuves. */
    private Attempt conteneurComplet(User user) {
        final Attempt parent = new Attempt();
        parent.setUser(user);
        parent.setType(AttemptType.MOCK_EXAM);
        parent.setModule(Module.TCF);
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        parent.setMode(AttemptMode.EXAMEN);
        parent.setStatus(AttemptStatus.TERMINE);
        parent.setStartedAt(Instant.now().minus(3, ChronoUnit.HOURS));
        return attemptManager.save(parent);
    }

    /** Une session de diagnostic TCF complet, accrochée à son conteneur. */
    private TcfDiagnosticSession sessionDiagnosticComplet(User user, Attempt parent) {
        final TcfDiagnosticSession session = new TcfDiagnosticSession();
        session.setUser(user);
        session.setParentAttempt(parent);
        session.setConfigVersion(1);
        session.setStatus(TcfDiagnosticStatus.COMPLETED);
        session.setStartedAt(Instant.now().minus(3, ChronoUnit.HOURS));
        session.setExpiresAt(Instant.now().plus(7, ChronoUnit.DAYS));
        session.setCompletedAt(Instant.now());
        return tcfSessionManager.save(session);
    }

    /**
     * Une <b>épreuve complète de production</b> terminée, ses 3 tâches notées
     * {@code note}/20. La provenance se pose par l'appelant : {@code slotNumber}
     * (épreuve seule), {@code parentAttempt} (examen blanc complet) ou les deux
     * plus {@code tcfDiagnostic} (diagnostic complet).
     */
    private Attempt epreuveNotee(User user, EpreuveType epreuve, String note, Instant fin) {
        final Attempt a = new Attempt();
        a.setUser(user);
        a.setType(AttemptType.TRAINING); // c'est le cas réel : le slot fait l'examen
        a.setModule(Module.TCF);
        a.setEpreuve(epreuve);
        a.setMode(AttemptMode.EXAMEN);
        a.setStatus(AttemptStatus.TERMINE);
        a.setStartedAt(fin.minus(30, ChronoUnit.MINUTES));
        a.setFinishedAt(fin);
        a.setSlotNumber(1);
        attemptManager.save(a);
        troisTachesNotees(a, user, epreuve, note);
        return a;
    }

    private void troisTachesNotees(Attempt a, User user, EpreuveType epreuve, String note) {
        for (short numero = 1; numero <= 3; numero++) {
            final ProductionSubmission s = data.productionSubmission(
                    a, data.productionTacheNumero(epreuve, numero), user);
            s.setStatut(SubmissionStatut.EVALUATED);
            submissionManager.save(s);
            final AiEvaluation e = data.aiEvaluation(s);
            e.setNoteSur20(new BigDecimal(note));
            e.setNiveauCecrl(null);
            e.setNiveauCecrlIa(null);
            e.setFeedbackJson(new java.util.HashMap<>());
            aiEvaluationManager.save(e);
        }
        entityManager.flush();
    }

    /**
     * Un examen QCM passé dont les <b>réponses</b> démontrent {@code niveau} —
     * donc qualifiant. 🛑 Le palier ne se déclare plus et ne se dérive plus d'un
     * score : il se lit strate par strate sur les vraies réponses.
     */
    private void examenQcm(User user, EpreuveType epreuve, NiveauCecrl niveau, Instant fin) {
        final Attempt a = data.examenQcmTcfPasse(user, epreuve, niveau);
        a.setStartedAt(fin.minus(30, ChronoUnit.MINUTES));
        a.setFinishedAt(fin);
        attemptManager.save(a);
        entityManager.flush();
    }

    /**
     * 🛑 <b>Les TROIS provenances comptent à égalité.</b> Trois candidats, la
     * même note, trois provenances différentes : le même palier affiché. Si
     * l'une d'elles sortait du prédicat SQL, son candidat retomberait à
     * « À évaluer ».
     */
    @Test
    void affichage_lesTroisProvenancesQualifiantesComptentAEgalite() {
        // (1) épreuve seule : le slot suffit.
        final User seule = data.user();
        epreuveNotee(seule, EpreuveType.TCF_EE, "12", Instant.now());

        // (2) sous-épreuve d'un examen blanc TCF complet.
        final User complet = data.user();
        final Attempt parentComplet = conteneurComplet(complet);
        final Attempt ee = epreuveNotee(complet, EpreuveType.TCF_EE, "12", Instant.now());
        ee.setSlotNumber(null);
        ee.setParentAttempt(parentComplet);
        attemptManager.save(ee);

        // (3) sous-épreuve du diagnostic TCF complet (4 épreuves).
        final User diagnostic = data.user();
        final Attempt parentDiag = conteneurComplet(diagnostic);
        final TcfDiagnosticSession session = sessionDiagnosticComplet(diagnostic, parentDiag);
        final Attempt eeDiag = epreuveNotee(diagnostic, EpreuveType.TCF_EE, "12", Instant.now());
        eeDiag.setSlotNumber(null);
        eeDiag.setParentAttempt(parentDiag);
        eeDiag.setTcfDiagnostic(session);
        attemptManager.save(eeDiag);
        entityManager.flush();
        entityManager.clear();

        assertThat(service.levelProfileAccueil(seule.getId()).ee()).isEqualTo(NiveauCecrl.B2);
        assertThat(service.levelProfileAccueil(complet.getId()).ee()).isEqualTo(NiveauCecrl.B2);
        assertThat(service.levelProfileAccueil(diagnostic.getId()).ee()).isEqualTo(NiveauCecrl.B2);
    }

    /**
     * 🛑 <b>La moyenne, en base.</b> Trois épreuves complètes notées 12, 6 et 3
     * : la moyenne vaut 7 ⇒ <b>B1</b>. Ce n'est ni le meilleur (B2), ni le
     * dernier, ni le pire — c'est exactement ce que « niveau actuel estimé »
     * veut dire, et c'est ce que l'ancien maximum monotone rendait impossible.
     */
    @Test
    void affichage_moyenneDesTroisDernieres_niLeMeilleurNiLeDernier() {
        final User user = data.user();
        final Instant maintenant = Instant.now();
        epreuveNotee(user, EpreuveType.TCF_EE, "3", maintenant);
        epreuveNotee(user, EpreuveType.TCF_EE, "6", maintenant.minus(1, ChronoUnit.DAYS));
        epreuveNotee(user, EpreuveType.TCF_EE, "12", maintenant.minus(2, ChronoUnit.DAYS));
        entityManager.flush();
        entityManager.clear();

        assertThat(service.levelProfileAccueil(user.getId()).ee())
                .as("(12 + 6 + 3) / 3 = 7 ⇒ B1")
                .isEqualTo(NiveauCecrl.B1);
    }

    /**
     * 🛑 <b>Quatre épreuves ⇒ seules les 3 dernières comptent.</b> Un 20/20
     * d'il y a quatre épreuves ne tient plus le palier : la moyenne des trois
     * récentes vaut 3 ⇒ A2, celle des quatre vaudrait 7,25 ⇒ B1.
     */
    @Test
    void affichage_quatreEpreuves_seulesLesTroisDernieresComptent() {
        final User user = data.user();
        final Instant maintenant = Instant.now();
        epreuveNotee(user, EpreuveType.TCF_EO, "3", maintenant);
        epreuveNotee(user, EpreuveType.TCF_EO, "3", maintenant.minus(1, ChronoUnit.DAYS));
        epreuveNotee(user, EpreuveType.TCF_EO, "3", maintenant.minus(2, ChronoUnit.DAYS));
        epreuveNotee(user, EpreuveType.TCF_EO, "20", maintenant.minus(30, ChronoUnit.DAYS));
        entityManager.flush();
        entityManager.clear();

        assertThat(service.levelProfileAccueil(user.getId()).eo()).isEqualTo(NiveauCecrl.A2);
    }

    /**
     * 🛑 <b>Un entraînement n'entre JAMAIS dans la moyenne</b>, même corrigé par
     * l'IA — ni slot ni parent, il est hors du prédicat. Le Plan, lui, continue
     * de le voir : c'est l'arbitrage du propriétaire du 2026-09-16.
     */
    @Test
    void affichage_unEntrainementNEntreJamaisDansLaMoyenne_maisLePlanLeVoit() {
        final User user = data.user();
        epreuveNotee(user, EpreuveType.TCF_EE, "3", Instant.now().minus(1, ChronoUnit.DAYS));
        // L'entraînement : une production TCF évaluée B2, sans slot ni parent.
        evaluationReelle(user, EpreuveType.TCF_EE, NiveauCecrl.B2);
        entityManager.flush();
        entityManager.clear();

        assertThat(service.levelProfileAccueil(user.getId()).ee())
                .as("l'affichage ne voit que l'épreuve complète, notée 3 ⇒ A2")
                .isEqualTo(NiveauCecrl.A2);
        assertThat(service.levelProfile(user.getId()).ee())
                .as("le PLAN voit l'entraînement, c'est une observation")
                .isEqualTo(NiveauCecrl.B2);
    }

    /**
     * 🛑 <b>Le niveau global affiché est le MIN des 4 épreuves</b>, chacune
     * valant sa propre moyenne. La CO et la CE se moyennent exactement comme
     * l'EE et l'EO depuis le 2026-09-16.
     */
    @Test
    void affichage_leNiveauGlobalEstLeMinDesQuatreEpreuves() {
        final User user = data.user();
        final Instant maintenant = Instant.now();
        // CO : un sans-faute ⇒ B2.
        examenQcm(user, EpreuveType.TCF_CO, NiveauCecrl.B2, maintenant);
        // CE : deux examens, un sans-faute et un A2. Items cumulés : A2 20/20,
        // B1 8/16 (il en faut 10) ⇒ A2 — la CE se MOYENNE, elle ne retient pas
        // le B2.
        examenQcm(user, EpreuveType.TCF_CE, NiveauCecrl.B2, maintenant);
        examenQcm(user, EpreuveType.TCF_CE, NiveauCecrl.A2,
                maintenant.minus(1, ChronoUnit.DAYS));
        epreuveNotee(user, EpreuveType.TCF_EE, "12", maintenant);
        epreuveNotee(user, EpreuveType.TCF_EO, "3", maintenant);
        entityManager.flush();
        entityManager.clear();

        final TcfLevelProfile profil = service.levelProfileAccueil(user.getId());

        assertThat(profil.co()).isEqualTo(NiveauCecrl.B2);
        assertThat(profil.ce()).as("la CE se MOYENNE, elle ne retient pas le B2")
                .isEqualTo(NiveauCecrl.A2);
        assertThat(profil.ee()).isEqualTo(NiveauCecrl.B2);
        assertThat(profil.eo()).isEqualTo(NiveauCecrl.A2);
        assertThat(profil.globalLevel()).as("min des 4").isEqualTo(NiveauCecrl.A2);
        assertThat(profil.epreuvesCounted()).isEqualTo(4);
        assertThat(profil.partial()).isFalse();
    }
}

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
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Chemin réel en base du profil TCF par domaine, sur Postgres embarqué.
 *
 * <p>Deux choses qu'aucun mock ne prouverait :
 * <ul>
 *   <li>l'analyse du <b>diagnostic rapide</b> vit dans
 *       {@code diagnostic_production_analyses} et jamais dans
 *       {@code ai_evaluations} — c'est ce que la requête dédiée rattrape ;</li>
 *   <li>🛑 <b>ce qui distingue un examen complet d'un entraînement</b>
 *       (2026-09-16) est un prédicat SQL — {@code slot_number} ou
 *       {@code parent_attempt_id}, plus {@code finished_at} et une soumission —
 *       et <b>pas</b> {@code attempts.type}, qui vaut {@code TRAINING} même sur
 *       un examen blanc d'épreuve isolé.</li>
 * </ul>
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
    private AttemptManager attemptManager;

    @Autowired
    private ProductionSubmissionManager submissionManager;

    @Autowired
    private TcfDiagnosticSessionManager tcfSessionManager;

    @Autowired
    private JdbcTemplate jdbcTemplate;

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

    // ------------------------------------------------- épreuves de production

    /**
     * Une session de production TERMINÉE. ⚠️ {@code type} n'est PAS ce qui la
     * qualifie : {@code AttemptService.startProduction} pose {@code TRAINING}
     * sur tous les examens blancs d'épreuve. Ce sont le {@code slotNumber} et le
     * {@code parentAttempt} posés par les appelants ci-dessous qui décident.
     */
    private Attempt sessionProduction(User user, EpreuveType epreuve, AttemptType type, Instant fin) {
        final Attempt a = new Attempt();
        a.setUser(user);
        a.setType(type);
        a.setModule(Module.TCF);
        a.setEpreuve(epreuve);
        a.setMode(type == AttemptType.MOCK_EXAM ? AttemptMode.EXAMEN : AttemptMode.ENTRAINEMENT);
        a.setStatus(AttemptStatus.TERMINE);
        a.setStartedAt(fin.minus(30, ChronoUnit.MINUTES));
        a.setFinishedAt(fin);
        return a;
    }

    /** Le conteneur d'un examen blanc TCF complet — il porte les sous-épreuves. */
    private Attempt conteneurComplet(User user) {
        final Attempt parent = new Attempt();
        parent.setUser(user);
        parent.setType(AttemptType.MOCK_EXAM);
        parent.setModule(Module.TCF);
        parent.setEpreuve(EpreuveType.TCF_COMPLET);
        parent.setMode(AttemptMode.EXAMEN);
        parent.setStatus(AttemptStatus.TERMINE);
        parent.setStartedAt(Instant.now().minus(2, ChronoUnit.HOURS));
        return attemptManager.save(parent);
    }

    /** Une session de diagnostic TCF complet, accrochée à son conteneur. */
    private TcfDiagnosticSession sessionDiagnosticComplet(User user, Attempt parent) {
        final TcfDiagnosticSession session = new TcfDiagnosticSession();
        session.setUser(user);
        session.setParentAttempt(parent);
        session.setConfigVersion(1);
        session.setStatus(TcfDiagnosticStatus.COMPLETED);
        session.setStartedAt(Instant.now().minus(2, ChronoUnit.HOURS));
        session.setExpiresAt(Instant.now().plus(7, ChronoUnit.DAYS));
        session.setCompletedAt(Instant.now());
        return tcfSessionManager.save(session);
    }

    /**
     * CAS 2 — un examen blanc ISOLÉ de l'épreuve : slot posé au démarrage. La
     * fixture vit dans {@code TestData}, appelée aussi par les tests du Plan.
     */
    private void examenBlancIsole(User user, EpreuveType epreuve, NiveauCecrl niveau) {
        data.epreuveProductionPassee(user, epreuve, niveau);
        entityManager.flush();
    }

    /** CAS 3 — l'épreuve jouée DANS un examen blanc TCF complet. */
    private void sousEpreuveDExamenComplet(User user, EpreuveType epreuve, NiveauCecrl niveau) {
        final Attempt a = sessionProduction(
                user, epreuve, AttemptType.MOCK_EXAM, Instant.now().minus(2, ChronoUnit.DAYS));
        a.setParentAttempt(conteneurComplet(user));
        attemptManager.save(a);
        data.troisTachesEvaluees(a, user, epreuve, niveau);
        entityManager.flush();
    }

    /** CAS 1 — l'épreuve jouée dans le DIAGNOSTIC COMPLET (4 épreuves). */
    private void epreuveDuDiagnosticComplet(User user, EpreuveType epreuve, NiveauCecrl niveau) {
        final Attempt parent = conteneurComplet(user);
        final Attempt a = sessionProduction(
                user, epreuve, AttemptType.MOCK_EXAM, Instant.now().minus(3, ChronoUnit.DAYS));
        a.setParentAttempt(parent);
        a.setTcfDiagnostic(sessionDiagnosticComplet(user, parent));
        attemptManager.save(a);
        data.troisTachesEvaluees(a, user, epreuve, niveau);
        entityManager.flush();
    }

    /**
     * Le même examen blanc isolé, mais évalué par de vraies <b>notes</b> : c'est
     * la moyenne pondérée des 3 tâches qui décide du palier, via les seuils de
     * la grille active ({@code ProductionRubricsProvider} l'emporte sur la
     * config ; en v15, ceux du TCF IRN — <b>B2 ≥ 10, B1 ≥ 6, A2 ≥ 2</b>).
     */
    private void examenBlancNote(User user, EpreuveType epreuve, String note) {
        final Attempt a = sessionProduction(
                user, epreuve, AttemptType.TRAINING, Instant.now().minus(1, ChronoUnit.DAYS));
        a.setSlotNumber(1);
        attemptManager.save(a);
        for (short numero = 1; numero <= 3; numero++) {
            final ProductionSubmission s = data.productionSubmission(
                    a, data.productionTacheNumero(epreuve, numero), user);
            s.setStatut(SubmissionStatut.EVALUATED);
            submissionManager.save(s);
            final AiEvaluation e = data.aiEvaluation(s);
            e.setNoteSur20(new BigDecimal(note));
            e.setFeedbackJson(new HashMap<>(Map.of("note_globale", note)));
            aiEvaluationManager.save(e);
        }
        entityManager.flush();
    }

    /**
     * L'ENTRAÎNEMENT LIBRE : ni slot ni parent. Une seule tâche, évaluée, avec
     * son niveau — exactement la trace du compte de test
     * {@code wewiwe4789@bowlfuel.com} (une soumission EO de trois minutes,
     * {@code type = TRAINING}, {@code mode = ENTRAINEMENT}, notée A2).
     */
    private void entrainementLibreEvalue(User user, EpreuveType epreuve, NiveauCecrl niveau) {
        final Attempt a = sessionProduction(user, epreuve, AttemptType.TRAINING, Instant.now());
        attemptManager.save(a);
        final ProductionSubmission s = data.productionSubmission(
                a, data.productionTacheNumero(epreuve, (short) 1), user);
        s.setStatut(SubmissionStatut.EVALUATED);
        submissionManager.save(s);
        final AiEvaluation e = data.aiEvaluation(s);
        e.setNiveauCecrl(niveau);
        aiEvaluationManager.save(e);
        entityManager.flush();
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

    // --------------------------------- EE/EO : seuls les EXAMENS COMPLETS comptent

    /*
     * 🛑 LA RÈGLE DU PROPRIÉTAIRE, 2026-09-16. Pour EO et EE, un entraînement ne
     * définit JAMAIS le niveau global affiché à l'Accueil, même corrigé par l'IA
     * et même situé sur un palier CECRL. Seul un EXAMEN COMPLET de l'épreuve le
     * fait, et il n'y en a que trois sortes.
     */

    /**
     * 🛑 <b>LE CAS CONSTATÉ</b> — compte {@code wewiwe4789@bowlfuel.com}. Une
     * seule soumission EO : un entraînement libre de trois minutes, évalué A2
     * par l'IA. Ce A2 remontait comme « niveau global d'expression orale » alors
     * qu'aucune épreuve d'EO n'avait jamais été passée.
     *
     * <p>L'épreuve reste désormais <b>à évaluer</b> — {@code null}, que le front
     * rend « À évaluer ». L'entraînement garde son niveau observé sur sa propre
     * tâche, sur son propre écran de résultat : rien de ce côté-là ne change.
     */
    @Test
    @DisplayName("🛑 Un entraînement libre évalué A2 ne définit AUCUN niveau global d'épreuve")
    void entrainementLibreEvalue_neDefinitJamaisLeNiveauGlobal() {
        final User user = data.user();
        entrainementLibreEvalue(user, EpreuveType.TCF_EO, NiveauCecrl.A2);
        entrainementLibreEvalue(user, EpreuveType.TCF_EE, NiveauCecrl.B2);
        entityManager.clear();

        final TcfLevelProfile profile = service.levelProfile(user.getId());

        assertThat(profile.eo()).isNull();
        assertThat(profile.ee()).isNull();
        // Et surtout : pas de A1_NON_ATTEINT de substitution.
        assertThat(profile.globalLevel()).isNull();
        assertThat(profile.epreuvesCounted()).isZero();
    }

    /** CAS 1 — l'épreuve EO/EE du diagnostic complet (4 épreuves). */
    @Test
    @DisplayName("CAS 1 — l'épreuve du diagnostic complet définit le niveau de l'épreuve")
    void epreuveDuDiagnosticComplet_definitLeNiveauDeLEpreuve() {
        final User user = data.user();
        epreuveDuDiagnosticComplet(user, EpreuveType.TCF_EO, NiveauCecrl.B2);
        entityManager.clear();

        assertThat(service.levelProfile(user.getId()).eo()).isEqualTo(NiveauCecrl.B2);
    }

    /** CAS 2 — un examen blanc isolé de l'épreuve. */
    @Test
    @DisplayName("CAS 2 — un examen blanc isolé définit le niveau de l'épreuve")
    void examenBlancIsole_definitLeNiveauDeLEpreuve() {
        final User user = data.user();
        examenBlancIsole(user, EpreuveType.TCF_EE, NiveauCecrl.B1);
        entityManager.clear();

        assertThat(service.levelProfile(user.getId()).ee()).isEqualTo(NiveauCecrl.B1);
    }

    /** CAS 3 — l'épreuve jouée dans un examen blanc TCF complet. */
    @Test
    @DisplayName("CAS 3 — la sous-épreuve d'un examen TCF complet définit le niveau")
    void sousEpreuveDExamenTcfComplet_definitLeNiveauDeLEpreuve() {
        final User user = data.user();
        sousEpreuveDExamenComplet(user, EpreuveType.TCF_EO, NiveauCecrl.A2);
        entityManager.clear();

        assertThat(service.levelProfile(user.getId()).eo()).isEqualTo(NiveauCecrl.A2);
    }

    /**
     * 🛑 Le niveau servi est l'<b>AGRÉGAT des 3 tâches</b>, jamais une tâche
     * isolée : trois tâches notées 7/20 donnent un B1 d'épreuve par la moyenne
     * pondérée de {@code ProductionBilanService}, pas par un niveau recopié.
     */
    @Test
    @DisplayName("Le niveau servi est l'agrégat pondéré des 3 tâches de l'épreuve")
    void leNiveauServiEstLAgregatDeLEpreuve_pasUnNiveauDeTache() {
        final User user = data.user();
        examenBlancNote(user, EpreuveType.TCF_EE, "7.0");
        entityManager.clear();

        assertThat(service.levelProfile(user.getId()).ee()).isEqualTo(NiveauCecrl.B1);
    }

    /**
     * Le <b>maximum monotone</b> survit à la règle : entre deux examens complets,
     * c'est le meilleur qui tient, et un entraînement bien noté intercalé ne
     * change toujours rien.
     */
    @Test
    @DisplayName("🛑 Le meilleur EXAMEN COMPLET l'emporte, et l'entraînement n'y entre pas")
    void plusieursExamensComplets_retiennentLeMeilleur_sansCompterLEntrainement() {
        final User user = data.user();
        examenBlancIsole(user, EpreuveType.TCF_EE, NiveauCecrl.B1);
        sousEpreuveDExamenComplet(user, EpreuveType.TCF_EE, NiveauCecrl.A2);
        entrainementLibreEvalue(user, EpreuveType.TCF_EE, NiveauCecrl.B2);
        entityManager.clear();

        assertThat(service.levelProfile(user.getId()).ee()).isEqualTo(NiveauCecrl.B1);
    }

    // ------------------------------------------------------- baseline vs production

    /**
     * Règle d'arbitrage : une épreuve complète réellement évaluée prime toujours
     * sur la baseline du diagnostic rapide, <b>même quand elle est plus basse</b>.
     * Le repli se fait domaine par domaine — l'EO, elle, reste sur sa baseline.
     */
    @Test
    void epreuveComplete_primeSurLaBaseline_domaineParDomaine() {
        final User user = data.user();
        final DiagnosticSession session =
                data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        analyseLesDeuxProductions(session, NiveauCecrl.B2, NiveauCecrl.B2);

        examenBlancIsole(user, EpreuveType.TCF_EE, NiveauCecrl.A1);
        entityManager.clear();

        final TcfLevelProfile profile = service.levelProfile(user.getId());

        assertThat(profile.ee()).isEqualTo(NiveauCecrl.A1);
        assertThat(profile.eo()).isEqualTo(NiveauCecrl.B2);
    }

    /**
     * 🛑 <b>Le repli sur la baseline reste INCHANGÉ</b> : un entraînement libre
     * ne bloque pas le diagnostic rapide, puisqu'il ne renseigne plus rien. Une
     * baseline n'est jamais concurrente d'une preuve réelle — elle ne l'était
     * pas hier, elle ne l'est pas davantage aujourd'hui.
     */
    @Test
    void entrainementLibre_neBloquePasLeRepliSurLaBaselineDuDiagnostic() {
        final User user = data.user();
        final DiagnosticSession session =
                data.diagnosticSession(user, DiagnosticSessionStatus.COMPLETED);
        analyseLesDeuxProductions(session, NiveauCecrl.B1, NiveauCecrl.B1);

        entrainementLibreEvalue(user, EpreuveType.TCF_EE, NiveauCecrl.A1);
        entityManager.clear();

        assertThat(service.levelProfile(user.getId()).ee()).isEqualTo(NiveauCecrl.B1);
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
     * mesurés. ⚠️ Depuis le 2026-09-16 le domaine EE n'est plus renseigné par
     * une tâche isolée : il faut une épreuve complète pour qu'il compte.
     */
    @Test
    void productionInexploitable_neRendAucunNiveau_etLaisseLeDomaineAMesurer() {
        final User user = data.user();
        evaluationInexploitable(user, EpreuveType.TCF_EO);
        examenBlancIsole(user, EpreuveType.TCF_EE, NiveauCecrl.B1);
        entityManager.clear();

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
}

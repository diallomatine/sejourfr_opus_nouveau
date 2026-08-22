package com.sejourfr.app.service;

import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.DiagnosticSession;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.DiagnosticSessionStatus;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ProductionEvaluabilite;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;

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
}

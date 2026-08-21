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
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.assertj.core.api.Assertions.assertThat;

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

package com.sejourfr.app.service;

import com.sejourfr.app.dto.CalibrationStatsDto;
import com.sejourfr.app.dto.CalibrationSubmissionDto;
import com.sejourfr.app.dto.HumanCalibrationNoteDto;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Console de calibration vue depuis la vraie base : filtre annotees /
 * non-annotees, relecture de la derniere note humaine, et surtout
 * <b>deduplication du dashboard</b> — une production reannotee ne doit peser
 * qu'une fois dans la statistique censee dire si l'IA note juste.
 *
 * <p>Assertions en DELTA : la table est partagee avec les autres tests et le
 * seed, on ne raisonne jamais sur un total absolu.
 */
class AdminCalibrationServiceIT extends AbstractIntegrationTest {

    @Autowired
    private AdminCalibrationService service;
    @Autowired
    private ProductionSubmissionManager submissionManager;
    @Autowired
    private AiEvaluationManager aiEvaluationManager;
    @Autowired
    private TestData testData;

    private ProductionSubmission submissionEvaluee() {
        ProductionSubmission s = testData.productionSubmission();
        s.setStatut(SubmissionStatut.EVALUATED);
        return submissionManager.save(s);
    }

    private static HumanCalibrationNoteDto note(String noteSur20) {
        return new HumanCalibrationNoteDto(null, new BigDecimal(noteSur20), NiveauCecrl.B1, "test");
    }

    private static List<UUID> ids(List<CalibrationSubmissionDto> l) {
        return l.stream().map(row -> row.submission().id()).toList();
    }

    private static CalibrationSubmissionDto row(List<CalibrationSubmissionDto> l, UUID submissionId) {
        return l.stream()
                .filter(r -> submissionId.equals(r.submission().id()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Submission absente de la liste : " + submissionId));
    }

    @Test
    void listSubmissions_separe_reellement_annotees_et_vierges() {
        User admin = testData.admin();
        ProductionSubmission annotee = submissionEvaluee();
        ProductionSubmission vierge = submissionEvaluee();
        testData.aiEvaluation(annotee);
        service.annoter(annotee.getId(), admin.getId(), note("15.0"));

        List<UUID> avecNote = ids(service.listSubmissions("evaluated", true, 200));
        List<UUID> sansNote = ids(service.listSubmissions("evaluated", false, 200));

        assertThat(avecNote).contains(annotee.getId()).doesNotContain(vierge.getId());
        assertThat(sansNote).contains(vierge.getId()).doesNotContain(annotee.getId());
    }

    /**
     * La version de grille remonte bien de {@code ai_evaluations.rubrics_version}
     * jusqu'a la console. Colonne nullable (V022) : une evaluation anterieure
     * sort avec {@code null}, la console affiche « inconnue » plutot qu'une
     * erreur.
     */
    @Test
    void listSubmissions_expose_la_version_de_grille_persistee() {
        ProductionSubmission avecGrille = submissionEvaluee();
        ProductionSubmission sansGrille = submissionEvaluee();
        AiEvaluation eval = testData.aiEvaluation(avecGrille);
        eval.setRubricsVersion("v4.2");
        aiEvaluationManager.save(eval);
        testData.aiEvaluation(sansGrille); // rubrics_version laisse a null

        List<CalibrationSubmissionDto> vierges = service.listSubmissions("evaluated", false, 200);

        assertThat(row(vierges, avecGrille.getId()).rubricsVersion()).isEqualTo("v4.2");
        assertThat(row(vierges, avecGrille.getId()).promptVersion()).isEqualTo("v1.0");
        assertThat(row(vierges, sansGrille.getId()).rubricsVersion()).isNull();
    }

    @Test
    void latestHumanNote_relit_la_derniere_annotation() {
        User admin = testData.admin();
        ProductionSubmission sub = submissionEvaluee();
        service.annoter(sub.getId(), admin.getId(), note("9.0"));
        service.annoter(sub.getId(), admin.getId(), note("13.5"));

        HumanCalibrationNoteDto relue = service.latestHumanNote(sub.getId());

        assertThat(relue.noteHumaineSurVingt()).isEqualByComparingTo(new BigDecimal("13.5"));
        assertThat(relue.submissionId()).isEqualTo(sub.getId());
    }

    @Test
    void latestHumanNote_submission_jamais_annotee_renvoie_404() {
        ProductionSubmission sub = submissionEvaluee();
        assertThatThrownBy(() -> service.latestHumanNote(sub.getId()))
                .isInstanceOf(NotFoundException.class);
    }

    /**
     * Non-regression du biais silencieux : trois annotations successives de la
     * MEME production ne doivent ajouter qu'une observation au dashboard, celle
     * de la derniere note. Avant le correctif, les trois etaient moyennees.
     */
    @Test
    void stats_reannoter_ne_cree_pas_de_doublon_dans_le_dashboard() {
        User admin = testData.admin();
        ProductionSubmission sub = submissionEvaluee();
        testData.aiEvaluation(sub); // note IA = 14.5

        CalibrationStatsDto avant = service.stats();

        service.annoter(sub.getId(), admin.getId(), note("4.5"));   // ecart -10.0
        service.annoter(sub.getId(), admin.getId(), note("20.0"));  // ecart  +5.5
        service.annoter(sub.getId(), admin.getId(), note("15.0"));  // ecart  +0.5 (retenu)

        CalibrationStatsDto apres = service.stats();

        assertThat(apres.totalNotes() - avant.totalNotes()).isEqualTo(1);
        // Seule la derniere note compte : |0.5| ne franchit pas le seuil hors-cible.
        assertThat(apres.ecartsHorsCible()).isEqualTo(avant.ecartsHorsCible());
    }

    @Test
    void stats_deux_submissions_annotees_comptent_deux_fois() {
        User admin = testData.admin();
        ProductionSubmission a = submissionEvaluee();
        ProductionSubmission b = submissionEvaluee();
        testData.aiEvaluation(a);
        testData.aiEvaluation(b);

        CalibrationStatsDto avant = service.stats();
        service.annoter(a.getId(), admin.getId(), note("15.0"));
        service.annoter(b.getId(), admin.getId(), note("15.0"));

        assertThat(service.stats().totalNotes() - avant.totalNotes()).isEqualTo(2);
    }
}

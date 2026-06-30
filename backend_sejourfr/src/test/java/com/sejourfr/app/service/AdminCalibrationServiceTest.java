package com.sejourfr.app.service;

import com.sejourfr.app.dto.CalibrationStatsDto;
import com.sejourfr.app.dto.HumanCalibrationNoteDto;
import com.sejourfr.app.dto.NiveauCalibrationStatsDto;
import com.sejourfr.app.dto.ProductionSubmissionDto;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.HumanCalibrationNote;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.HumanCalibrationNoteManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.mapper.HumanCalibrationNoteMapper;
import com.sejourfr.app.mapper.ProductionSubmissionMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Console admin de calibration IA (cf. {@link AdminCalibrationService}) : filtre
 * de liste, calcul de l'ecart vs derniere {@link AiEvaluation}, agregation du
 * dashboard de fiabilite. Unitaire pur (managers mockes).
 */
class AdminCalibrationServiceTest {

    private ProductionSubmissionManager submissionManager;
    private AiEvaluationManager aiEvaluationManager;
    private HumanCalibrationNoteManager humanNoteManager;
    private UserManager userManager;
    private ProductionSubmissionMapper submissionMapper;
    private HumanCalibrationNoteMapper noteMapper;
    private AdminCalibrationService service;

    @BeforeEach
    void setUp() {
        submissionManager = mock(ProductionSubmissionManager.class);
        aiEvaluationManager = mock(AiEvaluationManager.class);
        humanNoteManager = mock(HumanCalibrationNoteManager.class);
        userManager = mock(UserManager.class);
        submissionMapper = mock(ProductionSubmissionMapper.class);
        noteMapper = mock(HumanCalibrationNoteMapper.class);
        service = new AdminCalibrationService(
                submissionManager, aiEvaluationManager, humanNoteManager,
                userManager, submissionMapper, noteMapper);
    }

    private static ProductionSubmission sub(UUID id) {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(id);
        return s;
    }

    private static HumanCalibrationNote noteWithEcart(BigDecimal ecart) {
        HumanCalibrationNote n = new HumanCalibrationNote();
        n.setEcartNote(ecart);
        return n;
    }

    // ------------------------------------------------------------------------
    // listSubmissions
    // ------------------------------------------------------------------------

    @Test
    void listSubmissions_statut_non_evaluated_refuse() {
        assertThatThrownBy(() -> service.listSubmissions("submitted", null, 50))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void listSubmissions_hasHumanNote_true_retourne_toutes_les_evaluees() {
        ProductionSubmission a = sub(UUID.randomUUID());
        ProductionSubmission b = sub(UUID.randomUUID());
        when(submissionManager.findByStatutOrderedBySubmittedAt(SubmissionStatut.EVALUATED))
                .thenReturn(List.of(a, b));
        when(submissionMapper.toDtoWithSignedAudio(any())).thenReturn(mock(ProductionSubmissionDto.class));

        List<ProductionSubmissionDto> result = service.listSubmissions("evaluated", true, 50);

        assertThat(result).hasSize(2);
        verify(submissionMapper).toDtoWithSignedAudio(a);
        verify(submissionMapper).toDtoWithSignedAudio(b);
    }

    @Test
    void listSubmissions_sans_filtre_ne_garde_que_les_non_annotees() {
        ProductionSubmission annotee = sub(UUID.randomUUID());
        ProductionSubmission vierge = sub(UUID.randomUUID());
        when(submissionManager.findByStatutOrderedBySubmittedAt(SubmissionStatut.EVALUATED))
                .thenReturn(List.of(annotee, vierge));
        when(humanNoteManager.findBySubmissionOrderedByCreatedAtDesc(annotee.getId()))
                .thenReturn(List.of(noteWithEcart(BigDecimal.ONE)));
        when(humanNoteManager.findBySubmissionOrderedByCreatedAtDesc(vierge.getId()))
                .thenReturn(List.of());
        when(submissionMapper.toDtoWithSignedAudio(any())).thenReturn(mock(ProductionSubmissionDto.class));

        List<ProductionSubmissionDto> result = service.listSubmissions("evaluated", false, 50);

        assertThat(result).hasSize(1);
        verify(submissionMapper).toDtoWithSignedAudio(vierge);
    }

    // ------------------------------------------------------------------------
    // annoter
    // ------------------------------------------------------------------------

    @Test
    void annoter_payload_invalide_refuse() {
        // note hors [0,20]
        assertThatThrownBy(() -> service.annoter(UUID.randomUUID(), UUID.randomUUID(),
                new HumanCalibrationNoteDto(null, new BigDecimal("21"), NiveauCecrl.B1, "x")))
                .isInstanceOf(BusinessException.class);
        // note manquante
        assertThatThrownBy(() -> service.annoter(UUID.randomUUID(), UUID.randomUUID(),
                new HumanCalibrationNoteDto(null, null, NiveauCecrl.B1, "x")))
                .isInstanceOf(BusinessException.class);
        // niveau manquant
        assertThatThrownBy(() -> service.annoter(UUID.randomUUID(), UUID.randomUUID(),
                new HumanCalibrationNoteDto(null, new BigDecimal("12"), null, "x")))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void annoter_submission_introuvable_renvoie_404() {
        when(submissionManager.findById(any())).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.annoter(UUID.randomUUID(), UUID.randomUUID(),
                new HumanCalibrationNoteDto(null, new BigDecimal("12"), NiveauCecrl.B1, "x")))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void annoter_calcule_l_ecart_vs_derniere_eval_et_persiste() {
        UUID subId = UUID.randomUUID();
        UUID evalId = UUID.randomUUID();
        ProductionSubmission submission = sub(subId);
        User evaluator = new User();
        AiEvaluation ai = new AiEvaluation();
        ai.setNoteSur20(new BigDecimal("14.5"));

        when(submissionManager.findById(subId)).thenReturn(Optional.of(submission));
        when(userManager.findById(evalId)).thenReturn(Optional.of(evaluator));
        when(aiEvaluationManager.findLatestBySubmissionId(subId)).thenReturn(Optional.of(ai));
        when(humanNoteManager.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(noteMapper.toDto(any())).thenReturn(mock(HumanCalibrationNoteDto.class));

        service.annoter(subId, evalId,
                new HumanCalibrationNoteDto(null, new BigDecimal("16.0"), NiveauCecrl.B2, "bien"));

        ArgumentCaptor<HumanCalibrationNote> captor = ArgumentCaptor.forClass(HumanCalibrationNote.class);
        verify(humanNoteManager).save(captor.capture());
        HumanCalibrationNote saved = captor.getValue();
        // ecart = 16.0 - 14.5 = 1.5
        assertThat(saved.getEcartNote()).isEqualByComparingTo(new BigDecimal("1.5"));
        assertThat(saved.getNoteHumaineSur20()).isEqualByComparingTo(new BigDecimal("16.0"));
        assertThat(saved.getNiveauCecrlHumain()).isEqualTo(NiveauCecrl.B2);
        assertThat(saved.getSubmission()).isSameAs(submission);
        assertThat(saved.getEvaluator()).isSameAs(evaluator);
    }

    @Test
    void annoter_sans_eval_ia_laisse_l_ecart_null() {
        UUID subId = UUID.randomUUID();
        UUID evalId = UUID.randomUUID();
        when(submissionManager.findById(subId)).thenReturn(Optional.of(sub(subId)));
        when(userManager.findById(evalId)).thenReturn(Optional.of(new User()));
        when(aiEvaluationManager.findLatestBySubmissionId(subId)).thenReturn(Optional.empty());
        when(humanNoteManager.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(noteMapper.toDto(any())).thenReturn(mock(HumanCalibrationNoteDto.class));

        service.annoter(subId, evalId,
                new HumanCalibrationNoteDto(null, new BigDecimal("12"), NiveauCecrl.B1, null));

        ArgumentCaptor<HumanCalibrationNote> captor = ArgumentCaptor.forClass(HumanCalibrationNote.class);
        verify(humanNoteManager).save(captor.capture());
        assertThat(captor.getValue().getEcartNote()).isNull();
    }

    // ------------------------------------------------------------------------
    // stats
    // ------------------------------------------------------------------------

    @Test
    void stats_aucune_note_renvoie_zero_non_calibre() {
        when(humanNoteManager.findAll()).thenReturn(List.of());
        CalibrationStatsDto dto = service.stats();
        assertThat(dto.totalNotes()).isZero();
        assertThat(dto.calibre()).isFalse();
        assertThat(dto.seuilHorsCible()).isEqualByComparingTo(new BigDecimal("3.0"));
    }

    @Test
    void stats_agrege_moyenne_pourcentage_et_marque_non_calibre() {
        when(humanNoteManager.findAll()).thenReturn(List.of(
                noteWithEcart(new BigDecimal("1.0")),
                noteWithEcart(new BigDecimal("2.0")),
                noteWithEcart(new BigDecimal("-1.0")),
                noteWithEcart(new BigDecimal("4.0")),
                noteWithEcart(null))); // null ignore

        CalibrationStatsDto dto = service.stats();

        assertThat(dto.totalNotes()).isEqualTo(4);
        assertThat(dto.ecartMoyen()).isEqualByComparingTo(new BigDecimal("1.50"));      // 6/4
        assertThat(dto.ecartMoyenAbsolu()).isEqualByComparingTo(new BigDecimal("2.00")); // 8/4
        assertThat(dto.ecartsHorsCible()).isEqualTo(1);                                  // |4.0|>3.0
        assertThat(dto.pourcentageHorsCible()).isEqualByComparingTo(new BigDecimal("25.0"));
        // moyenneAbs 2.0 >= 1.5 → non calibre
        assertThat(dto.calibre()).isFalse();
    }

    @Test
    void stats_petits_ecarts_marque_calibre() {
        when(humanNoteManager.findAll()).thenReturn(List.of(
                noteWithEcart(new BigDecimal("1.0")),
                noteWithEcart(new BigDecimal("-1.0")),
                noteWithEcart(new BigDecimal("1.0"))));

        CalibrationStatsDto dto = service.stats();

        assertThat(dto.totalNotes()).isEqualTo(3);
        assertThat(dto.ecartsHorsCible()).isZero();
        // moyenneAbs 1.0 < 1.5 et pourcentage 0 < 5 → calibre
        assertThat(dto.calibre()).isTrue();
    }

    // ------------------------------------------------------------------------
    // niveauStats
    // ------------------------------------------------------------------------

    @Test
    void niveauStats_calcule_le_pourcentage_de_divergence() {
        when(aiEvaluationManager.countWithBothNiveaux()).thenReturn(10L);
        when(aiEvaluationManager.countNiveauDivergent()).thenReturn(3L);

        NiveauCalibrationStatsDto dto = service.niveauStats();

        assertThat(dto.totalAvecNiveau()).isEqualTo(10);
        assertThat(dto.divergents()).isEqualTo(3);
        assertThat(dto.pourcentageDivergents()).isEqualByComparingTo(new BigDecimal("30.0"));
    }

    @Test
    void niveauStats_total_zero_evite_la_division() {
        when(aiEvaluationManager.countWithBothNiveaux()).thenReturn(0L);
        when(aiEvaluationManager.countNiveauDivergent()).thenReturn(0L);

        NiveauCalibrationStatsDto dto = service.niveauStats();

        assertThat(dto.totalAvecNiveau()).isZero();
        assertThat(dto.pourcentageDivergents()).isEqualByComparingTo(BigDecimal.ZERO);
    }
}

package com.sejourfr.app.service;

import com.sejourfr.app.dto.CalibrationStatsDto;
import com.sejourfr.app.dto.CalibrationSubmissionDto;
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
import com.sejourfr.app.mapper.CalibrationSubmissionMapper;
import com.sejourfr.app.mapper.HumanCalibrationNoteMapper;
import com.sejourfr.app.mapper.ProductionSubmissionMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
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
        // Mapper pur : la vraie implementation, sinon les assertions sur les
        // versions de grille ne testeraient qu'un mock.
        service = new AdminCalibrationService(
                submissionManager, aiEvaluationManager, humanNoteManager,
                userManager, submissionMapper, new CalibrationSubmissionMapper(), noteMapper);
    }

    private static ProductionSubmission sub(UUID id) {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(id);
        return s;
    }

    /** Note rattachee a une submission distincte : le cas "pas de doublon". */
    private static HumanCalibrationNote noteWithEcart(BigDecimal ecart) {
        return noteWithEcart(sub(UUID.randomUUID()), ecart);
    }

    private static HumanCalibrationNote noteWithEcart(ProductionSubmission submission, BigDecimal ecart) {
        HumanCalibrationNote n = new HumanCalibrationNote();
        n.setSubmission(submission);
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

    /**
     * Non-regression : {@code hasHumanNote=true} renvoyait TOUTES les evaluees
     * (filtre oublie), obligeant la console admin a deduire les annotees par
     * difference de listes.
     */
    @Test
    void listSubmissions_hasHumanNote_true_ne_garde_que_les_annotees() {
        ProductionSubmission annotee = sub(UUID.randomUUID());
        ProductionSubmission vierge = sub(UUID.randomUUID());
        when(submissionManager.findByStatutOrderedBySubmittedAt(SubmissionStatut.EVALUATED))
                .thenReturn(List.of(annotee, vierge));
        when(humanNoteManager.findAnnotatedSubmissionIds(any()))
                .thenReturn(Set.of(annotee.getId()));
        when(submissionMapper.toDto(any())).thenReturn(mock(ProductionSubmissionDto.class));

        List<CalibrationSubmissionDto> result = service.listSubmissions("evaluated", true, 50);

        assertThat(result).hasSize(1);
        verify(submissionMapper).toDto(annotee);
        verify(submissionMapper, never()).toDto(vierge);
    }

    @Test
    void listSubmissions_sans_filtre_ne_garde_que_les_non_annotees() {
        ProductionSubmission annotee = sub(UUID.randomUUID());
        ProductionSubmission vierge = sub(UUID.randomUUID());
        when(submissionManager.findByStatutOrderedBySubmittedAt(SubmissionStatut.EVALUATED))
                .thenReturn(List.of(annotee, vierge));
        when(humanNoteManager.findAnnotatedSubmissionIds(any()))
                .thenReturn(Set.of(annotee.getId()));
        when(submissionMapper.toDto(any())).thenReturn(mock(ProductionSubmissionDto.class));

        List<CalibrationSubmissionDto> result = service.listSubmissions("evaluated", false, 50);

        assertThat(result).hasSize(1);
        verify(submissionMapper).toDto(vierge);
    }

    /** Les ids annotes sont charges en UNE requete, pas une par submission. */
    @Test
    void listSubmissions_ne_fait_qu_une_requete_pour_les_ids_annotes() {
        List<ProductionSubmission> base = List.of(
                sub(UUID.randomUUID()), sub(UUID.randomUUID()), sub(UUID.randomUUID()));
        when(submissionManager.findByStatutOrderedBySubmittedAt(SubmissionStatut.EVALUATED))
                .thenReturn(base);
        when(humanNoteManager.findAnnotatedSubmissionIds(any())).thenReturn(Set.of());
        when(submissionMapper.toDto(any())).thenReturn(mock(ProductionSubmissionDto.class));

        service.listSubmissions("evaluated", false, 50);

        verify(humanNoteManager, times(1)).findAnnotatedSubmissionIds(any());
    }

    /**
     * Comparer note IA et note humaine n'a de sens qu'a bareme connu : la ligne
     * expose la grille de sa derniere evaluation.
     */
    @Test
    void listSubmissions_expose_les_versions_de_la_derniere_evaluation() {
        ProductionSubmission vierge = sub(UUID.randomUUID());
        AiEvaluation eval = new AiEvaluation();
        eval.setRubricsVersion("v4.2");
        eval.setPromptVersion("v4");
        when(submissionManager.findByStatutOrderedBySubmittedAt(SubmissionStatut.EVALUATED))
                .thenReturn(List.of(vierge));
        when(humanNoteManager.findAnnotatedSubmissionIds(any())).thenReturn(Set.of());
        when(submissionMapper.toDto(any())).thenReturn(mock(ProductionSubmissionDto.class));
        when(aiEvaluationManager.findLatestBySubmissionId(vierge.getId()))
                .thenReturn(Optional.of(eval));

        List<CalibrationSubmissionDto> result = service.listSubmissions("evaluated", false, 50);

        assertThat(result).singleElement().satisfies(row -> {
            assertThat(row.rubricsVersion()).isEqualTo("v4.2");
            assertThat(row.promptVersion()).isEqualTo("v4");
            assertThat(row.submission()).isNotNull();
        });
    }

    /**
     * Colonne {@code rubrics_version} ajoutee apres coup (V022) : une evaluation
     * anterieure sort avec une version nulle, ce n'est pas une erreur. Idem
     * quand aucune evaluation n'est rattachee.
     */
    @Test
    void listSubmissions_versions_nulles_quand_inconnues() {
        ProductionSubmission ancienne = sub(UUID.randomUUID());
        ProductionSubmission sansEval = sub(UUID.randomUUID());
        AiEvaluation legacy = new AiEvaluation();
        legacy.setPromptVersion("v2");
        when(submissionManager.findByStatutOrderedBySubmittedAt(SubmissionStatut.EVALUATED))
                .thenReturn(List.of(ancienne, sansEval));
        when(humanNoteManager.findAnnotatedSubmissionIds(any())).thenReturn(Set.of());
        when(submissionMapper.toDto(any())).thenReturn(mock(ProductionSubmissionDto.class));
        when(aiEvaluationManager.findLatestBySubmissionId(ancienne.getId()))
                .thenReturn(Optional.of(legacy));
        when(aiEvaluationManager.findLatestBySubmissionId(sansEval.getId()))
                .thenReturn(Optional.empty());

        List<CalibrationSubmissionDto> result = service.listSubmissions("evaluated", false, 50);

        assertThat(result).hasSize(2);
        assertThat(result.get(0).rubricsVersion()).isNull();
        assertThat(result.get(0).promptVersion()).isEqualTo("v2");
        assertThat(result.get(1).rubricsVersion()).isNull();
        assertThat(result.get(1).promptVersion()).isNull();
    }

    // ------------------------------------------------------------------------
    // latestHumanNote
    // ------------------------------------------------------------------------

    @Test
    void latestHumanNote_renvoie_la_derniere_note() {
        UUID subId = UUID.randomUUID();
        HumanCalibrationNote derniere = noteWithEcart(sub(subId), new BigDecimal("2.0"));
        HumanCalibrationNoteDto dto = mock(HumanCalibrationNoteDto.class);
        when(humanNoteManager.findLatestBySubmission(subId)).thenReturn(Optional.of(derniere));
        when(noteMapper.toDto(derniere)).thenReturn(dto);

        assertThat(service.latestHumanNote(subId)).isSameAs(dto);
    }

    @Test
    void latestHumanNote_jamais_annotee_renvoie_404() {
        UUID subId = UUID.randomUUID();
        when(humanNoteManager.findLatestBySubmission(subId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.latestHumanNote(subId))
                .isInstanceOf(NotFoundException.class);
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
        when(humanNoteManager.findAllOrderedByCreatedAtDesc()).thenReturn(List.of());
        CalibrationStatsDto dto = service.stats();
        assertThat(dto.totalNotes()).isZero();
        assertThat(dto.calibre()).isFalse();
        assertThat(dto.seuilHorsCible()).isEqualByComparingTo(new BigDecimal("3.0"));
    }

    @Test
    void stats_agrege_moyenne_pourcentage_et_marque_non_calibre() {
        when(humanNoteManager.findAllOrderedByCreatedAtDesc()).thenReturn(List.of(
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
        when(humanNoteManager.findAllOrderedByCreatedAtDesc()).thenReturn(List.of(
                noteWithEcart(new BigDecimal("1.0")),
                noteWithEcart(new BigDecimal("-1.0")),
                noteWithEcart(new BigDecimal("1.0"))));

        CalibrationStatsDto dto = service.stats();

        assertThat(dto.totalNotes()).isEqualTo(3);
        assertThat(dto.ecartsHorsCible()).isZero();
        // moyenneAbs 1.0 < 1.5 et pourcentage 0 < 5 → calibre
        assertThat(dto.calibre()).isTrue();
    }

    /**
     * Non-regression du biais le plus grave : une production reannotee comptait
     * autant de fois qu'elle avait de notes. Ici la reannotation a corrige un
     * ecart de 6.0 en 0.5 — l'ancien code moyennait les deux (3.25) et marquait
     * la calibration en echec ; seule la DERNIERE note doit compter.
     */
    @Test
    void stats_une_submission_reannotee_ne_compte_qu_une_fois() {
        ProductionSubmission reannotee = sub(UUID.randomUUID());
        when(humanNoteManager.findAllOrderedByCreatedAtDesc()).thenReturn(List.of(
                noteWithEcart(reannotee, new BigDecimal("0.5")),   // la plus recente
                noteWithEcart(reannotee, new BigDecimal("6.0")),   // corrigee, ignoree
                noteWithEcart(reannotee, new BigDecimal("-6.0")),  // corrigee, ignoree
                noteWithEcart(new BigDecimal("0.5"))));            // autre submission

        CalibrationStatsDto dto = service.stats();

        assertThat(dto.totalNotes()).isEqualTo(2);
        assertThat(dto.ecartMoyen()).isEqualByComparingTo(new BigDecimal("0.50"));
        assertThat(dto.ecartsHorsCible()).isZero();
        assertThat(dto.calibre()).isTrue();
    }

    /** Une note sans submission ne peut pas etre dedupliquee : on l'ignore. */
    @Test
    void stats_ignore_une_note_orpheline() {
        HumanCalibrationNote orpheline = new HumanCalibrationNote();
        orpheline.setEcartNote(new BigDecimal("10.0"));
        when(humanNoteManager.findAllOrderedByCreatedAtDesc()).thenReturn(List.of(
                orpheline, noteWithEcart(new BigDecimal("1.0"))));

        CalibrationStatsDto dto = service.stats();

        assertThat(dto.totalNotes()).isEqualTo(1);
        assertThat(dto.ecartMoyen()).isEqualByComparingTo(new BigDecimal("1.00"));
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

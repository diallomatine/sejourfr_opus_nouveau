package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.HumanCalibrationNoteDto;
import com.sejourfr.app.entity.HumanCalibrationNote;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.NiveauCecrl;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class HumanCalibrationNoteMapperTest {

    private final HumanCalibrationNoteMapper mapper = new HumanCalibrationNoteMapper();

    @Test
    void toDto_mapsEveryField() {
        UUID submissionId = UUID.randomUUID();
        ProductionSubmission submission = new ProductionSubmission();
        submission.setId(submissionId);

        HumanCalibrationNote note = new HumanCalibrationNote();
        note.setSubmission(submission);
        note.setNoteHumaineSur20(new BigDecimal("14.5"));
        note.setNiveauCecrlHumain(NiveauCecrl.B1);
        note.setCommentaires("Bon niveau mais lexique limité");

        HumanCalibrationNoteDto dto = mapper.toDto(note);

        assertThat(dto.submissionId()).isEqualTo(submissionId);
        assertThat(dto.noteHumaineSurVingt()).isEqualByComparingTo("14.5");
        assertThat(dto.niveauCecrlHumain()).isEqualTo(NiveauCecrl.B1);
        assertThat(dto.commentaires()).isEqualTo("Bon niveau mais lexique limité");
    }

    @Test
    void toDto_nullCommentaires_passthrough() {
        ProductionSubmission submission = new ProductionSubmission();
        submission.setId(UUID.randomUUID());
        HumanCalibrationNote note = new HumanCalibrationNote();
        note.setSubmission(submission);
        note.setNoteHumaineSur20(new BigDecimal("8.0"));
        note.setNiveauCecrlHumain(NiveauCecrl.A1_NON_ATTEINT);

        HumanCalibrationNoteDto dto = mapper.toDto(note);

        assertThat(dto.commentaires()).isNull();
        assertThat(dto.niveauCecrlHumain()).isEqualTo(NiveauCecrl.A1_NON_ATTEINT);
    }
}

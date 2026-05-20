package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.HumanCalibrationNoteDto;
import com.sejourfr.app.entity.HumanCalibrationNote;
import org.springframework.stereotype.Component;

@Component
public class HumanCalibrationNoteMapper {

    public HumanCalibrationNoteDto toDto(HumanCalibrationNote n) {
        return new HumanCalibrationNoteDto(
                n.getSubmission().getId(),
                n.getNoteHumaineSur20(),
                n.getNiveauCecrlHumain(),
                n.getCommentaires()
        );
    }
}

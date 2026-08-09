package com.sejourfr.app.dto;

import com.sejourfr.app.enums.DiagnosticCommunicationStatus;
import com.sejourfr.app.enums.DiagnosticTaskCompletion;
import com.sejourfr.app.enums.NiveauCecrl;

import java.util.List;

public record DiagnosticProductionResultDto(
        NiveauCecrl levelEstimate,
        DiagnosticTaskCompletion taskCompletion,
        DiagnosticCommunicationStatus communicationStatus,
        String summary,
        List<String> strengths,
        List<String> weaknesses,
        List<DiagnosticSkillObservationDto> skills
) {}

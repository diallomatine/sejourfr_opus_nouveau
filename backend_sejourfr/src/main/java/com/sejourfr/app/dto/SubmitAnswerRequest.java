package com.sejourfr.app.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import java.util.List;
import java.util.UUID;

public record SubmitAnswerRequest(
        @NotNull UUID attemptQuestionId,
        @NotEmpty List<UUID> choiceIds
) {}

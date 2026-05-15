package com.sejourfr.app.audioquestion.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.sejourfr.app.audioquestion.domain.AudioMode;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * Structure attendue dans le `input` du bloc tool_use renvoye par Claude
 * (outil `emit_audio_question`). Validee par Bean Validation des reception
 * pour rejeter immediatement toute reponse hors specs.
 */
public record AnthropicGenerationResponse(

    @NotNull @Valid AudioSection audio,
    @NotNull @Valid QuestionSection question,
    @NotNull @Size(min = 4, max = 4, message = "Exactement 4 choix attendus")
    List<@Valid ChoiceSection> choices

) {

    public record AudioSection(
        @NotBlank @Size(max = 5000) String transcript,
        @NotBlank @Size(max = 8000) String ssml,
        @Min(1) @Max(5) int speakerCount,
        @NotEmpty @Size(min = 1, max = 5) List<@Valid VoiceInfo> voices,
        @Min(5) @Max(240) int estimatedDurationSec,
        @NotBlank @Size(max = 500) String contextDescription,
        @NotNull AudioMode audioMode
    ) {}

    public record VoiceInfo(
        @NotBlank @Size(max = 64) String role,
        @NotBlank @Pattern(regexp = "^fr-FR-[A-Za-z]+Neural$", message = "Voix Azure non conforme")
        String azureVoice,
        @NotBlank @Pattern(regexp = "^(F|M)$", message = "Le genre doit etre F ou M")
        String gender
    ) {}

    public record QuestionSection(
        @NotBlank @Size(max = 500) String statement,
        @NotBlank @Size(min = 50, max = 1500) String explanation,
        @NotBlank @Pattern(regexp = "^co_[a-z_]+$", message = "Code competence non conforme")
        String competenceCode,
        @NotBlank @Pattern(regexp = "^(A2|B1|B2)$", message = "Niveau de difficulte non conforme")
        String difficulty,
        @NotBlank @Size(max = 64) String themeSuggested
    ) {}

    public record ChoiceSection(
        @NotBlank @Size(max = 200) String label,
        @JsonProperty("isCorrect") boolean isCorrect,
        @Min(1) @Max(4) int displayOrder
    ) {}
}

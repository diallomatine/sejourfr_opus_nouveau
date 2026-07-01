package com.sejourfr.app.service;

import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.manager.ProductionTaskManager;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ProductionRubricsValidatorTest {

    @Mock
    private ProductionRubricsProvider rubrics;
    @Mock
    private ProductionTaskManager taskManager;

    private ProductionRubricsValidator validator() {
        return new ProductionRubricsValidator(rubrics, taskManager);
    }

    private Map<String, Object> validCommun() {
        return Map.of(
                "sections", List.of(Map.of("titre", "Role", "contenu", "...")),
                "few_shot", List.of(Map.of("niveau", "A2")));
    }

    private Map<String, Object> rubric(double poids1, double poids2, String code1, String code2) {
        return Map.of("criteres", List.of(
                Map.of("code", code1, "poids", poids1),
                Map.of("code", code2, "poids", poids2)));
    }

    private void stubValid() {
        when(rubrics.getCommun()).thenReturn(validCommun());
        when(rubrics.all()).thenReturn(Map.of("EE_T1",
                rubric(0.5, 0.5, "lexique", "morphosyntaxe")));
        when(taskManager.findAllActive()).thenReturn(List.of());
    }

    @Test
    void validate_validRubrics_noThrow() {
        stubValid();
        assertThatCode(() -> validator().validate()).doesNotThrowAnyException();
    }

    @Test
    void validate_poidsSumNotOne_throws() {
        when(rubrics.getCommun()).thenReturn(validCommun());
        when(rubrics.all()).thenReturn(Map.of("EE_T1",
                rubric(0.5, 0.3, "lexique", "morphosyntaxe")));
        lenient().when(taskManager.findAllActive()).thenReturn(List.of());

        assertThatThrownBy(() -> validator().validate())
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void validate_nonCanonicalCode_throws() {
        when(rubrics.getCommun()).thenReturn(validCommun());
        when(rubrics.all()).thenReturn(Map.of("EE_T1",
                rubric(0.5, 0.5, "lexique", "orthographe")));
        lenient().when(taskManager.findAllActive()).thenReturn(List.of());

        assertThatThrownBy(() -> validator().validate())
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void validate_emptyCommunSections_throws() {
        when(rubrics.getCommun()).thenReturn(Map.of("sections", List.of(), "few_shot", List.of()));
        when(rubrics.all()).thenReturn(Map.of("EE_T1",
                rubric(0.5, 0.5, "lexique", "morphosyntaxe")));
        lenient().when(taskManager.findAllActive()).thenReturn(List.of());

        assertThatThrownBy(() -> validator().validate())
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void validate_activeTaskWithoutRubric_throws() {
        when(rubrics.getCommun()).thenReturn(validCommun());
        when(rubrics.all()).thenReturn(Map.of("EE_T1",
                rubric(0.5, 0.5, "lexique", "morphosyntaxe")));

        ProductionTask task = new ProductionTask();
        task.setEpreuve(EpreuveType.TCF_EE);
        task.setTacheNumero((short) 2);
        when(taskManager.findAllActive()).thenReturn(List.of(task));
        when(rubrics.find(EpreuveType.TCF_EE, 2)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> validator().validate())
                .isInstanceOf(IllegalStateException.class);
    }
}

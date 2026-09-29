package com.sejourfr.app.service;

import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.support.EmbeddedPostgresHolder;
import com.sejourfr.app.support.TestData;
import com.sejourfr.app.support.TestSupportConfig;
import org.junit.jupiter.api.Test;
import org.springframework.aop.support.AopUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

/**
 * Reproduction avec proxy {@code @Async}, proxy transactionnel et vrai
 * PostgreSQL du rollback-only qui faisait sortir un UnexpectedRollbackException
 * apres que le catch avait pourtant enregistre FAILED.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@ActiveProfiles("test")
@Import(TestSupportConfig.class)
class ProductionPipelineAsyncRunnerIT {

    @Autowired private ProductionPipelineAsyncRunner runner;
    @Autowired private AiEvaluationService aiEvaluationService;
    @Autowired private ProductionSubmissionManager submissionManager;
    @Autowired private TestData testData;

    // Remplace uniquement le port externe. AiEvaluationService reste un vrai
    // bean transactionnel proxifie : son exception traverse donc bien
    // l'intercepteur Spring qui devait autrefois marquer la transaction
    // englobante du runner rollback-only.
    @MockitoBean(name = "evaluationLlmClient")
    private EvaluationLlmClient llmClient;

    @DynamicPropertySource
    static void datasourceProperties(DynamicPropertyRegistry registry) {
        EmbeddedPostgresHolder.registerDatasource(registry);
    }

    @Test
    void echecEvaluationPersisteFailedSansUnexpectedRollbackDansLeFutureAsync() {
        assertThat(AopUtils.isAopProxy(aiEvaluationService)).isTrue();

        ProductionSubmission submission = testData.productionSubmission();
        UUID submissionId = submission.getId();
        submission.setTexteSoumis("Je souhaite vous présenter mon projet de formation en français. "
            + "Cette formation m'aidera dans mon travail et dans mes démarches quotidiennes. "
            + "Je suis motivé parce que je veux communiquer clairement avec mes collègues "
            + "et devenir plus autonome en France.");
        submission.setMotsCount(39);
        submissionManager.save(submission);

        when(llmClient.getPromptVersion()).thenReturn("v4");
        when(llmClient.getModelName()).thenReturn("llm-transaction-test");
        when(llmClient.evaluate(anyString(), anyString()))
            .thenThrow(new AiEvaluationException("sortie LLM invalide de test"));

        CompletableFuture<Void> execution = runner.runPipelineAsync(submissionId, false);

        assertThatCode(() -> execution.get(10, TimeUnit.SECONDS))
            .doesNotThrowAnyException();
        ProductionSubmission reloaded = submissionManager.findById(submissionId).orElseThrow();
        assertThat(reloaded.getStatut()).isEqualTo(SubmissionStatut.FAILED);
        assertThat(reloaded.getErreurMessage()).isEqualTo("sortie LLM invalide de test");
    }
}

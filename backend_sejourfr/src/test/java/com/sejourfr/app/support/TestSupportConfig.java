package com.sejourfr.app.support;

import com.sejourfr.app.audioquestion.repository.AudioQuestionDraftRepository;
import com.sejourfr.app.audioquestion.repository.AudioQuestionGenerationLogRepository;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.AnswerManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.manager.ConversationManager;
import com.sejourfr.app.manager.EmailChangeTokenManager;
import com.sejourfr.app.manager.ExamTemplateManager;
import com.sejourfr.app.manager.HumanCalibrationNoteManager;
import com.sejourfr.app.manager.MediaManager;
import com.sejourfr.app.manager.MessageManager;
import com.sejourfr.app.manager.PassageManager;
import com.sejourfr.app.manager.PasswordResetTokenManager;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.RealtimeSessionManager;
import com.sejourfr.app.manager.RefreshTokenManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.manager.UserQuestionStatusManager;
import com.sejourfr.app.manager.UserSubscriptionManager;
import com.sejourfr.app.repository.ProcessedExternalEventRepository;
import com.sejourfr.app.repository.ProductionTaskRepository;
import com.sejourfr.app.security.JwtService;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * Beans utilitaires de test, importés par {@link AbstractIntegrationTest}. Isolés
 * dans une {@code @TestConfiguration} (et non en {@code @Component} scanné) pour
 * ne charger que dans les contextes de test.
 */
@TestConfiguration
public class TestSupportConfig {

    @Bean
    public TestData testData(UserManager userManager,
                             ThemeManager themeManager,
                             PasswordEncoder passwordEncoder,
                             MediaManager mediaManager,
                             PassageManager passageManager,
                             QuestionManager questionManager,
                             AttemptManager attemptManager,
                             AttemptQuestionManager attemptQuestionManager,
                             AnswerManager answerManager,
                             PlanManager planManager,
                             UserSubscriptionManager userSubscriptionManager,
                             ProductionTaskManager productionTaskManager,
                             ProductionTaskRepository productionTaskRepository,
                             ProductionSubmissionManager productionSubmissionManager,
                             ExamTemplateManager examTemplateManager,
                             ConversationManager conversationManager,
                             MessageManager messageManager,
                             RefreshTokenManager refreshTokenManager,
                             PasswordResetTokenManager passwordResetTokenManager,
                             EmailChangeTokenManager emailChangeTokenManager,
                             ProcessedExternalEventRepository processedExternalEventRepository,
                             UserQuestionStatusManager userQuestionStatusManager,
                             AiEvaluationManager aiEvaluationManager,
                             TranscriptionManager transcriptionManager,
                             HumanCalibrationNoteManager humanCalibrationNoteManager,
                             RealtimeSessionManager realtimeSessionManager,
                             AudioQuestionDraftRepository audioQuestionDraftRepository,
                             AudioQuestionGenerationLogRepository audioQuestionGenerationLogRepository) {
        return new TestData(userManager, themeManager, passwordEncoder,
                mediaManager, passageManager, questionManager, attemptManager,
                attemptQuestionManager, answerManager, planManager,
                userSubscriptionManager, productionTaskManager, productionTaskRepository,
                productionSubmissionManager, examTemplateManager, conversationManager,
                messageManager, refreshTokenManager, passwordResetTokenManager,
                emailChangeTokenManager, processedExternalEventRepository,
                userQuestionStatusManager, aiEvaluationManager, transcriptionManager,
                humanCalibrationNoteManager, realtimeSessionManager,
                audioQuestionDraftRepository, audioQuestionGenerationLogRepository);
    }

    @Bean
    public AuthTestSupport authTestSupport(JwtService jwtService) {
        return new AuthTestSupport(jwtService);
    }
}

import { QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { AuthProvider } from "./auth/AuthContext";
import { AppLayout } from "./components/layout/AppLayout";
import { ToastProvider } from "./components/ui/Toast";
import { AudioDraftReviewPage } from "./features/audioQuestions/AudioDraftReviewPage";
import { AudioQuestionGeneratePage } from "./features/audioQuestions/AudioQuestionGeneratePage";
import { AudioQuestionLogsPage } from "./features/audioQuestions/AudioQuestionLogsPage";
import { AnalyticsPage } from "./features/analytics/AnalyticsPage";
import { AiCostsPage } from "./features/aiCosts/AiCostsPage";
import { CalibrationPage } from "./features/calibration/CalibrationPage";
import { ExampleAudioReviewPage } from "./features/exampleAudio/ExampleAudioReviewPage";
import { ConversationsPage } from "./features/conversations/ConversationsPage";
import { ExamFormPage } from "./features/exams/ExamFormPage";
import { ExamsPage } from "./features/exams/ExamsPage";
import { PlansPage } from "./features/plans/PlansPage";
import { ProductionTitlesPage } from "./features/productionTasks/ProductionTitlesPage";
import { QuestionDetailPage } from "./features/questions/QuestionDetailPage";
import { QuestionsPage } from "./features/questions/QuestionsPage";
import { SkillDetailPage } from "./features/skills/SkillDetailPage";
import { SkillsPage } from "./features/skills/SkillsPage";
import { SkillsStatsPage } from "./features/skills/SkillsStatsPage";
import { SubscriptionsPage } from "./features/subscriptions/SubscriptionsPage";
import { ThemesPage } from "./features/themes/ThemesPage";
import { queryClient } from "./lib/queryClient";
import { LoginPage } from "./pages/LoginPage";
import { ProtectedRoute } from "./routes/ProtectedRoute";

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <AuthProvider>
          <ToastProvider>
            <Routes>
              <Route path="/login" element={<LoginPage />} />

              <Route
                element={
                  <ProtectedRoute>
                    <AppLayout />
                  </ProtectedRoute>
                }
              >
                <Route index element={<Navigate to="/dashboard" replace />} />
                <Route path="/dashboard" element={<AnalyticsPage />} />
                <Route
                  path="/questions"
                  element={<Navigate to="/questions/civique" replace />}
                />
                <Route path="/questions/:module" element={<QuestionsPage />} />
                <Route
                  path="/questions/:module/:id"
                  element={<QuestionDetailPage />}
                />
                <Route path="/themes" element={<ThemesPage />} />
                <Route path="/skills" element={<SkillsPage />} />
                <Route
                  path="/production-titles"
                  element={<ProductionTitlesPage />}
                />
                <Route path="/skills/stats" element={<SkillsStatsPage />} />
                <Route path="/skills/:id" element={<SkillDetailPage />} />
                <Route path="/exams" element={<ExamsPage />} />
                <Route path="/exams/new" element={<ExamFormPage />} />
                <Route path="/exams/:id" element={<ExamFormPage />} />
                <Route
                  path="/audio-questions/generate"
                  element={<AudioQuestionGeneratePage />}
                />
                <Route
                  path="/audio-questions/review"
                  element={<AudioDraftReviewPage />}
                />
                <Route
                  path="/audio-questions/logs"
                  element={<AudioQuestionLogsPage />}
                />
                <Route
                  path="/example-audio/review"
                  element={<ExampleAudioReviewPage />}
                />
                <Route path="/calibration" element={<CalibrationPage />} />
                <Route path="/couts-ia" element={<AiCostsPage />} />
                <Route path="/plans" element={<PlansPage />} />
                <Route path="/subscriptions" element={<SubscriptionsPage />} />
                <Route path="/conversations" element={<ConversationsPage />} />
              </Route>

              <Route path="*" element={<Navigate to="/dashboard" replace />} />
            </Routes>
          </ToastProvider>
        </AuthProvider>
      </BrowserRouter>
    </QueryClientProvider>
  );
}

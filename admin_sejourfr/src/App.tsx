import { QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { AuthProvider } from "./auth/AuthContext";
import { AppLayout } from "./components/layout/AppLayout";
import { ToastProvider } from "./components/ui/Toast";
import { ConversationsPage } from "./features/conversations/ConversationsPage";
import { DashboardPage } from "./features/dashboard/DashboardPage";
import { ExamFormPage } from "./features/exams/ExamFormPage";
import { ExamsPage } from "./features/exams/ExamsPage";
import { QuestionDetailPage } from "./features/questions/QuestionDetailPage";
import { QuestionsPage } from "./features/questions/QuestionsPage";
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
                <Route path="/dashboard" element={<DashboardPage />} />
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
                <Route path="/exams" element={<ExamsPage />} />
                <Route path="/exams/new" element={<ExamFormPage />} />
                <Route path="/exams/:id" element={<ExamFormPage />} />
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

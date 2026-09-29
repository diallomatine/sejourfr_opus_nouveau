import { apiRequest } from "./http";
import type {
  AdminExamTemplateDto,
  AdminExamTemplateWriteRequest,
  ExamCompositionSuggestionDto,
  Module,
  TargetLevel,
  TargetProcedure,
} from "../types/api";

export const examsApi = {
  list(module?: Module) {
    return apiRequest<AdminExamTemplateDto[]>("/api/admin/exams", {
      query: { module },
    });
  },

  getById(id: string) {
    return apiRequest<AdminExamTemplateDto>(`/api/admin/exams/${id}`);
  },

  create(req: AdminExamTemplateWriteRequest) {
    return apiRequest<AdminExamTemplateDto>("/api/admin/exams", {
      method: "POST",
      body: req,
    });
  },

  update(id: string, req: AdminExamTemplateWriteRequest) {
    return apiRequest<AdminExamTemplateDto>(`/api/admin/exams/${id}`, {
      method: "PUT",
      body: req,
    });
  },

  delete(id: string) {
    return apiRequest<void>(`/api/admin/exams/${id}`, { method: "DELETE" });
  },

  suggestComposition(params: {
    module: Module;
    targetProcedure?: TargetProcedure;
    targetLevel?: TargetLevel;
    totalQuestions?: number;
  }) {
    return apiRequest<ExamCompositionSuggestionDto>(
      "/api/admin/exams/composition-suggestion",
      { query: params },
    );
  },
};

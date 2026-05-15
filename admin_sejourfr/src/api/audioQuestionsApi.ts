import { apiRequest } from "./http";
import type {
  GenerateAudioQuestionRequest,
  GenerationLogDto,
  GenerationStatus,
  PageResponse,
  QuestionPreviewDto,
  ValidationResultDto,
} from "../types/api";

export interface GenerationLogsParams {
  status?: GenerationStatus;
  adminUserId?: string;
  page?: number;
  size?: number;
  sort?: string;
}

export const audioQuestionsApi = {
  generate(req: GenerateAudioQuestionRequest) {
    return apiRequest<QuestionPreviewDto>("/api/admin/audio-questions/generate", {
      method: "POST",
      body: req,
    });
  },

  preview(id: string) {
    return apiRequest<QuestionPreviewDto>(`/api/admin/audio-questions/${id}/preview`);
  },

  validate(id: string) {
    return apiRequest<ValidationResultDto>(`/api/admin/audio-questions/${id}/validate`, {
      method: "PATCH",
    });
  },

  reject(id: string) {
    return apiRequest<void>(`/api/admin/audio-questions/${id}`, { method: "DELETE" });
  },

  listLogs(params: GenerationLogsParams = {}) {
    return apiRequest<PageResponse<GenerationLogDto>>(
      "/api/admin/audio-questions/generation-logs",
      { query: { ...params } },
    );
  },
};

import { apiRequest } from "./http";
import type {
  Difficulty,
  Module,
  PageResponse,
  QuestionDto,
  QuestionMediaFilter,
  QuestionType,
  QuestionWriteRequest,
} from "../types/api";

export interface QuestionsSearchParams {
  module?: Module;
  themeId?: string;
  difficulty?: Difficulty;
  type?: QuestionType;
  active?: boolean;
  /** Filtre serveur : les 3 types de média, ou `NONE` pour « sans média ». */
  media?: QuestionMediaFilter;
  search?: string;
  page?: number;
  size?: number;
  sort?: string;
}

export const questionsApi = {
  search(params: QuestionsSearchParams = {}) {
    return apiRequest<PageResponse<QuestionDto>>("/api/admin/questions", {
      query: { ...params },
    });
  },

  getById(id: string) {
    return apiRequest<QuestionDto>(`/api/admin/questions/${id}`);
  },

  create(req: QuestionWriteRequest) {
    return apiRequest<QuestionDto>("/api/admin/questions", {
      method: "POST",
      body: req,
    });
  },

  update(id: string, req: QuestionWriteRequest) {
    return apiRequest<QuestionDto>(`/api/admin/questions/${id}`, {
      method: "PUT",
      body: req,
    });
  },

  setActive(id: string, active: boolean) {
    return apiRequest<QuestionDto>(`/api/admin/questions/${id}/status`, {
      method: "PATCH",
      body: { active },
    });
  },

  delete(id: string) {
    return apiRequest<void>(`/api/admin/questions/${id}`, { method: "DELETE" });
  },
};

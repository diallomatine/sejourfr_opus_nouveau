import { apiRequest } from "./http";
import type {
  AudioDraftDto,
  AudioLevel,
  BatchGenerationResultDto,
  PageResponse,
  PendingReviewCountDto,
} from "../types/api";

export interface PendingReviewParams {
  page?: number;
  size?: number;
  difficulty?: AudioLevel;
}

export const audioDraftsApi = {
  batchGenerate(difficulty?: AudioLevel) {
    return apiRequest<BatchGenerationResultDto>("/api/admin/audio-drafts/batch-generate", {
      method: "POST",
      query: difficulty ? { difficulty } : undefined,
    });
  },

  pendingReview(params: PendingReviewParams = {}) {
    return apiRequest<PageResponse<AudioDraftDto>>("/api/admin/audio-drafts/pending-review", {
      query: { ...params },
    });
  },

  pendingReviewCount(difficulty?: AudioLevel) {
    return apiRequest<PendingReviewCountDto>("/api/admin/audio-drafts/pending-review/count", {
      query: difficulty ? { difficulty } : undefined,
    });
  },

  validate(id: string) {
    return apiRequest<AudioDraftDto>(`/api/admin/audio-drafts/${id}/validate`, {
      method: "POST",
    });
  },

  reject(id: string, reason: string) {
    return apiRequest<AudioDraftDto>(`/api/admin/audio-drafts/${id}/reject`, {
      method: "POST",
      body: { reason },
    });
  },

  replaceImage(id: string, file: File) {
    const form = new FormData();
    form.append("file", file);
    return apiRequest<AudioDraftDto>(`/api/admin/audio-drafts/${id}/image`, {
      method: "POST",
      formData: form,
    });
  },
};

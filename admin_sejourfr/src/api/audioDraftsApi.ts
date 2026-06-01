import { apiRequest } from "./http";
import type {
  AudioDraftDto,
  BatchGenerationResultDto,
  PageResponse,
  PendingReviewCountDto,
} from "../types/api";

export interface PendingReviewParams {
  page?: number;
  size?: number;
}

export const audioDraftsApi = {
  batchGenerate() {
    return apiRequest<BatchGenerationResultDto>("/api/admin/audio-drafts/batch-generate", {
      method: "POST",
    });
  },

  pendingReview(params: PendingReviewParams = {}) {
    return apiRequest<PageResponse<AudioDraftDto>>("/api/admin/audio-drafts/pending-review", {
      query: { ...params },
    });
  },

  pendingReviewCount() {
    return apiRequest<PendingReviewCountDto>("/api/admin/audio-drafts/pending-review/count");
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

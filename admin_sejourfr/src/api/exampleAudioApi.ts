import { apiRequest } from "./http";
import type {
  ExampleAudioBatchResultDto,
  ExampleAudioDto,
  PendingReviewCountDto,
} from "../types/api";

const BASE = "/api/admin/production/examples/audio";

export const exampleAudioApi = {
  batchGenerate(size = 10) {
    return apiRequest<ExampleAudioBatchResultDto>(`${BASE}/batch-generate`, {
      method: "POST",
      query: { size },
    });
  },

  pendingCount() {
    return apiRequest<PendingReviewCountDto>(`${BASE}/pending/count`);
  },

  toReview() {
    return apiRequest<ExampleAudioDto[]>(`${BASE}/to-review`);
  },

  publish(id: string) {
    return apiRequest<ExampleAudioDto>(`${BASE}/${id}/publish`, {
      method: "POST",
    });
  },

  regenerate(id: string, voice?: string) {
    return apiRequest<ExampleAudioDto>(`${BASE}/${id}/regenerate`, {
      method: "POST",
      body: voice ? { voice } : {},
    });
  },
};

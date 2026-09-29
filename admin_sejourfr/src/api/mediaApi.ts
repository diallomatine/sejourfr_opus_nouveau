import { apiRequest } from "./http";
import type {
  MediaCreateFromUrlRequest,
  MediaDto,
  MediaType,
} from "../types/api";

interface UploadParams {
  file: File;
  type: MediaType;
  durationSec?: number;
  altText?: string;
}

function upload({ file, type, durationSec, altText }: UploadParams): Promise<MediaDto> {
  const formData = new FormData();
  formData.append("file", file);
  return apiRequest<MediaDto>("/api/admin/media/upload", {
    method: "POST",
    formData,
    query: { type, durationSec, altText },
  });
}

export const mediaApi = {
  upload,
  createFromUrl(req: MediaCreateFromUrlRequest) {
    return apiRequest<MediaDto>("/api/admin/media/from-url", {
      method: "POST",
      body: req,
    });
  },
  getById(id: string) {
    return apiRequest<MediaDto>(`/api/admin/media/${id}`);
  },
  delete(id: string) {
    return apiRequest<void>(`/api/admin/media/${id}`, { method: "DELETE" });
  },
};

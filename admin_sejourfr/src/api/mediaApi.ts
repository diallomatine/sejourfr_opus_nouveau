import { apiBaseUrl, apiRequest, HttpError } from "./http";
import { tokenStorage } from "../auth/tokenStorage";
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

async function upload({ file, type, durationSec, altText }: UploadParams): Promise<MediaDto> {
  const form = new FormData();
  form.append("file", file);
  const params = new URLSearchParams();
  params.set("type", type);
  if (durationSec !== undefined) params.set("durationSec", String(durationSec));
  if (altText) params.set("altText", altText);

  const token = tokenStorage.getAccess();
  const res = await fetch(`${apiBaseUrl()}/api/admin/media/upload?${params.toString()}`, {
    method: "POST",
    headers: token ? { Authorization: `Bearer ${token}` } : {},
    body: form,
  });
  if (!res.ok) {
    let payload = null;
    try {
      payload = await res.json();
    } catch {
      payload = null;
    }
    const msg = (payload as { message?: string } | null)?.message ?? `Erreur HTTP ${res.status}`;
    throw new HttpError(res.status, msg, payload);
  }
  return (await res.json()) as MediaDto;
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

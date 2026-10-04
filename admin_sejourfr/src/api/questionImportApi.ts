import { HttpError, apiRequest } from "./http";
import type { CoImageImportReport } from "../types/api";

const BASE = "/api/admin/question-imports/co-image";

function multipart(manifest: string, images: File[]): FormData {
  const form = new FormData();
  form.append("manifest", new Blob([manifest], { type: "application/json" }));
  for (const image of images) form.append("images", image, image.name);
  return form;
}

function isReport(value: unknown): value is CoImageImportReport {
  return (
    typeof value === "object" &&
    value !== null &&
    "questions" in value &&
    "errors" in value &&
    "imported" in value
  );
}

export const questionImportApi = {
  analyzeCoImage(manifest: string, images: File[]) {
    return apiRequest<CoImageImportReport>(`${BASE}/analyze`, {
      method: "POST",
      formData: multipart(manifest, images),
    });
  },

  /** 201 ⇒ brouillons créés ; 422 ⇒ le même rapport, rien d'écrit (rendu, pas levé). */
  async importCoImage(manifest: string, images: File[]): Promise<CoImageImportReport> {
    try {
      return await apiRequest<CoImageImportReport>(`${BASE}/import`, {
        method: "POST",
        formData: multipart(manifest, images),
      });
    } catch (err) {
      if (err instanceof HttpError && err.status === 422 && isReport(err.payload)) {
        return err.payload;
      }
      throw err;
    }
  },
};

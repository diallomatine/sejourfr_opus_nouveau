import { apiRequest, HttpError } from "./http";
import type {
  CalibrationStatsDto,
  HumanCalibrationNoteDto,
  NiveauCalibrationStatsDto,
  ProductionSubmissionDto,
} from "../types/api";

export const calibrationApi = {
  submissions(hasHumanNote: boolean, limit: number) {
    return apiRequest<ProductionSubmissionDto[]>(
      "/api/admin/calibration/submissions",
      { query: { status: "evaluated", hasHumanNote, limit } },
    );
  },

  /** La dernière note humaine d'une submission, ou `null` si jamais annotée (404). */
  async humanNote(
    submissionId: string,
  ): Promise<HumanCalibrationNoteDto | null> {
    try {
      return await apiRequest<HumanCalibrationNoteDto>(
        `/api/admin/calibration/submissions/${submissionId}/human-note`,
      );
    } catch (err) {
      if (err instanceof HttpError && err.status === 404) return null;
      throw err;
    }
  },

  saveHumanNote(submissionId: string, body: HumanCalibrationNoteDto) {
    return apiRequest<HumanCalibrationNoteDto>(
      `/api/admin/calibration/submissions/${submissionId}/human-note`,
      { method: "POST", body },
    );
  },

  stats() {
    return apiRequest<CalibrationStatsDto>("/api/admin/calibration/stats");
  },

  niveauStats() {
    return apiRequest<NiveauCalibrationStatsDto>(
      "/api/admin/calibration/stats/niveau",
    );
  },
};

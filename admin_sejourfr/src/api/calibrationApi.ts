import { apiRequest } from "./http";
import type {
  CalibrationStatsDto,
  HumanCalibrationNoteDto,
  NiveauCalibrationStatsDto,
  ProductionSubmissionDto,
} from "../types/api";

/**
 * `hasHumanNote=false` restreint aux submissions non annotées ; `true` renvoie
 * la totalité des évaluées (le backend ne filtre pas dans ce sens). Le tri
 * des deux listes est identique, ce qui permet de déduire les annotées par
 * différence côté page.
 */
export const calibrationApi = {
  submissions(hasHumanNote: boolean, limit: number) {
    return apiRequest<ProductionSubmissionDto[]>(
      "/api/admin/calibration/submissions",
      { query: { status: "evaluated", hasHumanNote, limit } },
    );
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

import { apiRequest } from "./http";
import type {
  CivicNotionDto,
  CivicTaggingQueue,
} from "../types/api";

/**
 * Le référentiel de notions civiques et son tagging (lot L8).
 *
 * 🛑 **Aucun appel LLM.** La table de suggestions existe et reste vide : la
 * remplir coûte de l'argent pour 1 016 questions, et c'est une décision du
 * propriétaire.
 */
export const civicNotionsApi = {
  /** Le référentiel, avec la couverture **mesurée** par notion et par mention. */
  referentiel(signal?: AbortSignal) {
    return apiRequest<CivicNotionDto[]>("/api/admin/civic-notions", { signal });
  },

  /** La file de tagging. `tagged=false` = ce qu'il reste à faire. */
  file(
    params: { theme?: string; tagged: boolean; limit: number; offset: number },
    signal?: AbortSignal,
  ) {
    const query: Record<string, string> = {
      tagged: String(params.tagged),
      limit: String(params.limit),
      offset: String(params.offset),
    };
    if (params.theme) query.theme = params.theme;
    return apiRequest<CivicTaggingQueue>("/api/admin/civic-notions/questions", {
      query,
      signal,
    });
  },

  /**
   * Pose ou efface le tag **validé** d'une question.
   *
   * `notionCode: null` efface — se tromper doit rester rattrapable depuis
   * l'écran. Effacer ne dit pas « cette question n'a pas de notion », mais
   * « elle attend à nouveau ».
   */
  taguer(questionId: string, notionCode: string | null) {
    return apiRequest<void>(`/api/admin/civic-notions/questions/${questionId}`, {
      method: "PUT",
      body: { notionCode },
    });
  },
};

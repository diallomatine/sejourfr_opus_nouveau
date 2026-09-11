import { apiRequest } from "./http";
import type {
  CivicNotionDto,
  CivicTaggingQueue,
  CivicTaggingQuestion,
  CivicTaggingSuggestion,
} from "../types/api";

/**
 * Le référentiel de notions civiques et son tagging (lot L8).
 *
 * 🛑 **Aucun appel LLM n'est déclenché depuis cette couche.** Les suggestions
 * sont lues, jamais produites : les fabriquer pour 1 016 questions coûte de
 * l'argent, et c'est une décision du propriétaire.
 */

/**
 * Le contrat sert `explication`, `choix`, `rationale` et `reviewVerdict`, mais
 * le backend peut être en cours de livraison : un champ absent doit produire un
 * écran sobre, pas un écran cassé ni un « null » affiché. On normalise **ici**,
 * une seule fois, pour que le composant n'ait aucun `??` défensif à porter.
 */
function normaliserSuggestion(suggestion: CivicTaggingSuggestion): CivicTaggingSuggestion {
  return {
    notionCode: suggestion.notionCode,
    notionLabel: suggestion.notionLabel,
    confidence: typeof suggestion.confidence === "number" ? suggestion.confidence : 0,
    rationale: suggestion.rationale ?? null,
    reviewVerdict: suggestion.reviewVerdict ?? null,
  };
}

function normaliserQuestion(question: CivicTaggingQuestion): CivicTaggingQuestion {
  return {
    ...question,
    explication: question.explication ?? null,
    choix: (question.choix ?? []).filter((choix) => Boolean(choix?.label)),
    // La suggestion « n°1 » est la mieux notée, jamais celle qui arrive en
    // premier dans le tableau : c'est elle que « Valider » retient et c'est à
    // elle que le serveur se compare pour trancher VALIDATED / CORRECTED.
    suggestions: (question.suggestions ?? [])
      .map(normaliserSuggestion)
      .sort((a, b) => b.confidence - a.confidence),
  };
}

export const civicNotionsApi = {
  /** Le référentiel, avec la couverture **mesurée** par notion et par mention. */
  referentiel(signal?: AbortSignal) {
    return apiRequest<CivicNotionDto[]>("/api/admin/civic-notions", { signal });
  },

  /** La file de tagging. `tagged=false` = ce qu'il reste à faire. */
  async file(
    params: { theme?: string; tagged: boolean; limit: number; offset: number },
    signal?: AbortSignal,
  ): Promise<CivicTaggingQueue> {
    const query: Record<string, string> = {
      tagged: String(params.tagged),
      limit: String(params.limit),
      offset: String(params.offset),
    };
    if (params.theme) query.theme = params.theme;
    const queue = await apiRequest<CivicTaggingQueue>(
      "/api/admin/civic-notions/questions",
      { query, signal },
    );
    return {
      resteATaguer: queue.resteATaguer ?? 0,
      questions: (queue.questions ?? []).map(normaliserQuestion),
    };
  },

  /**
   * Écrit le geste du relecteur sur une question.
   *
   * Les quatre gestes produisent quatre écritures distinctes :
   * - valider   → `{notionCode: <suggestion n°1>, verdict: null}`
   * - corriger  → `{notionCode: <autre notion>,   verdict: null}`
   * - rejeter   → `{notionCode: null,             verdict: "REJECTED"}`
   * - passer    → `{notionCode: null,             verdict: "SKIPPED"}`
   *
   * 🛑 **Le client n'envoie jamais `VALIDATED` ni `CORRECTED`.** C'est le
   * serveur qui compare la notion retenue à la suggestion la mieux notée : la
   * mesure de justesse du pré-tagging ne peut pas dépendre du client, sinon
   * elle mesure le client.
   */
  taguer(questionId: string, notionCode: string | null, verdict: string | null) {
    return apiRequest<void>(`/api/admin/civic-notions/questions/${questionId}`, {
      method: "PUT",
      body: { notionCode, verdict },
    });
  },
};

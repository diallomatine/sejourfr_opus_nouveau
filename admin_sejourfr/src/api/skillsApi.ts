import { apiRequest } from "./http";
import type {
  AdminSkillCreateRequest,
  AdminSkillDetailDto,
  AdminSkillDto,
  AdminSkillFilters,
  AdminSkillPromptCreateRequest,
  AdminSkillPromptDto,
  AdminSkillPromptUpdateRequest,
  AdminSkillReferencesUpdateRequest,
  AdminSkillStatsDto,
  AdminSkillUpdateRequest,
  PageResponse,
  SkillSection,
} from "../types/api";

export const skillsApi = {
  list(filters: AdminSkillFilters = {}) {
    return apiRequest<PageResponse<AdminSkillDto>>("/api/admin/skills", {
      query: {
        section: filters.section,
        taskCode: filters.taskCode,
        active: filters.active,
        q: filters.q,
        page: filters.page,
        size: filters.size,
      },
    });
  },

  getById(id: string) {
    return apiRequest<AdminSkillDetailDto>(`/api/admin/skills/${id}`);
  },

  /** `generalCriterion` est obligatoire : la colonne est NOT NULL, l'omettre renvoie 400. */
  create(req: AdminSkillCreateRequest) {
    return apiRequest<AdminSkillDto>("/api/admin/skills", {
      method: "POST",
      body: req,
    });
  },

  update(id: string, req: AdminSkillUpdateRequest) {
    return apiRequest<AdminSkillDto>(`/api/admin/skills/${id}`, {
      method: "PATCH",
      body: req,
    });
  },

  /** 409 si une tentative candidat référence la compétence : on désactive au lieu de détruire. */
  remove(id: string) {
    return apiRequest<void>(`/api/admin/skills/${id}`, { method: "DELETE" });
  },

  stats(section?: SkillSection) {
    return apiRequest<AdminSkillStatsDto[]>("/api/admin/skills/stats", {
      query: { section },
    });
  },

  getPrompt(id: string) {
    return apiRequest<AdminSkillPromptDto>(`/api/admin/skill-prompts/${id}`);
  },

  /**
   * Les quatre champs de guidage (`checklist`, `constraintTags`,
   * `answerStarter`, `tip`) partent dans la même charge utile. Ils sont
   * facultatifs, mais **toujours envoyés** : une liste vide vaut `null` côté
   * serveur, et le service valide tout avant d'écrire quoi que ce soit — un
   * refus (422) ne laisse jamais un sujet à moitié créé.
   */
  createPrompt(req: AdminSkillPromptCreateRequest) {
    return apiRequest<AdminSkillPromptDto>("/api/admin/skill-prompts", {
      method: "POST",
      body: req,
    });
  },

  /**
   * PATCH à sémantique de **remplacement** sur les bornes de longueur ET sur les
   * quatre champs de guidage : un `null` y efface, il ne veut pas dire « ne
   * touche pas ». C'est ce qui rend une check-list posée par erreur effaçable
   * depuis la console — le formulaire envoie donc systématiquement les quatre.
   */
  updatePrompt(id: string, req: AdminSkillPromptUpdateRequest) {
    return apiRequest<AdminSkillPromptDto>(`/api/admin/skill-prompts/${id}`, {
      method: "PATCH",
      body: req,
    });
  },

  /** 409 si une tentative candidat référence le sujet. */
  removePrompt(id: string) {
    return apiRequest<void>(`/api/admin/skill-prompts/${id}`, {
      method: "DELETE",
    });
  },

  /** Remplace les 3 références d'un coup (atomique côté serveur). */
  replaceReferences(promptId: string, req: AdminSkillReferencesUpdateRequest) {
    return apiRequest<AdminSkillPromptDto>(
      `/api/admin/skill-prompts/${promptId}/references`,
      { method: "PUT", body: req },
    );
  },
};

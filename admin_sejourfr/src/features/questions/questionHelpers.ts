import type { Difficulty, Module, QuestionType } from "../../types/api";

export const CIVIQUE_LEVELS: Difficulty[] = ["CSP", "CR", "NAT"];
export const TCF_LEVELS: Difficulty[] = ["A2", "B1", "B2"];

const CIVIQUE_TYPES: QuestionType[] = ["CONNAISSANCE", "MISE_SITUATION"];
const TCF_TYPES: QuestionType[] = ["CO", "CE", "STRUCTURE"];

export function levelsForModule(module: Module): Difficulty[] {
  return module === "CIVIQUE" ? CIVIQUE_LEVELS : TCF_LEVELS;
}

export function typesForModule(module: Module): QuestionType[] {
  return module === "CIVIQUE" ? CIVIQUE_TYPES : TCF_TYPES;
}

export const QUESTION_TYPE_LABELS: Record<QuestionType, string> = {
  CONNAISSANCE: "Connaissance",
  MISE_SITUATION: "Mise en situation",
  CO: "Compréhension orale",
  CE: "Compréhension écrite",
  STRUCTURE: "Structure de la langue",
};

export const QUESTION_TYPE_SHORT: Record<QuestionType, string> = {
  CONNAISSANCE: "Connaissance",
  MISE_SITUATION: "Mise en situation",
  CO: "CO",
  CE: "CE",
  STRUCTURE: "Structure",
};

export function tagToneForLevel(level: Difficulty): "csp" | "cr" | "nat" | "a2" | "b1" | "b2" {
  return level.toLowerCase() as ReturnType<typeof tagToneForLevel>;
}

export function tagToneForType(
  type: QuestionType,
): "conn" | "mise" | "co" | "ce" | "structure" {
  switch (type) {
    case "CONNAISSANCE":
      return "conn";
    case "MISE_SITUATION":
      return "mise";
    case "CO":
      return "co";
    case "CE":
      return "ce";
    case "STRUCTURE":
      return "structure";
  }
}

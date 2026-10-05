import type { TagTone } from "../../components/ui/Tag";
import type { MessageStatus } from "../../types/api";

export const MESSAGE_STATUSES = ["NOUVEAU", "LU", "EN_COURS", "REPONDU", "ARCHIVE"] as const satisfies readonly MessageStatus[];

export const STATUS_LABELS: Record<MessageStatus, string> = {
  NOUVEAU: "Nouveau",
  LU: "Lu",
  EN_COURS: "En cours",
  REPONDU: "Répondu",
  ARCHIVE: "Archivé",
};

export const STATUS_TONES: Record<MessageStatus, TagTone> = {
  NOUVEAU: "info",
  LU: "neutral",
  EN_COURS: "warning",
  REPONDU: "success",
  ARCHIVE: "neutral",
};

export function messageCountLabel(count: number): string {
  return `${count} message${count > 1 ? "s" : ""}`;
}

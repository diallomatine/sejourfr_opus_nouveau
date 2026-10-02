import type { TagTone } from "../../components/ui/Tag";
import type { AdminAccessOperationType, ProductAccessStatus } from "../../types/api";

/**
 * Couleur d'un statut d'accès SERVI (D-29) : simple correspondance d'enum, le
 * texte affiché reste le libellé du serveur.
 */
export const ACCESS_STATUS_TONE: Record<ProductAccessStatus, TagTone> = {
  ACTIVE: "success",
  SCHEDULED: "info",
  REVOKED: "danger",
  EXPIRED: "warning",
  NONE: "neutral",
};

/** Ton du bouton d'une opération servie (le serveur décide lesquelles existent). */
export const OPERATION_VARIANT: Record<AdminAccessOperationType, "primary" | "default" | "danger" | "ghost"> = {
  EXTEND: "primary",
  REACTIVATE: "primary",
  SHORTEN: "default",
  CORRECT_PRODUCT: "default",
  GRANT: "ghost",
  END: "danger",
};

/** Opérations qui retirent un droit : point rouge dans l'historique. */
export const RESTRICTIVE_OPERATIONS: readonly AdminAccessOperationType[] = ["END", "CORRECT_PRODUCT", "SHORTEN"];

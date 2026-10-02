import type { ProductAccessStatus } from "../../../types/api";
import styles from "./AccessStatusBadge.module.css";

const TONE: Record<ProductAccessStatus, string> = {
  ACTIVE: styles.active,
  SCHEDULED: styles.scheduled,
  REVOKED: styles.revoked,
  EXPIRED: styles.expired,
  NONE: styles.none,
};

interface AccessStatusBadgeProps {
  status: ProductAccessStatus;
  /** Libellé servi (« Intégral · Actif », « Révoqué »…). */
  label: string;
}

/** Pastille d'un statut d'accès SERVI : la couleur suit l'enum, le texte est celui du serveur. */
export function AccessStatusBadge({ status, label }: AccessStatusBadgeProps) {
  return <span className={`${styles.badge} ${TONE[status]}`}>{label}</span>;
}

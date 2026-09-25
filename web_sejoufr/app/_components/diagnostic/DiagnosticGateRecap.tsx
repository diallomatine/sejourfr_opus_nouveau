import { Check, ShieldCheck, type LucideIcon } from "lucide-react";
import styles from "@/app/_components/auth/auth.module.css";

export interface DiagnosticGateRecapItem {
  Icon: LucideIcon;
  title: string;
  meta: string;
}

/**
 * Ce que le visiteur a déjà fait, rappelé en tête de la carte de compte des
 * deux diagnostics invités (TCF et civique) — c'est ce qui rend le compte
 * concret : il ne s'inscrit pas « pour voir », il récupère son travail.
 *
 * 🛑 Uniquement des faits connus de l'écran (mots écrits, durée enregistrée,
 * réponses données). Aucun résultat : il n'existe pas encore.
 */
export function DiagnosticGateRecap({
  items,
  note,
}: {
  items: readonly DiagnosticGateRecapItem[];
  /** Où le travail est gardé en attendant le compte. */
  note?: string;
}) {
  return (
    <>
      <ul className={styles.recap}>
        {items.map(({ Icon, title, meta }) => (
          <li key={title} className={styles.recapItem}>
            <span className={styles.recapIcon} aria-hidden>
              <Icon size={17} />
            </span>
            <span className={styles.recapTitle}>{title}</span>
            <span className={styles.recapMeta}>{meta}</span>
            <span className={styles.recapCheck} aria-hidden>
              <Check size={13} strokeWidth={3.2} />
            </span>
          </li>
        ))}
      </ul>
      {note ? (
        <p className={styles.recapNote}>
          <ShieldCheck size={15} aria-hidden />
          <span>{note}</span>
        </p>
      ) : null}
    </>
  );
}

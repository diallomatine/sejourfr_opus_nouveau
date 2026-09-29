"use client";

import { AlertCircle, ArrowRight, Loader2 } from "lucide-react";
import type { ReactNode } from "react";
import styles from "./auth.module.css";

/** Bandeau d'erreur global (identifiants refusés, panne, erreur hors champ). */
export function AuthAlert({ children }: { children: ReactNode }) {
  return (
    <div className={styles.alert} role="alert">
      <AlertCircle size={18} aria-hidden />
      <span>{children}</span>
    </div>
  );
}

/**
 * Bouton d'envoi pleine largeur. Bleu par défaut ; rouge réservé au CTA
 * critique (création du compte).
 */
export function AuthSubmit({
  loading,
  label,
  loadingLabel,
  tone = "blue",
}: {
  loading: boolean;
  label: string;
  loadingLabel: string;
  tone?: "blue" | "red";
}) {
  return (
    <button
      type="submit"
      disabled={loading}
      aria-busy={loading}
      className={`${styles.submit} ${tone === "red" ? styles.submitRed : styles.submitBlue}`}
    >
      {loading ? <Loader2 size={18} className={styles.spin} aria-hidden /> : null}
      <span>{loading ? loadingLabel : label}</span>
      {loading ? null : <ArrowRight size={17} className={styles.submitArrow} aria-hidden />}
    </button>
  );
}

/** Donne le focus au premier champ en erreur, dans l'ordre du formulaire. */
export function focusFirstError(order: readonly string[], errors: Partial<Record<string, string>>): void {
  const first = order.find((id) => errors[id]);
  if (first) document.getElementById(first)?.focus();
}

import type { ReactNode } from "react";
import { Button } from "./Button";
import styles from "./InlineError.module.css";

interface InlineErrorProps {
  children: ReactNode;
  /** Affiche « Réessayer » quand il est fourni. */
  onRetry?: () => void;
}

/** Bandeau d'erreur pleine largeur d'un panneau (chargement, actualisation). */
export function InlineError({ children, onRetry }: InlineErrorProps) {
  return (
    <div className={styles.error} role="alert">
      <span>{children}</span>
      {onRetry && (
        <Button variant="default" size="sm" onClick={onRetry}>
          Réessayer
        </Button>
      )}
    </div>
  );
}

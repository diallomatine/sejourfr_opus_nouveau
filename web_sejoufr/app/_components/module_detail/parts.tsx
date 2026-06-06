"use client";

import Link from "next/link";
import styles from "./ModuleDetail.module.css";

/**
 * Écran d'invite à la connexion affiché par les pages détail d'entraînement
 * (connecté uniquement) quand le visiteur n'est pas authentifié.
 *
 * Les briques des pages détail vivent dans `app/_components/hub/DetailParts.tsx`
 * (DetailShell, LevelChoiceCard, SerieCard, ExamsGrid…) depuis la refonte
 * web_refonte.
 */
export function ModuleDetailGate({next}: {next: string}) {
  return (
    <main className={styles.gate}>
      <p>Connectez-vous pour accéder à cette page.</p>
      <Link href={`/connexion?next=${encodeURIComponent(next)}`} className={styles.gateCta}>
        Se connecter →
      </Link>
    </main>
  );
}

export {styles as moduleDetailStyles};

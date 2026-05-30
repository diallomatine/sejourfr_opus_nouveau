"use client";

import Link from "next/link";
import styles from "./ModuleDetail.module.css";

/**
 * Écran d'invite à la connexion affiché par les pages détail d'entraînement
 * (connecté uniquement) quand le visiteur n'est pas authentifié.
 *
 * Les anciennes briques à onglets (ModuleDetailShell / ModuleHero / ModuleTabs
 * / LotsGrid / ExamSlots / ErrorsList / SkeletonGrid) ont été retirées lors du
 * passage des pages détail au design single-scroll mobile : elles vivent
 * désormais dans `app/_components/hub/` (HubDetailHeader, LotRow, ExamSlotsView,
 * ExamHistoryList…).
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

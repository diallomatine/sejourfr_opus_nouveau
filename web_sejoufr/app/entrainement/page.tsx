"use client";

import {useSearchParams} from "next/navigation";
import {Suspense} from "react";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ReviserScreen} from "@/app/_components/reviser/ReviserScreen";
import {useAuth} from "@/lib/auth-context";
import {moduleDeLUrl} from "@/lib/module-switch";

export default function EntrainementPage() {
  return (
    <Suspense fallback={<EntrainementSkeleton />}>
      <EntrainementRoot />
    </Suspense>
  );
}

/**
 * **L'écran « Réviser »**, scopé par `?module=`.
 *
 * 🛑 **Pas de bascule de parcours ici** : on y arrive par la barre latérale,
 * qui porte une entrée « Entraînement » par module (Navigation v2) — le choix
 * est fait avant d'arriver. Le mobile garde la sienne, parce que Réviser y est un onglet de la
 * barre du bas ; écart de **forme**, pas de parcours.
 *
 * Connecté → sidebar via `DualChromeShell` ; visiteur → chrome public
 * (`SiteHeader` / `Footer` du layout racine).
 */
function EntrainementRoot() {
  const {status, user} = useAuth();
  const searchParams = useSearchParams();
  if (status === "loading") return <EntrainementSkeleton />;
  const safeUser = status === "authenticated" ? user : null;
  // `moduleDeLUrl` (casse tolérée), la même lecture que la barre latérale.
  const parcours = moduleDeLUrl(searchParams) === "TCF" ? "TCF" : "CIVIQUE";
  const screen = <ReviserScreen module={parcours} user={safeUser} />;
  return safeUser ? <DualChromeShell>{screen}</DualChromeShell> : screen;
}

function EntrainementSkeleton() {
  return <div style={{minHeight: "calc(100vh - 80px)", background: "var(--color-paper)"}} />;
}

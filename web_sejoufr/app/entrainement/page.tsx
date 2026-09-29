"use client";

import {useSearchParams} from "next/navigation";
import {Suspense} from "react";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ReviserScreen} from "@/app/_components/reviser/ReviserScreen";
import {useAuth} from "@/lib/auth-context";

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
 * 🛑 **Pas de bascule de parcours ici** (arbitrage du propriétaire,
 * 2026-09-12) : on y arrive par la barre latérale, qui porte déjà ses deux
 * entrées « TCF IRN » et « Examen civique » — le choix est fait avant
 * d'arriver. Le mobile garde la sienne, parce que Réviser y est un onglet de la
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
  const module = searchParams?.get("module") === "TCF" ? "TCF" : "CIVIQUE";
  const screen = <ReviserScreen module={module} user={safeUser} />;
  return safeUser ? <DualChromeShell>{screen}</DualChromeShell> : screen;
}

function EntrainementSkeleton() {
  return <div style={{minHeight: "calc(100vh - 80px)", background: "var(--color-paper)"}} />;
}

"use client";

import {useSearchParams} from "next/navigation";
import {Suspense} from "react";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {CiviqueHub} from "@/app/_components/hub/CiviqueHub";
import {TcfHub} from "@/app/_components/hub/TcfHub";
import {useAuth} from "@/lib/auth-context";

export default function EntrainementPage() {
  return (
    <Suspense fallback={<EntrainementSkeleton />}>
      <EntrainementRoot />
    </Suspense>
  );
}

/**
 * Dispatch par module, miroir des écrans mobiles séparés (CiviqueScreen /
 * TcfScreen) : `?module=TCF` → TcfHub, sinon CiviqueHub. Les deux sont des
 * hubs single-scroll dédiés. Connecté → sidebar via DualChromeShell ; guest →
 * chrome public (SiteHeader/Footer du layout racine).
 */
function EntrainementRoot() {
  const {status, user} = useAuth();
  const searchParams = useSearchParams();
  if (status === "loading") return <EntrainementSkeleton />;
  const safeUser = status === "authenticated" ? user : null;
  const moduleParam = searchParams?.get("module") === "TCF" ? "TCF" : "CIVIQUE";
  const hub =
    moduleParam === "TCF" ? <TcfHub user={safeUser} /> : <CiviqueHub user={safeUser} />;
  return safeUser ? <DualChromeShell>{hub}</DualChromeShell> : hub;
}

function EntrainementSkeleton() {
  return <div style={{minHeight: "calc(100vh - 80px)", background: "var(--color-paper)"}} />;
}

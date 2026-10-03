"use client";

import {usePathname} from "next/navigation";
import {useEffect} from "react";
import {trackScreenView} from "@/lib/analytics";
import {useAuth} from "@/lib/auth-context";
import {startPresence, stopPresence} from "@/lib/presence";

/** Chantier « Activité » : une vue d'écran par changement d'adresse
 *  (`SCREEN_VIEWED`, tout visiteur) et le battement de présence d'un compte
 *  connecté (`lib/presence.ts`). Monté une fois, dans le layout racine. */
export function ActivityTracker() {
  const pathname = usePathname();
  const {status} = useAuth();

  useEffect(() => {
    if (pathname) trackScreenView(pathname);
  }, [pathname]);

  useEffect(() => {
    if (status !== "authenticated") return;
    startPresence();
    return stopPresence;
  }, [status]);

  return null;
}

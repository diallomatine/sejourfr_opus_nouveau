"use client";

import { usePathname } from "next/navigation";
import { useEffect } from "react";
import { notePopState, recordPath } from "@/lib/nav-history";

/** Tient le compteur d'historique interne (`lib/nav-history.ts`). Layout racine. */
export function NavHistoryTracker() {
  const pathname = usePathname();

  useEffect(() => {
    window.addEventListener("popstate", notePopState);
    return () => window.removeEventListener("popstate", notePopState);
  }, []);

  useEffect(() => {
    if (pathname) recordPath(pathname);
  }, [pathname]);

  return null;
}

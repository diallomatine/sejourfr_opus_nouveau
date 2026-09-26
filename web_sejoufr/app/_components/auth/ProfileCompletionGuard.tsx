"use client";

import { usePathname, useRouter } from "next/navigation";
import { useEffect } from "react";
import { useAuth } from "@/lib/auth-context";
import {
  mustCompleteProfile,
  profileCompletionHref,
  requiresCompleteProfile,
} from "@/lib/profile-completion";

/**
 * Garde de l'application : un compte connecté dont le serveur dit le profil
 * incomplet (`profileIncomplete`) est conduit à `/completer-profil`, avec la
 * page demandée en `?next=`. Monté une fois, dans le layout racine.
 *
 * Miroir mobile : le `redirect` global de `app_router.dart` vers `/target-path`.
 */
export function ProfileCompletionGuard() {
  const { status, user } = useAuth();
  const pathname = usePathname();
  const router = useRouter();

  useEffect(() => {
    if (status !== "authenticated" || !mustCompleteProfile(user)) return;
    if (!requiresCompleteProfile(pathname)) return;
    const search = typeof window === "undefined" ? "" : window.location.search;
    router.replace(profileCompletionHref(`${pathname}${search}`));
  }, [status, user, pathname, router]);

  return null;
}

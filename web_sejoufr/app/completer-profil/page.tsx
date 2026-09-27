"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect } from "react";
import { AuthShell } from "@/app/_components/auth/AuthShell";
import { ProfileCompletionForm } from "@/app/_components/auth/ProfileCompletionForm";
import { SIGNUP_PANEL } from "@/app/_components/auth/auth-panels";
import styles from "@/app/_components/auth/auth.module.css";
import { useAuth } from "@/lib/auth-context";
import { mustCompleteProfile, PROFILE_COMPLETION_PATH } from "@/lib/profile-completion";
import { postLoginPath } from "@/lib/security";

/**
 * **Compléter son profil** — les questions de l'inscription, posées à un
 * compte qui ne les a pas encore reçues (première connexion Google, compte
 * ancien sans démarche). Atteint par `ProfileCompletionGuard` avec la page
 * demandée en `?next=`, rendue telle quelle une fois le profil complet.
 *
 * Miroir mobile : `/target-path` (étape 1 la démarche), ouvert par le
 * `redirect` global du router.
 */
export default function CompleterProfilPage() {
  return (
    <Suspense fallback={null}>
      <CompleterProfilInner />
    </Suspense>
  );
}

function CompleterProfilInner() {
  const router = useRouter();
  const search = useSearchParams();
  const { status, user, logout } = useAuth();
  const raw = postLoginPath(search.get("next"));
  // Jamais de boucle sur l'écran lui-même.
  const nextHref = raw.startsWith(PROFILE_COMPLETION_PATH) ? "/dashboard" : raw;

  useEffect(() => {
    if (status === "guest") {
      router.replace(`/connexion?next=${encodeURIComponent(nextHref)}`);
    } else if (status === "authenticated" && user && !mustCompleteProfile(user)) {
      router.replace(nextHref);
    }
  }, [status, user, router, nextHref]);

  if (status !== "authenticated" || !user || !mustCompleteProfile(user)) return null;

  return (
    <AuthShell
      kicker="Dernière étape · votre profil"
      title={
        <>
          Complétez votre <em>profil</em>.
        </>
      }
      subtitle="Votre compte est ouvert. Il nous manque ce que demande l'inscription : votre entraînement, votre plan et le niveau de français visé en dépendent."
      panel={SIGNUP_PANEL}
    >
      <ProfileCompletionForm user={user} onCompleted={() => router.replace(nextHref)} />

      <p className={styles.switchLine}>
        Ce n&apos;est pas votre compte ?{" "}
        <button
          type="button"
          className={styles.switchButton}
          onClick={() => {
            logout();
            router.replace("/connexion");
          }}
        >
          Se déconnecter
        </button>
      </p>
    </AuthShell>
  );
}

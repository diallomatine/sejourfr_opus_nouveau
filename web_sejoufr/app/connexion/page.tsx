"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect } from "react";
import { AuthShell } from "@/app/_components/auth/AuthShell";
import { LoginForm } from "@/app/_components/auth/LoginForm";
import { SIGNIN_PANEL } from "@/app/_components/auth/auth-panels";
import styles from "@/app/_components/auth/auth.module.css";
import { useAuth } from "@/lib/auth-context";
import { postLoginPath } from "@/lib/security";

export default function ConnexionPage() {
  return (
    <Suspense fallback={null}>
      <ConnexionInner />
    </Suspense>
  );
}

function ConnexionInner() {
  const router = useRouter();
  const search = useSearchParams();
  const { status, user } = useAuth();
  const nextHref = postLoginPath(search.get("next"));
  const registerHref = `/inscription?next=${encodeURIComponent(nextHref)}`;

  useEffect(() => {
    if (status === "authenticated" && user) {
      router.replace(nextHref);
    }
  }, [status, user, router, nextHref]);

  return (
    <AuthShell
      kicker="Espace personnel"
      title={
        <>
          Heureux de vous <em>revoir</em>.
        </>
      }
      subtitle="Connectez-vous pour reprendre votre préparation là où vous l'avez laissée."
      panel={SIGNIN_PANEL}
    >
      <LoginForm autoFocus onLoggedIn={() => router.push(nextHref)} />

      <p className={styles.switchLine}>
        Nouveau sur SejourFR ?{" "}
        <Link href={registerHref} className={styles.switchLink}>
          Créer un compte gratuit
        </Link>
      </p>
    </AuthShell>
  );
}

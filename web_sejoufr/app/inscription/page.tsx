"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect } from "react";
import { AuthShell } from "@/app/_components/auth/AuthShell";
import { RegisterForm } from "@/app/_components/auth/RegisterForm";
import { SIGNUP_PANEL } from "@/app/_components/auth/auth-panels";
import styles from "@/app/_components/auth/auth.module.css";
import { track, type AnalyticsRegistrationContext } from "@/lib/analytics";
import { useAuth } from "@/lib/auth-context";
import { postLoginPath } from "@/lib/security";

export default function InscriptionPage() {
  return (
    <Suspense fallback={null}>
      <InscriptionInner />
    </Suspense>
  );
}

function InscriptionInner() {
  const router = useRouter();
  const search = useSearchParams();
  const { status, user } = useAuth();
  // Parcours d'achat depuis une landing : ?next=/paiement?plan=… ramène le
  // nouvel inscrit sur le pass qu'il venait de choisir, au lieu du dashboard.
  const nextHref = postLoginPath(search.get("next"));

  useEffect(() => {
    if (status === "authenticated" && user) {
      router.replace(nextHref);
    }
  }, [status, user, router, nextHref]);

  return (
    <AuthShell
      kicker="Compte gratuit · sans carte bancaire"
      title={
        <>
          Commencez votre <em>préparation</em>.
        </>
      }
      subtitle="Un compte pour suivre votre niveau, votre plan et vos entraînements, sur le web comme sur l'application."
      panel={SIGNUP_PANEL}
    >
      {/* D'où vient cette inscription ? La seule chose que le navigateur
          sache, ici, c'est la destination demandée (`?next=`). On n'en déduit
          rien au-delà : le repli est `OTHER`, jamais une provenance inventée. */}
      <RegisterForm
        registrationContext={registrationContextOf(nextHref)}
        onRegistered={() => router.push(nextHref)}
        onGoogleSuccess={() => router.push(nextHref)}
      />

      <p className={styles.switchLine}>
        Déjà un compte ?{" "}
        <Link
          href={`/connexion?next=${encodeURIComponent(nextHref)}`}
          className={styles.switchLink}
          onClick={() => track("LOGIN_CLICKED", {})}
        >
          Se connecter
        </Link>
      </p>
    </AuthShell>
  );
}

/**
 * Contexte d'inscription **déduit de faits**, jamais deviné : la destination
 * demandée après création du compte est la seule intention réellement connue à
 * cet instant.
 *
 * ⚠️ L'inscription faite *pendant* le diagnostic ne passe pas par ici : elle a
 * son propre écran (`DiagnosticAccountGate`, même `RegisterForm`), qui déclare
 * `DURING_DIAGNOSTIC`.
 */
function registrationContextOf(nextHref: string): AnalyticsRegistrationContext {
  if (nextHref.startsWith("/diagnostic")) return "BEFORE_DIAGNOSTIC";
  if (nextHref.startsWith("/plan")) return "AFTER_DIAGNOSTIC";
  if (nextHref.startsWith("/paiement") || nextHref.startsWith("/tarifs")) return "PRICING";
  if (nextHref.startsWith("/reussir")) return "LANDING";
  return "OTHER";
}

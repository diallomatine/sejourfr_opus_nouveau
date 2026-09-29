"use client";

import Link from "next/link";
import { useEffect, type ReactNode } from "react";
import { track, type AnalyticsCtaLocation } from "@/lib/analytics";
import { withTrafficSource } from "@/lib/traffic-source";
import { useTrafficSource } from "@/lib/use-traffic-source";

/**
 * La mesure de l'accueil, isolée pour que les sections restent des composants
 * serveur. Trois portes, trois événements du registre — jamais un quatrième :
 *  · diagnostic TCF → `DIAGNOSTIC_CTA_CLICKED` (type inconnu : on ne devine pas) ;
 *  · diagnostic civique → `CIVIQUE_CTA_CLICKED`, jamais l'événement TCF ;
 *  · compte gratuit → `SIGNUP_CTA_CLICKED`.
 * Les prix sont mesurés par la carte de pass partagée (`PassCard`).
 */
export type LandingCtaKind = "diagnostic" | "civique" | "signup";

function trackCta(kind: LandingCtaKind, ctaLocation: AnalyticsCtaLocation): void {
  if (kind === "diagnostic") {
    track("DIAGNOSTIC_CTA_CLICKED", { ctaLocation, diagnosticType: "UNKNOWN" });
  } else if (kind === "civique") {
    track("CIVIQUE_CTA_CLICKED", { ctaLocation });
  } else {
    track("SIGNUP_CTA_CLICKED", { ctaLocation });
  }
}

/** Lien mesuré qui emporte la provenance (`?src=`) jusqu'à la porte suivante. */
export function TrackedLink({
  href,
  kind,
  ctaLocation,
  className,
  children,
}: {
  href: string;
  kind: LandingCtaKind;
  ctaLocation: AnalyticsCtaLocation;
  className?: string;
  children: ReactNode;
}) {
  const source = useTrafficSource();
  return (
    <Link
      href={withTrafficSource(href, source)}
      className={className}
      onClick={() => trackCta(kind, ctaLocation)}
    >
      {children}
    </Link>
  );
}

/** `LANDING_VIEWED` une fois par montage de l'accueil. */
export function LandingViewTracker() {
  useEffect(() => {
    track("LANDING_VIEWED", { landingPath: "/" }, { once: true });
  }, []);
  return null;
}

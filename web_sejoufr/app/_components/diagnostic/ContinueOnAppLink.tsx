"use client";

import {useEffect, useState} from "react";
import {Smartphone} from "lucide-react";
import {continueOnAppHref, detectMobilePlatform} from "@/lib/app-link";
import {isDiagnosticRunUsable, readDiagnosticRun} from "@/lib/diagnostic-run-store";
import type {DiagnosticRunType} from "@/lib/types";

/**
 * « Continuer sur l'application » (lot 3b, scénario 4) — sur l'écran de compte
 * qui tient lieu de résultat pour un **invité** (TCF rapide et civique).
 *
 * Rendu seulement quand il sert à quelque chose : sur un **téléphone**, pour
 * une run créée **sans compte** dont le jeton vaut encore — et, pour le
 * civique, la run de **cette** session. Sinon rien : un lien qui ne peut rien
 * rattacher ne s'affiche pas.
 *
 * Le lien porte la run et son jeton (fragment, jamais query string ni
 * événement : `lib/app-link.ts`). Les réponses, elles, restent où elles sont :
 * [note] le dit au candidat.
 */
export function ContinueOnAppLink({
  diagnosticType,
  sessionId = null,
  note,
}: {
  diagnosticType: Extract<DiagnosticRunType, "QUICK_TCF" | "CIVIQUE">;
  /** Civique : la session affichée. `null` pour le TCF rapide invité, sans session. */
  sessionId?: string | null;
  note: string;
}) {
  const [href, setHref] = useState<string | null>(null);

  useEffect(() => {
    if (!detectMobilePlatform()) return;
    let cancelled = false;
    void readDiagnosticRun(diagnosticType)
      .then((record) => {
        if (cancelled || !record?.createdAsGuest || !isDiagnosticRunUsable(record)) return;
        if (record.sessionId !== sessionId) return;
        setHref(continueOnAppHref(record.diagnosticRunId, record.claimToken));
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [diagnosticType, sessionId]);

  if (!href) return null;

  return (
    <div className="coa">
      <a className="coa-link" href={href}>
        <Smartphone size={16} aria-hidden />
        Continuer sur l&apos;application
      </a>
      <p className="coa-note">{note}</p>
      <style>{`
        .coa {
          display: grid;
          gap: 6px;
          margin: 16px 0 0;
          text-align: center;
        }
        .coa-link {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          min-height: 44px;
          padding: 10px 16px;
          border: 1px solid var(--color-line-strong);
          border-radius: 12px;
          background: var(--color-paper);
          color: var(--color-blue);
          font-family: var(--font-sans);
          font-size: 14px;
          font-weight: 700;
          text-decoration: none;
        }
        .coa-link:hover {
          border-color: var(--color-blue);
        }
        .coa-note {
          margin: 0;
          color: var(--color-muted);
          font-size: 12px;
          line-height: 1.45;
        }
      `}</style>
    </div>
  );
}

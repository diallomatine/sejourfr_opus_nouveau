"use client";

import {useRouter} from "next/navigation";
import {useEffect, useState} from "react";
import {ApiException, attemptApi, publicAttemptApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {type AttemptSummaryResponse, canAccessModule} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {HubDetailHeader} from "@/app/_components/hub/HubParts";
import {ExamSlotsView} from "@/app/_components/hub/ExamSlotsView";
import hub from "@/app/_components/hub/hub.module.css";

const SLOTS = 20;

/**
 * Examens blancs civique GLOBAUX (40 Q tous thèmes, 45 min, seuil 32/40) —
 * grille de 20 slots, miroir de `CiviqueFullExamsScreen` mobile. Dual
 * guest/connecté : un visiteur lance la démo du slot 1, les slots 2+ invitent
 * à se connecter ; un non-abonné voit le slot 1 gratuit, 2+ → paywall.
 */
export default function CiviqueGlobalExamsPage() {
  const router = useRouter();
  const {user, status} = useAuth();
  const safeUser = status === "authenticated" ? user : null;
  const isGuest = !safeUser;
  const isPremium = canAccessModule(safeUser, "CIVIQUE");

  const [exams, setExams] = useState<AttemptSummaryResponse[]>([]);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);

  useEffect(() => {
    if (status !== "authenticated") return;
    let cancelled = false;
    attemptApi
      .listMine({type: "MOCK_EXAM", module: "CIVIQUE", limit: 50})
      .then((list) => {
        if (cancelled) return;
        setExams(
          list
            .filter((a) => a.finishedAt && !a.examTemplateId)
            .sort((a, b) => b.startedAt.localeCompare(a.startedAt)),
        );
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [status]);

  async function start() {
    if (starting) return;
    setError(null);
    setStarting(true);
    try {
      const body = {type: "MOCK_EXAM" as const, module: "CIVIQUE" as const};
      const a = isGuest ? await publicAttemptApi.startDemo(body) : await attemptApi.start(body);
      router.push(`/sessions/${a.id}`);
    } catch (e) {
      setError(e instanceof ApiException ? e.message : "Impossible de démarrer l'examen.");
      setStarting(false);
    }
  }

  if (status === "loading") return <div className={hub.loading}>Chargement…</div>;

  const body = (
    <main className={hub.hub}>
      <HubDetailHeader
        backHref="/entrainement?module=CIVIQUE"
        title="Examens blancs"
        subtitle="Civique · 40 questions tous thèmes · 45 min · seuil 32/40"
      />
      {error && <div className={hub.error}>{error}</div>}
      <ExamSlotsView
        count={SLOTS}
        exams={exams}
        premium={isPremium}
        starting={starting}
        accent="blue"
        onStart={start}
        onLocked={() => (isGuest ? router.push("/connexion") : setPaywallOpen(true))}
      />
      <PaywallSheet open={paywallOpen} onClose={() => setPaywallOpen(false)} module="CIVIQUE" />
    </main>
  );

  return safeUser ? <DualChromeShell>{body}</DualChromeShell> : body;
}

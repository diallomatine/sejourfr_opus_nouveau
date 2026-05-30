"use client";

import {useParams, useRouter} from "next/navigation";
import {useEffect, useState} from "react";
import {ApiException, attemptApi, themeApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {type AttemptSummaryResponse, canAccessModule} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {HubDetailHeader} from "@/app/_components/hub/HubParts";
import {ExamSlotsView} from "@/app/_components/hub/ExamSlotsView";
import hub from "@/app/_components/hub/hub.module.css";

const SLOTS = 10;

/**
 * Examens blancs d'un thème civique (20 Q du thème, 20 min, seuil 16/20) —
 * grille de 10 slots, miroir de `CiviqueThemeExamsScreen` mobile. Connecté
 * uniquement (le contexte thème l'est déjà côté détail).
 */
export default function CiviqueThemeExamsPage() {
  const params = useParams<{themeId: string}>();
  const themeId = params?.themeId ?? "";
  const router = useRouter();
  const {user, status} = useAuth();
  const isPremium = user ? canAccessModule(user, "CIVIQUE") : false;

  const [themeName, setThemeName] = useState("Thème civique");
  const [exams, setExams] = useState<AttemptSummaryResponse[]>([]);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);

  useEffect(() => {
    if (status !== "authenticated" || !themeId) return;
    let cancelled = false;
    Promise.allSettled([
      themeApi.list("CIVIQUE"),
      attemptApi.listMine({type: "MOCK_EXAM", module: "CIVIQUE", themeId, limit: 30}),
    ]).then(([t, e]) => {
      if (cancelled) return;
      if (t.status === "fulfilled") {
        const found = t.value.find((x) => x.id === themeId);
        if (found) setThemeName(found.name);
      }
      if (e.status === "fulfilled") {
        setExams(
          e.value
            .filter((a) => a.finishedAt)
            .sort((a, b) => b.startedAt.localeCompare(a.startedAt)),
        );
      }
    });
    return () => {
      cancelled = true;
    };
  }, [status, themeId]);

  async function start() {
    if (starting) return;
    setError(null);
    setStarting(true);
    try {
      const a = await attemptApi.start({type: "MOCK_EXAM", module: "CIVIQUE", themeId});
      router.push(`/sessions/${a.id}`);
    } catch (e) {
      setError(e instanceof ApiException ? e.message : "Impossible de démarrer l'examen.");
      setStarting(false);
    }
  }

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`/entrainement/civique/${themeId}/examens`} />;

  return (
    <DualChromeShell>
      <main className={hub.hub}>
        <HubDetailHeader
          backHref={`/entrainement/civique/${themeId}`}
          title="Examens blancs"
          subtitle={`${themeName} · 20 questions · 20 min · seuil 16/20`}
        />
        {error && <div className={hub.error}>{error}</div>}
        <ExamSlotsView
          count={SLOTS}
          exams={exams}
          premium={isPremium}
          starting={starting}
          accent="blue"
          onStart={start}
          onLocked={() => setPaywallOpen(true)}
        />
        <PaywallSheet open={paywallOpen} onClose={() => setPaywallOpen(false)} module="CIVIQUE" />
      </main>
    </DualChromeShell>
  );
}

"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { CheckCircle2, Flame, LayoutGrid, Target, Trophy } from "lucide-react";
import { ApiException, attemptApi, themeApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { type AttemptSummaryResponse, canAccessModule } from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { ModuleDetailGate, moduleDetailStyles as ds } from "@/app/_components/module_detail/parts";
import { DetailShell, DetailStatCard, ExamsGrid } from "@/app/_components/hub/DetailParts";
import detail from "@/app/_components/hub/detail.module.css";

const SLOTS = 20;

/**
 * Examens blancs d'un thème civique (20 Q du thème, 20 min, seuil 16/20) —
 * maquette sejour_fr.html : 3 stat cards (passés / meilleur score / restant)
 * + grille de 20 examens. Examen 1 gratuit, 2+ premium.
 */
export default function CiviqueThemeExamsPage() {
  const params = useParams<{ themeId: string }>();
  const themeId = params?.themeId ?? "";
  const router = useRouter();
  const { user, status } = useAuth();
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
      attemptApi.listMine({ type: "MOCK_EXAM", module: "CIVIQUE", themeId, limit: 30 }),
    ]).then(([t, e]) => {
      if (cancelled) return;
      if (t.status === "fulfilled") {
        const found = t.value.find((x) => x.id === themeId);
        if (found) setThemeName(found.name);
      }
      if (e.status === "fulfilled") {
        // Ordre chronologique : le 1er examen passé occupe la card 01.
        setExams(
          e.value
            .filter((a) => a.finishedAt)
            .sort((a, b) => a.startedAt.localeCompare(b.startedAt)),
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
      const a = await attemptApi.start({ type: "MOCK_EXAM", module: "CIVIQUE", themeId });
      router.push(`/sessions/${a.id}`);
    } catch (e) {
      setError(e instanceof ApiException ? e.message : "Impossible de démarrer l'examen.");
      setStarting(false);
    }
  }

  const done = Math.min(exams.length, SLOTS);
  const best = useMemo(
    () => exams.reduce((max, e) => Math.max(max, e.score ?? 0), 0),
    [exams],
  );

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`/entrainement/civique/${themeId}/examens`} />;

  return (
    <DualChromeShell>
      <DetailShell
        backHref="/entrainement?module=CIVIQUE"
        backLabel="Examen civique"
        eyebrowIcon={<Target size={18} strokeWidth={2} />}
        eyebrow={themeName}
        title="Examens blancs"
        subtitle={`${SLOTS} examens blancs de 20 questions, dans les conditions de l'épreuve. Choisissez-en un et retrouvez votre dernier score.`}
        action={
          <Link href={`/entrainement/civique/${themeId}`} className={detail.headBtn}>
            <LayoutGrid size={17} strokeWidth={1.7} aria-hidden />
            Mode entraînement
          </Link>
        }
      >
        <div className={detail.statCards}>
          <DetailStatCard
            icon={<Trophy size={20} />}
            tone="blue"
            value={`${done}/${SLOTS}`}
            label="Examens passés"
            sub="dans cette catégorie"
          />
          <DetailStatCard
            icon={<Flame size={20} />}
            tone="red"
            value={done > 0 ? `${best}/20` : "—"}
            label="Meilleur score"
            sub={done > 0 && best >= 16 ? "Au-dessus du seuil (16/20)" : "seuil : 16/20"}
          />
          <DetailStatCard
            icon={<CheckCircle2 size={20} />}
            tone="green"
            value={String(SLOTS - done)}
            label="Restant"
            sub="examens à tenter"
          />
        </div>

        {error && <div className={detail.error}>{error}</div>}

        <ExamsGrid
          count={SLOTS}
          exams={exams}
          premium={isPremium}
          starting={starting}
          onStart={start}
          onLocked={() => setPaywallOpen(true)}
        />
        <PaywallSheet open={paywallOpen} onClose={() => setPaywallOpen(false)} module="CIVIQUE" />
      </DetailShell>
    </DualChromeShell>
  );
}

"use client";

import { Suspense, useEffect, useRef, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { ModuleDetailGate } from "@/app/_components/module_detail/parts";
import { ApiException, fullTcfExamApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  canAccessModule,
  type FullTcfExamSummaryResponse,
} from "@/lib/types";
import { TcfFullExamBriefingSheet } from "./TcfFullExamBriefingSheet";
import {
  fullExamStartedHref,
  TcfFullExamSlots,
  type FullExamSlotData,
} from "./TcfFullExamSlots";
import s from "./tcfFullExam.module.css";

export default function TcfFullExamListPage() {
  return (
    <DualChromeShell>
      <Suspense fallback={<div className={s.loading}>Chargement…</div>}>
        <TcfFullExamListInner />
      </Suspense>
    </DualChromeShell>
  );
}

function TcfFullExamListInner() {
  const { user, status } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  const [exams, setExams] = useState<FullTcfExamSummaryResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [briefingSlot, setBriefingSlot] = useState<number | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);
  const autoOpenDone = useRef(false);

  const premium = user != null && canAccessModule(user, "TCF");

  useEffect(() => {
    if (status !== "authenticated") return;
    fullTcfExamApi
      .listMine(20)
      .then(setExams)
      .catch((e) =>
        setError(e instanceof ApiException ? e.message : "Impossible de charger vos examens."),
      )
      .finally(() => setLoading(false));
  }, [status]);

  // Auto-ouvre le briefing pour le slot demandé (venant de /examens-blancs).
  useEffect(() => {
    if (loading || autoOpenDone.current) return;
    const raw = searchParams.get("startSlot");
    if (!raw) return;
    const num = parseInt(raw, 10);
    if (isNaN(num) || num < 1 || num > 20) return;
    autoOpenDone.current = true;
    const existing = exams.find((e) => e.slotNumber === num);
    const startedHref = existing ? fullExamStartedHref(existing) : null;
    if (startedHref) {
      router.replace(startedHref);
    } else if (!premium) {
      setPaywallOpen(true);
    } else {
      setBriefingSlot(num);
    }
  }, [loading, exams, searchParams, premium, router]);

  if (status === "loading") return <div className={s.loading}>Chargement…</div>;
  if (!user) return <ModuleDetailGate next="/tcf/examen-blanc" />;

  function handleSlotClick(slot: FullExamSlotData) {
    const startedHref = slot.exam ? fullExamStartedHref(slot.exam) : null;
    if (startedHref) {
      router.push(startedHref);
      return;
    }
    setBriefingSlot(slot.number);
  }

  return (
    <div className={s.page}>
      <div className={s.listEyebrow}>TCF IRN</div>
      <h1 className={s.listTitle}>Examens blancs complets</h1>
      <p className={s.listSub}>
        4 épreuves enchaînées (CO · CE · EE · EO) — 90 min en conditions réelles.
      </p>

      {error && <div className={s.error}>{error}</div>}

      {loading ? (
        <div className={s.loading}>Chargement de vos examens…</div>
      ) : (
        <TcfFullExamSlots
          exams={exams}
          premium={premium}
          onSlotClick={handleSlotClick}
          onLocked={() => setPaywallOpen(true)}
        />
      )}

      <Link href="/examens-blancs" className="btn btn-ghost">
        Tous les examens blancs
      </Link>

      {briefingSlot !== null && (
        <TcfFullExamBriefingSheet
          slotNumber={briefingSlot}
          onClose={() => setBriefingSlot(null)}
          onNeedsPremium={() => {
            setBriefingSlot(null);
            setPaywallOpen(true);
          }}
        />
      )}

      <PaywallSheet
        open={paywallOpen}
        onClose={() => setPaywallOpen(false)}
        module="INTEGRAL"
        title="Débloquez l'examen blanc TCF complet"
        message="L'examen blanc TCF complet (CO · CE · EE · EO) est réservé aux abonnés Intégral."
      />
    </div>
  );
}

"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { ApiException, attemptApi, lotApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { canAccessModule, type Difficulty, type QuestionType } from "@/lib/types";
import type { LotDto } from "@/lib/types";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import {
  LotsGrid,
  ModuleDetailGate,
  ModuleDetailShell,
  ModuleHero,
  SkeletonGrid,
  moduleDetailStyles as s,
} from "@/app/_components/module_detail/parts";

const TCF_QCM = {
  co: { questionType: "CO" as QuestionType, title: "Compréhension orale" },
  ce: { questionType: "CE" as QuestionType, title: "Compréhension écrite" },
  structure: { questionType: "STRUCTURE" as QuestionType, title: "Structure de la langue" },
} as const;
type TcfCode = keyof typeof TCF_QCM;

const LEVELS = {
  a2: { difficulty: "A2" as Difficulty, label: "Niveau débutant" },
  b1: { difficulty: "B1" as Difficulty, label: "Niveau intermédiaire" },
  b2: { difficulty: "B2" as Difficulty, label: "Niveau avancé" },
} as const;
type LevelKey = keyof typeof LEVELS;

export default function TcfLevelLotsPage() {
  const params = useParams<{ code: string; level: string }>();
  const code = (params?.code ?? "").toLowerCase() as TcfCode;
  const levelKey = (params?.level ?? "").toLowerCase() as LevelKey;
  const config = TCF_QCM[code];
  const level = LEVELS[levelKey];
  const router = useRouter();
  const { user, status } = useAuth();

  const [lots, setLots] = useState<LotDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);

  const isPremium = user ? canAccessModule(user, "TCF") : false;
  const valid = Boolean(config && level);

  useEffect(() => {
    if (status !== "authenticated" || !valid) return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    lotApi
      .listTcf(config.questionType, level.difficulty)
      .then((l) => {
        if (!cancelled) setLots(l);
      })
      .catch((e) => {
        if (!cancelled)
          setError(e instanceof ApiException ? e.message : "Impossible de charger les lots.");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [status, valid, config, level]);

  async function startLot(lot: LotDto) {
    if (starting) return;
    if (!isPremium) {
      setPaywallOpen(true);
      return;
    }
    setError(null);
    setStarting(true);
    try {
      const a = await attemptApi.start({
        type: "TRAINING",
        module: "TCF",
        questionType: config.questionType,
        difficulty: level.difficulty,
        lotNumero: lot.numero,
      });
      router.push(`/sessions/${a.id}?lot=${lot.numero}`);
    } catch (e) {
      setError(e instanceof ApiException ? e.message : "Impossible de démarrer le lot.");
      setStarting(false);
    }
  }

  if (status === "loading") return <div className={s.gate} />;
  if (!user) return <ModuleDetailGate next={`/entrainement/tcf/${code}/${levelKey}`} />;
  if (!valid) {
    return (
      <ModuleDetailShell accent="red">
        <p className={s.empty}>Épreuve ou niveau TCF inconnu.</p>
        <Link href="/entrainement?module=TCF" className={s.errCta}>
          ← Retour à l&apos;entraînement TCF
        </Link>
      </ModuleDetailShell>
    );
  }

  return (
    <ModuleDetailShell accent="red">
      <div className={s.breadcrumb}>
        <Link href="/entrainement?module=TCF">Entraînement</Link>
        <span className="sep">/</span>{" "}
        <Link href={`/entrainement/tcf/${code}`}>{config.title}</Link>{" "}
        <span className="sep">/</span> <strong>{levelKey.toUpperCase()}</strong>
      </div>

      <ModuleHero
        eyebrow={`TCF · ${config.title}`}
        title={`${level.label} (${levelKey.toUpperCase()})`}
        description="Touche un lot pour t'entraîner — ton dernier score reste affiché."
      />

      {error && <div className={`form-error ${s.error}`}>{error}</div>}

      {loading ? (
        <SkeletonGrid />
      ) : lots.length === 0 ? (
        <p className={s.empty}>
          Aucun lot disponible à ce niveau pour l&apos;instant — le pool est en cours de
          constitution.
        </p>
      ) : (
        <LotsGrid lots={lots} starting={starting} onStart={startLot} />
      )}

      <PaywallSheet
        open={paywallOpen}
        onClose={() => setPaywallOpen(false)}
        module="INTEGRAL"
      />
    </ModuleDetailShell>
  );
}

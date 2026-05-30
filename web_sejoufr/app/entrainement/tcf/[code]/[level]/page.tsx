"use client";

import Link from "next/link";
import {useParams, useRouter} from "next/navigation";
import {useEffect, useMemo, useState} from "react";
import {ApiException, attemptApi, lotApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {canAccessModule, type Difficulty, type LotDto, type QuestionType} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {
  HubDetailHeader,
  type HubTone,
  LotRow,
  SectionCounter,
  SectionLabel,
} from "@/app/_components/hub/HubParts";
import hub from "@/app/_components/hub/hub.module.css";

const TCF_QCM = {
  co: {questionType: "CO" as QuestionType, title: "Compréhension orale"},
  ce: {questionType: "CE" as QuestionType, title: "Compréhension écrite"},
  structure: {questionType: "STRUCTURE" as QuestionType, title: "Structure de la langue"},
} as const;
type TcfCode = keyof typeof TCF_QCM;

const LEVELS = {
  a2: {difficulty: "A2" as Difficulty, label: "Niveau débutant", tone: "green" as HubTone},
  b1: {difficulty: "B1" as Difficulty, label: "Niveau intermédiaire", tone: "amber" as HubTone},
  b2: {difficulty: "B2" as Difficulty, label: "Niveau avancé", tone: "red" as HubTone},
} as const;
type LevelKey = keyof typeof LEVELS;

/**
 * Lots d'un (épreuve TCF QCM, niveau) — single-scroll calqué sur
 * `TcfLevelLotsScreen` mobile : header + liste de lots (lot 1 gratuit, 2+
 * premium). Tap lot → runner mode batch fixe → bilan donut (TcfLotResult).
 */
export default function TcfLevelLotsPage() {
  const params = useParams<{code: string; level: string}>();
  const code = (params?.code ?? "").toLowerCase() as TcfCode;
  const levelKey = (params?.level ?? "").toLowerCase() as LevelKey;
  const config = TCF_QCM[code];
  const level = LEVELS[levelKey];
  const router = useRouter();
  const {user, status} = useAuth();

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
    // Lot 1 gratuit par (épreuve, niveau) ; lots 2+ réservés aux abonnés.
    if (!isPremium && lot.numero > 1) {
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
      router.push(
        `/sessions/${a.id}?lot=${lot.numero}&result=tcfLot&code=${code}&level=${levelKey}`,
      );
    } catch (e) {
      setError(e instanceof ApiException ? e.message : "Impossible de démarrer le lot.");
      setStarting(false);
    }
  }

  const tone = level?.tone ?? "blue";
  const subtitle = useMemo(
    () => (config && level ? `${config.title} · ${level.label}` : ""),
    [config, level],
  );

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`/entrainement/tcf/${code}/${levelKey}`} />;
  if (!valid) {
    return (
      <DualChromeShell>
        <main className={hub.hub}>
          <p className={hub.empty}>Épreuve ou niveau TCF inconnu.</p>
          <Link href="/entrainement?module=TCF" className={hub.sectionLink}>
            ← Retour à l&apos;entraînement TCF
          </Link>
        </main>
      </DualChromeShell>
    );
  }

  return (
    <DualChromeShell>
      <main className={hub.hub}>
        <HubDetailHeader
          backHref={`/entrainement/tcf/${code}`}
          title={`Niveau ${levelKey.toUpperCase()}`}
          subtitle={subtitle}
        />
        {error && <div className={hub.error}>{error}</div>}
        {loading ? (
          <div className={hub.loading}>Chargement des lots…</div>
        ) : lots.length === 0 ? (
          <p className={hub.empty}>
            Aucun lot disponible à ce niveau pour l&apos;instant — le pool est en cours de
            constitution.
          </p>
        ) : (
          <>
            <SectionLabel
              label="Lots disponibles"
              trailing={<SectionCounter text={`${lots.length} lots`} />}
            />
            <div className={hub.list}>
              {lots.map((lot) => (
                <LotRow
                  key={lot.numero}
                  lot={lot}
                  tone={tone}
                  locked={!isPremium && lot.numero > 1}
                  disabled={starting}
                  onClick={() => startLot(lot)}
                />
              ))}
            </div>
          </>
        )}
        <PaywallSheet open={paywallOpen} onClose={() => setPaywallOpen(false)} module="INTEGRAL" />
      </main>
    </DualChromeShell>
  );
}

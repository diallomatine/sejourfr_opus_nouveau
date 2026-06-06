"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { BookOpen, Headphones, SpellCheck, Target } from "lucide-react";
import { ApiException, attemptApi, lotApi, publicAttemptApi, publicLotApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { canAccessModule, type Difficulty, type LotDto, type QuestionType } from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { GuestGateSheet } from "@/app/_components/GuestGateSheet";
import { moduleDetailStyles as ds } from "@/app/_components/module_detail/parts";
import { DetailShell, SerieCard, SeriesProgressCard } from "@/app/_components/hub/DetailParts";
import { ExamDoneSheet } from "@/app/_components/hub/ExamDoneSheet";
import detail from "@/app/_components/hub/detail.module.css";

const TCF_QCM = {
  co: {
    questionType: "CO" as QuestionType,
    title: "Compréhension orale",
    icon: <Headphones size={18} strokeWidth={2} />,
  },
  ce: {
    questionType: "CE" as QuestionType,
    title: "Compréhension écrite",
    icon: <BookOpen size={18} strokeWidth={2} />,
  },
  structure: {
    questionType: "STRUCTURE" as QuestionType,
    title: "Structure de la langue",
    icon: <SpellCheck size={18} strokeWidth={2} />,
  },
} as const;
type TcfCode = keyof typeof TCF_QCM;

const LEVELS = {
  a2: { difficulty: "A2" as Difficulty },
  b1: { difficulty: "B1" as Difficulty },
  b2: { difficulty: "B2" as Difficulty },
} as const;
type LevelKey = keyof typeof LEVELS;

/**
 * Séries d'entraînement d'un (épreuve TCF QCM, niveau) — maquette
 * sejour_fr.html : carte de progression + grille de cards Série (série 1
 * gratuite, 2+ premium). Une série = 20 questions, correction immédiate.
 * Série faite → feuille « Voir le bilan / Refaire ».
 *
 * Mode guest : la page est navigable sans compte. La série 1 se joue en
 * anonyme (publicAttemptApi, attempt user NULL côté backend) ; les séries 2+
 * ouvrent la GuestGateSheet (inscription gratuite).
 */
export default function TcfLevelSeriesPage() {
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
  const [guestGateOpen, setGuestGateOpen] = useState(false);
  const [selectedLot, setSelectedLot] = useState<LotDto | null>(null);

  const isGuest = status === "guest";
  const isPremium = user ? canAccessModule(user, "TCF") : false;
  const valid = Boolean(config && level);

  useEffect(() => {
    if (status === "loading" || !valid) return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    const fetchLots =
      status === "authenticated"
        ? lotApi.listTcf(config.questionType, level.difficulty)
        : publicLotApi.listTcf(config.questionType, level.difficulty);
    fetchLots
      .then((l) => {
        if (!cancelled) setLots(l);
      })
      .catch((e) => {
        if (!cancelled)
          setError(e instanceof ApiException ? e.message : "Impossible de charger les séries.");
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
    // Série 1 gratuite par (épreuve, niveau) ; séries 2+ réservées aux
    // abonnés (connecté) ou aux comptes (guest).
    if (lot.numero > 1) {
      if (isGuest) {
        setGuestGateOpen(true);
        return;
      }
      if (!isPremium) {
        setPaywallOpen(true);
        return;
      }
    }
    setError(null);
    setStarting(true);
    try {
      const body = {
        type: "TRAINING" as const,
        module: "TCF" as const,
        questionType: config.questionType,
        difficulty: level.difficulty,
        lotNumero: lot.numero,
      };
      const a = isGuest
        ? await publicAttemptApi.startDemo(body)
        : await attemptApi.start(body);
      router.push(
        `/sessions/${a.id}?lot=${lot.numero}&result=tcfLot&code=${code}&level=${levelKey}`,
      );
    } catch (e) {
      setError(e instanceof ApiException ? e.message : "Impossible de démarrer la série.");
      setStarting(false);
    }
  }

  const doneCount = useMemo(() => lots.filter((l) => l.lastScore != null).length, [lots]);

  if (status === "loading") return <div className={ds.gate} />;
  if (!valid) {
    return (
      <DualChromeShell>
        <main className={detail.wrap}>
          <p className={detail.empty}>Épreuve ou niveau TCF inconnu.</p>
          <Link href="/entrainement?module=TCF" className={detail.back}>
            ← Retour à l&apos;entraînement TCF
          </Link>
        </main>
      </DualChromeShell>
    );
  }

  return (
    <DualChromeShell>
      <DetailShell
        backHref={`/entrainement/tcf/${code}`}
        backLabel={`${config.title} · niveaux`}
        eyebrowIcon={config.icon}
        eyebrow={`${config.title} · Niveau ${levelKey.toUpperCase()}`}
        title="Séries d'entraînement"
        subtitle="Chaque série contient jusqu'à 20 questions avec correction immédiate. Reprenez là où vous vous êtes arrêté."
        action={
          <Link href={`/entrainement/tcf/${code}/examens`} className={detail.headBtn}>
            <Target size={17} strokeWidth={1.7} aria-hidden />
            Examens blancs
          </Link>
        }
      >
        {error && <div className={detail.error}>{error}</div>}
        {loading ? (
          <div className={detail.loading}>Chargement des séries…</div>
        ) : lots.length === 0 ? (
          <p className={detail.empty}>
            Aucune série disponible à ce niveau pour l&apos;instant — le pool est en cours de
            constitution.
          </p>
        ) : (
          <>
            <SeriesProgressCard done={doneCount} total={lots.length} />
            <div className={detail.serieGrid}>
              {lots.map((lot) => (
                <SerieCard
                  key={lot.numero}
                  lot={lot}
                  locked={(isGuest || !isPremium) && lot.numero > 1}
                  lockedLabel={isGuest ? "Compte gratuit" : "Premium"}
                  disabled={starting}
                  onClick={() =>
                    lot.lastScore != null ? setSelectedLot(lot) : startLot(lot)
                  }
                />
              ))}
            </div>
          </>
        )}
        <ExamDoneSheet
          open={selectedLot !== null}
          title={selectedLot ? `Série ${selectedLot.numero}` : "Série"}
          subtitle={
            selectedLot && selectedLot.lastScore != null
              ? `Dernier score : ${selectedLot.lastScore} / ${selectedLot.totalQuestions}`
              : null
          }
          onViewDetail={() => {
            const lot = selectedLot;
            setSelectedLot(null);
            if (lot?.lastAttemptId) {
              router.push(
                `/sessions/${lot.lastAttemptId}?lot=${lot.numero}&result=tcfLot&code=${code}&level=${levelKey}`,
              );
            }
          }}
          onResume={() => {
            const lot = selectedLot;
            setSelectedLot(null);
            if (lot) void startLot(lot);
          }}
          onClose={() => setSelectedLot(null)}
        />
        <PaywallSheet open={paywallOpen} onClose={() => setPaywallOpen(false)} module="INTEGRAL" />
        <GuestGateSheet
          open={guestGateOpen}
          onClose={() => setGuestGateOpen(false)}
          message="La série 1 est offerte pour découvrir l'épreuve. Créez un compte gratuit pour continuer les séries et suivre votre progression."
        />
      </DetailShell>
    </DualChromeShell>
  );
}

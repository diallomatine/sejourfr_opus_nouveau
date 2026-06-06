"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { Lightbulb, Target } from "lucide-react";
import { ApiException, attemptApi, lotApi, themeApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { canAccessModule, type LotDto } from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { ModuleDetailGate, moduleDetailStyles as ds } from "@/app/_components/module_detail/parts";
import { DetailShell, SerieCard, SeriesProgressCard } from "@/app/_components/hub/DetailParts";
import { ExamDoneSheet } from "@/app/_components/hub/ExamDoneSheet";
import detail from "@/app/_components/hub/detail.module.css";

/**
 * Séries d'entraînement d'un thème civique — maquette sejour_fr.html :
 * carte de progression + grille de cards Série (série 1 gratuite, 2+
 * premium). Une série = 20 questions, correction immédiate. Les examens
 * blancs du thème vivent sur la page dédiée (bouton en header).
 */
export default function CiviqueThemeSeriesPage() {
  const params = useParams<{ themeId: string }>();
  const themeId = params?.themeId ?? "";
  const router = useRouter();
  const { user, status } = useAuth();

  const [themeName, setThemeName] = useState("Thème civique");
  const [lots, setLots] = useState<LotDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);
  const [selectedLot, setSelectedLot] = useState<LotDto | null>(null);

  const isPremium = user ? canAccessModule(user, "CIVIQUE") : false;

  useEffect(() => {
    if (status !== "authenticated" || !themeId) return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    Promise.allSettled([themeApi.list("CIVIQUE"), lotApi.listCivique(themeId)]).then(
      ([t, l]) => {
        if (cancelled) return;
        if (t.status === "fulfilled") {
          const found = t.value.find((x) => x.id === themeId);
          if (found) setThemeName(found.name);
        }
        if (l.status === "fulfilled") setLots(l.value);
        setLoading(false);
      },
    );
    return () => {
      cancelled = true;
    };
  }, [status, themeId]);

  async function startLot(lot: LotDto) {
    if (starting) return;
    // Série 1 = découverte gratuite ; séries 2+ réservées aux abonnés.
    if (!isPremium && lot.numero > 1) {
      setPaywallOpen(true);
      return;
    }
    setError(null);
    setStarting(true);
    try {
      const a = await attemptApi.start({
        type: "TRAINING",
        module: "CIVIQUE",
        themeId,
        lotNumero: lot.numero,
      });
      router.push(`/sessions/${a.id}?lot=${lot.numero}`);
    } catch (e) {
      setError(e instanceof ApiException ? e.message : "Impossible de démarrer la série.");
      setStarting(false);
    }
  }

  const doneCount = useMemo(() => lots.filter((l) => l.lastScore != null).length, [lots]);

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`/entrainement/civique/${themeId}`} />;

  return (
    <DualChromeShell>
      <DetailShell
        backHref="/entrainement?module=CIVIQUE"
        backLabel="Examen civique"
        eyebrowIcon={<Lightbulb size={18} strokeWidth={2} />}
        eyebrow={themeName}
        title="Séries d'entraînement"
        subtitle="Chaque série contient jusqu'à 20 questions avec correction immédiate. Reprenez là où vous vous êtes arrêté."
        action={
          <Link href={`/entrainement/civique/${themeId}/examens`} className={detail.headBtn}>
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
            Aucune série disponible pour ce thème pour l&apos;instant.
          </p>
        ) : (
          <>
            <SeriesProgressCard done={doneCount} total={lots.length} />
            <div className={detail.serieGrid}>
              {lots.map((lot) => (
                <SerieCard
                  key={lot.numero}
                  lot={lot}
                  locked={!isPremium && lot.numero > 1}
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
            const id = selectedLot?.lastAttemptId;
            setSelectedLot(null);
            if (id) router.push(`/sessions/${id}`);
          }}
          onResume={() => {
            const lot = selectedLot;
            setSelectedLot(null);
            if (lot) void startLot(lot);
          }}
          onClose={() => setSelectedLot(null)}
        />
        <PaywallSheet open={paywallOpen} onClose={() => setPaywallOpen(false)} module="CIVIQUE" />
      </DetailShell>
    </DualChromeShell>
  );
}

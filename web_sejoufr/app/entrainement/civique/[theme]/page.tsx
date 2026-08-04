"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { Lightbulb, Target } from "lucide-react";
import {
  attemptApi,
  lotApi,
  publicAttemptApi,
  publicLotApi,
  publicThemeApi,
  themeApi,
} from "@/lib/api";
import { handleStartFailure } from "@/lib/start-failure";
import { useAuth } from "@/lib/auth-context";
import { themeSlug, resolveThemeRef } from "@/lib/themes";
import {
  canAccessModule,
  type LotDto,
  type ThemeUserResponse,
} from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { GuestGateSheet } from "@/app/_components/GuestGateSheet";
import { moduleDetailStyles as ds } from "@/app/_components/module_detail/parts";
import { DetailShell, SerieCard, SeriesProgressCard } from "@/app/_components/hub/DetailParts";
import { ExamDoneSheet } from "@/app/_components/hub/ExamDoneSheet";
import detail from "@/app/_components/hub/detail.module.css";

/**
 * Séries d'entraînement d'un thème civique — maquette sejour_fr.html :
 * carte de progression + grille de cards Série (série 1 gratuite, 2+
 * premium). Une série = 20 questions, correction immédiate. Les examens
 * blancs du thème vivent sur la page dédiée (bouton en header).
 *
 * Mode guest : page navigable sans compte — série 1 jouable en anonyme
 * (publicAttemptApi), séries 2+ → GuestGateSheet.
 *
 * Le segment d'URL est le slug du thème (cf. lib/themes.ts) ; l'UUID
 * hérité reste résolu (retours de session, anciens liens).
 */
export default function CiviqueThemeSeriesPage() {
  const params = useParams<{ theme: string }>();
  const themeRef = params?.theme ?? "";
  const router = useRouter();
  const { user, status } = useAuth();

  const [theme, setTheme] = useState<ThemeUserResponse | null>(null);
  const [notFound, setNotFound] = useState(false);
  const [lots, setLots] = useState<LotDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);
  const [guestGateOpen, setGuestGateOpen] = useState(false);
  const [selectedLot, setSelectedLot] = useState<LotDto | null>(null);

  const isGuest = status === "guest";
  const isPremium = user ? canAccessModule(user, "CIVIQUE") : false;

  useEffect(() => {
    if (status === "loading" || !themeRef) return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    const auth = status === "authenticated";
    (async () => {
      try {
        const themes = await (auth
          ? themeApi.list("CIVIQUE")
          : publicThemeApi.list("CIVIQUE"));
        const found = resolveThemeRef(themes, themeRef);
        if (cancelled) return;
        if (!found) {
          setNotFound(true);
          setLoading(false);
          return;
        }
        setTheme(found);
        const l = await (auth
          ? lotApi.listCivique(found.id)
          : publicLotApi.listCivique(found.id));
        if (!cancelled) setLots(l);
      } catch {
        /* la grille restera vide, message "aucune série" */
      }
      if (!cancelled) setLoading(false);
    })();
    return () => {
      cancelled = true;
    };
  }, [status, themeRef]);

  async function startLot(lot: LotDto) {
    if (starting || !theme) return;
    // Série 1 = découverte gratuite ; séries 2+ réservées aux abonnés
    // (connecté) ou aux comptes (guest).
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
        module: "CIVIQUE" as const,
        themeId: theme.id,
        lotNumero: lot.numero,
      };
      const a = isGuest
        ? await publicAttemptApi.startDemo(body)
        : await attemptApi.start(body);
      router.push(`/sessions/${a.id}?lot=${lot.numero}`);
    } catch (e) {
      handleStartFailure(e, {
        onPaywall: () => (isGuest ? setGuestGateOpen(true) : setPaywallOpen(true)),
        onMessage: setError,
        fallbackMessage: "Impossible de démarrer la série.",
      });
      setStarting(false);
    }
  }

  const doneCount = useMemo(() => lots.filter((l) => l.lastScore != null).length, [lots]);
  const slug = theme ? themeSlug(theme.code) : themeRef;

  if (status === "loading") return <div className={ds.gate} />;

  if (notFound) {
    return (
      <DualChromeShell>
        <main className={detail.wrap}>
          <p className={detail.empty}>Thème civique introuvable.</p>
          <Link href="/entrainement?module=CIVIQUE" className={detail.back}>
            ← Retour à l&apos;entraînement civique
          </Link>
        </main>
      </DualChromeShell>
    );
  }

  return (
    <DualChromeShell>
      <DetailShell
        backHref="/entrainement?module=CIVIQUE"
        backLabel="Examen civique"
        eyebrowIcon={<Lightbulb size={18} strokeWidth={2} />}
        eyebrow={theme?.name ?? "Thème civique"}
        title="Séries d'entraînement"
        subtitle="Chaque série contient jusqu'à 20 questions avec correction immédiate. Reprenez là où vous vous êtes arrêté."
        action={
          <Link href={`/entrainement/civique/${slug}/examens`} className={detail.headBtn}>
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
              router.push(`/sessions/${lot.lastAttemptId}?lot=${lot.numero}`);
            }
          }}
          onResume={() => {
            const lot = selectedLot;
            setSelectedLot(null);
            if (lot) void startLot(lot);
          }}
          onClose={() => setSelectedLot(null)}
        />
        <PaywallSheet open={paywallOpen} onClose={() => setPaywallOpen(false)} module="CIVIQUE" />
        <GuestGateSheet
          open={guestGateOpen}
          onClose={() => setGuestGateOpen(false)}
          message="La série 1 est offerte pour découvrir ce thème. Créez un compte gratuit pour continuer les séries et suivre votre progression."
        />
      </DetailShell>
    </DualChromeShell>
  );
}

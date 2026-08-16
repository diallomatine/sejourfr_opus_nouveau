"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { CheckCircle2, Flame, LayoutGrid, Target, Trophy } from "lucide-react";
import { attemptApi, publicThemeApi, themeApi } from "@/lib/api";
import { handleStartFailure } from "@/lib/start-failure";
import { useAuth } from "@/lib/auth-context";
import { themeSlug, resolveThemeRef } from "@/lib/themes";
import {
  type AttemptSummaryResponse,
  canAccessModule,
  type ThemeUserResponse,
} from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { GuestGateSheet } from "@/app/_components/GuestGateSheet";
import { moduleDetailStyles as ds } from "@/app/_components/module_detail/parts";
import { DetailShell, DetailStatCard, ExamsGrid } from "@/app/_components/hub/DetailParts";
import { ExamIntroSheet } from "@/app/_components/hub/ExamIntroSheet";
import { examSlotGrid } from "@/lib/exam-slots";
import detail from "@/app/_components/hub/detail.module.css";

const SLOTS = 20;

/**
 * Examens blancs d'un thème civique (20 Q du thème, 20 min, seuil 16/20) —
 * maquette sejour_fr.html : 3 stat cards (passés / meilleur score / restant)
 * + grille de 20 examens. Examen 1 gratuit, 2+ premium.
 *
 * Mode guest : la page sert de vitrine (grille visible) mais tous les
 * examens ciblés exigent un compte → GuestGateSheet. La découverte guest
 * passe par les séries 1 et l'examen diagnostic de /examens-blancs.
 * Segment d'URL = slug du thème (UUID hérité toujours résolu).
 */
export default function CiviqueThemeExamsPage() {
  const params = useParams<{ theme: string }>();
  const themeRef = params?.theme ?? "";
  const router = useRouter();
  const { user, status } = useAuth();
  const isGuest = status === "guest";
  const isPremium = user ? canAccessModule(user, "CIVIQUE") : false;

  const [theme, setTheme] = useState<ThemeUserResponse | null>(null);
  const [notFound, setNotFound] = useState(false);
  const [exams, setExams] = useState<AttemptSummaryResponse[]>([]);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);
  const [guestGateOpen, setGuestGateOpen] = useState(false);
  const [introOpen, setIntroOpen] = useState(false);
  const [pendingSlot, setPendingSlot] = useState(1);

  useEffect(() => {
    if (status === "loading" || !themeRef) return;
    let cancelled = false;
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
          return;
        }
        setTheme(found);
        if (!auth) return; // guests : pas d'historique
        const list = await attemptApi.listMine({
          type: "MOCK_EXAM",
          module: "CIVIQUE",
          themeId: found.id,
          limit: 30,
        });
        if (cancelled) return;
        setExams(list.filter((a) => a.finishedAt));
      } catch {
        /* best-effort : la grille reste vide */
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [status, themeRef]);

  // Grille indexée par slot : refaire l'examen N met à jour la case N.
  const { bySlot, latest, doneCount } = useMemo(() => examSlotGrid(exams, SLOTS), [exams]);

  function requestStart(slot: number) {
    if (starting) return;
    // La porte visiteur passe avant le thème : elle n'a besoin d'aucune donnée
    // chargée, et un thème resté null (serveur muet) ne doit pas transformer un
    // slot verrouillé en bouton mort.
    if (isGuest) {
      setGuestGateOpen(true);
      return;
    }
    if (!theme) return;
    setError(null);
    setPendingSlot(slot);
    setIntroOpen(true);
  }

  async function launch() {
    if (starting || !theme) return;
    setError(null);
    setStarting(true);
    try {
      const a = await attemptApi.start({
        type: "MOCK_EXAM",
        module: "CIVIQUE",
        themeId: theme.id,
        slotNumber: pendingSlot,
      });
      router.push(`/sessions/${a.id}`);
    } catch (e) {
      handleStartFailure(e, {
        onPaywall: () => {
          setIntroOpen(false);
          setPaywallOpen(true);
        },
        onMessage: setError,
        fallbackMessage: "Impossible de démarrer l'examen.",
      });
      setStarting(false);
    }
  }

  const done = Math.min(doneCount, SLOTS);
  const best = useMemo(
    () => latest.reduce((max, e) => Math.max(max, e.score ?? 0), 0),
    [latest],
  );
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
        eyebrowIcon={<Target size={18} strokeWidth={2} />}
        eyebrow={theme?.name ?? "Thème civique"}
        title="Examens blancs"
        subtitle={`${SLOTS} examens blancs de 20 questions, dans les conditions de l'épreuve. Choisissez-en un et retrouvez votre dernier score.`}
        action={
          <Link href={`/entrainement/civique/${slug}`} className={detail.headBtn}>
            <LayoutGrid size={17} strokeWidth={1.7} aria-hidden />
            Mode entraînement
          </Link>
        }
      >
        <div className={detail.statCards}>
          <DetailStatCard
            icon={<Trophy size={20} />}
            tone="blue"
            value={isGuest ? "—" : `${done}/${SLOTS}`}
            label="Examens passés"
            sub={isGuest ? "compte requis pour l'historique" : "dans cette catégorie"}
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
            value={isGuest ? "—" : String(SLOTS - done)}
            label="Restant"
            sub="examens à tenter"
          />
        </div>

        {error && <div className={detail.error}>{error}</div>}

        <ExamsGrid
          count={SLOTS}
          exams={bySlot}
          premium={isPremium}
          freeSlots={isGuest ? 0 : 1}
          lockedLabel={isGuest ? "Compte gratuit" : undefined}
          starting={starting}
          onStart={requestStart}
          onLocked={() => (isGuest ? setGuestGateOpen(true) : setPaywallOpen(true))}
        />
        <ExamIntroSheet
          open={introOpen}
          eyebrow={`Examen blanc · ${theme?.name ?? "Civique"}`}
          title={`${theme?.name ?? "Examen civique"} en conditions réelles`}
          subtitle="Avant de commencer, voici comment se déroule l'examen."
          facts={[
            { label: "questions du thème", value: "20" },
            { label: "en conditions réelles", value: "20 min" },
            { label: "seuil de réussite", value: "16/20", highlight: true },
          ]}
          tips={[
            "Aucune correction pendant l'examen : votre résultat s'affiche à la fin.",
            "Le chronomètre tourne et l'examen se termine automatiquement à la fin du temps.",
            "Pas de retour en arrière : une réponse validée est définitive, comme le jour J.",
          ]}
          loading={starting}
          error={error}
          onConfirm={() => void launch()}
          onClose={() => setIntroOpen(false)}
        />
        <PaywallSheet open={paywallOpen} onClose={() => setPaywallOpen(false)} module="CIVIQUE" />
        <GuestGateSheet
          open={guestGateOpen}
          onClose={() => setGuestGateOpen(false)}
          message="Les examens blancs par thème sont réservés aux comptes. Créez un compte gratuit pour les passer — et l'examen diagnostic complet reste offert sur la page Examens blancs."
        />
      </DetailShell>
    </DualChromeShell>
  );
}

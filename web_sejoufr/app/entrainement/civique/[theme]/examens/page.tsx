"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { CheckCircle2, Flame, LayoutGrid, Target, Trophy } from "lucide-react";
import { ApiException, attemptApi, publicThemeApi, themeApi } from "@/lib/api";
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
        // Ordre chronologique : le 1er examen passé occupe la card 01.
        setExams(
          list
            .filter((a) => a.finishedAt)
            .sort((a, b) => a.startedAt.localeCompare(b.startedAt)),
        );
      } catch {
        /* best-effort : la grille reste vide */
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [status, themeRef]);

  async function start() {
    if (starting || !theme) return;
    if (isGuest) {
      setGuestGateOpen(true);
      return;
    }
    setError(null);
    setStarting(true);
    try {
      const a = await attemptApi.start({
        type: "MOCK_EXAM",
        module: "CIVIQUE",
        themeId: theme.id,
      });
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
          exams={exams}
          premium={isPremium}
          freeSlots={isGuest ? 0 : 1}
          lockedLabel={isGuest ? "Compte gratuit" : undefined}
          starting={starting}
          onStart={start}
          onLocked={() => (isGuest ? setGuestGateOpen(true) : setPaywallOpen(true))}
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

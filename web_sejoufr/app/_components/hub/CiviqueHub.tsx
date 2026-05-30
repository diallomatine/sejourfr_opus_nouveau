"use client";

import Link from "next/link";
import {useRouter} from "next/navigation";
import {useEffect, useMemo, useState} from "react";
import {BookOpen, Flag, Globe, Landmark, type LucideIcon, Scale, Users} from "lucide-react";
import {publicThemeApi, statsApi, themeApi} from "@/lib/api";
import {type AuthenticatedUser, canAccessModule, type ThemeUserResponse, type UserStatsResponse,} from "@/lib/types";
import {
  CiviqueMasteryCard,
  EpreuveCard,
  ExamBlancHero,
  HubHeader,
  type HubTone,
  SectionCounter,
  SectionLabel,
  SectionLink,
} from "./HubParts";
import styles from "./hub.module.css";

const DEMO_BATCH_SIZE = 20;

/**
 * Hub Civique web — single-scroll calqué sur `CiviqueScreen` mobile :
 * header dynamique + hero examen blanc 40 Q + liste des thèmes (cartes
 * verticales avec maîtrise) + carte maîtrise globale. Un tap thème ouvre le
 * détail `/entrainement/civique/[themeId]` (le gating premium vit dans le
 * détail, pas ici — le lot 1 de chaque thème est gratuit).
 */
export function CiviqueHub({user}: { user: AuthenticatedUser | null }) {
    const router = useRouter();
    const isGuest = user === null;
    const isPremium = !isGuest && canAccessModule(user, "CIVIQUE");

    const [themes, setThemes] = useState<ThemeUserResponse[]>([]);
    const [stats, setStats] = useState<UserStatsResponse | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        let cancelled = false;
        // eslint-disable-next-line react-hooks/set-state-in-effect
        setLoading(true);
        const themeFetcher = isGuest ? publicThemeApi.list : themeApi.list;
        Promise.allSettled([
            themeFetcher("CIVIQUE"),
            isGuest ? Promise.resolve(null) : statsApi.get("CIVIQUE").catch(() => null),
        ]).then((results) => {
            if (cancelled) return;
            const [t, s] = results;
            setThemes(t.status === "fulfilled" ? t.value : []);
            setStats(s.status === "fulfilled" ? s.value : null);
            if (t.status === "rejected") setError("Impossible de charger les thèmes.");
            setLoading(false);
        });
        return () => {
            cancelled = true;
        };
    }, [isGuest]);

    const sortedThemes = useMemo(
        () => [...themes].sort((a, b) => a.displayOrder - b.displayOrder),
        [themes],
    );
    const statsByTheme = useMemo(() => {
        const m = new Map<string, { answered: number; correct: number; total: number }>();
        for (const ts of stats?.byTheme ?? []) m.set(ts.themeId, ts);
        return m;
    }, [stats]);

    const target = user?.targetProcedure ?? null;
    const headerSub = loading
        ? `${target ?? "Civique"} · Examen 40 questions`
        : `${target ?? "Civique"} · ${sortedThemes.length} thèmes · Examen 40 Q`;

    // Maîtrise globale = somme des stats par thème (miroir du _MasteryBlock mobile).
    const mastery = useMemo(() => {
        const list = stats?.byTheme ?? [];
        return {
            answered: list.reduce((s, t) => s + t.answered, 0),
            correct: list.reduce((s, t) => s + t.correct, 0),
            total: list.reduce((s, t) => s + t.total, 0),
        };
    }, [stats]);

    return (
        <main className={styles.hub}>
            <HubHeader title="Préparer l'examen civique" subtitle={headerSub}/>

            {!isPremium && (
                <Link href={isGuest ? "/connexion" : "/paiement"} className={styles.demo}>
          <span className={styles.demoIcon} aria-hidden>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
                 strokeLinecap="round" strokeLinejoin="round">
              <path d="M12 2l3 7h7l-5.5 4 2 7L12 16l-6.5 4 2-7L2 9h7z"/>
            </svg>
          </span>
                    <span className={styles.demoBody}>
            <span className={styles.demoTitle}>
              Mode démo · {DEMO_BATCH_SIZE} questions par thème
            </span>
            <span className={styles.demoSub}>
              {isGuest
                  ? "Créez un compte pour sauvegarder vos résultats et débloquer l'illimité."
                  : "Débloquez l'entraînement illimité et tous les examens blancs civiques."}
            </span>
          </span>
                    <span className={styles.demoArrow} aria-hidden>→</span>
                </Link>
            )}

            <ExamBlancHero
                eyebrow="Examen blanc · 40 questions"
                title="Simuler l'entretien"
                description="40 questions tous thèmes, en 45 minutes. Seuil : 32/40."
                ctaLabel="Voir les examens blancs"
                accent="blue"
                onClick={() => router.push("/examens-blancs/civique")}
            />

            {error && <div className={styles.error}>{error}</div>}

            {loading ? (
                <div className={styles.loading}>Chargement des thèmes…</div>
            ) : (
                <>
                    <SectionLabel
                        label="S'entraîner par thème"
                        trailing={<SectionCounter text={`${sortedThemes.length} thèmes`}/>}
                    />
                    <div className={styles.list}>
                        {sortedThemes.map((theme) => {
                            const ts = statsByTheme.get(theme.id);
                            const qCount = theme.questionCount ?? 0;
                            const ratio =
                                ts && ts.answered > 0 && qCount > 0 ? Math.min(1, ts.correct / qCount) : 0;
                            const Icon = iconForTheme(theme.code);
                            return (
                                <EpreuveCard
                                    key={theme.id}
                                    icon={<Icon size={22} strokeWidth={1.9}/>}
                                    tone={toneForOrder(theme.displayOrder)}
                                    title={theme.name}
                                    subtitle={`${qCount} questions`}
                                    pill={target}
                                    progress={isGuest ? null : ratio}
                                    onClick={() => router.push(`/entrainement/civique/${theme.id}`)}
                                />
                            );
                        })}
                    </div>

                    <SectionLabel
                        label="Ma progression"
                        trailing={
                            !isGuest ? (
                                <SectionLink label="Détails" onClick={() => router.push("/statistiques")}/>
                            ) : undefined
                        }
                    />
                    <CiviqueMasteryCard
                        answered={mastery.answered}
                        correct={mastery.correct}
                        total={mastery.total}
                    />
                </>
            )}
        </main>
    );
}

function iconForTheme(code: string): LucideIcon {
    const c = code.toLowerCase();
    if (c.includes("principe") || c.includes("symbole")) return Flag;
    if (c.includes("institution")) return Landmark;
    if (c.includes("droit") || c.includes("devoir")) return Scale;
    if (c.includes("histoire") || c.includes("geo")) return Globe;
    if (c.includes("societe") || c.includes("société")) return Users;
    return BookOpen;
}

function toneForOrder(order: number): HubTone {
    switch (order % 5) {
        case 2:
            return "red";
        case 3:
            return "amber";
        case 4:
            return "green";
        default:
            return "blue";
    }
}

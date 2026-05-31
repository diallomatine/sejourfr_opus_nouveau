"use client";

import Link from "next/link";
import {useRouter} from "next/navigation";
import {useEffect, useMemo, useState} from "react";
import {BookOpen, Headphones, Mic, PenLine, SpellCheck} from "lucide-react";
import {publicThemeApi, statsApi, themeApi} from "@/lib/api";
import {
  type AuthenticatedUser,
  canAccessModule,
  type TargetLevel,
  type ThemeUserResponse,
  type UserStatsResponse,
} from "@/lib/types";
import {
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
const CECRL_LEVELS = ["A1", "A2", "B1", "B2", "C1", "C2"] as const;

/** Niveau TCF visé dérivé du parcours civique (CSP→A2, CR→B1, NAT→B2). */
function tcfLevelOf(p: string | null | undefined): TargetLevel | null {
  return p === "NAT" ? "B2" : p === "CR" ? "B1" : p === "CSP" ? "A2" : null;
}

/**
 * Hub TCF web — single-scroll calqué sur `TcfScreen` mobile : header + hero
 * examen blanc complet + 5 épreuves (CO/CE/Structure → détail QCM ; EE/EO →
 * parcours production web avec évaluation IA) + carte CECRL + stats. L'examen
 * blanc complet orchestré (CO→CE→EE→EO) arrive au lot suivant.
 */
export function TcfHub({user}: {user: AuthenticatedUser | null}) {
  const router = useRouter();
  const isGuest = user === null;
  const isPremium = !isGuest && canAccessModule(user, "TCF");
  const objective = tcfLevelOf(user?.targetProcedure);

  const [themes, setThemes] = useState<ThemeUserResponse[]>([]);
  const [stats, setStats] = useState<UserStatsResponse | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    const themeFetcher = isGuest ? publicThemeApi.list : themeApi.list;
    Promise.allSettled([
      themeFetcher("TCF"),
      isGuest ? Promise.resolve(null) : statsApi.get("TCF").catch(() => null),
    ]).then(([t, s]) => {
      if (cancelled) return;
      setThemes(t.status === "fulfilled" ? t.value : []);
      setStats(s.status === "fulfilled" ? s.value : null);
      setLoading(false);
    });
    return () => {
      cancelled = true;
    };
  }, [isGuest]);

  // Maîtrise par épreuve : ratio correct/questionCount du thème backend correspondant.
  const masteryByCode = useMemo(() => {
    const statsByTheme = new Map((stats?.byTheme ?? []).map((t) => [t.themeId, t]));
    const m = new Map<string, number | null>();
    for (const th of themes) {
      const ts = statsByTheme.get(th.id);
      const q = th.questionCount ?? 0;
      m.set(th.code, ts && ts.answered > 0 && q > 0 ? Math.min(1, ts.correct / q) : 0);
    }
    return m;
  }, [themes, stats]);

  const pill = objective ?? undefined;
  const headerSub = `IRN · 5 épreuves${objective ? ` · objectif ${objective}` : ""}`;

  type Epreuve = {
    key: string;
    icon: React.ReactNode;
    tone: HubTone;
    title: string;
    subtitle: string;
    pill?: string;
    code?: string;
    onClick: () => void;
  };
  const epreuves: Epreuve[] = [
    {
      key: "co",
      icon: <Headphones size={22} strokeWidth={1.9} />,
      tone: "blue",
      title: "Compréhension orale",
      subtitle: "25 QCM · 20 min · audio",
      pill,
      code: "TCF_CO",
      onClick: () => router.push("/entrainement/tcf/co"),
    },
    {
      key: "ce",
      icon: <BookOpen size={22} strokeWidth={1.9} />,
      tone: "green",
      title: "Compréhension écrite",
      subtitle: "25 QCM · 35 min · textes",
      pill,
      code: "TCF_CE",
      onClick: () => router.push("/entrainement/tcf/ce"),
    },
    {
      key: "structure",
      icon: <SpellCheck size={22} strokeWidth={1.9} />,
      tone: "amber",
      title: "Structure de la langue",
      subtitle: "Grammaire et lexique · bonus",
      pill: "BONUS",
      code: "TCF_STRUCTURE",
      onClick: () => router.push("/entrainement/tcf/structure"),
    },
    {
      key: "ee",
      icon: <PenLine size={22} strokeWidth={1.9} />,
      tone: "slate",
      title: "Expression écrite",
      subtitle: "3 tâches · rédaction · évaluation IA",
      pill,
      onClick: () => router.push("/entrainement/tcf/ee"),
    },
    {
      key: "eo",
      icon: <Mic size={22} strokeWidth={1.9} />,
      tone: "red",
      title: "Expression orale",
      subtitle: "3 tâches · audio · évaluation IA",
      pill,
      onClick: () => router.push("/entrainement/tcf/eo"),
    },
  ];

  return (
    <main className={styles.hub}>
      <HubHeader title="Préparer le TCF" subtitle={headerSub} />

      {!isPremium && (
        <Link href={isGuest ? "/connexion" : "/paiement"} className={styles.demo}>
          <span className={styles.demoIcon} aria-hidden>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M12 2l3 7h7l-5.5 4 2 7L12 16l-6.5 4 2-7L2 9h7z" />
            </svg>
          </span>
          <span className={styles.demoBody}>
            <span className={styles.demoTitle}>Mode démo · {DEMO_BATCH_SIZE} questions par épreuve</span>
            <span className={styles.demoSub}>
              {isGuest
                ? "Créez un compte pour sauvegarder vos résultats et débloquer l'illimité."
                : "L'abonnement Intégral débloque tout le TCF + Civique et les examens blancs."}
            </span>
          </span>
          <span className={styles.demoArrow} aria-hidden>→</span>
        </Link>
      )}

      <ExamBlancHero
        eyebrow="Examen blanc complet · 1h35"
        title="Simuler le jour J"
        description="Les 4 épreuves enchaînées en conditions réelles, niveau CECRL à la clé."
        ctaLabel="Voir les examens blancs"
        accent="red"
        onClick={() => router.push("/examens-blancs/tcf")}
      />

      <SectionLabel
        label="S'entraîner par épreuve"
        trailing={<SectionCounter text="5 épreuves" />}
      />
      <div className={styles.list}>
        {epreuves.map((e) => (
          <EpreuveCard
            key={e.key}
            icon={e.icon}
            tone={e.tone}
            title={e.title}
            subtitle={e.subtitle}
            pill={e.pill}
            progress={isGuest || !e.code ? null : (masteryByCode.get(e.code) ?? 0)}
            onClick={e.onClick}
          />
        ))}
      </div>

      <SectionLabel
        label="Ma progression"
        trailing={
          !isGuest ? (
            <SectionLink label="Détails" onClick={() => router.push("/statistiques")} />
          ) : undefined
        }
      />
      <CecrlCard objective={objective} />
      <div className={styles.statsRow}>
        <StatCell value={loading || isGuest ? "—" : String(stats?.attemptsTotal ?? 0)} label="Séances" />
        <StatCell value="—" label="Pratique" />
        <StatCell value="—" label="Jours actifs" />
      </div>

    </main>
  );
}

function CecrlCard({objective}: {objective: TargetLevel | null}) {
  const targetIdx = objective ? CECRL_LEVELS.indexOf(objective) : -1;
  return (
    <div className={styles.cecrl}>
      <div className={styles.cecrlTop}>
        <span className={styles.cecrlObjLabel}>Niveau visé</span>
        <span className={styles.cecrlObj}>{objective ?? "—"}</span>
      </div>
      <div className={styles.cecrlSegments}>
        {CECRL_LEVELS.map((lvl, i) => (
          <span
            key={lvl}
            className={`${styles.cecrlSeg} ${
              targetIdx >= 0 && i === targetIdx
                ? styles.cecrlSegTarget
                : targetIdx >= 0 && i < targetIdx
                  ? styles.cecrlSegOn
                  : ""
            }`}
          />
        ))}
      </div>
      <div className={styles.cecrlLabels}>
        {CECRL_LEVELS.map((lvl) => (
          <span key={lvl} className={styles.cecrlLabel}>
            {lvl}
          </span>
        ))}
      </div>
    </div>
  );
}

function StatCell({value, label}: {value: string; label: string}) {
  return (
    <div className={styles.statCell}>
      <div className={styles.statVal}>{value}</div>
      <div className={styles.statLabel}>{label}</div>
    </div>
  );
}

"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import {
  Gavel,
  Globe,
  Landmark,
  LayoutGrid,
  Lightbulb,
  Scale,
  Target,
  Users,
} from "lucide-react";
import { dashboardApi, publicThemeApi } from "@/lib/api";
import { masteryHint, moduleAverage } from "@/lib/dashboard";
import { themeSlug } from "@/lib/themes";
import {
  type AuthenticatedUser,
  canAccessModule,
  type DashboardCategoryStat,
  type DashboardSummaryResponse,
  type ThemeUserResponse,
} from "@/lib/types";
import {
  CategoryCard,
  ModuleHubHeader,
  ModuleStatsBand,
} from "./ModuleHubParts";
import moduleStyles from "./moduleHub.module.css";
import styles from "./hub.module.css";

const DEMO_BATCH_SIZE = 20;

/** Contenu statique des 5 cards civiques (maquette sejour_fr.html), par code thème. */
const CIVIQUE_CONTENT: Record<
  string,
  {
    icon: React.ReactNode;
    iconTone: "blue" | "green" | "amber" | "red" | "slate";
    desc: string;
    chips: string[];
  }
> = {
  CIV_PRINCIPES: {
    iconTone: "blue",
    icon: <Scale size={24} strokeWidth={1.7} />,
    desc: "Liberté, égalité, fraternité, laïcité, démocratie.",
    chips: ["Liberté", "Égalité", "Fraternité", "Laïcité", "Démocratie"],
  },
  CIV_INSTITUTIONS: {
    iconTone: "green",
    icon: <Landmark size={24} strokeWidth={1.7} />,
    desc: "Président, gouvernement, parlement, justice, collectivités.",
    chips: ["Président", "Gouvernement", "Parlement", "Justice", "Collectivités"],
  },
  CIV_DROITS_DEVOIRS: {
    iconTone: "amber",
    icon: <Gavel size={24} strokeWidth={1.7} />,
    desc: "Droits des citoyens, devoirs civiques, lois, école, travail, impôts.",
    chips: ["Droits", "Devoirs", "Lois", "École", "Travail"],
  },
  CIV_HISTOIRE_GEO: {
    iconTone: "red",
    icon: <Globe size={24} strokeWidth={1.7} />,
    desc: "Grandes dates, symboles, géographie, culture, patrimoine, fêtes.",
    chips: ["Histoire", "Symboles", "Géographie", "Culture", "Patrimoine"],
  },
  CIV_SOCIETE: {
    iconTone: "slate",
    icon: <Users size={24} strokeWidth={1.7} />,
    desc: "Vie quotidienne, logement, santé, éducation, travail, services publics.",
    chips: ["Quotidien", "Logement", "Santé", "Éducation", "Services publics"],
  },
};

/** Modèle d'une card : id du thème (routing) + stats éventuelles. */
interface CiviqueCardModel {
  themeId: string;
  code: string;
  title: string;
  stat: DashboardCategoryStat | null;
}

/**
 * Hub Civique web (refonte web_refonte, maquette sejour_fr.html) : header
 * eyebrow + bande de stats + 5 cards thème (donut, chips, statut, CTAs
 * S'entraîner / Examen blanc). Données : GET /api/me/dashboard (connecté,
 * fournit themeId + percent + nb d'examens) ; guests → thèmes publics sans
 * stats. Le gating premium vit dans les pages détail (lot 1 gratuit).
 */
export function CiviqueHub({ user }: { user: AuthenticatedUser | null }) {
  const isGuest = user === null;
  const isPremium = !isGuest && canAccessModule(user, "CIVIQUE");

  const [summary, setSummary] = useState<DashboardSummaryResponse | null>(null);
  const [guestThemes, setGuestThemes] = useState<ThemeUserResponse[]>([]);

  useEffect(() => {
    let cancelled = false;
    if (isGuest) {
      publicThemeApi
        .list("CIVIQUE")
        .then((t) => {
          if (!cancelled) setGuestThemes(t);
        })
        .catch(() => {});
    } else {
      dashboardApi
        .summaryCached()
        .then((d) => {
          if (!cancelled) setSummary(d);
        })
        .catch(() => {});
    }
    return () => {
      cancelled = true;
    };
  }, [isGuest]);

  const cards: CiviqueCardModel[] = useMemo(() => {
    if (summary) {
      return summary.civique
        .filter((c) => c.themeId !== null)
        .map((c) => ({
          themeId: c.themeId as string,
          code: c.code,
          title: c.label,
          stat: c,
        }));
    }
    return [...guestThemes]
      .sort((a, b) => a.displayOrder - b.displayOrder)
      .map((t) => ({ themeId: t.id, code: t.code, title: t.name, stat: null }));
  }, [summary, guestThemes]);

  const average = summary ? moduleAverage(summary.civique) : null;

  return (
    <main className={moduleStyles.wrap}>
      <ModuleHubHeader
        eyebrowIcon={<Lightbulb size={18} strokeWidth={2} />}
        eyebrow="Intégration républicaine"
        title="Examen civique"
        subtitle="Les valeurs, institutions et savoirs de la société française."
        action={
          <Link
            href={isGuest ? "/connexion" : "/dashboard"}
            className={moduleStyles.headBtn}
          >
            <LayoutGrid size={18} strokeWidth={1.7} aria-hidden />
            {isGuest ? "Se connecter" : "Tableau de bord"}
          </Link>
        }
      />

      {!isPremium && (
        <Link href={isGuest ? "/connexion" : "/paiement"} className={styles.demo}>
          <span className={styles.demoIcon} aria-hidden>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M12 2l3 7h7l-5.5 4 2 7L12 16l-6.5 4 2-7L2 9h7z" />
            </svg>
          </span>
          <span className={styles.demoBody}>
            <span className={styles.demoTitle}>
              {isGuest
                ? "Découverte gratuite · 1 série offerte par thème"
                : `Mode démo · ${DEMO_BATCH_SIZE} questions par thème`}
            </span>
            <span className={styles.demoSub}>
              {isGuest
                ? "Et un examen blanc complet offert. Créez un compte gratuit pour continuer et sauvegarder vos résultats."
                : "Débloquez l'entraînement illimité et tous les examens blancs civiques."}
            </span>
          </span>
          <span className={styles.demoArrow} aria-hidden>→</span>
        </Link>
      )}

      <ModuleStatsBand
        cells={[
          {
            label: "Maîtrise globale",
            value: average !== null ? `${average}%` : "—",
            hint: masteryHint(average),
            accent: true,
          },
          {
            label: "Catégories",
            value: cards.length > 0 ? String(cards.length) : "5",
            hint: "à travailler",
          },
          {
            label: "Examens blancs passés",
            value: summary ? String(summary.civiqueMockExams) : "—",
            hint: "au total",
          },
          {
            label: "Niveau estimé",
            value: "—",
            hint: "non noté CECRL",
          },
        ]}
      />

      <div className={moduleStyles.grid}>
        {cards.map((card) => {
          const content = CIVIQUE_CONTENT[card.code] ?? {
            icon: <Landmark size={24} strokeWidth={1.7} />,
            iconTone: "blue" as const,
            desc: "",
            chips: [],
          };
          const meta = card.stat
            ? `${card.stat.mockExams} examen${card.stat.mockExams > 1 ? "s" : ""} blanc${card.stat.mockExams > 1 ? "s" : ""}`
            : "QCM 20 questions";
          return (
            <CategoryCard
              key={card.themeId}
              icon={content.icon}
              iconTone={content.iconTone}
              title={card.title}
              desc={content.desc}
              percent={card.stat?.percent ?? null}
              chips={content.chips}
              meta={meta}
              ctas={[
                {
                  label: "S'entraîner",
                  href: `/entrainement/civique/${themeSlug(card.code)}`,
                  icon: <LayoutGrid size={18} strokeWidth={1.7} />,
                  variant: "soft",
                },
                {
                  label: "Examen blanc",
                  href: `/entrainement/civique/${themeSlug(card.code)}/examens`,
                  icon: <Target size={18} strokeWidth={1.7} />,
                  variant: "solid",
                },
              ]}
            />
          );
        })}
      </div>
    </main>
  );
}

"use client";

import Link from "next/link";
import {useEffect, useState} from "react";
import {BookOpen, Headphones, LayoutGrid, Mic, PenLine, SpellCheck, Target, Waves,} from "lucide-react";
import {dashboardApi} from "@/lib/api";
import {masteryHint, moduleAverage} from "@/lib/dashboard";
import {
    type AuthenticatedUser,
    canAccessModule,
    type DashboardCategoryStat,
    type DashboardSummaryResponse,
    estimatedTcfLevelScopeLabel,
    niveauCecrlLabel,
} from "@/lib/types";
import {
    EE_CONFIG,
    EO_CONFIG,
    productionEntryHref,
} from "@/app/_components/production/config";
import {CategoryCard, type CategoryCta, ModuleHubHeader, ModuleStatsBand,} from "./ModuleHubParts";
import moduleStyles from "./moduleHub.module.css";
import styles from "./hub.module.css";

const DEMO_BATCH_SIZE = 20;

/** Contenu statique des 5 cards TCF (maquette sejour_fr.html). */
const TCF_CARDS: Array<{
    code: string;
    iconTone: "blue" | "green" | "amber" | "red" | "slate";
    icon: React.ReactNode;
    title: string;
    desc: string;
    chips: string[];
    train?: string;
    exam?: string;
    exercise?: { href: string; icon: React.ReactNode };
}> = [
    {
        code: "TCF_CO",
        iconTone: "blue",
        icon: <Headphones size={24} strokeWidth={1.7}/>,
        title: "Compréhension orale",
        desc: "Écouter des audios courts et répondre à des QCM.",
        chips: ["Annonces", "Conversations", "Messages", "Médias"],
        train: "/entrainement/tcf/co",
        exam: "/entrainement/tcf/co/examens",
    },
    {
        code: "TCF_CE",
        iconTone: "green",
        icon: <BookOpen size={24} strokeWidth={1.7}/>,
        title: "Compréhension écrite",
        desc: "Lire des textes courts et répondre à des QCM.",
        chips: ["Affiches", "Courriels", "Articles", "Consignes"],
        train: "/entrainement/tcf/ce",
        exam: "/entrainement/tcf/ce/examens",
    },
    {
        code: "TCF_STRUCTURE",
        iconTone: "amber",
        icon: <SpellCheck size={24} strokeWidth={1.7}/>,
        title: "Structure de la langue",
        desc: "Grammaire, vocabulaire, conjugaison et syntaxe.",
        chips: ["Grammaire", "Vocabulaire", "Conjugaison", "Syntaxe"],
        train: "/entrainement/tcf/structure",
        exam: "/entrainement/tcf/structure/examens",
    },
    {
        code: "TCF_EE",
        iconTone: "slate",
        icon: <PenLine size={24} strokeWidth={1.7}/>,
        title: "Expression écrite",
        desc: "Rédiger des messages courts, analysés par l'IA.",
        chips: ["Message", "Courriel", "Argumentation"],
        exercise: {
            href: productionEntryHref(EE_CONFIG.base),
            icon: <PenLine size={18} strokeWidth={1.7}/>,
        },
    },
    {
        code: "TCF_EO",
        // Même teinte que l'expression écrite : les deux épreuves productives
        // sont bleues depuis le 2026-08-09. Ce qui les distingue ici, c'est le
        // pictogramme (micro vs stylo) et le titre.
        iconTone: "slate",
        icon: <Mic size={24} strokeWidth={1.7}/>,
        title: "Expression orale",
        desc: "Répondre à l'oral, enregistré et analysé par l'IA.",
        chips: ["Se présenter", "Décrire", "Argumenter"],
        exercise: {
            href: productionEntryHref(EO_CONFIG.base),
            icon: <Mic size={18} strokeWidth={1.7}/>,
        },
    },
];

/**
 * Hub TCF web (refonte web_refonte, maquette sejour_fr.html) : header
 * eyebrow + bande de stats (maîtrise, catégories, examens blancs, niveau
 * estimé) + 5 cards catégorie. Données : GET /api/me/dashboard (connecté) ;
 * les guests voient les cards sans stats. Le gating premium vit dans les
 * pages détail (lots / examens), pas ici.
 */
export function TcfHub({user}: { user: AuthenticatedUser | null }) {
    const isGuest = user === null;
    const isPremium = !isGuest && canAccessModule(user, "TCF");

    const [summary, setSummary] = useState<DashboardSummaryResponse | null>(null);

    useEffect(() => {
        if (isGuest) return;
        let cancelled = false;
        dashboardApi
            .summaryCached()
            .then((d) => {
                if (!cancelled) setSummary(d);
            })
            .catch(() => {
            });
        return () => {
            cancelled = true;
        };
    }, [isGuest]);

    const byCode = new Map<string, DashboardCategoryStat>(
        (summary?.tcf ?? []).map((c) => [c.code, c]),
    );
    const average = summary ? moduleAverage(summary.tcf) : null;

    return (
        <main className={moduleStyles.wrap}>
            <ModuleHubHeader
                eyebrowIcon={<Waves size={18} strokeWidth={2}/>}
                eyebrow="Test de connaissance du français"
                title="TCF IRN"
                subtitle="Le test linguistique exigé pour la résidence et la naturalisation."
                action={
                    <Link
                        href={isGuest ? "/connexion" : "/dashboard"}
                        className={moduleStyles.headBtn}
                    >
                        <LayoutGrid size={18} strokeWidth={1.7} aria-hidden/>
                        {isGuest ? "Se connecter" : "Tableau de bord"}
                    </Link>
                }
            />

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
              {isGuest
                  ? "Découverte gratuite · 1 série offerte par épreuve et niveau"
                  : `Mode démo · ${DEMO_BATCH_SIZE} questions par épreuve`}
            </span>
            <span className={styles.demoSub}>
              {isGuest
                  ? " Et un examen blanc complet offert. Créez un compte gratuit pour continuer et sauvegarder vos résultats."
                  : "L'abonnement Intégral débloque tout le TCF + Civique et les examens blancs."}
            </span>
          </span>
                    <span className={styles.demoArrow} aria-hidden>→</span>
                </Link>
            )}

            <br/>

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
                        value: String(TCF_CARDS.length),
                        hint: "à travailler",
                    },
                    {
                        label: "Examens blancs passés",
                        value: summary ? String(summary.tcfMockExams) : "—",
                        hint: "au total",
                    },
                    {
                        label: "Niveau estimé",
                        value: summary?.estimatedTcfLevel
                            ? niveauCecrlLabel(summary.estimatedTcfLevel)
                            : "—",
                        // Un niveau qui ne porte pas sur les 4 épreuves le dit
                        // ici, à la place de la mention générique.
                        hint:
                            estimatedTcfLevelScopeLabel(summary) ??
                            (summary?.estimatedTcfLevel
                                ? "équivalence CECRL"
                                : "non noté CECRL"),
                    },
                ]}
            />

            <div className={moduleStyles.grid}>
                {TCF_CARDS.map((card) => {
                    const stat = byCode.get(card.code) ?? null;
                    const isProduction = Boolean(card.exercise);
                    const meta = isProduction
                        ? stat?.level
                            ? `Niveau estimé ${niveauCecrlLabel(stat.level)}`
                            : "Évaluation IA"
                        : stat
                            ? `${stat.mockExams} examen${stat.mockExams > 1 ? "s" : ""} blanc${stat.mockExams > 1 ? "s" : ""}`
                            : "QCM chronométrés";
                    const ctas: CategoryCta[] = card.exercise
                        ? [
                            {
                                label: "S'exercer",
                                href: card.exercise.href,
                                icon: card.exercise.icon,
                                variant: "soft",
                            },
                            {
                                label: "Examens",
                                href: `${card.exercise.href}/examens`,
                                icon: <Target size={18} strokeWidth={1.7}/>,
                                variant: "solid",
                            },
                        ]
                        : [
                            {
                                label: "S'entraîner",
                                href: card.train ?? "#",
                                icon: <LayoutGrid size={18} strokeWidth={1.7}/>,
                                variant: "soft",
                            },
                            {
                                label: "Examen blanc",
                                href: card.exam ?? "#",
                                icon: <Target size={18} strokeWidth={1.7}/>,
                                variant: "solid",
                            },
                        ];
                    return (
                        <CategoryCard
                            key={card.code}
                            icon={card.icon}
                            iconTone={card.iconTone}
                            title={card.title}
                            desc={card.desc}
                            percent={stat?.percent ?? null}
                            chips={card.chips}
                            meta={meta}
                            ctas={ctas}
                        />
                    );
                })}
            </div>
        </main>
    );
}

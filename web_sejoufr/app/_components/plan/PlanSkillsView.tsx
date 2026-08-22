"use client";

import Link from "next/link";
import {useEffect, useState} from "react";
import {ArrowLeft, LayoutGrid, RotateCcw} from "lucide-react";
import {ApiException, learningPlanApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  PLAN_COMPLETE_PROFILE_NOTE,
  PLAN_DOMAIN_NOT_EVALUATED,
  PLAN_SKILLS_TEXT,
  PLAN_SKILLS_TITLE,
  planDomainHref,
  planDomainLabel,
  planDomainLevelLine,
  planLevelRowMeta,
  planProfileCountLabel,
} from "@/lib/plan-domain";
import type {LearningPlanDto, PlanDomainDto} from "@/lib/types";
import {PlanDomainIcon, PlanDomainPriorityPill, PlanTaskRow} from "./PlanBits";
import {EmptyCard, PlanShell} from "./LearningPlanView";
import {RowChevron, SkillMasteryPill} from "@/app/_components/skill-ui/SkillLayout";
import styles from "./plan.module.css";

/**
 * **« Toutes mes compétences »** — le référentiel, ouvert depuis « Mes
 * priorités ».
 *
 * 🛑 **Aucun écran concurrent n'est créé, et aucune donnée n'est redemandée.**
 * Tout vient de `GET /api/me/plan` (lu **en cache**), et chaque ligne renvoie
 * vers un parcours **déjà livré** :
 * - **expression** (EE / EO) : les trois tâches, qui ouvrent les huit
 *   compétences de la tâche — l'écran « Réviser → épreuve → Compétences » ;
 * - **compréhension** (CO / CE) : les trois paliers, qui ouvrent la **fiche du
 *   domaine**, seul écran qui les décrive et d'où part la série ciblée.
 *
 * 🛑 **L'ordre des domaines vient du serveur** (par urgence, puis ordre des
 * épreuves du TCF) : on ne regroupe pas par famille, on ne retrie pas — même
 * doctrine que « Mon profil TCF ».
 *
 * 🛑 **La page est OUVERTE à tout le monde** (arbitrage du 2026-08-22, aligné
 * sur le mobile et sur la maquette). Elle **révoque** le verrou de navigation
 * qui la fermait entièrement : *on floute l'action pas encore accessible,
 * jamais la mesure ni le catalogue*. Rien de ce qu'elle affiche n'est une
 * action — ce sont des **compteurs d'observation** (« 3 / 8 compétences
 * observées »), des **paliers mesurés** et l'état agrégé qui en découle, c'est-
 * à-dire le résultat du travail du candidat. Le verrou reste **là où le serveur
 * le pose** : sur chaque compétence et sur chaque sujet des écrans d'arrivée
 * (`SkillDto.locked` / `SkillPromptDto.locked`, opposables en 403). Ne pas
 * refermer la page « par symétrie ».
 */
export function PlanSkillsView() {
  const {status: authStatus, user} = useAuth();
  const [plan, setPlan] = useState<LearningPlanDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (authStatus === "loading" || !user) return;
    let cancelled = false;
    learningPlanApi.getCached().then(
      (current) => { if (!cancelled) { setPlan(current); setError(null); } },
      (cause: unknown) => {
        if (!cancelled) {
          setError(cause instanceof ApiException ? cause.message : "Impossible de charger vos compétences.");
        }
      },
    ).finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [authStatus, user]);

  if (authStatus === "loading" || (Boolean(user) && loading)) {
    return (
      <main className={styles.page} aria-busy="true" aria-label="Chargement des compétences">
        <div className={styles.skeletonHead} />
        <div className={styles.skeletonHero} />
      </main>
    );
  }

  if (!plan || plan.domaines.length === 0) {
    return (
      <PlanShell>
        <div className={styles.narrow}>
          <BackToPlan />
          <EmptyCard
            icon={<RotateCcw size={28} />}
            title="Vos compétences n'ont pas pu être chargées"
            text={error ?? "Réessayez dans un instant."}
            role="alert"
          >
            <Link className={styles.primaryButton} href="/plan">Revenir à mon plan</Link>
          </EmptyCard>
        </div>
      </PlanShell>
    );
  }

  return (
    <PlanShell>
      <div className={styles.narrow}>
        <BackToPlan />

        <header className={styles.header}>
          <p className={styles.eyebrow}><LayoutGrid size={15} aria-hidden /> Référentiel</p>
          <h1>{PLAN_SKILLS_TITLE}</h1>
          <p>{PLAN_SKILLS_TEXT}</p>
        </header>

        <div className={styles.stack}>
          <p className={styles.asideNote}>{planProfileCountLabel(plan.cycle)}</p>
          {plan.domaines.map((domain) => (
            <DomainBlock key={domain.epreuve} domain={domain} />
          ))}
          <p className={styles.asideNote}>{PLAN_COMPLETE_PROFILE_NOTE}</p>
        </div>
      </div>
    </PlanShell>
  );
}

function BackToPlan() {
  return (
    <Link className={styles.back} href="/plan">
      <ArrowLeft size={17} aria-hidden /> Mon plan
    </Link>
  );
}

/**
 * Un domaine et ce qu'il contient. **Les deux familles ne se travaillent pas
 * pareil, et le contrat l'impose** : `taches` est rempli en expression,
 * `paliers` en compréhension — jamais les deux. Un domaine sans ni l'un ni
 * l'autre garde sa ligne d'en-tête : elle mène à sa fiche, où l'on apprend par
 * quoi le mesurer.
 */
function DomainBlock({domain}: {domain: PlanDomainDto}) {
  return (
    <section className={styles.panel} aria-labelledby={`skills-${domain.epreuve}`}>
      <div className={styles.panelHead}>
        <PlanDomainIcon
          epreuve={domain.epreuve}
          active={domain.evaluated && domain.priority === "FORTE"}
          small
        />
        <div>
          <h2 id={`skills-${domain.epreuve}`}>{planDomainLabel(domain.epreuve)}</h2>
          <p>{planDomainLevelLine(domain)}</p>
        </div>
        <PlanDomainPriorityPill priority={domain.priority} />
      </div>

      <ul className={styles.panelList}>
        {domain.taches.map((tache) => (
          <PlanTaskRow key={tache.taskCode} tache={tache} epreuve={domain.epreuve} />
        ))}
        {domain.paliers.map((palier) => (
          <li key={palier.skillId}>
            {/* La série ciblée se lance depuis la FICHE du domaine : un seul
                endroit démarre un `TRAINING` de compréhension, et c'est celui
                qui connaît le palier bloquant. */}
            <Link className={styles.panelRow} href={planDomainHref(domain.epreuve)}>
              <span
                className={`${styles.levelBadge} ${palier.blocking ? styles.levelBadgeBlocking : ""}`}
              >
                {palier.niveau}
              </span>
              <span className={styles.panelBody}>
                <span className={styles.panelTitle}>{palier.skillCode}</span>
                <span className={styles.panelMeta}>{planLevelRowMeta(palier)}</span>
              </span>
              <SkillMasteryPill state={palier.masteryState} />
              <RowChevron />
            </Link>
          </li>
        ))}
        {domain.taches.length === 0 && domain.paliers.length === 0 && (
          <li>
            <Link className={styles.panelRow} href={planDomainHref(domain.epreuve)}>
              <span className={styles.panelBody}>
                <span className={styles.panelTitle}>{PLAN_DOMAIN_NOT_EVALUATED}</span>
                <span className={styles.panelMeta}>Ouvrir la fiche du domaine</span>
              </span>
              <RowChevron />
            </Link>
          </li>
        )}
      </ul>
    </section>
  );
}

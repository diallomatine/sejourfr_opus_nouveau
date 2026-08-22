"use client";

import Link from "next/link";
import {useEffect, useState} from "react";
import {ArrowRight} from "lucide-react";
import {learningPlanApi} from "@/lib/api";
import {
  planDomainHref,
  planDomainLabel,
  planDomainLevelLine,
  planProfileCountLabel,
} from "@/lib/plan-domain";
import type {LearningPlanDto} from "@/lib/types";
import {PlanDomainIcon, PlanDomainPriorityPill} from "./PlanBits";
import {RowChevron} from "@/app/_components/skill-ui/SkillLayout";
import styles from "./plan.module.css";

/**
 * **Les quatre domaines du TCF**, réutilisables hors du Plan — c'est ce que
 * « Ma progression » montre en tête, à la place d'un chiffre global qui ne dit
 * pas où le candidat bloque.
 *
 * 🛑 **L'ordre vient du serveur** (par urgence, puis ordre des épreuves) : on
 * ne retrie pas, et on ne complète aucun trou — les quatre sont toujours servis,
 * y compris ceux qui n'ont jamais été mesurés (`evaluated: false`).
 *
 * Le Plan est lu **en cache** (`getCached`) : cet écran ne déclenche pas une
 * seconde lecture quand le Plan vient d'être ouvert, et son échec ne dégrade
 * rien — la section disparaît, sans message d'erreur.
 */
export function PlanDomainsSummary() {
  const [plan, setPlan] = useState<LearningPlanDto | null>(null);

  useEffect(() => {
    let cancelled = false;
    learningPlanApi.getCached().then(
      (current) => { if (!cancelled) setPlan(current); },
      () => { /* confort d'affichage : un échec ne remonte pas à l'écran */ },
    );
    return () => { cancelled = true; };
  }, []);

  if (!plan || plan.domaines.length === 0) return null;

  return (
    <section className={`${styles.panel} ${styles.domainsSummary}`} aria-labelledby="domains-summary">
      <div className={styles.panelHead}>
        <div>
          <h2 id="domains-summary">Mon profil TCF</h2>
          <p>{planProfileCountLabel(plan.cycle)}</p>
        </div>
        <Link className={styles.panelCta} href="/plan">
          Mon plan <ArrowRight size={14} aria-hidden />
        </Link>
      </div>
      <ul className={styles.panelList}>
        {plan.domaines.map((domain) => (
          <li key={domain.epreuve}>
            <Link className={styles.panelRow} href={planDomainHref(domain.epreuve)}>
              <PlanDomainIcon
                epreuve={domain.epreuve}
                active={domain.evaluated && domain.priority === "FORTE"}
                small
              />
              <span className={styles.panelBody}>
                <span className={styles.panelTitle}>{planDomainLabel(domain.epreuve)}</span>
                <span className={styles.panelMeta}>{planDomainLevelLine(domain)}</span>
              </span>
              <PlanDomainPriorityPill priority={domain.priority} />
              <RowChevron />
            </Link>
          </li>
        ))}
      </ul>
    </section>
  );
}

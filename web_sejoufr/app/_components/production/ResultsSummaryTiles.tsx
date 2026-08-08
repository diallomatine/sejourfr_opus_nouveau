"use client";

import {ChevronDown, CircleAlert, CircleCheckBig} from "lucide-react";
import {treatedPointsSummary} from "@/lib/production-feedback";
import type {EeAccomplishment, EePriority} from "@/lib/types";
import {PriorityBody} from "./PriorityBody";
import styles from "./production.module.css";

/**
 * Les deux réponses que le candidat cherche juste après sa note : **ce qui
 * marche** et **ce qu'il faut corriger**.
 *
 * Deux bandeaux pleine largeur, empilés, **repliés par défaut** : sur une ligne
 * chacun, le rapport annonce son verdict positif et son verdict négatif sans
 * imposer une seule phrase de lecture. Le détail — points traités, points forts,
 * priorité complète avec sa technique et sa réécriture — s'ouvre en dessous,
 * dans le même encart.
 *
 * C'est aussi ce qui supprime la dernière redite du rapport : la priorité
 * n'était résumée en haut que pour être répétée en entier plus bas. Elle vit
 * désormais **à un seul endroit**, ici.
 *
 * `<details>` natif : aucune JS d'ouverture, aucun état à synchroniser, et le
 * clavier fonctionne sans un attribut de plus.
 */
export function ResultsSummaryTiles({
  accomplissement,
  priorites,
  pointsForts,
}: {
  accomplissement: EeAccomplishment | null;
  priorites: EePriority[];
  pointsForts: string[];
}) {
  const points = treatedPointsSummary(accomplissement);
  const hasPositif = points != null || pointsForts.length > 0;
  if (!hasPositif && priorites.length === 0) return null;

  return (
    <>
      {hasPositif && (
        <SummaryTile
          tone="good"
          icon={<CircleCheckBig size={18} strokeWidth={2.3} aria-hidden />}
          title="Ce qui marche"
          value={
            points
              ? `${points.done}/${points.total} points traités`
              : pointsForts.length > 1
                ? `${pointsForts.length} points forts`
                : "1 point fort"
          }
        >
          {points && points.libelles.length > 0 && (
            <ul className={styles.tileBullets}>
              {points.libelles.map((l, i) => (
                <li key={i}>{l}</li>
              ))}
            </ul>
          )}
          {/* Un filet, pas un titre : ce que la consigne demandait d'un côté, ce
              que la langue réussit de l'autre — une seule liste les mélangeait. */}
          {points && points.libelles.length > 0 && pointsForts.length > 0 && (
            <span className={styles.tileSplit} aria-hidden />
          )}
          {pointsForts.length > 0 && (
            <ul className={styles.tileBullets}>
              {pointsForts.map((p, i) => (
                <li key={i}>{p}</li>
              ))}
            </ul>
          )}
        </SummaryTile>
      )}

      {priorites.length > 0 && (
        <SummaryTile
          // Le rouge est juste ici : c'est le seul bloc du rapport qui dit
          // « à refaire ». Il ne peint aucun niveau CECRL — la règle « jamais de
          // rouge sur un niveau » n'est pas en cause.
          tone="fix"
          icon={<CircleAlert size={18} strokeWidth={2.3} aria-hidden />}
          title="À corriger en priorité"
          value={priorites.length > 1 ? `${priorites.length} priorités` : "1 priorité"}
        >
          {priorites.map((p, i) => (
            <PriorityBody
              key={i}
              priority={p}
              rank={i + 1}
              total={priorites.length}
            />
          ))}
        </SummaryTile>
      )}
    </>
  );
}

function SummaryTile({
  tone,
  icon,
  title,
  value,
  children,
}: {
  tone: "good" | "fix";
  icon: React.ReactNode;
  title: string;
  value: string;
  children: React.ReactNode;
}) {
  return (
    <details className={styles.tile} data-tone={tone}>
      <summary className={styles.tileHead}>
        <span className={styles.tileIcon}>{icon}</span>
        <span className={styles.tileTitle}>{title}</span>
        <span className={styles.tileValue}>{value}</span>
        <ChevronDown className={styles.tileChevron} size={18} strokeWidth={2.4} aria-hidden />
      </summary>
      <div className={styles.tileBody}>{children}</div>
    </details>
  );
}

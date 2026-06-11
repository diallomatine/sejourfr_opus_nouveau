"use client";

import {AlertTriangle, Lightbulb, ThumbsUp, TrendingUp} from "lucide-react";
import {parseEeFeedback, type EvaluationResultDto} from "@/lib/types";
import {NoteScoreDonut} from "./NoteScoreDonut";
import styles from "./production.module.css";

/**
 * Rendu complet d'une évaluation IA d'une production (écrite ou orale) : donut
 * note/20, critères notés (barre + commentaire), puis blocs « points forts /
 * à améliorer / suggestions / corrections ». Miroir des écrans de résultats
 * mobiles. Réutilisé en entraînement libre comme en examen blanc, EE comme EO
 * (le feedback IA a la même structure). Le niveau CECRL n'est plus affiché par
 * tâche — il ne vit qu'au bilan d'épreuve en examen blanc.
 */
export function ProductionFeedbackView({evaluation}: {evaluation: EvaluationResultDto}) {
  const fb = parseEeFeedback(evaluation);

  return (
    <div className={styles.wrap} style={{padding: 0, gap: 16}}>
      <NoteScoreDonut noteSurVingt={fb.noteGlobale} />

      {fb.avertissements.length > 0 && (
        <div className={styles.warnBox}>
          {fb.avertissements.map((a, i) => (
            <p key={i} style={{margin: i === 0 ? 0 : "6px 0 0"}}>
              {a}
            </p>
          ))}
        </div>
      )}

      {fb.criteres.length > 0 && (
        <div className={styles.card}>
          <p className={styles.cardLabel}>Détail par critère</p>
          {fb.criteres.map((c, i) => {
            const pct = Math.max(0, Math.min(100, (c.noteSurVingt / 20) * 100));
            const color =
              c.noteSurVingt >= 14
                ? "var(--color-green)"
                : c.noteSurVingt >= 10
                  ? "var(--color-amber)"
                  : "var(--color-red)";
            return (
              <div key={c.code || i} className={styles.critRow}>
                <span className={styles.critBubble} style={{background: color}}>
                  {formatNote(c.noteSurVingt)}
                </span>
                <div className={styles.critBody}>
                  <div className={styles.critTop}>
                    <span className={styles.critLabel}>{c.label}</span>
                    <span className={styles.critNote} style={{color}}>
                      {formatNote(c.noteSurVingt)}/20
                    </span>
                  </div>
                  <div className={styles.critTrack}>
                    <div className={styles.critFill} style={{width: `${pct}%`, background: color}} />
                  </div>
                  {c.commentaire && <p className={styles.critComment}>{c.commentaire}</p>}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {fb.pointsForts.length > 0 && (
        <FeedbackList
          title="Points forts"
          icon={<ThumbsUp size={16} strokeWidth={2.2} color="var(--color-green)" />}
          items={fb.pointsForts}
          dot={styles.fbGood}
        />
      )}
      {fb.pointsAAmeliorer.length > 0 && (
        <FeedbackList
          title="À améliorer"
          icon={<TrendingUp size={16} strokeWidth={2.2} color="var(--color-amber)" />}
          items={fb.pointsAAmeliorer}
          dot={styles.fbWarn}
        />
      )}
      {fb.suggestions.length > 0 && (
        <FeedbackList
          title="Suggestions"
          icon={<Lightbulb size={16} strokeWidth={2.2} color="var(--color-blue)" />}
          items={fb.suggestions}
          dot={styles.fbInfo}
        />
      )}

      {fb.exemplesCorriges.length > 0 && (
        <div className={styles.card}>
          <p className={styles.fbTitle}>
            <AlertTriangle size={16} strokeWidth={2.2} color="var(--color-red)" />
            Corrections
          </p>
          {fb.exemplesCorriges.map((e, i) => (
            <div key={i} className={styles.correction}>
              <div className={styles.corrLine}>
                {e.original && <span className={styles.corrOrig}>{e.original}</span>}
                {e.original && e.corrige ? "  →  " : ""}
                {e.corrige && <span className={styles.corrFix}>{e.corrige}</span>}
              </div>
              {e.explication && <p className={styles.corrExpl}>{e.explication}</p>}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function FeedbackList({
  title,
  icon,
  items,
  dot,
}: {
  title: string;
  icon: React.ReactNode;
  items: string[];
  dot: string;
}) {
  return (
    <div className={styles.card}>
      <p className={styles.fbTitle}>
        {icon}
        {title}
      </p>
      <ul className={styles.fbList}>
        {items.map((it, i) => (
          <li key={i} className={styles.fbItem}>
            <span className={`${styles.fbBullet} ${dot}`} />
            {it}
          </li>
        ))}
      </ul>
    </div>
  );
}

function formatNote(n: number): string {
  return Number.isInteger(n) ? String(n) : n.toFixed(1).replace(".", ",");
}

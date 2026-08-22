import { int, money, pct } from "../format";
import styles from "../analytics.module.css";
import { EmptyState } from "./Card";
import { useWidth } from "./useWidth";

export interface QualityPoint {
  id: string;
  label: string;
  /** Volume de visiteurs — axe horizontal. */
  v: number;
  /** Conversion visiteur → payant — axe vertical. `null` si aucun visiteur. */
  rate: number | null;
  /** Revenu encaisse, en centimes — taille du cercle. */
  revEurCents: number;
}

interface QualityMapProps {
  rows: QualityPoint[];
  /** Conversion moyenne de la periode : la ligne de reference. */
  avg: number | null;
  onPick: (id: string) => void;
  height?: number;
}

/**
 * Volume × qualite. Une source ne se juge ni sur son seul trafic, ni sur son
 * seul taux : ce nuage met les deux sur le meme dessin, et la taille du cercle
 * ajoute le revenu reellement encaisse.
 */
export function QualityMap({ rows, avg, onPick, height = 260 }: QualityMapProps) {
  const [ref, width] = useWidth();

  const points = rows.filter((row) => row.rate != null && row.v > 0);
  if (points.length === 0 || avg == null) {
    return (
      <EmptyState>
        Il faut au moins une source avec des visiteurs et un taux mesurable pour
        dessiner ce nuage.
      </EmptyState>
    );
  }

  const pad = { l: 52, r: 26, t: 22, b: 34 };
  const innerWidth = Math.max(140, width - pad.l - pad.r);
  const innerHeight = height - pad.t - pad.b;

  const maxV = Math.max(...points.map((row) => row.v)) * 1.14 || 1;
  const maxRate =
    Math.max(...points.map((row) => row.rate ?? 0), avg) * 1.25 || 1;
  const maxRev = Math.max(...points.map((row) => row.revEurCents), 1);

  const x = (value: number) => pad.l + (value / maxV) * innerWidth;
  const y = (value: number) => pad.t + innerHeight - (value / maxRate) * innerHeight;

  return (
    <div className={styles.chartWrap} ref={ref}>
      <svg width="100%" height={height} className={styles.chartSvg} role="img"
        aria-label="Volume de visiteurs par source, croisé avec leur conversion payante">
        {[0, maxRate / 2, maxRate].map((tick) => (
          <g key={tick}>
            <line
              x1={pad.l}
              x2={pad.l + innerWidth}
              y1={y(tick)}
              y2={y(tick)}
              stroke="var(--rule-2)"
            />
            <text
              x={pad.l - 10}
              y={y(tick) + 4}
              textAnchor="end"
              fontSize="11"
              fill="var(--muted-2)"
            >
              {pct(tick, 2)}
            </text>
          </g>
        ))}

        <line
          x1={pad.l}
          x2={pad.l + innerWidth}
          y1={y(avg)}
          y2={y(avg)}
          stroke="var(--muted-2)"
          strokeDasharray="4 4"
          opacity=".8"
        />
        <text
          x={pad.l + innerWidth}
          y={pad.t - 6}
          textAnchor="end"
          fontSize="11"
          fill="var(--muted)"
        >
          ligne pointillée : moyenne {pct(avg, 2)}
        </text>

        {points.map((row) => {
          const rate = row.rate as number;
          const radius = 7 + 13 * Math.sqrt(row.revEurCents / maxRev);
          const above = rate >= avg;
          const color = above ? "var(--blue)" : "var(--muted-2)";
          return (
            <g
              key={row.id}
              onClick={() => onPick(row.id)}
              style={{ cursor: "pointer" }}
            >
              <title>
                {`${row.label} — ${int(row.v)} visiteurs, ${pct(rate, 2)} payants, ${money(row.revEurCents)}`}
              </title>
              <circle
                cx={x(row.v)}
                cy={y(rate)}
                r={radius}
                fill={color}
                opacity={above ? 0.16 : 0.12}
              />
              <circle
                cx={x(row.v)}
                cy={y(rate)}
                r={radius}
                fill="none"
                stroke={color}
                strokeWidth="1.6"
              />
              <text
                x={x(row.v)}
                y={y(rate) - radius - 7}
                textAnchor="middle"
                fontSize="12.5"
                fontWeight="600"
                fill="var(--ink)"
              >
                {row.label}
              </text>
            </g>
          );
        })}

        <text x={pad.l} y={height - 8} fontSize="11" fill="var(--muted-2)">
          peu de trafic
        </text>
        <text
          x={pad.l + innerWidth}
          y={height - 8}
          textAnchor="end"
          fontSize="11"
          fill="var(--muted-2)"
        >
          beaucoup de trafic →
        </text>
      </svg>
      <div className={styles.chartNote}>
        Axe vertical : conversion visiteur → payant. Taille du cercle : revenu
        généré. Au-dessus de la ligne = source rentable pour le volume qu'elle
        amène.
      </div>
    </div>
  );
}

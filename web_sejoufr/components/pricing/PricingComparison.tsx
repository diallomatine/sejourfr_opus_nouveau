"use client";

import { useState } from "react";
import { Check, ChevronDown, X } from "lucide-react";

type Cell = boolean | string;

interface Row {
  feature: string;
  free: Cell;
  civique: Cell;
  integral: Cell;
}

/**
 * Le comparatif oppose les deux **périmètres** (Civique, Intégral), pas des
 * durées : depuis le passage aux passes, chaque périmètre se vend en plusieurs
 * durées et la ligne « Durée d'accès » renvoie donc à la grille au-dessus.
 * L'ancienne version comparait « Essentiel 90 jours » à « Premium 365 jours »,
 * deux formules qui n'existent plus.
 */
const ROWS: Row[] = [
  {
    feature: "Examen civique (5 thèmes du livret)",
    free: "Série 1 offerte par thème",
    civique: "Tout le catalogue",
    integral: "Tout le catalogue",
  },
  {
    feature: "TCF IRN — compréhension orale et écrite",
    free: "Série 1 offerte par niveau",
    civique: false,
    integral: "Tout le catalogue",
  },
  {
    feature: "TCF IRN — expression écrite et orale",
    free: "1 essai par épreuve",
    civique: false,
    integral: true,
  },
  {
    feature: "Examens blancs chronométrés",
    free: "Examen 1 offert",
    civique: "20 par thème",
    integral: "20 par épreuve + examen TCF complet",
  },
  {
    feature: "Correction IA des productions",
    free: "Limitée",
    civique: false,
    integral: "Illimitée",
  },
  {
    feature: "Simulations orales en direct",
    free: false,
    civique: false,
    integral: "Selon le pass choisi",
  },
  { feature: "Plan personnalisé après diagnostic", free: "Lecture seule", civique: true, integral: true },
  { feature: "Suivi de progression et statistiques", free: true, civique: true, integral: true },
  {
    feature: "Durée d'accès",
    free: "Illimité",
    civique: "3 mois ou 1 an",
    integral: "7 jours, 1 mois ou 2 mois",
  },
];

function CellRender({ value }: { value: Cell }) {
  if (value === true) {
    return <Check className="pcomp-yes" aria-label="Inclus" />;
  }
  if (value === false) {
    return <X className="pcomp-no" aria-label="Non inclus" />;
  }
  return <span className="pcomp-val">{value}</span>;
}

export function PricingComparison() {
  const [openMobile, setOpenMobile] = useState(false);

  return (
    <section className="pcomp">
      <h2 className="pcomp-title editorial">Comparatif des fonctionnalités</h2>
      <p className="pcomp-sub">
        Le pass Civique couvre l&apos;examen civique ; le pass Intégral ajoute
        les quatre épreuves du TCF IRN. La durée, elle, se choisit dans la
        grille ci-dessus.
      </p>

      {/* Desktop : table */}
      <div className="pcomp-table-wrap">
        <table className="pcomp-table">
          <thead>
            <tr>
              <th className="pcomp-th pcomp-th-feat">Fonctionnalité</th>
              <th className="pcomp-th pcomp-th-center">Gratuit</th>
              <th className="pcomp-th pcomp-th-center">Civique</th>
              <th className="pcomp-th pcomp-th-center pcomp-th-featured">
                Intégral
              </th>
            </tr>
          </thead>
          <tbody>
            {ROWS.map((row, i) => (
              <tr key={row.feature} className={i % 2 === 0 ? "is-even" : "is-odd"}>
                <td className="pcomp-td pcomp-td-feat">{row.feature}</td>
                <td className="pcomp-td pcomp-td-center">
                  <CellRender value={row.free} />
                </td>
                <td className="pcomp-td pcomp-td-center">
                  <CellRender value={row.civique} />
                </td>
                <td className="pcomp-td pcomp-td-center pcomp-td-featured">
                  <CellRender value={row.integral} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Mobile : accordéon */}
      <div className="pcomp-mobile">
        <button
          type="button"
          onClick={() => setOpenMobile((s) => !s)}
          aria-expanded={openMobile}
          className="pcomp-mobile-toggle"
        >
          {openMobile ? "Masquer le détail" : "Voir le détail des fonctionnalités"}
          <ChevronDown className={`pcomp-mobile-chev ${openMobile ? "is-open" : ""}`} />
        </button>
        {openMobile && (
          <ul className="pcomp-mobile-list">
            {ROWS.map((row) => (
              <li key={row.feature} className="pcomp-mobile-item">
                <p className="pcomp-mobile-feat">{row.feature}</p>
                <dl className="pcomp-mobile-grid">
                  <div>
                    <dt>Gratuit</dt>
                    <dd>
                      <CellRender value={row.free} />
                    </dd>
                  </div>
                  <div>
                    <dt>Civique</dt>
                    <dd>
                      <CellRender value={row.civique} />
                    </dd>
                  </div>
                  <div className="pcomp-mobile-cell-featured">
                    <dt>Intégral</dt>
                    <dd>
                      <CellRender value={row.integral} />
                    </dd>
                  </div>
                </dl>
              </li>
            ))}
          </ul>
        )}
      </div>

      <style>{`
        .pcomp {
          margin-top: 56px;
          max-width: 1080px;
          margin-left: auto;
          margin-right: auto;
        }
        .pcomp-title {
          margin: 0;
          font-size: clamp(24px, 3vw, 32px);
          color: var(--color-ink);
        }
        .pcomp-sub {
          margin: 6px 0 22px;
          color: var(--color-muted);
          font-size: 14.5px;
        }
        .pcomp-table-wrap {
          display: none;
          overflow: hidden;
          border-radius: 18px;
          border: 1px solid var(--color-line);
          background: #fff;
        }
        .pcomp-table {
          width: 100%;
          border-collapse: collapse;
          text-align: left;
        }
        .pcomp-table thead tr { background: var(--color-paper-2); }
        .pcomp-th {
          padding: 14px 16px;
          font-family: var(--font-mono);
          font-size: 11.5px;
          font-weight: 600;
          letter-spacing: 0.1em;
          text-transform: uppercase;
          color: var(--color-ink-2);
        }
        .pcomp-th-center { text-align: center; }
        .pcomp-th-featured { color: var(--color-blue); }
        .pcomp-table tbody tr.is-even { background: #fff; }
        .pcomp-table tbody tr.is-odd { background: var(--color-paper); }
        .pcomp-table tbody tr { border-top: 1px solid var(--color-line-2); }
        .pcomp-td {
          padding: 14px 16px;
          font-size: 14px;
          color: var(--color-ink);
        }
        .pcomp-td-center { text-align: center; }
        .pcomp-td-featured { background: var(--color-blue-soft); }
        .pcomp-val {
          font-size: 14px;
          color: var(--color-ink-2);
        }
        .pcomp-yes {
          width: 18px; height: 18px;
          color: var(--color-green);
          margin: 0 auto;
          display: block;
        }
        .pcomp-no {
          width: 18px; height: 18px;
          color: var(--color-muted-2);
          margin: 0 auto;
          display: block;
        }
        .pcomp-mobile { display: block; }
        .pcomp-mobile-toggle {
          width: 100%;
          display: inline-flex;
          align-items: center;
          justify-content: space-between;
          padding: 14px 18px;
          min-height: 48px;
          border-radius: 14px;
          background: #fff;
          border: 1px solid var(--color-line);
          font-family: var(--font-sans);
          font-size: 14px;
          font-weight: 600;
          color: var(--color-ink);
          cursor: pointer;
        }
        .pcomp-mobile-chev {
          width: 16px; height: 16px;
          color: var(--color-muted-2);
          transition: transform 0.2s ease;
        }
        .pcomp-mobile-chev.is-open { transform: rotate(180deg); }
        .pcomp-mobile-list {
          list-style: none;
          margin: 12px 0 0;
          padding: 0;
          display: flex;
          flex-direction: column;
          gap: 10px;
        }
        .pcomp-mobile-item {
          padding: 16px;
          border-radius: 16px;
          background: #fff;
          border: 1px solid var(--color-line);
        }
        .pcomp-mobile-feat {
          margin: 0 0 10px;
          font-size: 14px;
          font-weight: 600;
          color: var(--color-ink);
        }
        .pcomp-mobile-grid {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 8px;
          text-align: center;
          margin: 0;
        }
        .pcomp-mobile-grid div {
          padding: 6px 4px;
          border-radius: 8px;
        }
        .pcomp-mobile-grid dt {
          font-family: var(--font-mono);
          font-size: 10px;
          letter-spacing: 0.1em;
          text-transform: uppercase;
          color: var(--color-muted-2);
          margin-bottom: 4px;
        }
        .pcomp-mobile-grid dd { margin: 0; }
        .pcomp-mobile-cell-featured {
          background: var(--color-blue-soft);
        }
        .pcomp-mobile-cell-featured dt {
          color: var(--color-blue);
          font-weight: 600;
        }
        @media (min-width: 768px) {
          .pcomp-table-wrap { display: block; }
          .pcomp-mobile { display: none; }
        }
        @media (min-width: 1024px) {
          .pcomp { margin-top: 72px; }
        }
      `}</style>
    </section>
  );
}

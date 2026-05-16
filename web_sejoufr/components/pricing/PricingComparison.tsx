"use client";

import { useState } from "react";
import { Check, ChevronDown, X } from "lucide-react";

type Cell = boolean | string;

interface Row {
  feature: string;
  free: Cell;
  essential: Cell;
  premium: Cell;
}

const ROWS: Row[] = [
  {
    feature: "Questions par catégorie",
    free: "5",
    essential: "Toutes (350+)",
    premium: "Toutes (350+)",
  },
  {
    feature: "Examens blancs chronométrés",
    free: "1 examen blanc",
    essential: "20 / module",
    premium: "20 / module",
  },
  { feature: "Suivi progression par catégorie", free: false, essential: true, premium: true },
  { feature: "Statistiques avancées", free: false, essential: true, premium: true },
  { feature: "Mode chronométré", free: false, essential: true, premium: true },
  { feature: "Explications pédagogiques", free: false, essential: true, premium: true },
  { feature: "Support email", free: false, essential: true, premium: true },
  {
    feature: "Durée d'accès",
    free: "Illimité",
    essential: "90 jours",
    premium: "365 jours",
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
        Tout est inclus dans les plans Essentiel et Premium — la seule
        différence est la durée d&apos;accès.
      </p>

      {/* Desktop : table */}
      <div className="pcomp-table-wrap">
        <table className="pcomp-table">
          <thead>
            <tr>
              <th className="pcomp-th pcomp-th-feat">Fonctionnalité</th>
              <th className="pcomp-th pcomp-th-center">Gratuit</th>
              <th className="pcomp-th pcomp-th-center pcomp-th-featured">
                Essentiel
              </th>
              <th className="pcomp-th pcomp-th-center">Premium</th>
            </tr>
          </thead>
          <tbody>
            {ROWS.map((row, i) => (
              <tr key={row.feature} className={i % 2 === 0 ? "is-even" : "is-odd"}>
                <td className="pcomp-td pcomp-td-feat">{row.feature}</td>
                <td className="pcomp-td pcomp-td-center">
                  <CellRender value={row.free} />
                </td>
                <td className="pcomp-td pcomp-td-center pcomp-td-featured">
                  <CellRender value={row.essential} />
                </td>
                <td className="pcomp-td pcomp-td-center">
                  <CellRender value={row.premium} />
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
                  <div className="pcomp-mobile-cell-featured">
                    <dt>Essentiel</dt>
                    <dd>
                      <CellRender value={row.essential} />
                    </dd>
                  </div>
                  <div>
                    <dt>Premium</dt>
                    <dd>
                      <CellRender value={row.premium} />
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
